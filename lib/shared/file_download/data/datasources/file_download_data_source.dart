/// Интерфейс источника данных для скачивания файлов
/// Находится в data слое
abstract class FileDownloadDataSource {
  /// Скачать файл по URL
  Future<void> downloadFile(String url);
}
