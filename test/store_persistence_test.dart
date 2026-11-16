import 'package:elora/core/data/elora_store.dart';
import 'package:elora/core/data/sensitive_storage.dart';
import 'package:elora/core/domain/modelos_elora.dart';
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

  test('plano e tema locais persistem após reabrir', () async {
    final sensitive = MemorySensitiveStorage();
    final first = EloraStore(
      preferences: SharedPreferencesAsync(),
      sensitiveStorage: sensitive,
    );
    await first.conectarUsuario('test-user');
    first.iniciar('Teste');
    first.definirTema('dark');
    first.alternarTarefa('documents');
    await first.aguardarGravacao();

    final second = EloraStore(
      preferences: SharedPreferencesAsync(),
      sensitiveStorage: sensitive,
    );
    await second.conectarUsuario('test-user');
    expect(second.falhaAoSalvar, isFalse);
    expect(second.name, 'Teste');
    expect(second.theme, 'dark');
    expect(second.plano.length, 4);
    expect(second.tarefasPlanoConcluidas, 1);

    await second.apagarDados();
    expect(second.iniciado, isFalse);
    expect(second.tarefasPlanoConcluidas, 0);
  });

  test('códigos antigos dos indicadores continuam legíveis', () async {
    final preferences = SharedPreferencesAsync();
    final sensitive = MemorySensitiveStorage();
    await preferences.setString(
      'elora_mvp_v1_test-user',
      '{"hasStarted":true,"records":[{"id":"old","metric":"hydration","value":300,"createdAt":"2026-11-15T10:00:00.000"}]}',
    );

    final store = EloraStore(
      preferences: preferences,
      sensitiveStorage: sensitive,
    );
    await store.conectarUsuario('test-user');

    expect(store.falhaAoSalvar, isFalse);
    expect(store.iniciado, isTrue);
    expect(store.ultimoRegistro(TipoIndicador.hidratacao)?.value, 300);

    store.adicionarRegistro(TipoIndicador.sono, 7);
    await store.aguardarGravacao();
    expect(await preferences.getString('elora_mvp_v1_test-user'), isNull);
    final reloaded = EloraStore(
      preferences: preferences,
      sensitiveStorage: sensitive,
    );
    await reloaded.conectarUsuario('test-user');
    expect(reloaded.falhaAoSalvar, isFalse);
    expect(reloaded.ultimoRegistro(TipoIndicador.hidratacao)?.value, 300);
    expect(reloaded.ultimoRegistro(TipoIndicador.sono)?.value, 7);
  });
}

class MemorySensitiveStorage implements SensitiveStorage {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
