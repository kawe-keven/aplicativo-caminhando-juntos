import 'package:caminhandojuntos/services/base_api_service.dart';
import 'package:caminhandojuntos/services/secure_storage_service.dart';

class CaminhadaApiClient extends BaseApiService {
  final SecureStorageService _secureStorage = SecureStorageService();

  Future<Map<String, dynamic>> syncCaminhada(Map<String, dynamic> payload) async {
    try {
      await _secureStorage.read('auth_token');
      final response = await post('/api/caminhada/sync', payload);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
