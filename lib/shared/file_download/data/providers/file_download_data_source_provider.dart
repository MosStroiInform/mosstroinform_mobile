import 'package:mosstroinform_mobile/shared/file_download/data/datasources/file_download_data_source.dart';
// Условный импорт для разных платформ
import 'package:mosstroinform_mobile/shared/file_download/data/providers/file_download_data_source_impl_stub.dart'
    if (dart.library.html) 'package:mosstroinform_mobile/shared/file_download/data/providers/file_download_data_source_impl_web.dart'
    if (dart.library.io) 'package:mosstroinform_mobile/shared/file_download/data/providers/file_download_data_source_impl_native.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_download_data_source_provider.g.dart';

/// Провайдер для источника данных скачивания файлов
/// Использует условную компиляцию для разных платформ
@riverpod
FileDownloadDataSource fileDownloadDataSource(Ref ref) {
  return FileDownloadDataSourceImpl();
}
