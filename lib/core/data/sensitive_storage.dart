import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Contrato mínimo para dados locais que não podem ficar em texto aberto.
abstract interface class SensitiveStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Usa Keychain no iOS e criptografia com chaves protegidas pelo Keystore no
/// Android. A implementação Web só deve ser usada em HTTPS ou localhost.
class PlatformSensitiveStorage implements SensitiveStorage {
  PlatformSensitiveStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
