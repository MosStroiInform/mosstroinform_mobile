import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mosstroinform_mobile/core/data/mock_data/mock_state_providers.dart';
import 'package:mosstroinform_mobile/core/errors/failures.dart';
import 'package:mosstroinform_mobile/features/project_selection/domain/entities/project.dart';
import 'package:mosstroinform_mobile/features/project_selection/domain/repositories/project_repository.dart';

/// Интерактивная моковая реализация репозитория проектов
/// Использует состояние через Riverpod для имитации реальной работы приложения
/// Состояние сбрасывается при перезапуске приложения
class MockProjectRepository implements ProjectRepository {
  final Ref ref;

  MockProjectRepository(this.ref);

  @override
  Future<List<Project>> getProjects() async {
    // Симуляция задержки сети
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Получаем текущее состояние из провайдера
    final state = ref.read(mockProjectsStateProvider);
    return state;
  }

  @override
  Future<Project> getProjectById(String id) async {
    // Симуляция задержки сети
    await Future.delayed(const Duration(milliseconds: 300));

    final projects = await getProjects();
    try {
      final project = projects.firstWhere((p) => p.id == id);
      return project;
    } catch (e) {
      throw UnknownFailure('Проект с ID $id не найден');
    }
  }

  @override
  Future<void> requestConstruction(String projectId) async {
    // Симуляция задержки сети
    await Future.delayed(const Duration(milliseconds: 500));
    // В реальном приложении здесь была бы отправка запроса
    // Для моков можно обновить состояние проекта, если нужно
  }
}

