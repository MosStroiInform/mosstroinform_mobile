import 'package:mosstroinform_mobile/shared/file_download/data/providers/file_download_data_source_provider.dart';
import 'package:mosstroinform_mobile/shared/file_download/data/services/file_download_service_impl.dart';
import 'package:mosstroinform_mobile/shared/file_download/domain/services/file_download_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_download_service_provider.g.dart';

/// Провайдер для сервиса скачивания файлов
/// Возвращает интерфейс из domain слоя
/// Находится в domain слое, так как предоставляет доступ к интерфейсу сервиса
@riverpod
FileDownloadService fileDownloadService(Ref ref) {
  final dataSource = ref.watch(fileDownloadDataSourceProvider);
  return FileDownloadServiceImpl(dataSource: dataSource);
}
