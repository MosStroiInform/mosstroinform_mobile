// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_download_data_source_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Провайдер для источника данных скачивания файлов
/// Использует условную компиляцию для разных платформ

@ProviderFor(fileDownloadDataSource)
const fileDownloadDataSourceProvider = FileDownloadDataSourceProvider._();

/// Провайдер для источника данных скачивания файлов
/// Использует условную компиляцию для разных платформ

final class FileDownloadDataSourceProvider
    extends
        $FunctionalProvider<
          FileDownloadDataSource,
          FileDownloadDataSource,
          FileDownloadDataSource
        >
    with $Provider<FileDownloadDataSource> {
  /// Провайдер для источника данных скачивания файлов
  /// Использует условную компиляцию для разных платформ
  const FileDownloadDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileDownloadDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileDownloadDataSourceHash();

  @$internal
  @override
  $ProviderElement<FileDownloadDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FileDownloadDataSource create(Ref ref) {
    return fileDownloadDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileDownloadDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileDownloadDataSource>(value),
    );
  }
}

String _$fileDownloadDataSourceHash() =>
    r'02d5a2eba8c847739e84ff256b1f776015771230';
