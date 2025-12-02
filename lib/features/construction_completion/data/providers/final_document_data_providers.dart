import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:mosstroinform_mobile/core/constants/app_constants.dart';
import 'package:mosstroinform_mobile/core/network/dio_provider.dart';
import 'package:mosstroinform_mobile/features/construction_completion/data/datasources/final_document_remote_data_source.dart';
import 'package:mosstroinform_mobile/features/construction_completion/data/repositories/final_document_repository_impl.dart';
import 'package:mosstroinform_mobile/features/construction_completion/data/repositories/mock_final_document_repository.dart';
import 'package:mosstroinform_mobile/features/construction_completion/domain/repositories/final_document_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'final_document_data_providers.g.dart';

/// Провайдер для Retrofit источника данных финальных документов
@riverpod
FinalDocumentRemoteDataSource finalDocumentRemoteDataSource(Ref ref) {
  final dio = ref.watch(dioProvider);
  return FinalDocumentRemoteDataSource(dio, baseUrl: AppConstants.baseUrl);
}

/// Провайдер для репозитория финальных документов
/// Возвращает интерфейс, а не имплементацию
/// Использует моковый репозиторий если включены моки, иначе реальный
@riverpod
FinalDocumentRepository finalDocumentRepository(Ref ref) {
  if (AppConstants.useMocks) {
    return MockFinalDocumentRepository();
  }
  final remoteDataSource = ref.watch(finalDocumentRemoteDataSourceProvider);
  return FinalDocumentRepositoryImpl(remoteDataSource: remoteDataSource);
}

