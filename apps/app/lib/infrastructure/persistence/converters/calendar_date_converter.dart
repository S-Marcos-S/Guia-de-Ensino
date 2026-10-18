import 'package:drift/drift.dart';

/// Convenção Arquitetural de Armazenamento de Datas Letivas:
///
/// Datas escolares (início e término de anos letivos, feriados, recessos e ocorrência de aulas)
/// são puramente "datas de calendário" (ano, mês e dia civil).
/// Elas NÃO possuem hora específica ou fuso horário no contexto do cronograma escolar.
///
/// Armazenar como DateTime com offset de fuso local pode causar problemas graves de "data shift"
/// (por exemplo, ao converter entre UTC e GMT-3 / Horário de Brasília, uma aula em 15/03/2026
/// às 00:00:00 UTC pode virar 14/03/2026 às 21:00:00 local).
///
/// Portanto, todas as datas letivas no Guia de Ensino são armazenadas no SQLite
/// como texto ISO-8601 canônico de data estrita: 'YYYY-MM-DD' (ex: '2026-02-02').
/// Este conversor garante serialização e desserialização imune a fusos horários.
class CalendarDateConverter extends TypeConverter<DateTime, String> {
  const CalendarDateConverter();

  @override
  DateTime fromSql(String fromDb) {
    final parts = fromDb.split('-');
    if (parts.length != 3) {
      throw FormatException(
        'Formato de data letiva inválido no banco: $fromDb',
      );
    }
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    // Cria DateTime puro em UTC para evitar qualquer distorção de fuso
    return DateTime.utc(year, month, day);
  }

  @override
  String toSql(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
