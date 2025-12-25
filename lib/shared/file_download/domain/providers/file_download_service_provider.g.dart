// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_download_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Провайдер для сервиса скачивания файлов
/// Возвращает интерфейс из domain слоя
/// Находится в domain слое, так как предоставляет доступ к интерфейсу сервиса

@ProviderFor(fileDownloadService)
const fileDownloadServiceProvider = FileDownloadServiceProvider._();

/// Провайдер для сервиса скачивания файлов
/// Возвращает интерфейс из domain слоя
/// Находится в domain слое, так как предоставляет доступ к интерфейсу сервиса

final class FileDownloadServiceProvider
    extends
        $FunctionalProvider<
          FileDownloadService,
          FileDownloadService,
          FileDownloadService
        >
    with $Provider<FileDownloadService> {
  /// Провайдер для сервиса скачивания файлов
  /// Возвращает интерфейс из domain слоя
  /// Находится в domain слое, так как предоставляет доступ к интерфейсу сервиса
  const FileDownloadServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileDownloadServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileDownloadServiceHash();

  @$internal
  @override
  $ProviderElement<FileDownloadService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FileDownloadService create(Ref ref) {
    return fileDownloadService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileDownloadService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileDownloadService>(value),
    );
  }
}

String _$fileDownloadServiceHash() =>
    r'35f55d734f54ac65f8e9c1f9a3cd7a9a0625c90a';
