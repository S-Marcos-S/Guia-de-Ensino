/// Componente Curricular / Disciplina do domínio pedagógico.
class Subject {
  const Subject({
    required this.id,
    required this.name,
    this.colorHex = '#1E3A8A',
  });

  final String id;
  final String name;
  final String colorHex;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subject &&
        other.id == id &&
        other.name == name &&
        other.colorHex == colorHex;
  }

  @override
  int get hashCode => Object.hash(id, name, colorHex);
}
