import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
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

Future<void> bootstrap() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    String flavor;
    AppConfigSimple config;

    try {
      flavor = AppConfigSimple.getFlavor();
    } catch (e, stackTrace) {
      if (kIsWeb && kDebugMode) {
        AppLogger.error('Ошибка получения flavor', e, stackTrace);
      }
      flavor = 'prod';
    }

    try {
      config = AppConfigSimple.fromFlavor(flavor);
    } catch (e, stackTrace) {
      if (kIsWeb && kDebugMode) {
        AppLogger.error('Ошибка создания конфигурации', e, stackTrace);
      }
      config = AppConfigSimple.prod();
    }

    try {
      await AppLogger.init(showLogs: kDebugMode || config.useMocks);
    } catch (e, stackTrace) {
      if (kIsWeb && kDebugMode) {
        AppLogger.error('Ошибка инициализации AppLogger', e, stackTrace);
      } else {
        rethrow;
      }
    }

    if (!kIsWeb) {
      try {
        MediaKit.ensureInitialized();
        VideoPlayerMediaKit.ensureInitialized(
          android: true,
          iOS: true,
          macOS: true,
          windows: true,
          linux: true,
          web: false,
        );
      } catch (e, stackTrace) {
        AppLogger.error('Ошибка при инициализации MediaKit/VideoPlayerMediaKit', e, stackTrace);
      }
    }

    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }

    AppLogger.debug('Запуск приложения с flavor: $flavor');
    AppLogger.debug('Окружение: ${config.environmentName}');
    AppLogger.debug('Использование моков: ${config.useMocks}');
    AppLogger.debug('Base URL: ${config.baseUrl}');

    try {
      await HiveService.initializeSettings();
    } catch (e, stackTrace) {
      if (kIsWeb && kDebugMode) {
        AppLogger.error('Ошибка при инициализации Hive settings', e, stackTrace);
      } else {
        AppLogger.error('Ошибка при инициализации Hive settings', e, stackTrace);
      }
    }

    if (config.useMocks) {
      try {
        await HiveService.initialize();
      } catch (e, stackTrace) {
        if (kIsWeb && kDebugMode) {
          AppLogger.error('Ошибка при инициализации Hive', e, stackTrace);
        } else {
          AppLogger.error('Ошибка при инициализации Hive', e, stackTrace);
        }
      }
    }

    final container = ProviderContainer(observers: kIsWeb ? [] : [AppLogger.riverpodObserver]);

    try {
      final authState = await container.read(authProvider.future);
      AppLogger.log(
        'Bootstrap: авторизация проверена, isAuthenticated=${authState.isAuthenticated}, '
        'user=${authState.user?.email ?? "null"}',
      );
    } catch (e, stackTrace) {
      if (kIsWeb && kDebugMode) {
        AppLogger.error('Bootstrap: ошибка при проверке авторизации', e, stackTrace);
      } else {
        AppLogger.error('Bootstrap: ошибка при проверке авторизации', e, stackTrace);
      }
    }

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: MosstroinformApp(config: config),
      ),
    );
  } catch (e, stackTrace) {
    if (kIsWeb && kDebugMode) {
      AppLogger.error('КРИТИЧЕСКАЯ ОШИБКА ПРИ ИНИЦИАЛИЗАЦИИ', e, stackTrace);
    }
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
      AppLogger.error('Ошибка при запуске приложения: $e', e, stackTrace);
    }
  }
}
