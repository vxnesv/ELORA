enum DestinoAssistente { cuidado, protecao, ajuda, relatorios }

class RespostaAssistente {
  const RespostaAssistente(this.text, {this.destino, this.rotuloAcao});

  final String text;
  final DestinoAssistente? destino;
  final String? rotuloAcao;
}

class AssistenteLocal {
  static RespostaAssistente responder(String pergunta) {
    final text = _normalizar(pergunta);
    if (_contemAlgum(text, [
      'emergencia',
      'urgencia',
      'dor no peito',
      'falta de ar',
      'desmaio',
      'convulsao',
      'perigo imediato',
      'socorro',
    ])) {
      return const RespostaAssistente(
        'Se há perigo imediato ou sintomas graves, procure socorro agora. A ELORA não avalia urgências. Abra a área de ajuda para ver os serviços oficiais e informe sua localização ao ligar.',
        destino: DestinoAssistente.ajuda,
        rotuloAcao: 'Abrir ajuda',
      );
    }
    if (_contemAlgum(text, ['frequencia', 'batimento', 'coracao', 'bpm'])) {
      return const RespostaAssistente(
        'A frequência cardíaca varia com atividade, emoções e outros fatores. Um número isolado não permite diagnóstico. Registre o valor e observe o histórico para conversar com um profissional.',
        destino: DestinoAssistente.cuidado,
        rotuloAcao: 'Ver meu cuidado',
      );
    }
    if (_contemAlgum(text, ['sono', 'dormir', 'descanso'])) {
      return const RespostaAssistente(
        'O número de horas é apenas parte da história do sono. Observe a rotina e como você se sente, sem tirar conclusões de uma única noite. Registre exemplos e anote dúvidas para sua próxima consulta.',
        destino: DestinoAssistente.cuidado,
        rotuloAcao: 'Ver meu cuidado',
      );
    }
    if (_contemAlgum(text, ['agua', 'hidrat', 'beber'])) {
      return const RespostaAssistente(
        'Beber água regularmente é uma medida preventiva geral, especialmente em dias quentes. A necessidade individual varia. Você pode acompanhar seus registros em Meu cuidado sem usar a ELORA para definir uma meta clínica.',
        destino: DestinoAssistente.cuidado,
        rotuloAcao: 'Ver meu cuidado',
      );
    }
    if (_contemAlgum(text, ['calor', 'quente', 'temperatura', 'sol'])) {
      return const RespostaAssistente(
        'Para se preparar para calor intenso, procure água e sombra e ajuste atividades quando possível. Se surgirem sintomas como tontura ou fraqueza, busque avaliação em uma unidade de saúde. Veja a orientação oficial na área de proteção.',
        destino: DestinoAssistente.protecao,
        rotuloAcao: 'Ver orientações',
      );
    }
    if (_contemAlgum(text, [
      'enchente',
      'alagamento',
      'chuva',
      'deslizamento',
    ])) {
      return const RespostaAssistente(
        'Em situações de chuva forte, acompanhe os alertas oficiais, evite atravessar áreas alagadas e organize documentos, contatos e medicamentos. Siga a Defesa Civil da sua região para decisões de saída ou abrigo.',
        destino: DestinoAssistente.protecao,
        rotuloAcao: 'Abrir plano de ação',
      );
    }
    if (_contemAlgum(text, ['consulta', 'exame', 'medico', 'relatorio'])) {
      return const RespostaAssistente(
        'Anote suas dúvidas e leve seus registros para conversar com um profissional. O relatório da ELORA reúne apenas o que você inseriu; ele não interpreta exames nem substitui uma avaliação.',
        destino: DestinoAssistente.relatorios,
        rotuloAcao: 'Ver relatório',
      );
    }
    return const RespostaAssistente(
      'Posso explicar, de forma educativa, frequência cardíaca, sono, hidratação e preparação para calor, chuva ou uma consulta. Para situações graves, use “Preciso de ajuda”.',
      destino: DestinoAssistente.ajuda,
      rotuloAcao: 'Preciso de ajuda',
    );
  }

  static bool _contemAlgum(String text, List<String> terms) =>
      terms.any(text.contains);

  static String _normalizar(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâã]'), 'a')
      .replaceAll(RegExp(r'[éê]'), 'e')
      .replaceAll(RegExp(r'[í]'), 'i')
      .replaceAll(RegExp(r'[óôõ]'), 'o')
      .replaceAll(RegExp(r'[úü]'), 'u')
      .replaceAll('ç', 'c');
}
