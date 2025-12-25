import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:mosstroinform_mobile/app.dart';
import 'package:mosstroinform_mobile/core/config/app_config_simple.dart';
import 'package:mosstroinform_mobile/core/database/hive_service.dart';
import 'package:mosstroinform_mobile/features/auth/notifier/auth_notifier.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';

/// Функция инициализации и запуска приложения
Future<void> bootstrap() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Получаем flavor из константы компиляции или используем prod по умолчанию
    // Для платформ без поддержки flavors (Linux, Windows, Web) используется prod
    String flavor;
    AppConfigSimple config;

    try {
      flavor = AppConfigSimple.getFlavor();
    } catch (e, stackTrace) {
      if (kIsWeb) {
        debugPrint('Ошибка получения flavor: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      flavor = 'prod'; // Fallback на prod
    }

    // Инициализируем конфигурацию
    try {
      config = AppConfigSimple.fromFlavor(flavor);
    } catch (e, stackTrace) {
      if (kIsWeb) {
        debugPrint('Ошибка создания конфигурации: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      // Fallback на prod конфигурацию
      config = AppConfigSimple.prod();
    }

    // Инициализируем логгер перед использованием
    // На вебе оборачиваем в try-catch, так как Sentry может не работать
    try {
      await AppLogger.init(showLogs: kDebugMode || config.useMocks);
    } catch (e, stackTrace) {
      if (kIsWeb) {
        debugPrint('Ошибка инициализации AppLogger: $e');
        debugPrint('Stack trace: $stackTrace');
        // Продолжаем без логгера на вебе
      } else {
        rethrow; // На нативных платформах пробрасываем ошибку
      }
    }

    // Инициализируем video_player_media_kit для поддержки RTSP потоков
    // Это необходимо для воспроизведения RTSP потоков на всех платформах
    // VideoPlayerMediaKit автоматически перехватывает RTSP потоки и использует media_kit
    // Примечание: RTSP не поддерживается на вебе из-за ограничений браузеров,
    // но media_kit включен для веба для поддержки других форматов (HLS, HTTP)
    // Ошибки аудио обрабатываются в camera_view_screen.dart и не останавливают воспроизведение видео
    // На вебе MediaKit может не работать, поэтому пропускаем инициализацию
    if (!kIsWeb) {
      try {
        MediaKit.ensureInitialized();
        VideoPlayerMediaKit.ensureInitialized(
          android: true,
          iOS: true,
          macOS: true,
          windows: true,
          linux: true,
          web: false, // На вебе не используем media_kit
        );
      } catch (e, stackTrace) {
        AppLogger.error('Ошибка при инициализации MediaKit/VideoPlayerMediaKit: $e', stackTrace);
        // Продолжаем запуск приложения, даже если MediaKit не удалось инициализировать
      }
    } else {
      if (kIsWeb) {
        debugPrint('MediaKit пропущен на вебе');
      } else {
        AppLogger.log('MediaKit пропущен на вебе');
      }
    }

    // Устанавливаем только вертикальную ориентацию для всего приложения
    // На вебе это не поддерживается, поэтому пропускаем
    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    // В production можно логировать текущее окружение
    AppLogger.log('Запуск приложения с flavor: $flavor');
    AppLogger.log('Окружение: ${config.environmentName}');
    AppLogger.log('Использование моков: ${config.useMocks}');
    AppLogger.log('Base URL: ${config.baseUrl}');

    // Инициализируем settings box для хранения настроек (тема и т.д.) в любом режиме
    try {
      await HiveService.initializeSettings();
      if (kIsWeb) {
        debugPrint('Hive settings box инициализирован');
      } else {
        AppLogger.log('Hive settings box инициализирован');
      }
    } catch (e, stackTrace) {
      if (kIsWeb) {
        debugPrint('Ошибка при инициализации Hive settings: $e');
        debugPrint('Stack trace: $stackTrace');
      } else {
        AppLogger.error('Ошибка при инициализации Hive settings: $e', e, stackTrace);
      }
      // Не прерываем запуск приложения, даже если Hive не удалось инициализировать
    }

    // Инициализируем полную Hive базу данных в моковом режиме
    if (config.useMocks) {
      try {
        await HiveService.initialize();
        if (kIsWeb) {
          debugPrint('Hive база данных инициализирована');
        } else {
          AppLogger.log('Hive база данных инициализирована');
        }
      } catch (e, stackTrace) {
        if (kIsWeb) {
          debugPrint('Ошибка при инициализации Hive: $e');
          debugPrint('Stack trace: $stackTrace');
        } else {
          AppLogger.error('Ошибка при инициализации Hive: $e', e, stackTrace);
        }
        // Не прерываем запуск приложения, даже если Hive не удалось инициализировать
      }
    }

    // Создаем контейнер для предзагрузки авторизации
    // Этот контейнер будет использоваться на протяжении всего жизненного цикла приложения
    // На вебе может быть проблема с observers, поэтому используем условно
    final container = ProviderContainer(observers: kIsWeb ? [] : [AppLogger.riverpodObserver]);

    // Предзагружаем состояние авторизации до запуска приложения
    // Это позволяет роутеру сразу определить правильный initialLocation
    if (kIsWeb) {
      debugPrint('Bootstrap: проверка авторизации...');
    } else {
      AppLogger.log('Bootstrap: проверка авторизации...');
    }
    try {
      final authState = await container.read(authProvider.future);
      if (kIsWeb) {
        debugPrint(
          'Bootstrap: авторизация проверена, isAuthenticated=${authState.isAuthenticated}, '
          'user=${authState.user?.email ?? "null"}',
        );
      } else {
        AppLogger.log(
          'Bootstrap: авторизация проверена, isAuthenticated=${authState.isAuthenticated}, '
          'user=${authState.user?.email ?? "null"}',
        );
      }
    } catch (e, stackTrace) {
      if (kIsWeb) {
        debugPrint('Bootstrap: ошибка при проверке авторизации: $e');
        debugPrint('Stack trace: $stackTrace');
      } else {
        AppLogger.error('Bootstrap: ошибка при проверке авторизации: $e', e, stackTrace);
      }
      // Продолжаем запуск даже при ошибке - роутер покажет экран логина
    }

    // Запускаем приложение с предзагруженным контейнером
    // UncontrolledProviderScope позволяет использовать предзагруженный контейнер
    // Контейнер будет автоматически dispose при закрытии приложения через Flutter
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: MosstroinformApp(config: config),
      ),
    );
  } catch (e, stackTrace) {
    // Критическая ошибка при инициализации - логируем и показываем ошибку
    // На вебе это может быть единственный способ увидеть ошибку
    if (kIsWeb) {
      // На вебе выводим ошибку в консоль браузера
      debugPrint('КРИТИЧЕСКАЯ ОШИБКА ПРИ ИНИЦИАЛИЗАЦИИ: $e');
      debugPrint('Stack trace: $stackTrace');
    }
    // Пытаемся запустить приложение с минимальной конфигурацией
    try {
      runApp(
        MaterialApp(
          title: 'МосСтройИнформ',
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка инициализации: $e'),
                  const SizedBox(height: 8),
                  const Text(
                    'Проверьте консоль браузера для деталей',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      // Если даже это не сработало, ничего не делаем
      rethrow;
    }
  }
}
