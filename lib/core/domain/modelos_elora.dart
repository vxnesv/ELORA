enum TipoIndicador { hidratacao, sono, frequenciaCardiaca }

extension DetalhesIndicador on TipoIndicador {
  String get rotulo => switch (this) {
    TipoIndicador.hidratacao => 'Hidratação',
    TipoIndicador.sono => 'Sono',
    TipoIndicador.frequenciaCardiaca => 'Frequência cardíaca',
  };

  String get unidade => switch (this) {
    TipoIndicador.hidratacao => 'mL',
    TipoIndicador.sono => 'h',
    TipoIndicador.frequenciaCardiaca => 'bpm',
  };

  String get explicacao => switch (this) {
    TipoIndicador.hidratacao =>
      'Este registro ajuda a acompanhar o consumo de água informado por você. A necessidade de líquidos varia conforme a pessoa, o clima e a atividade. Não use um valor isolado como diagnóstico.',
    TipoIndicador.sono =>
      'O tempo de sono é apenas uma parte do descanso. Rotina, qualidade e como você se sente também importam. Observe mudanças ao longo do tempo e leve dúvidas a um profissional.',
    TipoIndicador.frequenciaCardiaca =>
      'A frequência cardíaca muda com esforço, emoções e outros fatores. Um número isolado, especialmente sem contexto, não permite concluir se há um problema de saúde.',
  };

  String formatar(double value) {
    final decimals = value == value.roundToDouble() ? 0 : 1;
    return '${value.toStringAsFixed(decimals).replaceAll('.', ',')} $unidade';
  }
}

class RegistroSaude {
  const RegistroSaude({
    required this.id,
    required this.indicador,
    required this.value,
    required this.createdAt,
  });

  final String id;
  final TipoIndicador indicador;
  final double value;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
    'id': id,
    'metric': indicador.name,
    'value': value,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RegistroSaude.fromJson(Map<String, dynamic> json) => RegistroSaude(
    id: json['id'] as String,
    indicador: switch (json['metric'] as String) {
      'hydration' => TipoIndicador.hidratacao,
      'sleep' => TipoIndicador.sono,
      'heartRate' => TipoIndicador.frequenciaCardiaca,
      final code => TipoIndicador.values.byName(code),
    },
    value: (json['value'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class MetaCuidado {
  const MetaCuidado({required this.id, required this.title, this.completedOn});

  final String id;
  final String title;
  final String? completedOn;

  MetaCuidado copyWith({String? completedOn, bool clearCompletion = false}) =>
      MetaCuidado(
        id: id,
        title: title,
        completedOn: clearCompletion ? null : completedOn ?? this.completedOn,
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'completedOn': completedOn,
  };

  factory MetaCuidado.fromJson(Map<String, dynamic> json) => MetaCuidado(
    id: json['id'] as String,
    title: json['title'] as String,
    completedOn: json['completedOn'] as String?,
  );
}

class TarefaPlano {
  const TarefaPlano({required this.id, required this.title, this.done = false});

  final String id;
  final String title;
  final bool done;

  TarefaPlano copyWith({bool? done}) =>
      TarefaPlano(id: id, title: title, done: done ?? this.done);

  Map<String, Object> toJson() => {'id': id, 'title': title, 'done': done};

  factory TarefaPlano.fromJson(Map<String, dynamic> json) => TarefaPlano(
    id: json['id'] as String,
    title: json['title'] as String,
    done: json['done'] as bool? ?? false,
  );
}

String chaveDia(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String dataCurta(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
