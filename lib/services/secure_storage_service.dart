import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço de armazenamento seguro para dados sensíveis.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Lista de chaves conhecidas para evitar apagar dados de outros contextos/plugins
  static const List<String> _knownKeys = [
    'auth_token',
    'refresh_token',
    'user_id',
    'emergency_contact_phone',
  ];

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      _secureLog('SecureStorage Error (Write): $e');
      rethrow;
    }
  }

  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      _secureLog('SecureStorage Error (Read): $e');
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      _secureLog('SecureStorage Error (Delete): $e');
    }
  }

  /// REGRA: Substitui deleteAll por exclusão seletiva
  Future<void> clearKnownData() async {
    try {
      for (final key in _knownKeys) {
        await _storage.delete(key: key);
      }
      _secureLog('SecureStorage: Dados conhecidos foram limpos.');
    } catch (e) {
      _secureLog('SecureStorage Error (ClearKnownData): $e');
    }
  }

  void _secureLog(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[SECURITY LOG] $message');
    }
  }
}
