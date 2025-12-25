import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mosstroinform_mobile/core/errors/failures.dart';
import 'package:mosstroinform_mobile/core/storage/secure_storage_provider.dart';
import 'package:mosstroinform_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mosstroinform_mobile/features/auth/data/models/user_model.dart';
import 'package:mosstroinform_mobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mosstroinform_mobile/features/auth/domain/entities/user.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockFlutterSecureStorage mockSecureStorage;

  setUpAll(() {
    registerFallbackValue(LoginRequest(email: 'test@example.com', password: 'password'));
    registerFallbackValue(RegisterRequest(email: 'test@example.com', password: 'password', name: 'Test'));
    registerFallbackValue(RefreshTokenRequest(refreshToken: 'refresh_token'));
  });

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockSecureStorage = MockFlutterSecureStorage();
    repository = AuthRepositoryImpl(remoteDataSource: mockRemoteDataSource, secureStorage: mockSecureStorage);
  });

  group('login', () {
    test('успешно сохраняет токены и данные пользователя', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      final response = LoginResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: UserModel(id: 'user1', email: email, name: 'Test User', phone: '+7 (999) 123-45-67'),
      );

      when(() => mockRemoteDataSource.login(any())).thenAnswer((_) async => response);
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      // Act
      final result = await repository.login(email, password);

      // Assert
      expect(result, equals('access_token'));
      verify(() => mockRemoteDataSource.login(any())).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.accessToken, value: 'access_token')).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.refreshToken, value: 'refresh_token')).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.userId, value: 'user1')).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.userEmail, value: email)).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.userName, value: 'Test User')).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.userPhone, value: '+7 (999) 123-45-67')).called(1);
    });

    test('удаляет phone из storage если phone == null', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      final response = LoginResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: UserModel(id: 'user1', email: email, name: 'Test User', phone: null),
      );

      when(() => mockRemoteDataSource.login(any())).thenAnswer((_) async => response);
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

      // Act
      await repository.login(email, password);

      // Assert
      verify(() => mockSecureStorage.delete(key: StorageKeys.userPhone)).called(1);
      verifyNever(
        () => mockSecureStorage.write(
          key: StorageKeys.userPhone,
          value: any(named: 'value'),
        ),
      );
    });

    test('пробрасывает ошибки из remoteDataSource', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'wrong_password';
      final failure = ValidationFailure('Неверный email или пароль');

      when(() => mockRemoteDataSource.login(any())).thenThrow(failure);

      // Act & Assert
      expect(() => repository.login(email, password), throwsA(isA<ValidationFailure>()));
      verify(() => mockRemoteDataSource.login(any())).called(1);
      verifyNever(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });
  });

  group('register', () {
    test('успешно сохраняет токены и данные пользователя', () async {
      // Arrange
      const email = 'new@example.com';
      const password = 'password123';
      const name = 'New User';
      const phone = '+7 (999) 123-45-67';
      final response = LoginResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: UserModel(id: 'user2', email: email, name: name, phone: phone),
      );

      when(() => mockRemoteDataSource.register(any())).thenAnswer((_) async => response);
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      // Act
      final result = await repository.register(email: email, password: password, name: name, phone: phone);

      // Assert
      expect(result, equals('access_token'));
      verify(() => mockRemoteDataSource.register(any())).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.accessToken, value: 'access_token')).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.refreshToken, value: 'refresh_token')).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.userId, value: 'user2')).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.userEmail, value: email)).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.userName, value: name)).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.userPhone, value: phone)).called(1);
    });

    test('удаляет phone из storage если phone == null', () async {
      // Arrange
      const email = 'new@example.com';
      const password = 'password123';
      const name = 'New User';
      final response = LoginResponse(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        user: UserModel(id: 'user2', email: email, name: name, phone: null),
      );

      when(() => mockRemoteDataSource.register(any())).thenAnswer((_) async => response);
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

      // Act
      await repository.register(email: email, password: password, name: name);

      // Assert
      verify(() => mockSecureStorage.delete(key: StorageKeys.userPhone)).called(1);
      verifyNever(
        () => mockSecureStorage.write(
          key: StorageKeys.userPhone,
          value: any(named: 'value'),
        ),
      );
    });

    test('пробрасывает ошибки из remoteDataSource', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      const name = 'Test User';
      final failure = ValidationFailure('Пользователь с таким email уже существует');

      when(() => mockRemoteDataSource.register(any())).thenThrow(failure);

      // Act & Assert
      expect(
        () => repository.register(email: email, password: password, name: name),
        throwsA(isA<ValidationFailure>()),
      );
      verify(() => mockRemoteDataSource.register(any())).called(1);
      verifyNever(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
    });
  });

  group('logout', () {
    test('удаляет все токены и данные пользователя', () async {
      // Arrange
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

      // Act
      await repository.logout();

      // Assert
      verify(() => mockSecureStorage.delete(key: StorageKeys.accessToken)).called(1);
      verify(() => mockSecureStorage.delete(key: StorageKeys.refreshToken)).called(1);
      verify(() => mockSecureStorage.delete(key: StorageKeys.userId)).called(1);
      verify(() => mockSecureStorage.delete(key: StorageKeys.userEmail)).called(1);
      verify(() => mockSecureStorage.delete(key: StorageKeys.userName)).called(1);
      verify(() => mockSecureStorage.delete(key: StorageKeys.userPhone)).called(1);
    });
  });

  group('getCurrentUser', () {
    test('успешно возвращает пользователя', () async {
      // Arrange
      final userModel = UserModel(
        id: 'user1',
        email: 'test@example.com',
        name: 'Test User',
        phone: '+7 (999) 123-45-67',
      );
      final expectedUser = User(
        id: 'user1',
        email: 'test@example.com',
        name: 'Test User',
        phone: '+7 (999) 123-45-67',
      );

      when(() => mockRemoteDataSource.getCurrentUser()).thenAnswer((_) async => userModel);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result.id, equals(expectedUser.id));
      expect(result.email, equals(expectedUser.email));
      expect(result.name, equals(expectedUser.name));
      expect(result.phone, equals(expectedUser.phone));
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
    });

    test('пробрасывает ошибки из remoteDataSource', () async {
      // Arrange
      final failure = ValidationFailure('Требуется авторизация');

      when(() => mockRemoteDataSource.getCurrentUser()).thenThrow(failure);

      // Act & Assert
      expect(
        () => repository.getCurrentUser(),
        throwsA(predicate<ValidationFailure>((e) => e.message == 'Требуется авторизация')),
      );
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
    });
  });

  group('isAuthenticated', () {
    test('возвращает true если токен существует', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: StorageKeys.accessToken)).thenAnswer((_) async => 'token');

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, isTrue);
      verify(() => mockSecureStorage.read(key: StorageKeys.accessToken)).called(1);
    });

    test('возвращает false если токен отсутствует', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: StorageKeys.accessToken)).thenAnswer((_) async => null);

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, isFalse);
      verify(() => mockSecureStorage.read(key: StorageKeys.accessToken)).called(1);
    });

    test('возвращает false если токен пустой', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: StorageKeys.accessToken)).thenAnswer((_) async => '');

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result, isFalse);
      verify(() => mockSecureStorage.read(key: StorageKeys.accessToken)).called(1);
    });
  });

  group('getAccessToken', () {
    test('возвращает токен если он существует', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: StorageKeys.accessToken)).thenAnswer((_) async => 'token');

      // Act
      final result = await repository.getAccessToken();

      // Assert
      expect(result, equals('token'));
      verify(() => mockSecureStorage.read(key: StorageKeys.accessToken)).called(1);
    });

    test('возвращает null если токен отсутствует', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: StorageKeys.accessToken)).thenAnswer((_) async => null);

      // Act
      final result = await repository.getAccessToken();

      // Assert
      expect(result, isNull);
      verify(() => mockSecureStorage.read(key: StorageKeys.accessToken)).called(1);
    });
  });

  group('refreshToken', () {
    test('успешно обновляет токены и данные пользователя', () async {
      // Arrange
      const refreshTokenValue = 'old_refresh_token';
      final response = LoginResponse(
        accessToken: 'new_access_token',
        refreshToken: 'new_refresh_token',
        user: UserModel(id: 'user1', email: 'test@example.com', name: 'Test User', phone: '+7 (999) 123-45-67'),
      );

      when(() => mockSecureStorage.read(key: StorageKeys.refreshToken)).thenAnswer((_) async => refreshTokenValue);
      when(() => mockRemoteDataSource.refreshToken(any())).thenAnswer((_) async => response);
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      // Act
      final result = await repository.refreshToken();

      // Assert
      expect(result, equals('new_access_token'));
      verify(() => mockSecureStorage.read(key: StorageKeys.refreshToken)).called(1);
      verify(() => mockRemoteDataSource.refreshToken(any())).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.accessToken, value: 'new_access_token')).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.refreshToken, value: 'new_refresh_token')).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.userId, value: 'user1')).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.userEmail, value: 'test@example.com')).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.userName, value: 'Test User')).called(1);
      verify(() => mockSecureStorage.write(key: StorageKeys.userPhone, value: '+7 (999) 123-45-67')).called(1);
    });

    test('удаляет phone из storage если phone == null', () async {
      // Arrange
      const refreshTokenValue = 'old_refresh_token';
      final response = LoginResponse(
        accessToken: 'new_access_token',
        refreshToken: 'new_refresh_token',
        user: UserModel(id: 'user1', email: 'test@example.com', name: 'Test User', phone: null),
      );

      when(() => mockSecureStorage.read(key: StorageKeys.refreshToken)).thenAnswer((_) async => refreshTokenValue);
      when(() => mockRemoteDataSource.refreshToken(any())).thenAnswer((_) async => response);
      when(
        () => mockSecureStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

      // Act
      await repository.refreshToken();

      // Assert
      verify(() => mockSecureStorage.delete(key: StorageKeys.userPhone)).called(1);
      verifyNever(
        () => mockSecureStorage.write(
          key: StorageKeys.userPhone,
          value: any(named: 'value'),
        ),
      );
    });

    test('выбрасывает ошибку если refresh token отсутствует', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: StorageKeys.refreshToken)).thenAnswer((_) async => null);

      // Act & Assert
      expect(() => repository.refreshToken(), throwsA(isA<ValidationFailure>()));
      verify(() => mockSecureStorage.read(key: StorageKeys.refreshToken)).called(1);
      verifyNever(() => mockRemoteDataSource.refreshToken(any()));
    });

    test('пробрасывает ошибки из remoteDataSource', () async {
      // Arrange
      const refreshTokenValue = 'old_refresh_token';
      final failure = ValidationFailure('Refresh token не найден или неверен');

      when(() => mockSecureStorage.read(key: StorageKeys.refreshToken)).thenAnswer((_) async => refreshTokenValue);
      when(() => mockRemoteDataSource.refreshToken(any())).thenThrow(failure);

      // Act & Assert
      try {
        await repository.refreshToken();
        fail('Должна была быть выброшена ошибка');
      } catch (e) {
        expect(e, isA<ValidationFailure>());
      }
      verify(() => mockSecureStorage.read(key: StorageKeys.refreshToken)).called(1);
      verify(() => mockRemoteDataSource.refreshToken(any())).called(1);
    });
  });
}
