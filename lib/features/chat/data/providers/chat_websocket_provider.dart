import 'package:mosstroinform_mobile/core/constants/app_constants.dart';
import 'package:mosstroinform_mobile/features/chat/data/datasources/chat_websocket_data_source_impl.dart';
import 'package:mosstroinform_mobile/features/chat/domain/datasources/chat_websocket_data_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_websocket_provider.g.dart';

/// Провайдер для WebSocket источника данных чата
@riverpod
IChatWebSocketDataSource chatWebSocketDataSource(Ref ref) {
  if (AppConstants.useMocks) {
    // Для моков можно вернуть заглушку или реальную реализацию
    // В зависимости от требований
    return ChatWebSocketDataSourceImpl();
  }
  return ChatWebSocketDataSourceImpl();
}
