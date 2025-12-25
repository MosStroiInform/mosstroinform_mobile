import 'package:mosstroinform_mobile/shared/file_download/data/datasources/file_download_data_source.dart';
import 'package:web/web.dart' as web;

/// Реализация источника данных для скачивания файлов на веб-платформе
class FileDownloadDataSourceImpl implements FileDownloadDataSource {
  FileDownloadDataSourceImpl();

  @override
  Future<void> downloadFile(String url) async {
    final fileName = url.split('/').last;
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..target = '_blank';
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
  }
}
