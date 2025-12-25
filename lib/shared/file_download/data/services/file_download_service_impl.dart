import 'package:mosstroinform_mobile/shared/file_download/data/datasources/file_download_data_source.dart';
import 'package:mosstroinform_mobile/shared/file_download/domain/services/file_download_service.dart';

/// Реализация сервиса скачивания файлов
/// Находится в data слое, так как зависит от реализации data source
class FileDownloadServiceImpl implements FileDownloadService {
  final FileDownloadDataSource dataSource;

  FileDownloadServiceImpl({required this.dataSource});

  @override
  Future<void> downloadFile(String url) {
    return dataSource.downloadFile(url);
  }
}
