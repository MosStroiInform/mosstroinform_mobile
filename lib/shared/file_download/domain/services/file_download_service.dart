/// Интерфейс сервиса для скачивания файлов
/// Находится в domain слое как чистый интерфейс без зависимостей
abstract class FileDownloadService {
  /// Скачать файл по URL
  Future<void> downloadFile(String url);
}
