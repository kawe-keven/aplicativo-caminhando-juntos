import 'package:caminhandojuntos/services/base_api_service.dart';
import 'package:caminhandojuntos/services/secure_storage_service.dart';

class ChatApiClient extends BaseApiService {
  final SecureStorageService _secureStorage = SecureStorageService();

  Future<Map<String, dynamic>> sendMessage(String message, {List<Map<String, dynamic>>? history}) async {
    try {
      final token = await _secureStorage.read('auth_token');
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final payload = {
        'message': message,
        if (history != null) 'history': history,
      };

      final response = await post('/api/chat', payload, headers: headers);
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
