enum TipoMetricaConectada {
  frequenciaCardiaca,
  frequenciaRepouso,
  glicemia,
  pressaoSistolica,
  pressaoDiastolica,
}

extension DetalhesMetricaConectada on TipoMetricaConectada {
  String get rotulo => switch (this) {
    TipoMetricaConectada.frequenciaCardiaca => 'Frequência cardíaca',
    TipoMetricaConectada.frequenciaRepouso => 'Frequência em repouso',
    TipoMetricaConectada.glicemia => 'Glicemia',
    TipoMetricaConectada.pressaoSistolica => 'Pressão sistólica',
    TipoMetricaConectada.pressaoDiastolica => 'Pressão diastólica',
  };

  String get unidade => switch (this) {
    TipoMetricaConectada.frequenciaCardiaca ||
    TipoMetricaConectada.frequenciaRepouso => 'bpm',
    TipoMetricaConectada.glicemia => 'mg/dL',
    TipoMetricaConectada.pressaoSistolica ||
    TipoMetricaConectada.pressaoDiastolica => 'mmHg',
  };
}

class MetricaConectada {
  const MetricaConectada({
    required this.id,
    required this.tipo,
    required this.valor,
    required this.registradaEm,
    required this.fonte,
  });

  final String id;
  final TipoMetricaConectada tipo;
  final double valor;
  final DateTime registradaEm;
  final String fonte;

  Map<String, Object> toJson() => {
    'id': id,
    'type': tipo.name,
    'value': valor,
    'recordedAt': registradaEm.toIso8601String(),
    'source': fonte,
  };

  factory MetricaConectada.fromJson(Map<String, dynamic> json) =>
      MetricaConectada(
        id: json['id'] as String,
        tipo: TipoMetricaConectada.values.byName(json['type'] as String),
        valor: (json['value'] as num).toDouble(),
        registradaEm: DateTime.parse(json['recordedAt'] as String),
        fonte: json['source'] as String? ?? 'Fonte não informada',
      );
}

enum TipoEventoRotina { refeicao, insulina }

class MedicamentoAgendado {
  const MedicamentoAgendado({
    required this.id,
    required this.nome,
    required this.horarioMinutos,
    this.ultimaConfirmacao,
    this.ativo = true,
  });

  final String id;
  final String nome;
  final int horarioMinutos;
  final DateTime? ultimaConfirmacao;
  final bool ativo;

  int get notificationId {
    final numeric = int.tryParse(id.replaceAll(RegExp('[^0-9]'), ''));
    return (numeric ?? id.hashCode).abs() % 2147483647;
  }

  String get horarioFormatado {
    final hour = (horarioMinutos ~/ 60).toString().padLeft(2, '0');
    final minute = (horarioMinutos % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool confirmadoEm(DateTime day) =>
      ultimaConfirmacao != null &&
      ultimaConfirmacao!.year == day.year &&
      ultimaConfirmacao!.month == day.month &&
      ultimaConfirmacao!.day == day.day;

  MedicamentoAgendado copyWith({DateTime? ultimaConfirmacao, bool? ativo}) =>
      MedicamentoAgendado(
        id: id,
        nome: nome,
        horarioMinutos: horarioMinutos,
        ultimaConfirmacao: ultimaConfirmacao ?? this.ultimaConfirmacao,
        ativo: ativo ?? this.ativo,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': nome,
    'scheduleMinutes': horarioMinutos,
    'lastConfirmation': ultimaConfirmacao?.toIso8601String(),
    'active': ativo,
  };

  factory MedicamentoAgendado.fromJson(Map<String, dynamic> json) =>
      MedicamentoAgendado(
        id: json['id'] as String,
        nome: json['name'] as String,
        horarioMinutos: json['scheduleMinutes'] as int,
        ultimaConfirmacao: json['lastConfirmation'] == null
            ? null
            : DateTime.parse(json['lastConfirmation'] as String),
        ativo: json['active'] as bool? ?? true,
      );
}

class EventoRotina {
  const EventoRotina({
    required this.id,
    required this.tipo,
    required this.registradoEm,
    this.valor,
  });

  final String id;
  final TipoEventoRotina tipo;
  final DateTime registradoEm;
  final double? valor;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': tipo.name,
    'recordedAt': registradoEm.toIso8601String(),
    'value': valor,
  };

  factory EventoRotina.fromJson(Map<String, dynamic> json) => EventoRotina(
    id: json['id'] as String,
    tipo: TipoEventoRotina.values.byName(json['type'] as String),
    registradoEm: DateTime.parse(json['recordedAt'] as String),
    valor: (json['value'] as num?)?.toDouble(),
  );
}

enum TipoEventoCiclo { inicio, fim, sintoma }

class EventoCiclo {
  const EventoCiclo({
    required this.id,
    required this.tipo,
    required this.registradoEm,
    this.descricao,
  });

  final String id;
  final TipoEventoCiclo tipo;
  final DateTime registradoEm;
  final String? descricao;

  Map<String, Object?> toJson() => {
    'id': id,
    'type': tipo.name,
    'recordedAt': registradoEm.toIso8601String(),
    'description': descricao,
  };

  factory EventoCiclo.fromJson(Map<String, dynamic> json) => EventoCiclo(
    id: json['id'] as String,
    tipo: TipoEventoCiclo.values.byName(json['type'] as String),
    registradoEm: DateTime.parse(json['recordedAt'] as String),
    descricao: json['description'] as String?,
  );
}

class OrientacaoContextual {
  const OrientacaoContextual({required this.titulo, required this.mensagem});

  final String titulo;
  final String mensagem;
}

List<OrientacaoContextual> gerarOrientacoesContextuais({
  required bool diabetesAtivo,
  required bool hipertensaoAtiva,
  required bool cicloAtivo,
  required int intervaloRefeicaoHoras,
  required List<EventoRotina> eventosRotina,
  required List<EventoCiclo> eventosCiclo,
  required List<MetricaConectada> metricas,
  required List<MedicamentoAgendado> medicamentos,
  DateTime? agora,
}) {
  final now = agora ?? DateTime.now();
  final result = <OrientacaoContextual>[];

  if (diabetesAtivo) {
    final refeicoes =
        eventosRotina
            .where((event) => event.tipo == TipoEventoRotina.refeicao)
            .toList()
          ..sort((a, b) => b.registradoEm.compareTo(a.registradoEm));
    if (refeicoes.isEmpty) {
      result.add(
        const OrientacaoContextual(
          titulo: 'Rotina de alimentação',
          mensagem:
              'Quando fizer uma refeição, registre aqui para organizar seus horários.',
        ),
      );
    } else {
      final hours = now.difference(refeicoes.first.registradoEm).inHours;
      if (hours >= intervaloRefeicaoHoras) {
        result.add(
          OrientacaoContextual(
            titulo: 'Você já conseguiu se alimentar?',
            mensagem:
                'Já faz cerca de $hours horas desde a última refeição registrada. Confira sua rotina de cuidado.',
          ),
        );
      }
    }
  }

  if (cicloAtivo) {
    final starts =
        eventosCiclo
            .where((event) => event.tipo == TipoEventoCiclo.inicio)
            .toList()
          ..sort((a, b) => b.registradoEm.compareTo(a.registradoEm));
    if (starts.isEmpty) {
      result.add(
        const OrientacaoContextual(
          titulo: 'Acompanhamento opcional do ciclo',
          mensagem:
              'Você pode registrar o início do ciclo e sintomas sem receber previsões clínicas.',
        ),
      );
    }
  }

  for (final medication in medicamentos.where((item) => item.ativo)) {
    final scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      medication.horarioMinutos ~/ 60,
      medication.horarioMinutos % 60,
    );
    if (!medication.confirmadoEm(now) && !now.isBefore(scheduled)) {
      result.add(
        OrientacaoContextual(
          titulo: 'Horário de ${medication.nome}',
          mensagem:
              'O horário configurado era ${medication.horarioFormatado}. Você já tomou conforme sua prescrição?',
        ),
      );
    }
  }

  if (hipertensaoAtiva &&
      !metricas.any(
        (metric) =>
            metric.tipo == TipoMetricaConectada.pressaoSistolica ||
            metric.tipo == TipoMetricaConectada.pressaoDiastolica,
      )) {
    result.add(
      const OrientacaoContextual(
        titulo: 'Acompanhamento da pressão',
        mensagem:
            'Se você medir a pressão com um aparelho adequado, pode registrar ou importar o resultado para seu histórico.',
      ),
    );
  }

  final recentConnected = metricas
      .where((metric) => now.difference(metric.registradaEm).inHours <= 24)
      .length;
  if (recentConnected > 0) {
    result.add(
      OrientacaoContextual(
        titulo: 'Dados conectados atualizados',
        mensagem:
            '$recentConnected registros autorizados foram encontrados nas últimas 24 horas.',
      ),
    );
  }

  return result;
}
