/// Entidade de domínio pura que representa uma Habilidade ou Referência Curricular Oficial (ex: BNCC).
class CurriculumCompetency {
  const CurriculumCompetency({
    required this.id,
    required this.code,
    required this.description,
    required this.thematicUnit,
    this.knowledgeObject,
    required this.stage,
    required this.gradeLevel,
    required this.subjectName,
    required this.sourceName,
    required this.sourceVersion,
  });

  /// Identificador único (UUID)
  final String id;

  /// Código oficial alfanumérico normativo (ex: EF06MA01, EM13MAT101)
  final String code;

  /// Descrição textual integral da habilidade conforme documento oficial
  final String description;

  /// Unidade temática ou área de conhecimento
  final String thematicUnit;

  /// Objeto de conhecimento específico
  final String? knowledgeObject;

  /// Etapa da Educação Básica (ex: Ensino Fundamental - Anos Finais, Ensino Médio)
  final String stage;

  /// Ano ou série de aplicação (ex: 6º ano, 1º ao 3º ano EM)
  final String gradeLevel;

  /// Componente curricular (ex: Matemática, Língua Portuguesa)
  final String subjectName;

  /// Nome do documento de origem (ex: Base Nacional Comum Curricular (MEC))
  final String sourceName;

  /// Versão ou resolução regulatória de referência
  final String sourceVersion;

  factory CurriculumCompetency.fromJson(Map<String, dynamic> json) {
    return CurriculumCompetency(
      id: json['id'] as String? ?? json['code'] as String,
      code: json['code'] as String,
      description: json['description'] as String,
      thematicUnit: json['thematicUnit'] as String? ?? '',
      knowledgeObject: json['knowledgeObject'] as String?,
      stage: json['stage'] as String? ?? '',
      gradeLevel: json['gradeLevel'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      sourceName: json['sourceName'] as String? ?? '',
      sourceVersion: json['sourceVersion'] as String? ?? '',
    );
  }

  CurriculumCompetency copyWith({
    String? id,
    String? code,
    String? description,
    String? thematicUnit,
    String? knowledgeObject,
    String? stage,
    String? gradeLevel,
    String? subjectName,
    String? sourceName,
    String? sourceVersion,
  }) {
    return CurriculumCompetency(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      thematicUnit: thematicUnit ?? this.thematicUnit,
      knowledgeObject: knowledgeObject ?? this.knowledgeObject,
      stage: stage ?? this.stage,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      subjectName: subjectName ?? this.subjectName,
      sourceName: sourceName ?? this.sourceName,
      sourceVersion: sourceVersion ?? this.sourceVersion,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurriculumCompetency &&
        other.id == id &&
        other.code == code &&
        other.description == description &&
        other.thematicUnit == thematicUnit &&
        other.knowledgeObject == knowledgeObject &&
        other.stage == stage &&
        other.gradeLevel == gradeLevel &&
        other.subjectName == subjectName &&
        other.sourceName == sourceName &&
        other.sourceVersion == sourceVersion;
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    description,
    thematicUnit,
    knowledgeObject,
    stage,
    gradeLevel,
    subjectName,
    sourceName,
    sourceVersion,
  );
}
