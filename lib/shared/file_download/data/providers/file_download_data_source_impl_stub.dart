import 'package:mosstroinform_mobile/shared/file_download/data/datasources/file_download_data_source.dart';

/// Stub реализация для платформ без поддержки скачивания
class FileDownloadDataSourceImpl implements FileDownloadDataSource {
  FileDownloadDataSourceImpl();

  @override
  Future<void> downloadFile(String url) async {
    throw UnsupportedError('File download is not supported on this platform');
  }
}
