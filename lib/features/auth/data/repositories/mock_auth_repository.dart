import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mosstroinform_mobile/core/config/app_config_simple.dart';
import 'package:mosstroinform_mobile/core/database/hive_service.dart';
import 'package:mosstroinform_mobile/core/utils/logger.dart';
import 'package:mosstroinform_mobile/features/auth/data/datasources/mock_auth_remote_data_source.dart';
import 'package:mosstroinform_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mosstroinform_mobile/features/auth/domain/entities/user.dart';
import 'package:mosstroinform_mobile/features/auth/domain/repositories/auth_repository.dart';

/// Mock реализация репозитория авторизации для тестирования
/// Использует MockAuthRemoteDataSource для имитации API вызовов
class MockAuthRepository implements AuthRepository {
  final FlutterSecureStorage secureStorage;
  late final AuthRepository _impl;

  MockAuthRepository({required this.secureStorage}) {
    // Используем AuthRepositoryImpl с MockAuthRemoteDataSource
    // Это позволяет использовать тот же код что и в реальном API
    final mockDataSource = MockAuthRemoteDataSource(secureStorage: secureStorage);
    _impl = AuthRepositoryImpl(remoteDataSource: mockDataSource, secureStorage: secureStorage);
  }

  @override
  Future<String> login(String email, String password) async {
    final token = await _impl.login(email, password);

    // Очищаем базу данных при логине, чтобы начать с чистого листа
    // Проекты загрузятся автоматически при первом обращении к списку проектов
    try {
      final flavor = AppConfigSimple.getFlavor();
      final config = AppConfigSimple.fromFlavor(flavor);
      if (config.useMocks) {
        await HiveService.clearUserData();
        AppLogger.info('MockAuthRepository.login: моковая база данных очищена, будет создана с нуля');
      }
    } catch (e) {
      AppLogger.warning('MockAuthRepository.login: ошибка при очистке базы данных: $e');
      // Не прерываем логин, даже если очистка не удалась
    }

    return token;
  }

  @override
  Future<String> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    final token = await _impl.register(email: email, password: password, name: name, phone: phone);

    // Очищаем базу данных при регистрации, чтобы начать с чистого листа
    // Проекты загрузятся автоматически при первом обращении к списку проектов
    try {
      final flavor = AppConfigSimple.getFlavor();
      final config = AppConfigSimple.fromFlavor(flavor);
      if (config.useMocks) {
        await HiveService.clearUserData();
        AppLogger.info('MockAuthRepository.register: моковая база данных очищена, будет создана с нуля');
      }
    } catch (e) {
      AppLogger.warning('MockAuthRepository.register: ошибка при очистке базы данных: $e');
      // Не прерываем регистрацию, даже если очистка не удалась
    }

    return token;
  }

  @override
  Future<void> logout() async {
    await _impl.logout();

    // Очищаем всю моковую базу данных при logout (только в моковом режиме)
    // При новом логине база будет создана с нуля
    try {
      final flavor = AppConfigSimple.getFlavor();
      final config = AppConfigSimple.fromFlavor(flavor);
      if (config.useMocks) {
        await HiveService.clearUserData();
        AppLogger.info(
          'MockAuthRepository.logout: вся моковая база данных очищена, будет создана с нуля при следующем логине',
        );
      }
    } catch (e) {
      AppLogger.warning('MockAuthRepository.logout: ошибка при очистке базы данных: $e');
      // Не прерываем logout, даже если очистка базы не удалась
    }
  }

  @override
  Future<User> getCurrentUser() => _impl.getCurrentUser();

  @override
  Future<bool> isAuthenticated() => _impl.isAuthenticated();

  @override
  Future<String?> getAccessToken() => _impl.getAccessToken();

  @override
  Future<String> refreshToken() => _impl.refreshToken();
}
