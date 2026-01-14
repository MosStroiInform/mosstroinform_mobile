import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mosstroinform_mobile/core/errors/failures.dart';
import 'package:mosstroinform_mobile/core/utils/logger.dart';
import 'package:mosstroinform_mobile/features/auth/notifier/auth_notifier.dart';
import 'package:mosstroinform_mobile/features/my_objects/ui/screens/my_objects_screen.dart';
import 'package:mosstroinform_mobile/features/project_selection/domain/entities/project.dart';
import 'package:mosstroinform_mobile/features/project_selection/domain/providers/project_repository_provider.dart';
import 'package:mosstroinform_mobile/features/project_selection/notifier/paginated_project_notifier.dart';
import 'package:mosstroinform_mobile/features/project_selection/notifier/requested_projects_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_notifier.freezed.dart';
part 'project_notifier.g.dart';

@freezed
abstract class ProjectsState with _$ProjectsState {
  const factory ProjectsState({
    required List<Project> projects,
    @Default(false) bool isLoading,
    @Default(null) Failure? error,
  }) = _ProjectsState;
}

@Riverpod(keepAlive: true)
class ProjectsNotifier extends _$ProjectsNotifier {
  @override
  Future<ProjectsState> build() async {
    ref.watch(authProvider);

    return const ProjectsState(projects: [], isLoading: true);
  }

  Future<void> loadProjects() async {
    final authAsync = ref.read(authProvider);
    AuthState? authState;
    try {
      authState = authAsync.value ?? await ref.read(authProvider.future);
    } catch (_) {
      authState = authAsync.value;
    }

    if (authState?.isAuthenticated != true) {
      AppLogger.info('ProjectsNotifier.loadProjects: пользователь не авторизован, пропускаем загрузку');
      return;
    }

    state = const AsyncValue.loading();

    try {
      final repository = ref.read(projectRepositoryProvider);
      final projects = await repository.getProjects();

      if (!ref.mounted) return;

      if (state.hasValue || !state.hasError) {
        state = AsyncValue.data(ProjectsState(projects: projects, isLoading: false));
      }
    } on Failure catch (e) {
      if (!ref.mounted) return;

      state = AsyncValue.data(const ProjectsState(projects: []).copyWith(isLoading: false, error: e));
    } catch (e, _) {
      if (e.toString().contains('disposed')) return;

      if (!ref.mounted) return;

      state = AsyncValue.data(
        const ProjectsState(
          projects: [],
        ).copyWith(isLoading: false, error: UnknownFailure('Неизвестная ошибка: $e')),
      );
    }
  }
}

@freezed
abstract class ProjectState with _$ProjectState {
  const factory ProjectState({
    @Default(null) Project? project,
    @Default(false) bool isLoading,
    @Default(false) bool isRequestingConstruction,
    @Default(null) Failure? error,
  }) = _ProjectState;
}

@riverpod
class ProjectNotifier extends _$ProjectNotifier {
  @override
  Future<ProjectState> build() async {
    return const ProjectState();
  }

  Future<void> loadProject(String id, {bool showLoading = true}) async {
    final currentState = state.value;
    if (showLoading || currentState == null || currentState.project == null) {
      state = const AsyncValue.loading();
    }

    try {
      final repository = ref.read(projectRepositoryProvider);
      final project = await repository.getProjectById(id);

      state = AsyncValue.data(ProjectState(project: project, isLoading: false));
    } on Failure catch (e) {
      state = AsyncValue.data(
        currentState?.copyWith(isLoading: false, error: e) ??
            const ProjectState().copyWith(isLoading: false, error: e),
      );
    } catch (e) {
      state = AsyncValue.data(
        currentState?.copyWith(isLoading: false, error: UnknownFailure('Неизвестная ошибка: $e')) ??
            const ProjectState().copyWith(isLoading: false, error: UnknownFailure('Неизвестная ошибка: $e')),
      );
    }
  }

  Future<void> startConstruction(String projectId, String address) async {
    final currentState = state.value;
    state = AsyncValue.data(
      currentState?.copyWith(isLoading: true, error: null) ?? const ProjectState(isLoading: true),
    );

    try {
      final repository = ref.read(projectRepositoryProvider);
      await repository.startConstruction(projectId, address);
      if (!ref.mounted) return;

      await loadProject(projectId);
      if (!ref.mounted) return;

      ref.read(projectsProvider.notifier).loadProjects();
      ref.read(requestedProjectsProvider.notifier).loadRequestedProjects();
      ref.read(paginatedProjectsProvider.notifier).loadFirstPage();

      ref.invalidate(isProjectRequestedProvider(projectId));
      ref.invalidate(myObjectsProvider);
    } on Failure catch (e) {
      state = AsyncValue.data(currentState?.copyWith(isLoading: false, error: e) ?? ProjectState(error: e));
    } catch (e) {
      state = AsyncValue.data(
        currentState?.copyWith(isLoading: false, error: UnknownFailure('Неизвестная ошибка: $e')) ??
            ProjectState(error: UnknownFailure('Неизвестная ошибка: $e')),
      );
    }
  }

  Future<void> requestConstruction(String projectId) async {
    final currentState = state.value;
    state = AsyncValue.data(
      currentState?.copyWith(isLoading: false, isRequestingConstruction: true, error: null) ??
          const ProjectState(isRequestingConstruction: true),
    );

    try {
      final repository = ref.read(projectRepositoryProvider);
      await repository.requestConstruction(projectId);
      if (!ref.mounted) return;

      await loadProject(projectId, showLoading: false);
      if (!ref.mounted) return;

      await ref.read(projectsProvider.notifier).loadProjects();
      if (!ref.mounted) return;

      await ref.read(requestedProjectsProvider.notifier).loadRequestedProjects();
      if (!ref.mounted) return;

      await ref.read(paginatedProjectsProvider.notifier).loadFirstPage();
      if (!ref.mounted) return;

      ref.invalidate(isProjectRequestedProvider(projectId));
    } on Failure catch (e) {
      state = AsyncValue.data(
        currentState?.copyWith(isLoading: false, isRequestingConstruction: false, error: e) ??
            ProjectState(error: e),
      );
    } catch (e) {
      state = AsyncValue.data(
        currentState?.copyWith(
              isLoading: false,
              isRequestingConstruction: false,
              error: UnknownFailure('Неизвестная ошибка: $e'),
            ) ??
            ProjectState(error: UnknownFailure('Неизвестная ошибка: $e')),
      );
    }
  }
}
