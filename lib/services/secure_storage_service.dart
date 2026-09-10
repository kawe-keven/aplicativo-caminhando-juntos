import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço de armazenamento seguro para dados sensíveis.
/// Utiliza Keystore no Android e Keychain no iOS para criptografia de hardware.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Salva um valor associado a uma chave de forma criptografada.
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      _secureLog('SecureStorage: Gravado com sucesso - Chave: $key');
    } catch (e) {
      _secureLog('SecureStorage Error (Write): $e');
      rethrow;
    }
  }

  /// Lê um valor criptografado associado a uma chave.
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      _secureLog('SecureStorage: Leitura concluída - Chave: $key');
      return value;
    } catch (e) {
      _secureLog('SecureStorage Error (Read): $e');
      return null;
    }
  }

  /// Remove um valor associado a uma chave.
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      _secureLog('SecureStorage: Deletado com sucesso - Chave: $key');
    } catch (e) {
      _secureLog('SecureStorage Error (Delete): $e');
    }
  }

  /// Limpa todo o armazenamento seguro.
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      _secureLog('SecureStorage: Todo o cache seguro foi limpo.');
    } catch (e) {
      _secureLog('SecureStorage Error (DeleteAll): $e');
    }
  }

  /// REGRA DE SEGURANÇA: Logs apenas em modo de desenvolvimento.
  /// Nunca expõe dados reais nos logs.
  void _secureLog(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[SECURITY LOG] $message');
    }
  }
}
