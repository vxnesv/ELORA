import '../../../core/domain/modelos_elora.dart';

String montarResumoConsulta({
  required List<RegistroSaude> registros,
  required List<MetaCuidado> metas,
  required String note,
  required DateTime today,
}) {
  final buffer = StringBuffer()
    ..writeln('ELORA — resumo para consulta')
    ..writeln('Gerado em ${dataCurta(today)}')
    ..writeln('Os dados abaixo foram informados pelo usuário.')
    ..writeln('Registros: ${registros.length}');

  for (final indicador in TipoIndicador.values) {
    final matching =
        registros.where((registro) => registro.indicador == indicador).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (matching.isNotEmpty) {
      final ultimoRegistro = matching.first;
      buffer.writeln(
        '${indicador.rotulo}: último registro ${indicador.formatar(ultimoRegistro.value)} em ${dataCurta(ultimoRegistro.createdAt)}.',
      );
    }
  }

  final doneToday = metas
      .where((meta) => meta.completedOn == chaveDia(today))
      .length;
  buffer.writeln('Metas realizadas hoje: $doneToday de ${metas.length}.');
  if (note.trim().isNotEmpty) {
    buffer.writeln('Perguntas e observações: ${note.trim()}');
  }
  buffer.writeln(
    'Este resumo não contém diagnóstico ou interpretação clínica.',
  );
  return buffer.toString();
}
