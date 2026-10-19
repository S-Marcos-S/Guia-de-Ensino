/// Origem de registro do Conteúdo Programático.
enum ContentOrigin { manual, officialCurriculumImport, documentImport }

extension ContentOriginExtension on ContentOrigin {
  String get displayName {
    switch (this) {
      case ContentOrigin.manual:
        return 'Personalizado';
      case ContentOrigin.officialCurriculumImport:
        return 'Base Curricular Oficial';
      case ContentOrigin.documentImport:
        return 'Importação de Documento';
    }
  }
}

/// Entidade de domínio pura para Conteúdo Programático de uma disciplina e turma.
class CourseContent {
  const CourseContent({
    required this.id,
    required this.classroomSubjectId,
    required this.title,
    this.description,
    this.thematicUnit,
    this.estimatedLessons = 1,
    required this.orderIndex,
    this.isMandatory = true,
    this.curriculumCompetencyId,
    this.prerequisiteIds = const [],
    this.origin = ContentOrigin.manual,
  });

  /// Identificador único (UUID)
  final String id;

  /// Vínculo específico com a disciplina na turma (ClassroomSubject)
  final String classroomSubjectId;

  /// Título ou descrição resumida do conteúdo (ex: "Operações com Frações e Decimais")
  final String title;

  /// Detalhamento pedagógico ou observações
  final String? description;

  /// Unidade temática ou bloco curricular
  final String? thematicUnit;

  /// Estimativa de duração em número de aulas (mínimo 1)
  final int estimatedLessons;

  /// Ordem pedagógica sequencial planejada (mínimo 1)
  final int orderIndex;

  /// Se é um conteúdo curricular obrigatório ou atividade opcional/complementar
  final bool isMandatory;

  /// Referência opcional à Habilidade Oficial cadastrada
  final String? curriculumCompetencyId;

  /// IDs de conteúdos que são pré-requisitos para este conteúdo
  final List<String> prerequisiteIds;

  /// Origem do cadastro (manual, importação oficial ou documento)
  final ContentOrigin origin;

  /// Se possui vínculo com uma habilidade oficial verificada
  bool get hasOfficialReference => curriculumCompetencyId != null;

  CourseContent copyWith({
    String? id,
    String? classroomSubjectId,
    String? title,
    String? description,
    String? thematicUnit,
    int? estimatedLessons,
    int? orderIndex,
    bool? isMandatory,
    String? curriculumCompetencyId,
    List<String>? prerequisiteIds,
    ContentOrigin? origin,
  }) {
    return CourseContent(
      id: id ?? this.id,
      classroomSubjectId: classroomSubjectId ?? this.classroomSubjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      thematicUnit: thematicUnit ?? this.thematicUnit,
      estimatedLessons: estimatedLessons ?? this.estimatedLessons,
      orderIndex: orderIndex ?? this.orderIndex,
      isMandatory: isMandatory ?? this.isMandatory,
      curriculumCompetencyId:
          curriculumCompetencyId ?? this.curriculumCompetencyId,
      prerequisiteIds: prerequisiteIds ?? this.prerequisiteIds,
      origin: origin ?? this.origin,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseContent &&
        other.id == id &&
        other.classroomSubjectId == classroomSubjectId &&
        other.title == title &&
        other.description == description &&
        other.thematicUnit == thematicUnit &&
        other.estimatedLessons == estimatedLessons &&
        other.orderIndex == orderIndex &&
        other.isMandatory == isMandatory &&
        other.curriculumCompetencyId == curriculumCompetencyId &&
        other.origin == origin;
  }

  @override
  int get hashCode => Object.hash(
    id,
    classroomSubjectId,
    title,
    description,
    thematicUnit,
    estimatedLessons,
    orderIndex,
    isMandatory,
    curriculumCompetencyId,
    origin,
  );
}
