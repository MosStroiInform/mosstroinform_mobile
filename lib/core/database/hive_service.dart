import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mosstroinform_mobile/core/data/mock_data/projects_mock_data.dart';
import 'package:mosstroinform_mobile/core/database/adapters/construction_object_adapter.dart';
import 'package:mosstroinform_mobile/core/database/adapters/document_adapter.dart';
import 'package:mosstroinform_mobile/core/database/adapters/final_document_adapter.dart';
import 'package:mosstroinform_mobile/core/database/adapters/project_adapter.dart';
import 'package:mosstroinform_mobile/core/utils/logger.dart';
import 'package:mosstroinform_mobile/features/project_selection/data/models/project_model.dart';
import 'package:path_provider/path_provider.dart';

class HiveService {
  static const String _projectsBoxName = 'projects';
  static const String _documentsBoxName = 'documents';
  static const String _constructionObjectsBoxName = 'construction_objects';
  static const String _requestedProjectsBoxName = 'requested_projects';
  static const String _finalDocumentsBoxName = 'final_documents';

  static Box<ProjectAdapter>? _projectsBox;
  static Box<DocumentAdapter>? _documentsBox;
  static Box<ConstructionObjectAdapter>? _constructionObjectsBox;
  static Box<String>? _requestedProjectsBox;
  static Box<FinalDocumentAdapter>? _finalDocumentsBox;

  static bool get isInitialized => _projectsBox != null;

  static Future<void> initializeSettings() async {
    try {
      if (Hive.isBoxOpen('settings')) {
        AppLogger.info('HiveService.initializeSettings: settings box уже открыт');
        return;
      }

      try {
        await Hive.openBox('settings');
        AppLogger.info('HiveService.initializeSettings: settings box открыт');
        return;
      } catch (_) {}

      if (kIsWeb) {
        Hive.init('');
        AppLogger.info('HiveService.initializeSettings: Hive инициализирован для веба (IndexedDB)');
      } else {
        final appSupportDir = await getApplicationSupportDirectory();
        await Hive.initFlutter(appSupportDir.path);
        AppLogger.info('HiveService.initializeSettings: Hive инициализирован');
      }

      await Hive.openBox('settings');
      AppLogger.info('HiveService.initializeSettings: settings box открыт');
    } catch (e, stackTrace) {
      AppLogger.error('HiveService.initializeSettings: ошибка инициализации: $e', stackTrace);
    }
  }

  static Future<void> initialize() async {
    if (isInitialized) {
      AppLogger.info('HiveService.initialize: Hive уже инициализирован');
      if (!Hive.isBoxOpen('settings')) {
        await Hive.openBox('settings');
      }
      return;
    }

    try {
      if (kIsWeb) {
        Hive.init('');
        AppLogger.info('HiveService.initialize: Hive инициализирован для веба (IndexedDB)');
      } else {
        final appSupportDir = await getApplicationSupportDirectory();
        await Hive.initFlutter(appSupportDir.path);
        AppLogger.info('HiveService.initialize: Hive инициализирован');
      }

      await Hive.openBox('settings');
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ProjectAdapterAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(DocumentAdapterAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ConstructionStageAdapterAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ConstructionObjectAdapterAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(FinalDocumentAdapterAdapter());
      }

      // Открываем боксы
      _projectsBox = await Hive.openBox<ProjectAdapter>(_projectsBoxName);
      _documentsBox = await Hive.openBox<DocumentAdapter>(_documentsBoxName);
      _constructionObjectsBox = await Hive.openBox<ConstructionObjectAdapter>(_constructionObjectsBoxName);
      _requestedProjectsBox = await Hive.openBox<String>(_requestedProjectsBoxName);
      _finalDocumentsBox = await Hive.openBox<FinalDocumentAdapter>(_finalDocumentsBoxName);

      AppLogger.info('HiveService.initialize: боксы открыты');

      AppLogger.info('HiveService.initialize: инициализация завершена');
    } catch (e, stackTrace) {
      AppLogger.error('HiveService.initialize: ошибка инициализации: $e', stackTrace);
      rethrow;
    }
  }

  static Future<void> ensureProjectsLoaded() async {
    if (_projectsBox == null) {
      throw StateError('HiveService не инициализирован. Вызовите initialize()');
    }

    if (_projectsBox!.isEmpty) {
      AppLogger.info('HiveService.ensureProjectsLoaded: загрузка начальных проектов');
      final mockData = ProjectsMockData.projects;
      final projects = mockData.map((json) => ProjectModel.fromJson(json).toEntity()).toList();

      for (final project in projects) {
        await _projectsBox!.put(project.id, ProjectAdapter.fromProject(project));
      }
      AppLogger.info('HiveService.ensureProjectsLoaded: загружено ${projects.length} проектов');
    }
  }

  static Future<void> clearUserData() async {
    if (_projectsBox != null) {
      await _projectsBox!.clear();
      AppLogger.info('HiveService.clearUserData: проекты очищены');
    }
    if (_documentsBox != null) {
      await _documentsBox!.clear();
      AppLogger.info('HiveService.clearUserData: документы очищены');
    }
    if (_constructionObjectsBox != null) {
      await _constructionObjectsBox!.clear();
      AppLogger.info('HiveService.clearUserData: объекты строительства очищены');
    }
    if (_requestedProjectsBox != null) {
      await _requestedProjectsBox!.clear();
      AppLogger.info('HiveService.clearUserData: запрошенные проекты очищены');
    }
    if (_finalDocumentsBox != null) {
      await _finalDocumentsBox!.clear();
      AppLogger.info('HiveService.clearUserData: финальные документы очищены');
    }

    AppLogger.info(
      'HiveService.clearUserData: все данные очищены, база будет создана с нуля при следующем логине',
    );
  }

  static Box<FinalDocumentAdapter> get finalDocumentsBox {
    if (_finalDocumentsBox == null) {
      throw StateError('HiveService не инициализирован. Вызовите initialize()');
    }
    return _finalDocumentsBox!;
  }

  static Box<ProjectAdapter> get projectsBox {
    if (_projectsBox == null) {
      throw StateError('HiveService не инициализирован. Вызовите initialize()');
    }
    return _projectsBox!;
  }

  static Box<DocumentAdapter> get documentsBox {
    if (_documentsBox == null) {
      throw StateError('HiveService не инициализирован. Вызовите initialize()');
    }
    return _documentsBox!;
  }

  static Box<ConstructionObjectAdapter> get constructionObjectsBox {
    if (_constructionObjectsBox == null) {
      throw StateError('HiveService не инициализирован. Вызовите initialize()');
    }
    return _constructionObjectsBox!;
  }

  static Box<String> get requestedProjectsBox {
    if (_requestedProjectsBox == null) {
      throw StateError('HiveService не инициализирован. Вызовите initialize()');
    }
    return _requestedProjectsBox!;
  }

  static Future<void> clearAll() async {
    await _projectsBox?.clear();
    await _documentsBox?.clear();
    await _constructionObjectsBox?.clear();
    await _requestedProjectsBox?.clear();
    await ensureProjectsLoaded();
  }

  static Future<void> initializeForTests(String testPath) async {
    if (isInitialized) {
      AppLogger.info('HiveService.initializeForTests: Hive уже инициализирован');
      return;
    }

    try {
      Hive.init(testPath);
      AppLogger.info('HiveService.initializeForTests: Hive инициализирован для тестов');

      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(ProjectAdapterAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(DocumentAdapterAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(ConstructionStageAdapterAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ConstructionObjectAdapterAdapter());
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(FinalDocumentAdapterAdapter());
      }

      _projectsBox = await Hive.openBox<ProjectAdapter>(_projectsBoxName);
      _documentsBox = await Hive.openBox<DocumentAdapter>(_documentsBoxName);
      _constructionObjectsBox = await Hive.openBox<ConstructionObjectAdapter>(_constructionObjectsBoxName);
      _requestedProjectsBox = await Hive.openBox<String>(_requestedProjectsBoxName);

      AppLogger.info('HiveService.initializeForTests: боксы открыты');
      AppLogger.info('HiveService.initializeForTests: инициализация завершена');
    } catch (e, stackTrace) {
      AppLogger.error('HiveService.initializeForTests: ошибка инициализации: $e', stackTrace);
      rethrow;
    }
  }
}
