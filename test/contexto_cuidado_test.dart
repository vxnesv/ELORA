import 'package:elora/core/data/elora_store.dart';
import 'package:elora/core/data/sensitive_storage.dart';
import 'package:elora/core/domain/contexto_cuidado.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('gera lembretes explicáveis sem recomendar tratamento', () {
    final now = DateTime(2026, 11, 15, 14);
    final result = gerarOrientacoesContextuais(
      diabetesAtivo: true,
      hipertensaoAtiva: true,
      cicloAtivo: false,
      intervaloRefeicaoHoras: 4,
      eventosRotina: [
        EventoRotina(
          id: 'meal',
          tipo: TipoEventoRotina.refeicao,
          registradoEm: now.subtract(const Duration(hours: 5)),
        ),
      ],
      eventosCiclo: const [],
      metricas: const [],
      medicamentos: const [
        MedicamentoAgendado(
          id: 'med',
          nome: 'Medicamento da manhã',
          horarioMinutos: 8 * 60,
        ),
      ],
      agora: now,
    );

    expect(result.any((item) => item.titulo.contains('alimentar')), isTrue);
    expect(result.any((item) => item.titulo.contains('Medicamento')), isTrue);
    expect(
      result.expand((item) => [item.titulo, item.mensagem]).join(' '),
      isNot(contains('aumente a dose')),
    );
  });

  test('dados de cuidado persistem apenas no armazenamento sensível', () async {
    final preferences = SharedPreferencesAsync();
    final sensitive = _MemorySensitiveStorage();
    final store = EloraStore(
      preferences: preferences,
      sensitiveStorage: sensitive,
    );
    await store.conectarUsuario('care-user');
    store
      ..definirDiabetes(true)
      ..definirHipertensao(true)
      ..definirCiclo(true)
      ..registrarRefeicao()
      ..adicionarMedicamento(
        'Medicamento contínuo',
        const TimeOfDayValue(9, 30),
      )
      ..adicionarMetricaManual(TipoMetricaConectada.glicemia, 110);
    await store.aguardarGravacao();

    expect(
      await preferences.getString('elora_preferences_v2_care-user'),
      isNot(contains('Medicamento contínuo')),
    );

    final reloaded = EloraStore(
      preferences: preferences,
      sensitiveStorage: sensitive,
    );
    await reloaded.conectarUsuario('care-user');
    expect(reloaded.diabetesAtivo, isTrue);
    expect(reloaded.hipertensaoAtiva, isTrue);
    expect(reloaded.cicloAtivo, isTrue);
    expect(reloaded.medicamentos.single.nome, 'Medicamento contínuo');
    expect(reloaded.metricasConectadas.single.valor, 110);
  });
}

class _MemorySensitiveStorage implements SensitiveStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
