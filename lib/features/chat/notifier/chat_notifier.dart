import 'dart:async';

import 'package:mosstroinform_mobile/core/errors/failures.dart';
import 'package:mosstroinform_mobile/core/utils/logger.dart';
import 'package:mosstroinform_mobile/features/chat/data/providers/chat_websocket_provider.dart';
import 'package:mosstroinform_mobile/features/chat/domain/datasources/chat_websocket_data_source.dart';
import 'package:mosstroinform_mobile/features/chat/domain/entities/chat.dart';
import 'package:mosstroinform_mobile/features/chat/domain/entities/chat_action.dart';
import 'package:mosstroinform_mobile/features/chat/domain/providers/chat_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_notifier.g.dart';

class ChatsState {
  final List<Chat> chats;
  final bool isLoading;
  final Failure? error;

  const ChatsState({required this.chats, this.isLoading = false, this.error});

  ChatsState copyWith({List<Chat>? chats, bool? isLoading, Failure? error}) {
    return ChatsState(chats: chats ?? this.chats, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

@riverpod
class ChatsNotifier extends _$ChatsNotifier {
  @override
  Future<ChatsState> build() async {
    return const ChatsState(chats: []);
  }

  Future<void> loadChats() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(chatRepositoryProvider);
      final chats = await repository.getChats();
      state = AsyncValue.data(ChatsState(chats: chats, isLoading: false));
    } on Failure catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    } catch (e, s) {
      state = AsyncValue.error(UnknownFailure('Неизвестная ошибка: $e'), s);
    }
  }
}

class MessagesState {
  final List<Message> messages;
  final bool isLoading;
  final Failure? error;
  final bool isSending;

  const MessagesState({required this.messages, this.isLoading = false, this.error, this.isSending = false});

  MessagesState copyWith({List<Message>? messages, bool? isLoading, Failure? error, bool? isSending}) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSending: isSending ?? this.isSending,
    );
  }
}

@Riverpod(keepAlive: true)
class MessagesNotifier extends _$MessagesNotifier {
  IChatWebSocketDataSource? _websocket;

  @override
  Future<MessagesState> build(String chatId) async {
    ref.onDispose(() {
      _websocket?.disconnect();
    });

    try {
      final repository = ref.read(chatRepositoryProvider);
      final messages = await repository.getMessages(chatId);

      _connectWebSocket(chatId);

      return MessagesState(messages: messages, isLoading: false);
    } on Failure catch (e) {
      AppLogger.error('[MessagesNotifier] build: ошибка Failure: $e');
      return MessagesState(messages: [], isLoading: false, error: e);
    } catch (e) {
      AppLogger.error('[MessagesNotifier] build: неизвестная ошибка: $e');
      return MessagesState(messages: [], isLoading: false, error: UnknownFailure('Неизвестная ошибка: $e'));
    }
  }

  void _connectWebSocket(String chatId) {
    try {
      final websocket = ref.read(chatWebSocketDataSourceProvider);
      _websocket = websocket;

      websocket.connect(
        chatId,
        (Message message) {
          if (!ref.mounted) {
            return;
          }

          final currentState = state.value;
          if (currentState != null) {
            final messageIds = currentState.messages.map((m) => m.id).toSet();

            if (!messageIds.contains(message.id)) {
              state = AsyncValue.data(
                currentState.copyWith(messages: [...currentState.messages, message], isSending: false),
              );
            } else {
              state = AsyncValue.data(
                currentState.copyWith(
                  messages: currentState.messages.map((m) => m.id == message.id ? message : m).toList(),
                ),
              );
            }
          }
        },
        (error) {
          AppLogger.error('[MessagesNotifier] ✗ ошибка WebSocket: $error');
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('[MessagesNotifier] ✗ ошибка подключения к WebSocket: $e', stackTrace);
    }
  }

  Future<void> loadMessages({bool showLoading = true}) async {
    final currentState = state.value;
    if (showLoading || currentState == null || currentState.messages.isEmpty) {
      state = const AsyncValue.loading();
    }

    try {
      final repository = ref.read(chatRepositoryProvider);
      final messages = await repository.getMessages(chatId);
      state = AsyncValue.data(MessagesState(messages: messages, isLoading: false));
    } on Failure catch (e) {
      state = AsyncValue.data(
        currentState?.copyWith(isLoading: false, error: e) ??
            MessagesState(messages: [], isLoading: false, error: e),
      );
    } catch (e) {
      state = AsyncValue.data(
        currentState?.copyWith(isLoading: false, error: UnknownFailure('Неизвестная ошибка: $e')) ??
            MessagesState(messages: [], isLoading: false, error: UnknownFailure('Неизвестная ошибка: $e')),
      );
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(isSending: true));

    try {
      if (_websocket == null || !_websocket!.isConnected) {
        AppLogger.error('[MessagesNotifier] sendMessage: WebSocket не подключен');
        state = AsyncValue.data(
          currentState.copyWith(
            isSending: false,
            error: UnknownFailure('WebSocket не подключен. Не удалось отправить сообщение.'),
          ),
        );
        return;
      }

      final createAction = CreateMessageAction(text: text.trim(), fromSpecialist: false);
      await _websocket!.sendAction(createAction);

      final finalState = state.value;
      if (finalState != null) {
        state = AsyncValue.data(finalState.copyWith(isSending: false));
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '[MessagesNotifier] sendMessage: ошибка отправки CREATE action через WebSocket: $e',
        stackTrace,
      );
      state = AsyncValue.data(
        currentState.copyWith(isSending: false, error: UnknownFailure('Ошибка отправки сообщения: $e')),
      );
    }
  }

  Future<void> markAsRead() async {
    try {
      final repository = ref.read(chatRepositoryProvider);
      await repository.markMessagesAsRead(chatId);
      await loadMessages(showLoading: false);
    } on Failure catch (_) {
    } catch (e, stackTrace) {
      AppLogger.error('[MessagesNotifier] markAsRead: неизвестная ошибка', e, stackTrace);
    }
  }
}
