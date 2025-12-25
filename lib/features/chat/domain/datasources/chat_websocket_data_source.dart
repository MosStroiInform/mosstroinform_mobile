import 'package:mosstroinform_mobile/features/chat/domain/entities/chat.dart';
import 'package:mosstroinform_mobile/features/chat/domain/entities/chat_action.dart';

/// Интерфейс для WebSocket соединения чата
abstract class IChatWebSocketDataSource {
  /// Подключиться к WebSocket для чата
  /// [chatId] - ID чата
  /// [onMessage] - callback для получения новых сообщений
  /// [onError] - callback для обработки ошибок
  Future<void> connect(
    String chatId,
    void Function(Message message) onMessage,
    void Function(Object error) onError,
  );

  /// Отключиться от WebSocket
  Future<void> disconnect();

  /// Отправить действие через WebSocket
  Future<void> sendAction(ChatAction action);

  /// Проверить, подключен ли WebSocket
  bool get isConnected;
}
