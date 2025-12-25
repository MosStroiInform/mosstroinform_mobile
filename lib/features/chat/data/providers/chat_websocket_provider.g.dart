// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_websocket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Провайдер для WebSocket источника данных чата

@ProviderFor(chatWebSocketDataSource)
const chatWebSocketDataSourceProvider = ChatWebSocketDataSourceProvider._();

/// Провайдер для WebSocket источника данных чата

final class ChatWebSocketDataSourceProvider
    extends
        $FunctionalProvider<
          IChatWebSocketDataSource,
          IChatWebSocketDataSource,
          IChatWebSocketDataSource
        >
    with $Provider<IChatWebSocketDataSource> {
  /// Провайдер для WebSocket источника данных чата
  const ChatWebSocketDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatWebSocketDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatWebSocketDataSourceHash();

  @$internal
  @override
  $ProviderElement<IChatWebSocketDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IChatWebSocketDataSource create(Ref ref) {
    return chatWebSocketDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IChatWebSocketDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IChatWebSocketDataSource>(value),
    );
  }
}

String _$chatWebSocketDataSourceHash() =>
    r'a4b90a6e53fe004e00efb2fd2ff3f74ba08f5da6';
