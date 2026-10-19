import 'package:app/domain/models/course_content.dart';

/// Exceção lançada quando é detectada uma dependência circular entre conteúdos pedagógicos.
class CircularDependencyException implements Exception {
  CircularDependencyException(this.message, {this.cyclePath = const []});

  final String message;
  final List<String> cyclePath;

  @override
  String toString() => 'CircularDependencyException: $message';
}

/// Exceção lançada quando regras pedagógicas básicas de conteúdo são violadas.
class CurriculumValidationException implements Exception {
  CurriculumValidationException(this.message);

  final String message;

  @override
  String toString() => 'CurriculumValidationException: $message';
}

/// Serviço de domínio para validação de integridade pedagógica e dependências de conteúdos.
class CurriculumIntegrityService {
  const CurriculumIntegrityService();

  /// Valida os dados de um conteúdo individual.
  void validateContent(CourseContent content) {
    if (content.title.trim().isEmpty) {
      throw CurriculumValidationException(
        'O título do conteúdo é obrigatório.',
      );
    }
    if (content.estimatedLessons < 1) {
      throw CurriculumValidationException(
        'A duração estimada deve ser de pelo menos 1 aula.',
      );
    }
    if (content.orderIndex < 1) {
      throw CurriculumValidationException(
        'O índice de ordem pedagógica deve ser maior ou igual a 1.',
      );
    }
    if (content.prerequisiteIds.contains(content.id)) {
      throw CircularDependencyException(
        'Um conteúdo não pode ser pré-requisito de si mesmo.',
        cyclePath: [content.id, content.id],
      );
    }
  }

  /// Valida individualmente os conteúdos da lista e assegura a ausência de ciclos de dependência.
  void validateContents(List<CourseContent> allContents) {
    for (final content in allContents) {
      validateContent(content);
    }
    validateNoCircularDependencies(allContents);
  }

  /// Valida a ausência de dependências circulares em um conjunto de conteúdos.
  ///
  /// Lança [CircularDependencyException] se for detectado um ciclo.
  void validateNoCircularDependencies(List<CourseContent> allContents) {
    final adjacency = <String, List<String>>{};
    final contentMap = {for (final c in allContents) c.id: c};

    for (final content in allContents) {
      // Auto-dependência direta
      if (content.prerequisiteIds.contains(content.id)) {
        throw CircularDependencyException(
          'Dependência circular detectada: "${content.title}" depende de si mesmo.',
          cyclePath: [content.id, content.id],
        );
      }

      // Filtra pré-requisitos válidos que pertencem a esta mesma turma/disciplina
      adjacency[content.id] = content.prerequisiteIds
          .where((prereqId) => contentMap.containsKey(prereqId))
          .toList();
    }

    // Algoritmo de DFS com 3 estados (branco: não visitado, cinza: em processamento, preto: concluído)
    final visited = <String, int>{}; // 0 = unvisited, 1 = visiting, 2 = visited
    final currentPath = <String>[];

    void dfs(String node) {
      visited[node] = 1; // Marca como visiting
      currentPath.add(node);

      final neighbors = adjacency[node] ?? const [];
      for (final neighbor in neighbors) {
        final state = visited[neighbor] ?? 0;
        if (state == 1) {
          // Ciclo detectado!
          final cycleStartIndex = currentPath.indexOf(neighbor);
          final cycle = currentPath.sublist(cycleStartIndex)..add(neighbor);
          final names = cycle
              .map((id) => contentMap[id]?.title ?? id)
              .join(' -> ');

          throw CircularDependencyException(
            'Dependência circular detectada entre os conteúdos: $names',
            cyclePath: cycle,
          );
        } else if (state == 0) {
          dfs(neighbor);
        }
      }

      currentPath.removeLast();
      visited[node] = 2; // Marca como visited
    }

    for (final content in allContents) {
      if ((visited[content.id] ?? 0) == 0) {
        dfs(content.id);
      }
    }
  }
}
