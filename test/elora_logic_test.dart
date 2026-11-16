import 'package:elora/core/domain/modelos_elora.dart';
import 'package:elora/features/assistente/domain/assistente_local.dart';
import 'package:elora/features/relatorios/domain/resumo_relatorio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mensagem urgente direciona para ajuda', () {
    final resposta = AssistenteLocal.responder('Estou com dor no peito');
    expect(resposta.destino, DestinoAssistente.ajuda);
    expect(resposta.text, contains('não avalia urgências'));
  });

  test('relatório usa apenas os registros fornecidos', () {
    final today = DateTime(2026, 11, 15);
    final empty = montarResumoConsulta(
      registros: const [],
      metas: const [],
      note: '',
      today: today,
    );
    expect(empty, contains('Registros: 0'));
    expect(empty, isNot(contains('72 bpm')));

    final withRecord = montarResumoConsulta(
      registros: [
        RegistroSaude(
          id: 'example',
          indicador: TipoIndicador.frequenciaCardiaca,
          value: 72,
          createdAt: today,
        ),
      ],
      metas: const [],
      note: 'Perguntar sobre a rotina.',
      today: today,
    );
    expect(withRecord, contains('72 bpm'));
    expect(withRecord, contains('Perguntar sobre a rotina.'));
  });
}
