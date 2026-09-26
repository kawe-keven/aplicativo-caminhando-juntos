import 'package:caminhandojuntos/services/base_api_service.dart';
import 'package:caminhandojuntos/services/secure_storage_service.dart';

class CaminhadaApiClient extends BaseApiService {
  final SecureStorageService _secureStorage = SecureStorageService();

  Future<Map<String, dynamic>> syncCaminhada(Map<String, dynamic> payload) async {
    try {
      final token = await _secureStorage.read('auth_token');
      if (token == null || token.isEmpty) {
        throw const SessaoExpiradaException();
      }
      final headers = {'Authorization': 'Bearer $token'};
      final response = await post('/api/caminhada/sync', payload, headers: headers);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
