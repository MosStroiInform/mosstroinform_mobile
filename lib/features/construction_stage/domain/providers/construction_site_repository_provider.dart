import 'package:mosstroinform_mobile/core/config/app_config_provider.dart';
import 'package:mosstroinform_mobile/features/construction_stage/data/providers/construction_site_data_source_provider.dart';
import 'package:mosstroinform_mobile/features/construction_stage/data/repositories/construction_site_repository_impl.dart';
import 'package:mosstroinform_mobile/features/construction_stage/data/repositories/mock_construction_site_repository.dart';
import 'package:mosstroinform_mobile/features/construction_stage/domain/repositories/construction_site_repository.dart';
import 'package:mosstroinform_mobile/features/project_selection/domain/providers/construction_object_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'construction_site_repository_provider.g.dart';

@Riverpod(keepAlive: true)
ConstructionSiteRepository constructionSiteRepository(Ref ref) {
  final config = ref.watch(appConfigSimpleProvider);
  if (config.useMocks) {
    final constructionObjectRepository = ref.read(constructionObjectRepositoryProvider);
    return MockConstructionSiteRepository(constructionObjectRepository: constructionObjectRepository);
  }
  final remoteDataSource = ref.watch(constructionSiteRemoteDataSourceProvider);
  return ConstructionSiteRepositoryImpl(remoteDataSource: remoteDataSource);
}
