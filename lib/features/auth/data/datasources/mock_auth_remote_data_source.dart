import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mosstroinform_mobile/core/errors/failures.dart';
import 'package:mosstroinform_mobile/core/storage/secure_storage_provider.dart';
import 'package:mosstroinform_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mosstroinform_mobile/features/auth/data/models/user_model.dart';

/// Mock реализация удалённого источника данных для авторизации
/// Имитирует API вызовы, но данные берёт из secure storage
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  final FlutterSecureStorage secureStorage;

  MockAuthRemoteDataSource({required this.secureStorage});

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock данные пользователей
    const mockUsers = {
      'test@example.com': {
        'password': 'password123',
        'id': 'user1',
        'name': 'Тестовый Пользователь',
        'phone': '+7 (999) 123-45-67',
      },
      'admin@example.com': {'password': 'admin123', 'id': 'user2', 'name': 'Администратор', 'phone': null},
    };

    final userData = mockUsers[request.email];
    if (userData == null || userData['password'] != request.password) {
      throw ValidationFailure('Неверный email или пароль');
    }

    final token = 'mock_token_${userData['id']}_${DateTime.now().millisecondsSinceEpoch}';

    return LoginResponse(
      accessToken: token,
      refreshToken: 'refresh_$token',
      user: UserModel(
        id: userData['id'] as String,
        email: request.email,
        name: userData['name'] as String,
        phone: userData['phone'],
      ),
    );
  }

  @override
  Future<LoginResponse> register(RegisterRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));

    const mockUsers = {'test@example.com': true, 'admin@example.com': true};

    if (mockUsers.containsKey(request.email)) {
      throw ValidationFailure('Пользователь с таким email уже существует');
    }

    if (request.password.length < 6) {
      throw ValidationFailure('Пароль должен содержать минимум 6 символов');
    }

    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final token = 'mock_token_$userId';

    return LoginResponse(
      accessToken: token,
      refreshToken: 'refresh_$token',
      user: UserModel(id: userId, email: request.email, name: request.name, phone: request.phone),
    );
  }

  @override
  Future<UserModel> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final userId = await secureStorage.read(key: StorageKeys.userId);
    if (userId == null) {
      throw ValidationFailure('Требуется авторизация');
    }

    // Получаем данные пользователя из secure storage (имитация API вызова)
    final email = await secureStorage.read(key: StorageKeys.userEmail);
    final name = await secureStorage.read(key: StorageKeys.userName);
    final phone = await secureStorage.read(key: StorageKeys.userPhone);

    if (email == null || name == null) {
      throw ValidationFailure('Данные пользователя не найдены');
    }

    return UserModel(id: userId, email: email, name: name, phone: phone);
  }

  @override
  Future<LoginResponse> refreshToken(RefreshTokenRequest request) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final refreshTokenValue = await secureStorage.read(key: StorageKeys.refreshToken);
    if (refreshTokenValue == null || refreshTokenValue != request.refreshToken) {
      throw ValidationFailure('Refresh token не найден или неверен');
    }

    final newToken = 'mock_token_refreshed_${DateTime.now().millisecondsSinceEpoch}';
    final newRefreshToken = 'refresh_$newToken';

    // Получаем данные пользователя для ответа
    final userId = await secureStorage.read(key: StorageKeys.userId);
    final email = await secureStorage.read(key: StorageKeys.userEmail);
    final name = await secureStorage.read(key: StorageKeys.userName);
    final phone = await secureStorage.read(key: StorageKeys.userPhone);

    if (userId == null || email == null || name == null) {
      throw ValidationFailure('Данные пользователя не найдены');
    }

    return LoginResponse(
      accessToken: newToken,
      refreshToken: newRefreshToken,
      user: UserModel(id: userId, email: email, name: name, phone: phone),
    );
  }
}
