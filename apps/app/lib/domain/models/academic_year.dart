/// Entidade de domínio pura representando o Ano Letivo e limites do calendário escolar.
/// Totalmente independente de bibliotecas de interface.
class AcademicYear {
  const AcademicYear({
    required this.id,
    required this.year,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.totalMandatoryDays = 200,
  });

  final String id;
  final int year;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final int totalMandatoryDays;

  /// Validação de consistência do período letivo
  bool isValidPeriod() {
    return endDate.isAfter(startDate);
  }

  /// Duração total em dias corridos do período escolar
  int get totalCalendarDays {
    return endDate.difference(startDate).inDays + 1;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AcademicYear &&
        other.id == id &&
        other.year == year &&
        other.title == title &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.totalMandatoryDays == totalMandatoryDays;
  }

  @override
  int get hashCode =>
      Object.hash(id, year, title, startDate, endDate, totalMandatoryDays);
}
