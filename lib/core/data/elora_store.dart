import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/modelos_elora.dart';
import '../domain/contexto_cuidado.dart';
import 'sensitive_storage.dart';

class EloraStore extends ChangeNotifier {
  EloraStore({
    SharedPreferencesAsync? preferences,
    SensitiveStorage? sensitiveStorage,
  }) : _preferencias = preferences ?? SharedPreferencesAsync(),
       _dadosSensiveis = sensitiveStorage ?? PlatformSensitiveStorage();

  static const _prefixoLegado = 'elora_mvp_v1';
  static const _prefixoPreferencias = 'elora_preferences_v2';
  static const _prefixoSensivel = 'elora_sensitive_v2';
  final SharedPreferencesAsync _preferencias;
  final SensitiveStorage _dadosSensiveis;
  Future<void> _filaGravacao = Future<void>.value();
  String? _usuarioId;

  String? get usuarioId => _usuarioId;
  String get _chaveLegada => '${_prefixoLegado}_${_usuarioId ?? 'sem_usuario'}';
  String get _chavePreferencias =>
      '${_prefixoPreferencias}_${_usuarioId ?? 'sem_usuario'}';
  String get _chaveSensivel =>
      '${_prefixoSensivel}_${_usuarioId ?? 'sem_usuario'}';

  bool iniciado = false;
  String name = 'Visitante';
  String theme = 'system';
  bool textoAmpliado = false;
  String contextoTrabalho = 'Escritório';
  String notaConsulta = '';
  bool falhaAoSalvar = false;
  bool diabetesAtivo = false;
  bool hipertensaoAtiva = false;
  bool cicloAtivo = false;
  bool integracaoSaudeAtiva = false;
  bool lembretesSistemaAtivos = false;
  int intervaloRefeicaoHoras = 4;
  DateTime? ultimaSincronizacaoSaude;

  final List<RegistroSaude> _registros = [];
  final List<MetaCuidado> _metas = [];
  final List<TarefaPlano> _plano = _planoInicial();
  final List<MetricaConectada> _metricasConectadas = [];
  final List<EventoRotina> _eventosRotina = [];
  final List<EventoCiclo> _eventosCiclo = [];
  final List<MedicamentoAgendado> _medicamentos = [];

  List<RegistroSaude> get registros => List.unmodifiable(_registros);
  List<MetaCuidado> get metas => List.unmodifiable(_metas);
  List<TarefaPlano> get plano => List.unmodifiable(_plano);
  List<MetricaConectada> get metricasConectadas =>
      List.unmodifiable(_metricasConectadas);
  List<EventoRotina> get eventosRotina => List.unmodifiable(_eventosRotina);
  List<EventoCiclo> get eventosCiclo => List.unmodifiable(_eventosCiclo);
  List<MedicamentoAgendado> get medicamentos =>
      List.unmodifiable(_medicamentos);
  List<OrientacaoContextual> get orientacoesContextuais =>
      gerarOrientacoesContextuais(
        diabetesAtivo: diabetesAtivo,
        hipertensaoAtiva: hipertensaoAtiva,
        cicloAtivo: cicloAtivo,
        intervaloRefeicaoHoras: intervaloRefeicaoHoras,
        eventosRotina: _eventosRotina,
        eventosCiclo: _eventosCiclo,
        metricas: _metricasConectadas,
        medicamentos: _medicamentos,
      );

  int get metasConcluidasHoje => _metas
      .where((meta) => meta.completedOn == chaveDia(DateTime.now()))
      .length;
  int get tarefasPlanoConcluidas =>
      _plano.where((tarefa) => tarefa.done).length;

  Future<void> aguardarGravacao() => _filaGravacao;

  Future<void> conectarUsuario(String uid) async {
    if (_usuarioId == uid) return;
    await _filaGravacao;
    iniciado = true;
    name = 'Visitante';
    theme = 'system';
    textoAmpliado = false;
    contextoTrabalho = 'Escritório';
    notaConsulta = '';
    falhaAoSalvar = false;
    diabetesAtivo = false;
    hipertensaoAtiva = false;
    cicloAtivo = false;
    integracaoSaudeAtiva = false;
    lembretesSistemaAtivos = false;
    intervaloRefeicaoHoras = 4;
    ultimaSincronizacaoSaude = null;
    _registros.clear();
    _metas.clear();
    _metricasConectadas.clear();
    _eventosRotina.clear();
    _eventosCiclo.clear();
    _medicamentos.clear();
    _plano
      ..clear()
      ..addAll(_planoInicial());
    _usuarioId = uid;
    await carregar();
  }

  RegistroSaude? ultimoRegistro(TipoIndicador indicador) {
    for (final registro in _registros) {
      if (registro.indicador == indicador) return registro;
    }
    return null;
  }

  List<int> get registrosPorDiaRecente {
    final today = DateTime.now();
    return List.generate(7, (index) {
      final target = chaveDia(today.subtract(Duration(days: 6 - index)));
      return _registros
          .where((registro) => chaveDia(registro.createdAt) == target)
          .length;
    });
  }

  Future<void> carregar() async {
    try {
      final results = await Future.wait<String?>([
        _preferencias.getString(_chavePreferencias),
        _dadosSensiveis.read(_chaveSensivel),
        _preferencias.getString(_chaveLegada),
      ]);
      final rawPreferences = results[0];
      final rawSensitive = results[1];
      final rawLegacy = results[2];

      final preferencesData = _decode(rawPreferences ?? rawLegacy);
      final sensitiveData = _decode(rawSensitive ?? rawLegacy);

      theme = preferencesData?['theme'] as String? ?? 'system';
      textoAmpliado = preferencesData?['largeText'] as bool? ?? false;
      if (sensitiveData == null) {
        notifyListeners();
        return;
      }

      iniciado = sensitiveData['hasStarted'] as bool? ?? false;
      name = sensitiveData['name'] as String? ?? 'Visitante';
      contextoTrabalho =
          sensitiveData['workContext'] as String? ?? 'Escritório';
      notaConsulta = sensitiveData['consultationNote'] as String? ?? '';
      diabetesAtivo = sensitiveData['diabetesEnabled'] as bool? ?? false;
      hipertensaoAtiva = sensitiveData['hypertensionEnabled'] as bool? ?? false;
      cicloAtivo = sensitiveData['cycleEnabled'] as bool? ?? false;
      integracaoSaudeAtiva =
          sensitiveData['healthIntegrationEnabled'] as bool? ?? false;
      lembretesSistemaAtivos =
          sensitiveData['systemRemindersEnabled'] as bool? ?? false;
      intervaloRefeicaoHoras = sensitiveData['mealReminderHours'] as int? ?? 4;
      ultimaSincronizacaoSaude = sensitiveData['lastHealthSync'] == null
          ? null
          : DateTime.parse(sensitiveData['lastHealthSync'] as String);
      _registros
        ..clear()
        ..addAll(
          (sensitiveData['records'] as List<dynamic>? ?? []).map(
            (item) =>
                RegistroSaude.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
      _registros.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _metas
        ..clear()
        ..addAll(
          (sensitiveData['goals'] as List<dynamic>? ?? []).map(
            (item) =>
                MetaCuidado.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
      if (sensitiveData['plan'] is List) {
        _plano
          ..clear()
          ..addAll(
            (sensitiveData['plan'] as List<dynamic>).map(
              (item) =>
                  TarefaPlano.fromJson(Map<String, dynamic>.from(item as Map)),
            ),
          );
      }
      _metricasConectadas
        ..clear()
        ..addAll(
          (sensitiveData['connectedMetrics'] as List<dynamic>? ?? []).map(
            (item) => MetricaConectada.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
      _metricasConectadas.sort(
        (a, b) => b.registradaEm.compareTo(a.registradaEm),
      );
      _eventosRotina
        ..clear()
        ..addAll(
          (sensitiveData['routineEvents'] as List<dynamic>? ?? []).map(
            (item) =>
                EventoRotina.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
      _eventosRotina.sort((a, b) => b.registradoEm.compareTo(a.registradoEm));
      _eventosCiclo
        ..clear()
        ..addAll(
          (sensitiveData['cycleEvents'] as List<dynamic>? ?? []).map(
            (item) =>
                EventoCiclo.fromJson(Map<String, dynamic>.from(item as Map)),
          ),
        );
      _eventosCiclo.sort((a, b) => b.registradoEm.compareTo(a.registradoEm));
      _medicamentos
        ..clear()
        ..addAll(
          (sensitiveData['medications'] as List<dynamic>? ?? []).map(
            (item) => MedicamentoAgendado.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );

      if (rawLegacy != null) {
        await Future.wait<void>([
          _preferencias.setString(
            _chavePreferencias,
            jsonEncode({'theme': theme, 'largeText': textoAmpliado}),
          ),
          _dadosSensiveis.write(_chaveSensivel, jsonEncode(sensitiveData)),
        ]);
        await _preferencias.remove(_chaveLegada);
      }
      notifyListeners();
    } catch (error) {
      debugPrint('Não foi possível carregar os dados locais da ELORA: $error');
      falhaAoSalvar = true;
      notifyListeners();
    }
  }

  void iniciar(String preferredName) {
    final cleaned = preferredName.trim();
    name = cleaned.isEmpty ? 'Visitante' : cleaned;
    iniciado = true;
    _alterado();
  }

  void definirNome(String value) {
    final cleaned = value.trim();
    name = cleaned.isEmpty ? 'Visitante' : cleaned;
    _alterado();
  }

  void definirTema(String value) {
    theme = value;
    _alterado();
  }

  void definirTextoAmpliado(bool value) {
    textoAmpliado = value;
    _alterado();
  }

  void definirContextoTrabalho(String value) {
    contextoTrabalho = value;
    _alterado();
  }

  void definirNotaConsulta(String value) {
    notaConsulta = value.trim();
    _alterado();
  }

  void definirDiabetes(bool value) {
    diabetesAtivo = value;
    _alterado();
  }

  void definirHipertensao(bool value) {
    hipertensaoAtiva = value;
    _alterado();
  }

  void definirCiclo(bool value) {
    cicloAtivo = value;
    _alterado();
  }

  void definirIntervaloRefeicao(int hours) {
    intervaloRefeicaoHoras = hours.clamp(2, 8).toInt();
    _alterado();
  }

  void registrarRefeicao() {
    _eventosRotina.insert(
      0,
      EventoRotina(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        tipo: TipoEventoRotina.refeicao,
        registradoEm: DateTime.now(),
      ),
    );
    _alterado();
  }

  void registrarInsulina(double units) {
    _eventosRotina.insert(
      0,
      EventoRotina(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        tipo: TipoEventoRotina.insulina,
        registradoEm: DateTime.now(),
        valor: units,
      ),
    );
    _alterado();
  }

  MedicamentoAgendado? adicionarMedicamento(String name, TimeOfDayValue time) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return null;
    final medication = MedicamentoAgendado(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      nome: cleaned,
      horarioMinutos: time.hour * 60 + time.minute,
    );
    _medicamentos.add(medication);
    _medicamentos.sort((a, b) => a.horarioMinutos.compareTo(b.horarioMinutos));
    _alterado();
    return medication;
  }

  void definirLembretesSistema(bool value) {
    lembretesSistemaAtivos = value;
    _alterado();
  }

  void confirmarMedicamento(String id) {
    final index = _medicamentos.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _medicamentos[index] = _medicamentos[index].copyWith(
      ultimaConfirmacao: DateTime.now(),
    );
    _alterado();
  }

  void removerMedicamento(String id) {
    _medicamentos.removeWhere((item) => item.id == id);
    _alterado();
  }

  void registrarEventoCiclo(TipoEventoCiclo type, {String? description}) {
    _eventosCiclo.insert(
      0,
      EventoCiclo(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        tipo: type,
        registradoEm: DateTime.now(),
        descricao: description?.trim(),
      ),
    );
    _alterado();
  }

  void adicionarMetricaManual(TipoMetricaConectada type, double value) {
    _metricasConectadas.insert(
      0,
      MetricaConectada(
        id: 'manual-${DateTime.now().microsecondsSinceEpoch}',
        tipo: type,
        valor: value,
        registradaEm: DateTime.now(),
        fonte: 'Registro manual',
      ),
    );
    _alterado();
  }

  void salvarMetricasImportadas(List<MetricaConectada> metrics) {
    final merged = <String, MetricaConectada>{
      for (final metric in _metricasConectadas) metric.id: metric,
      for (final metric in metrics) metric.id: metric,
    };
    _metricasConectadas
      ..clear()
      ..addAll(merged.values)
      ..sort((a, b) => b.registradaEm.compareTo(a.registradaEm));
    if (_metricasConectadas.length > 500) {
      _metricasConectadas.removeRange(500, _metricasConectadas.length);
    }
    integracaoSaudeAtiva = true;
    ultimaSincronizacaoSaude = DateTime.now();
    _alterado();
  }

  void adicionarRegistro(TipoIndicador indicador, double value) {
    _registros.insert(
      0,
      RegistroSaude(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        indicador: indicador,
        value: value,
        createdAt: DateTime.now(),
      ),
    );
    _alterado();
  }

  void removerRegistro(String id) {
    _registros.removeWhere((registro) => registro.id == id);
    _alterado();
  }

  void adicionarMeta(String title) {
    final cleaned = title.trim();
    if (cleaned.isEmpty) return;
    _metas.add(
      MetaCuidado(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: cleaned,
      ),
    );
    _alterado();
  }

  void alternarMeta(String id) {
    final index = _metas.indexWhere((meta) => meta.id == id);
    if (index < 0) return;
    final today = chaveDia(DateTime.now());
    final current = _metas[index];
    _metas[index] = current.completedOn == today
        ? current.copyWith(clearCompletion: true)
        : current.copyWith(completedOn: today);
    _alterado();
  }

  void removerMeta(String id) {
    _metas.removeWhere((meta) => meta.id == id);
    _alterado();
  }

  void alternarTarefa(String id) {
    final index = _plano.indexWhere((tarefa) => tarefa.id == id);
    if (index < 0) return;
    _plano[index] = _plano[index].copyWith(done: !_plano[index].done);
    _alterado();
  }

  void adicionarTarefa(String title) {
    final cleaned = title.trim();
    if (cleaned.isEmpty) return;
    _plano.add(
      TarefaPlano(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: cleaned,
      ),
    );
    _alterado();
  }

  void removerTarefa(String id) {
    _plano.removeWhere((tarefa) => tarefa.id == id);
    _alterado();
  }

  Future<void> apagarDados() async {
    await _filaGravacao;
    await Future.wait<void>([
      _preferencias.remove(_chavePreferencias),
      _preferencias.remove(_chaveLegada),
      _dadosSensiveis.delete(_chaveSensivel),
    ]);
    iniciado = false;
    name = 'Visitante';
    theme = 'system';
    textoAmpliado = false;
    contextoTrabalho = 'Escritório';
    notaConsulta = '';
    falhaAoSalvar = false;
    diabetesAtivo = false;
    hipertensaoAtiva = false;
    cicloAtivo = false;
    integracaoSaudeAtiva = false;
    lembretesSistemaAtivos = false;
    intervaloRefeicaoHoras = 4;
    ultimaSincronizacaoSaude = null;
    _registros.clear();
    _metas.clear();
    _metricasConectadas.clear();
    _eventosRotina.clear();
    _eventosCiclo.clear();
    _medicamentos.clear();
    _plano
      ..clear()
      ..addAll(_planoInicial());
    notifyListeners();
  }

  void _alterado() {
    notifyListeners();
    if (_usuarioId == null) return;
    final preferencesSnapshot = jsonEncode({
      'theme': theme,
      'largeText': textoAmpliado,
    });
    final sensitiveSnapshot = jsonEncode({
      'hasStarted': iniciado,
      'name': name,
      'workContext': contextoTrabalho,
      'consultationNote': notaConsulta,
      'diabetesEnabled': diabetesAtivo,
      'hypertensionEnabled': hipertensaoAtiva,
      'cycleEnabled': cicloAtivo,
      'healthIntegrationEnabled': integracaoSaudeAtiva,
      'systemRemindersEnabled': lembretesSistemaAtivos,
      'mealReminderHours': intervaloRefeicaoHoras,
      'lastHealthSync': ultimaSincronizacaoSaude?.toIso8601String(),
      'records': _registros.map((registro) => registro.toJson()).toList(),
      'goals': _metas.map((meta) => meta.toJson()).toList(),
      'plan': _plano.map((tarefa) => tarefa.toJson()).toList(),
      'connectedMetrics': _metricasConectadas
          .map((metric) => metric.toJson())
          .toList(),
      'routineEvents': _eventosRotina.map((event) => event.toJson()).toList(),
      'cycleEvents': _eventosCiclo.map((event) => event.toJson()).toList(),
      'medications': _medicamentos
          .map((medication) => medication.toJson())
          .toList(),
    });
    _filaGravacao = _filaGravacao
        .then(
          (_) => Future.wait<void>([
            _preferencias.setString(_chavePreferencias, preferencesSnapshot),
            _dadosSensiveis.write(_chaveSensivel, sensitiveSnapshot),
          ]),
        )
        .then((_) {
          if (falhaAoSalvar) {
            falhaAoSalvar = false;
            notifyListeners();
          }
        })
        .catchError((Object error) {
          debugPrint(
            'Não foi possível salvar os dados locais da ELORA: $error',
          );
          falhaAoSalvar = true;
          notifyListeners();
        });
  }

  static Map<String, dynamic>? _decode(String? raw) {
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  static List<TarefaPlano> _planoInicial() => [
    const TarefaPlano(id: 'documents', title: 'Separar documentos essenciais'),
    const TarefaPlano(id: 'contacts', title: 'Anotar contatos de confiança'),
    const TarefaPlano(
      id: 'medication',
      title: 'Revisar medicamentos de uso contínuo',
    ),
    const TarefaPlano(
      id: 'meeting',
      title: 'Combinar um ponto de encontro seguro',
    ),
  ];
}

class TimeOfDayValue {
  const TimeOfDayValue(this.hour, this.minute);

  final int hour;
  final int minute;
}
