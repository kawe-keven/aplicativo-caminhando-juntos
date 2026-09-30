import 'package:caminhandojuntos/models/achievement.dart';
import 'package:caminhandojuntos/services/base_api_service.dart';
import 'package:caminhandojuntos/services/secure_storage_service.dart';

class AchievementsApiClient extends BaseApiService {
  final SecureStorageService _secureStorage = SecureStorageService();

  Future<List<Achievement>> fetchAchievements() async {
    try {
      final token = await _secureStorage.read('auth_token');
      final headers = {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await get('/api/v1/achievements', headers: headers);
      if (response is Map && response.containsKey('achievements')) {
        final list = response['achievements'] as List;
        return list.map((json) => Achievement.fromJson(json as Map<String, dynamic>)).toList();
      }
      if (response is List) {
        return response.map((json) => Achievement.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
