import 'dart:io' show Platform;

import 'package:background_downloader/background_downloader.dart';
import 'package:mosstroinform_mobile/core/utils/logger.dart';
import 'package:mosstroinform_mobile/shared/file_download/data/datasources/file_download_data_source.dart';

class FileDownloadDataSourceImpl implements FileDownloadDataSource {
  static bool _notificationsConfigured = false;
  static final Map<String, String> _filePathsInSharedStorage = {};
  static final Map<String, DownloadTask> _tasksForIOS = {};

  FileDownloadDataSourceImpl();

  Future<PermissionStatus> _configureNotifications() async {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      AppLogger.info('Notifications are not supported on desktop platforms (macOS/Windows/Linux)');
      AppLogger.info('Progress updates should be shown within the application UI');
      _notificationsConfigured = true;
      return PermissionStatus.denied;
    }

    if (_notificationsConfigured) {
      final permissionType = PermissionType.notifications;
      return await FileDownloader().permissions.status(permissionType);
    }

    try {
      final permissionType = PermissionType.notifications;
      var status = await FileDownloader().permissions.status(permissionType);

      if (status != PermissionStatus.granted) {
        AppLogger.info('Requesting notification permission...');
        status = await FileDownloader().permissions.request(permissionType);
        AppLogger.info('Notification permission status: $status');
      }

      final notificationStatus = status;

      FileDownloader().configureNotification(
        running: const TaskNotification('Скачивание', 'Файл: {filename}'),
        complete: const TaskNotification('Скачивание завершено', 'Нажмите, чтобы открыть {filename}'),
        error: const TaskNotification('Ошибка скачивания', 'Не удалось скачать {filename}'),
        progressBar: true,
        tapOpensFile: false,
      );

      FileDownloader().registerCallbacks(
        taskNotificationTapCallback: (task, notificationType) {
          final taskId = task.taskId.toString();
          final filePath = _filePathsInSharedStorage[taskId];
          if (filePath != null) {
            AppLogger.info('Opening file from shared storage: $filePath');
            FileDownloader().openFile(filePath: filePath).then((success) {
              if (success) {
                AppLogger.info('File opened successfully');
              } else {
                AppLogger.warning('Failed to open file from shared storage: $filePath');
              }
            });
          } else if (Platform.isIOS) {
            AppLogger.info('Opening file via task (iOS): $taskId');
            FileDownloader().openFile(task: task).then((success) {
              if (success) {
                AppLogger.info('File opened successfully');
              } else {
                AppLogger.warning('Failed to open file via task: $taskId');
              }
            });
          } else {
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
      await _configureNotifications();

      final encodedUrl = _encodeUrl(url);

      final uri = Uri.tryParse(url);
      String fileName = 'file';
      if (uri != null && uri.pathSegments.isNotEmpty) {
        fileName = uri.pathSegments.last.split('?').first;
        try {
          fileName = Uri.decodeComponent(fileName);
        } catch (_) {
          // ignore
        }
      }

      final safeFileName = _transliterateFileName(fileName);

      AppLogger.info('Starting download: originalUrl=$url, encodedUrl=$encodedUrl, filename=$safeFileName');

      final baseDirectory = Platform.isIOS
          ? BaseDirectory.applicationDocuments
          : Platform.isAndroid
          ? BaseDirectory.applicationSupport
          : BaseDirectory.applicationDocuments;
      final task = DownloadTask(
        url: encodedUrl,
        filename: safeFileName,
        baseDirectory: baseDirectory,
        updates: Updates.statusAndProgress,
      );

      final result = await FileDownloader().download(
        task,
        onProgress: (progress) {
          AppLogger.info('Download progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
        onStatus: (status) {
          AppLogger.info('Download status: $status');
        },
      );

      final status = result.status;
      AppLogger.info('Download result status: $status');

      if (status == TaskStatus.complete) {
        AppLogger.info('File downloaded successfully: $safeFileName');

        String? filePathInSharedStorage;

        if (Platform.isAndroid) {
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
          }

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
          }
        } else if (Platform.isMacOS) {
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
          }
        }

        final taskId = task.taskId.toString();
        if (filePathInSharedStorage != null) {
          _filePathsInSharedStorage[taskId] = filePathInSharedStorage;
          AppLogger.info('File path saved for opening: $taskId -> $filePathInSharedStorage');
        } else if (Platform.isIOS) {
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

  String _transliterateFileName(String fileName) {
    final hasCyrillic = fileName.runes.any((rune) => rune >= 0x0400 && rune <= 0x04FF);
    if (!hasCyrillic) {
      return fileName;
    }

    final extension = fileName.contains('.') ? fileName.split('.').last : '';
    final nameWithoutExt = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;

    final transliterated = _transliterateText(nameWithoutExt);
    return extension.isNotEmpty ? '$transliterated.$extension' : transliterated;
  }

  String _transliterateText(String text) {
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

  String _encodeUrl(String url) {
    try {
      if (url.contains('%') && RegExp(r'%[0-9A-Fa-f]{2}').hasMatch(url)) {
        return url;
      }

      final uriMatch = RegExp(r'^([^:]+://[^/]+)(/.*)?$').firstMatch(url);
      if (uriMatch == null) {
        return url;
      }

      final baseUrl = uriMatch.group(1) ?? '';
      final pathPart = uriMatch.group(2) ?? '';

      if (pathPart.isEmpty) {
        return url;
      }

      final pathSegments = pathPart.split('/').where((s) => s.isNotEmpty).toList();
      final encodedSegments = pathSegments.map((segment) {
        if (segment.runes.any((rune) => rune > 127)) {
          return Uri.encodeComponent(segment);
        }
        return segment;
      }).toList();

      final encodedPath = '/${encodedSegments.join('/')}';
      return baseUrl + encodedPath;
    } catch (e) {
      AppLogger.warning('Could not encode URL, using original: $url, error: $e');
      return url;
    }
  }

  static Future<bool> openFileByTaskId(String taskId) async {
    final filePath = _filePathsInSharedStorage[taskId];
    if (filePath != null) {
      final success = await FileDownloader().openFile(filePath: filePath);
      if (success) {
        _filePathsInSharedStorage.remove(taskId);
      }
      return success;
    }

    final task = _tasksForIOS[taskId];
    if (task != null) {
      final success = await FileDownloader().openFile(task: task);
      if (success) {
        _tasksForIOS.remove(taskId);
      }
      return success;
    }

    return false;
  }

  static String? getLastDownloadedTaskId() {
    if (_filePathsInSharedStorage.isNotEmpty) {
      return _filePathsInSharedStorage.keys.last;
    }
    if (_tasksForIOS.isNotEmpty) {
      return _tasksForIOS.keys.last;
    }
    return null;
  }

  static String? getLastDownloadedFilePath() {
    if (_filePathsInSharedStorage.isNotEmpty) {
      return _filePathsInSharedStorage.values.last;
    }
    return null;
  }
}
