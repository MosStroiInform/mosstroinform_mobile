import 'package:mosstroinform_mobile/core/errors/failures.dart';
import 'package:mosstroinform_mobile/features/construction_stage/domain/entities/construction_site.dart';
import 'package:mosstroinform_mobile/features/construction_stage/domain/repositories/construction_site_repository.dart';

/// Use case для получения информации о строительной площадке по ID объекта строительства
class GetConstructionSite {
  final ConstructionSiteRepository repository;

  GetConstructionSite(this.repository);

  /// Получить информацию о строительной площадке
  ///
  /// [objectId] - ID объекта строительства
  Future<ConstructionSite> call(String objectId) async {
    try {
      return await repository.getConstructionSiteByObjectId(objectId);
    } on Failure {
      rethrow;
    } catch (e) {
      throw UnknownFailure('Ошибка при получении информации о стройке: $e');
    }
  }
}
