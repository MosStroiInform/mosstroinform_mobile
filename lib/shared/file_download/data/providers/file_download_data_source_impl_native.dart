import 'dart:io' show Platform;

import 'package:background_downloader/background_downloader.dart';
import 'package:mosstroinform_mobile/core/utils/logger.dart';
import 'package:mosstroinform_mobile/shared/file_download/data/datasources/file_download_data_source.dart';

/// Реализация источника данных для скачивания файлов на нативных платформах
/// Использует background_downloader для фонового скачивания файлов
class FileDownloadDataSourceImpl implements FileDownloadDataSource {
  static bool _notificationsConfigured = false;
  // Храним пути к файлам в shared storage для открытия, если разрешения на уведомления нет
  // Ключ - taskId, значение - путь к файлу в shared storage (Android/macOS) или taskId (iOS)
  static final Map<String, String> _filePathsInSharedStorage = {};
  // Храним задачи для открытия на iOS (файлы в applicationDocuments, открываются через task)
  static final Map<String, DownloadTask> _tasksForIOS = {};

  FileDownloadDataSourceImpl();

  /// Настраивает уведомления для скачивания файлов
  /// Возвращает статус разрешения на уведомления
  /// Примечание: на desktop платформах (macOS, Windows, Linux) уведомления не поддерживаются
  /// согласно документации background_downloader, так как там нет true background mode
  Future<PermissionStatus> _configureNotifications() async {
    // На desktop платформах уведомления не поддерживаются
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      AppLogger.info('Notifications are not supported on desktop platforms (macOS/Windows/Linux)');
      AppLogger.info('Progress updates should be shown within the application UI');
      _notificationsConfigured = true;
      return PermissionStatus.denied; // Desktop platforms don't support notifications
    }

    if (_notificationsConfigured) {
      // Если уже настроено, проверяем текущий статус разрешения
      final permissionType = PermissionType.notifications;
      return await FileDownloader().permissions.status(permissionType);
    }

    try {
      // Запрашиваем разрешение на уведомления (только для iOS и Android)
      final permissionType = PermissionType.notifications;
      var status = await FileDownloader().permissions.status(permissionType);

      if (status != PermissionStatus.granted) {
        AppLogger.info('Requesting notification permission...');
        status = await FileDownloader().permissions.request(permissionType);
        AppLogger.info('Notification permission status: $status');
      }

      // Сохраняем статус разрешения для использования
      final notificationStatus = status;

      // Настраиваем уведомления (только для iOS и Android)
      FileDownloader().configureNotification(
        running: const TaskNotification('Скачивание', 'Файл: {filename}'),
        complete: const TaskNotification('Скачивание завершено', 'Нажмите, чтобы открыть {filename}'),
        error: const TaskNotification('Ошибка скачивания', 'Не удалось скачать {filename}'),
        progressBar: true,
        tapOpensFile: false, // Открываем файл вручную через callback, так как файл в shared storage
      );

      // Регистрируем callback для открытия файла при нажатии на уведомление
      // На Android/macOS: используем путь из shared storage
      // На iOS: используем task напрямую (файл в applicationDocuments)
      FileDownloader().registerCallbacks(
        taskNotificationTapCallback: (task, notificationType) {
          final taskId = task.taskId.toString();
          final filePath = _filePathsInSharedStorage[taskId];
          if (filePath != null) {
            // Android/macOS: открываем через filePath из shared storage
            AppLogger.info('Opening file from shared storage: $filePath');
            FileDownloader().openFile(filePath: filePath).then((success) {
              if (success) {
                AppLogger.info('File opened successfully');
              } else {
                AppLogger.warning('Failed to open file from shared storage: $filePath');
              }
            });
          } else if (Platform.isIOS) {
            // iOS: открываем через task (файл в applicationDocuments)
            AppLogger.info('Opening file via task (iOS): $taskId');
            FileDownloader().openFile(task: task).then((success) {
              if (success) {
                AppLogger.info('File opened successfully');
              } else {
                AppLogger.warning('Failed to open file via task: $taskId');
              }
            });
          } else {
            // Fallback: пытаемся открыть через task
            AppLogger.warning('File path not found for taskId: $taskId, trying to open via task');
            FileDownloader().openFile(task: task);
          }
        },
      );

      _notificationsConfigured = true;
      AppLogger.info('File download notifications configured');
      return notificationStatus;
    } catch (e) {
      AppLogger.warning('Could not configure download notifications: $e');
      return PermissionStatus.denied;
    }
  }

  @override
  Future<void> downloadFile(String url) async {
    try {
      // Убеждаемся, что уведомления настроены перед скачиванием
      await _configureNotifications();

      // Кодируем URL, если содержит кириллицу или не-ASCII символы
      final encodedUrl = _encodeUrl(url);

      // Извлекаем имя файла из оригинального URL для транслитерации
      final uri = Uri.tryParse(url);
      String fileName = 'file';
      if (uri != null && uri.pathSegments.isNotEmpty) {
        fileName = uri.pathSegments.last.split('?').first;
        // Пытаемся декодировать, если закодировано, иначе используем как есть
        try {
          fileName = Uri.decodeComponent(fileName);
        } catch (_) {
          // Если не удалось декодировать, используем как есть
        }
      }

      // Транслитерируем имя файла, если содержит кириллицу
      final safeFileName = _transliterateFileName(fileName);

      AppLogger.info('Starting download: originalUrl=$url, encodedUrl=$encodedUrl, filename=$safeFileName');

      // Создаем задачу на скачивание с закодированным URL
      // На iOS: используем BaseDirectory.applicationDocuments, чтобы файлы были видны в Files browser
      // (согласно документации: на iOS не нужно перемещать в shared storage, достаточно скачать в applicationDocuments
      //  и добавить LSSupportsOpeningDocumentsInPlace и UIFileSharingEnabled в Info.plist)
      // На Android: используем BaseDirectory.applicationSupport, так как applicationDocuments не может быть открыт,
      // затем переместим в shared storage
      // На других платформах: используем BaseDirectory.applicationDocuments
      final baseDirectory = Platform.isIOS
          ? BaseDirectory.applicationDocuments
          : Platform.isAndroid
          ? BaseDirectory.applicationSupport
          : BaseDirectory.applicationDocuments;
      // На iOS: важно не использовать параметр directory, чтобы файлы сохранялись
      // прямо в корень applicationDocuments, а не в поддиректорию
      // Файлы в поддиректориях могут быть не видны в Files app
      // Согласно документации background_downloader, если directory не указан,
      // файлы сохраняются в корень baseDirectory
      final task = DownloadTask(
        url: encodedUrl,
        filename: safeFileName,
        baseDirectory: baseDirectory,
        // Явно не указываем directory, чтобы файлы были в корне baseDirectory
        // Это важно для iOS, чтобы файлы были видны в Files app
        updates: Updates.statusAndProgress,
      );

      // Запускаем скачивание и ждем завершения
      final result = await FileDownloader().download(
        task,
        onProgress: (progress) {
          AppLogger.info('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
        onStatus: (status) {
          AppLogger.info('Download status: $status');
        },
      );

      // Проверяем результат (result - это TaskStatusUpdate)
      final status = result.status;
      AppLogger.info('Download result status: $status');

      if (status == TaskStatus.complete) {
        AppLogger.info('File downloaded successfully: $safeFileName');

        // На iOS: логируем путь к файлу для отладки
        if (Platform.isIOS) {
          try {
            // Получаем путь к файлу через task
            // Файл должен быть в applicationDocuments для видимости в Files app
            AppLogger.info('iOS: File saved to applicationDocuments directory');
            AppLogger.info('iOS: Filename: $safeFileName');
            AppLogger.info('iOS: Task ID: ${task.taskId}');
            AppLogger.info('iOS: BaseDirectory: $baseDirectory');
            // Примечание: для видимости в Files app файлы должны быть в корне Documents,
            // не в поддиректориях. Убедитесь, что Info.plist содержит:
            // LSSupportsOpeningDocumentsInPlace = true
            // UIFileSharingEnabled = true
            // И перезапустите приложение после изменения Info.plist
          } catch (e) {
            AppLogger.warning('Could not log iOS file path: $e');
          }
        }

        String? filePathInSharedStorage;

        // На iOS: НЕ перемещаем в shared storage, так как файлы уже в applicationDocuments
        // и будут видны в Files browser благодаря LSSupportsOpeningDocumentsInPlace и UIFileSharingEnabled в Info.plist
        // Согласно документации: на iOS moveToSharedStorage для .downloads создает "fake" директорию,
        // которая не доступна другим пользователям, поэтому лучше использовать applicationDocuments
        if (Platform.isAndroid) {
          // На Android: перемещаем файл в shared storage (Downloads), чтобы пользователь мог его видеть и открывать
          // Согласно документации: на Android файлы в BaseDirectory.applicationDocuments не могут быть открыты,
          // поэтому нужно переместить файл в shared storage перед попыткой открыть

          // Проверяем и запрашиваем разрешение на shared storage (для Android API 29 и ниже)
          // Согласно документации: для moveToSharedStorage на Android может потребоваться androidSharedStorage permission
          try {
            final sharedStoragePermissionType = PermissionType.androidSharedStorage;
            var sharedStorageStatus = await FileDownloader().permissions.status(sharedStoragePermissionType);

            if (sharedStorageStatus != PermissionStatus.granted) {
              AppLogger.info('Requesting androidSharedStorage permission...');
              sharedStorageStatus = await FileDownloader().permissions.request(sharedStoragePermissionType);
              AppLogger.info('androidSharedStorage permission status: $sharedStorageStatus');
            }
          } catch (e) {
            AppLogger.warning('Could not check/request androidSharedStorage permission: $e');
            // Продолжаем попытку перемещения, так как на Android 30+ permission не требуется
          }

          // Перемещаем файл в shared storage (Downloads)
          try {
            final newFilePath = await FileDownloader().moveToSharedStorage(task, SharedStorage.downloads);
            if (newFilePath != null) {
              filePathInSharedStorage = newFilePath;
              AppLogger.info('File moved to shared storage: $newFilePath');
            } else {
              AppLogger.warning('Could not move file to shared storage, but download completed');
            }
          } catch (e) {
            AppLogger.warning('Error moving file to shared storage: $e, but download completed');
            // Не бросаем исключение, так как файл уже скачан
          }
        } else if (Platform.isMacOS) {
          // На macOS: перемещаем в Downloads (требует App Sandbox entitlements)
          // Согласно документации: для .downloads на macOS нужно включить
          // com.apple.security.files.downloads.read-write в entitlements
          try {
            final newFilePath = await FileDownloader().moveToSharedStorage(task, SharedStorage.downloads);
            if (newFilePath != null) {
              filePathInSharedStorage = newFilePath;
              AppLogger.info('File moved to shared storage: $newFilePath');
            } else {
              AppLogger.warning('Could not move file to shared storage, but download completed');
            }
          } catch (e) {
            AppLogger.warning('Error moving file to shared storage: $e, but download completed');
            // Не бросаем исключение, так как файл уже скачан
          }
        } else {
          // На других платформах (Windows, Linux): файл уже в applicationDocuments, можно использовать напрямую
          // Для открытия файла можно использовать путь из task
          AppLogger.info('File downloaded to applicationDocuments, can be opened directly');
        }

        // Сохраняем путь к файлу для открытия через уведомление или snackbar
        // На iOS используем task напрямую (файл в applicationDocuments, виден в Files),
        // на Android/macOS - путь из shared storage
        final taskId = task.taskId.toString();
        if (filePathInSharedStorage != null) {
          _filePathsInSharedStorage[taskId] = filePathInSharedStorage;
          AppLogger.info('File path saved for opening: $taskId -> $filePathInSharedStorage');
        } else if (Platform.isIOS) {
          // На iOS файл в applicationDocuments, для открытия используем task напрямую
          // Сохраняем task для открытия через task (не через filePath)
          _tasksForIOS[taskId] = task;
          AppLogger.info('File saved in applicationDocuments (iOS), will open via task: $taskId');
        }
      } else if (status == TaskStatus.failed) {
        final exception = result.exception;
        final errorMessage = exception != null
            ? 'Download failed: ${exception.toString()}'
            : 'Download failed with unknown error';
        AppLogger.error('Download failed: $errorMessage', null, null);
        throw Exception(errorMessage);
      } else if (status == TaskStatus.canceled) {
        throw Exception('Download was canceled');
      } else if (status == TaskStatus.notFound) {
        final exception = result.exception;
        final errorMessage = exception != null
            ? 'File not found: ${exception.toString()}'
            : 'File not found at URL: $encodedUrl';
        AppLogger.error('File not found: $errorMessage', null, null);
        throw Exception(errorMessage);
      } else {
        throw Exception('Download did not complete: $status');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error downloading file: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Транслитерирует кириллицу в латиницу для имени файла
  String _transliterateFileName(String fileName) {
    // Проверяем, содержит ли имя файла кириллицу
    final hasCyrillic = fileName.runes.any((rune) => rune >= 0x0400 && rune <= 0x04FF);
    if (!hasCyrillic) {
      return fileName;
    }

    // Разделяем на имя и расширение
    final extension = fileName.contains('.') ? fileName.split('.').last : '';
    final nameWithoutExt = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;

    // Транслитерируем только имя без расширения
    final transliterated = _transliterateText(nameWithoutExt);
    return extension.isNotEmpty ? '$transliterated.$extension' : transliterated;
  }

  /// Транслитерация кириллицы в латиницу
  String _transliterateText(String text) {
    // Простая замена кириллицы на латиницу
    final cyrillicToLatin = {
      'а': 'a',
      'б': 'b',
      'в': 'v',
      'г': 'g',
      'д': 'd',
      'е': 'e',
      'ё': 'yo',
      'ж': 'zh',
      'з': 'z',
      'и': 'i',
      'й': 'y',
      'к': 'k',
      'л': 'l',
      'м': 'm',
      'н': 'n',
      'о': 'o',
      'п': 'p',
      'р': 'r',
      'с': 's',
      'т': 't',
      'у': 'u',
      'ф': 'f',
      'х': 'h',
      'ц': 'ts',
      'ч': 'ch',
      'ш': 'sh',
      'щ': 'sch',
      'ъ': '',
      'ы': 'y',
      'ь': '',
      'э': 'e',
      'ю': 'yu',
      'я': 'ya',
      'А': 'A',
      'Б': 'B',
      'В': 'V',
      'Г': 'G',
      'Д': 'D',
      'Е': 'E',
      'Ё': 'Yo',
      'Ж': 'Zh',
      'З': 'Z',
      'И': 'I',
      'Й': 'Y',
      'К': 'K',
      'Л': 'L',
      'М': 'M',
      'Н': 'N',
      'О': 'O',
      'П': 'P',
      'Р': 'R',
      'С': 'S',
      'Т': 'T',
      'У': 'U',
      'Ф': 'F',
      'Х': 'H',
      'Ц': 'Ts',
      'Ч': 'Ch',
      'Ш': 'Sh',
      'Щ': 'Sch',
      'Ъ': '',
      'Ы': 'Y',
      'Ь': '',
      'Э': 'E',
      'Ю': 'Yu',
      'Я': 'Ya',
    };

    return text.split('').map((char) => cyrillicToLatin[char] ?? char).join();
  }

  /// Кодирует URL, правильно обрабатывая кириллицу в пути
  String _encodeUrl(String url) {
    try {
      // Проверяем, содержит ли URL уже закодированные символы
      if (url.contains('%') && RegExp(r'%[0-9A-Fa-f]{2}').hasMatch(url)) {
        // URL уже закодирован, используем как есть
        return url;
      }

      // Разделяем URL на базовую часть и путь
      final uriMatch = RegExp(r'^([^:]+://[^/]+)(/.*)?$').firstMatch(url);
      if (uriMatch == null) {
        return url;
      }

      final baseUrl = uriMatch.group(1) ?? '';
      final pathPart = uriMatch.group(2) ?? '';

      if (pathPart.isEmpty) {
        return url;
      }

      // Разбиваем путь на сегменты и кодируем только те, что содержат не-ASCII
      final pathSegments = pathPart.split('/').where((s) => s.isNotEmpty).toList();
      final encodedSegments = pathSegments.map((segment) {
        // Если содержит не-ASCII, кодируем
        if (segment.runes.any((rune) => rune > 127)) {
          return Uri.encodeComponent(segment);
        }
        return segment;
      }).toList();

      // Собираем закодированный путь
      final encodedPath = '/${encodedSegments.join('/')}';
      return baseUrl + encodedPath;
    } catch (e) {
      AppLogger.warning('Could not encode URL, using original: $url, error: $e');
      return url;
    }
  }

  /// Открывает файл по taskId (используется когда разрешения на уведомления нет)
  /// На Android/macOS: использует путь к файлу в shared storage после moveToSharedStorage
  /// На iOS: использует task напрямую (файл в applicationDocuments)
  static Future<bool> openFileByTaskId(String taskId) async {
    // Проверяем, есть ли путь в shared storage (Android/macOS)
    final filePath = _filePathsInSharedStorage[taskId];
    if (filePath != null) {
      // Используем filePath из shared storage для открытия файла
      final success = await FileDownloader().openFile(filePath: filePath);
      if (success) {
        _filePathsInSharedStorage.remove(taskId);
      }
      return success;
    }

    // Проверяем, есть ли task для iOS
    final task = _tasksForIOS[taskId];
    if (task != null) {
      // На iOS открываем через task (файл в applicationDocuments)
      final success = await FileDownloader().openFile(task: task);
      if (success) {
        _tasksForIOS.remove(taskId);
      }
      return success;
    }

    return false;
  }

  /// Получает taskId для последнего скачанного файла (если разрешения на уведомления нет)
  static String? getLastDownloadedTaskId() {
    if (_filePathsInSharedStorage.isNotEmpty) {
      return _filePathsInSharedStorage.keys.last;
    }
    if (_tasksForIOS.isNotEmpty) {
      return _tasksForIOS.keys.last;
    }
    return null;
  }

  /// Получает путь к последнему скачанному файлу
  /// На Android/macOS: возвращает путь в shared storage
  /// На iOS: возвращает путь в applicationDocuments или null (файл виден в Files app)
  static String? getLastDownloadedFilePath() {
    if (_filePathsInSharedStorage.isNotEmpty) {
      return _filePathsInSharedStorage.values.last;
    }
    // На iOS файлы в applicationDocuments, путь не возвращаем (файл виден в Files app)
    return null;
  }
}
