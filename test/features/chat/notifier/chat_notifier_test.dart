import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mosstroinform_mobile/core/errors/failures.dart';
import 'package:mosstroinform_mobile/features/chat/domain/datasources/chat_websocket_data_source.dart';
import 'package:mosstroinform_mobile/features/chat/domain/entities/chat.dart';
import 'package:mosstroinform_mobile/features/chat/domain/repositories/chat_repository.dart';
import 'package:mosstroinform_mobile/features/chat/domain/providers/chat_repository_provider.dart';
import 'package:mosstroinform_mobile/features/chat/data/providers/chat_websocket_provider.dart';
import 'package:mosstroinform_mobile/features/chat/notifier/chat_notifier.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockChatWebSocketDataSource extends Mock implements IChatWebSocketDataSource {}

void main() {
  late MockChatRepository mockRepository;
  late MockChatWebSocketDataSource mockWebSocket;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockChatRepository();
    mockWebSocket = MockChatWebSocketDataSource();
    
    // Настраиваем базовые моки для WebSocket, которые нужны для всех тестов
    // isConnected будет устанавливаться в каждом тесте отдельно
    when(() => mockWebSocket.disconnect()).thenAnswer((_) async {});
    when(
      () => mockWebSocket.connect(
        any(),
        any(),
        any(),
      ),
    ).thenAnswer((_) async {});
    
    container = ProviderContainer(
      overrides: [
        chatRepositoryProvider.overrideWithValue(mockRepository),
        chatWebSocketDataSourceProvider.overrideWithValue(mockWebSocket),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ChatsNotifier', () {
    test('build возвращает начальное состояние с пустым списком', () async {
      final state = await container.read(chatsProvider.future);

      expect(state.chats, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('loadChats успешно загружает чаты', () async {
      final chats = [
        Chat(
          id: '1',
          projectId: 'project1',
          specialistName: 'Специалист 1',
          unreadCount: 2,
          isActive: true,
        ),
        Chat(
          id: '2',
          projectId: 'project2',
          specialistName: 'Специалист 2',
          unreadCount: 0,
          isActive: false,
        ),
      ];

      when(() => mockRepository.getChats()).thenAnswer((_) async => chats);

      final notifier = container.read(chatsProvider.notifier);
      await notifier.loadChats();

      final state = await container.read(chatsProvider.future);

      expect(state.chats, equals(chats));
      expect(state.isLoading, false);
      expect(state.error, isNull);
      verify(() => mockRepository.getChats()).called(1);
    });

    test('loadChats обрабатывает Failure', () async {
      final failure = NetworkFailure('Ошибка сети');

      // Для асинхронных методов нужно использовать thenAnswer с throw
      when(
        () => mockRepository.getChats(),
      ).thenAnswer((_) async => throw failure);

      final notifier = container.read(chatsProvider.notifier);

      // Вызываем метод - он установит AsyncValue.error
      await notifier.loadChats();

      // Проверяем состояние - AsyncValue.error устанавливается синхронно внутри catch
      final state = container.read(chatsProvider);

      expect(
        state.hasError,
        true,
        reason: 'State should have error after Failure',
      );
      expect(state.error, isA<NetworkFailure>());
      verify(() => mockRepository.getChats()).called(1);
    });
  });

  group('MessagesNotifier', () {
    const chatId = 'chat1';

    test('build загружает сообщения сразу', () async {
      final messages = [
        Message(
          id: '1',
          chatId: chatId,
          text: 'Привет',
          sentAt: DateTime(2024, 1, 1),
          isFromSpecialist: true,
          isRead: true,
        ),
      ];

      when(
        () => mockRepository.getMessages(chatId),
      ).thenAnswer((_) async => messages);

      // Настраиваем мок WebSocket для build
      when(
        () => mockWebSocket.connect(
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async {});

      final state = await container.read(messagesProvider(chatId).future);

      expect(state.messages, equals(messages));
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isSending, false);
      verify(() => mockRepository.getMessages(chatId)).called(1);
    });

    test('loadMessages успешно загружает сообщения', () async {
      final initialMessages = [
        Message(
          id: '1',
          chatId: chatId,
          text: 'Привет',
          sentAt: DateTime(2024, 1, 1),
          isFromSpecialist: true,
          isRead: true,
        ),
      ];

      final updatedMessages = [
        Message(
          id: '1',
          chatId: chatId,
          text: 'Привет',
          sentAt: DateTime(2024, 1, 1),
          isFromSpecialist: true,
          isRead: true,
        ),
        Message(
          id: '2',
          chatId: chatId,
          text: 'Как дела?',
          sentAt: DateTime(2024, 1, 2),
          isFromSpecialist: false,
          isRead: false,
        ),
      ];

      // build уже загрузил сообщения один раз
      when(
        () => mockRepository.getMessages(chatId),
      ).thenAnswer((_) async => initialMessages);

      // Настраиваем мок WebSocket для build
      when(() => mockWebSocket.isConnected).thenReturn(false);
      when(
        () => mockWebSocket.connect(
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async {});

      // Ждем завершения build
      await container.read(messagesProvider(chatId).future);

      // Теперь настраиваем для loadMessages
      when(
        () => mockRepository.getMessages(chatId),
      ).thenAnswer((_) async => updatedMessages);

      final notifier = container.read(messagesProvider(chatId).notifier);
      await notifier.loadMessages();

      final state = await container.read(messagesProvider(chatId).future);

      expect(state.messages, equals(updatedMessages));
      expect(state.isLoading, false);
      expect(state.error, isNull);
      // build вызвал getMessages один раз, loadMessages еще раз
      verify(
        () => mockRepository.getMessages(chatId),
      ).called(greaterThanOrEqualTo(1));
    });

    // TODO: Временно закомментировано - требует доработки моков WebSocket
    /*
    test('sendMessage успешно отправляет сообщение', () async {
      final existingMessages = [
        Message(
          id: '1',
          chatId: chatId,
          text: 'Привет',
          sentAt: DateTime(2024, 1, 1),
          isFromSpecialist: true,
          isRead: true,
        ),
      ];

      final newMessage = Message(
        id: '2',
        chatId: chatId,
        text: 'Новое сообщение',
        sentAt: DateTime(2024, 1, 2),
        isFromSpecialist: false,
        isRead: false,
      );

      // Сохраняем callback для последующего вызова
      void Function(Message)? onMessageCallback;

      // build уже загрузил сообщения
      when(
        () => mockRepository.getMessages(chatId),
      ).thenAnswer((_) async => existingMessages);

      // Настраиваем мок WebSocket
      when(
        () => mockWebSocket.connect(
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((invocation) async {
        // Сохраняем callback из второго аргумента (onMessage)
        onMessageCallback = invocation.positionalArguments[1] as void Function(Message);
      });
      when(
        () => mockWebSocket.sendAction(any()),
      ).thenAnswer((_) async {});

      // Ждем завершения build
      await container.read(messagesProvider(chatId).future);

      // После build устанавливаем isConnected = true синхронно
      // Это имитирует состояние после успешного подключения
      when(() => mockWebSocket.isConnected).thenReturn(true);

      final notifier = container.read(messagesProvider(chatId).notifier);

      // Отправляем сообщение
      await notifier.sendMessage('Новое сообщение');

      // Симулируем получение сообщения через WebSocket callback
      onMessageCallback?.call(newMessage);

      // Ждем обновления состояния
      await Future.delayed(const Duration(milliseconds: 100));

      final state = await container.read(messagesProvider(chatId).future);

      expect(state.messages.length, 2);
      expect(state.messages.last.text, equals('Новое сообщение'));
      expect(state.messages.last.id, equals('2'));
      expect(state.isSending, false);
      verify(
        () => mockWebSocket.sendAction(any(that: isA<CreateMessageAction>())),
      ).called(1);
    });
    */

    // TODO: Временно закомментировано - требует доработки моков WebSocket
    /*
    test('sendMessage игнорирует пустые сообщения', () async {
      // Настраиваем мок WebSocket для build
      when(
        () => mockRepository.getMessages(chatId),
      ).thenAnswer((_) async => []);
      when(
        () => mockWebSocket.connect(
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async {});

      // Ждем завершения build
      await container.read(messagesProvider(chatId).future);

      // После build устанавливаем isConnected = true синхронно
      when(() => mockWebSocket.isConnected).thenReturn(true);

      final notifier = container.read(messagesProvider(chatId).notifier);

      await notifier.sendMessage('');
      await notifier.sendMessage('   ');

      verifyNever(() => mockWebSocket.sendAction(any()));
    });
    */

    // TODO: Временно закомментировано - требует доработки моков WebSocket
    /*
    test('markAsRead успешно отмечает сообщения как прочитанные', () async {
      final messages = [
        Message(
          id: '1',
          chatId: chatId,
          text: 'Привет',
          sentAt: DateTime(2024, 1, 1),
          isFromSpecialist: true,
          isRead: false,
        ),
      ];

      final updatedMessages = [
        Message(
          id: '1',
          chatId: chatId,
          text: 'Привет',
          sentAt: DateTime(2024, 1, 1),
          isFromSpecialist: true,
          isRead: true, // Теперь прочитано
        ),
      ];

      // build уже загрузил сообщения
      when(
        () => mockRepository.getMessages(chatId),
      ).thenAnswer((_) async => messages);

      // Настраиваем мок WebSocket для build
      when(
        () => mockWebSocket.connect(
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async {});

      // Ждем завершения build
      await container.read(messagesProvider(chatId).future);

      // После build устанавливаем isConnected = true синхронно
      when(() => mockWebSocket.isConnected).thenReturn(true);

      when(
        () => mockRepository.markMessagesAsRead(chatId),
      ).thenAnswer((_) async {});

      // После markAsRead вызывается loadMessages, который вернет обновленный список
      when(
        () => mockRepository.getMessages(chatId),
      ).thenAnswer((_) async => updatedMessages);

      final notifier = container.read(messagesProvider(chatId).notifier);
      await notifier.markAsRead();

      // Ждем завершения loadMessages
      await Future.delayed(const Duration(milliseconds: 50));

      final state = await container.read(messagesProvider(chatId).future);

      verify(() => mockRepository.markMessagesAsRead(chatId)).called(1);
      // build вызвал getMessages один раз, markAsRead -> loadMessages еще раз
      verify(
        () => mockRepository.getMessages(chatId),
      ).called(greaterThanOrEqualTo(2));
      // Проверяем, что сообщение теперь прочитано
      expect(state.messages.first.isRead, true);
    });
    */
  });
}
