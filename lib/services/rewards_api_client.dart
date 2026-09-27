import 'package:caminhandojuntos/services/base_api_service.dart';
import 'package:caminhandojuntos/services/secure_storage_service.dart';

class RewardsApiClient extends BaseApiService {
  final SecureStorageService _secureStorage = SecureStorageService();

  /// Resgata uma recompensa no backend.
  /// TODO(backend): O servidor Java deve validar o saldo atual de moedas do usuário antes de debitar
  /// e retornar o novo saldo autoritativo para evitar fraudes ou duplicações no cliente.
  Future<int> redeemReward(String rewardId, int cost) async {
    try {
      final token = await _secureStorage.read('auth_token');
      final headers = {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await post(
        '/api/rewards/redeem',
        {'reward_id': rewardId, 'cost': cost},
        headers: headers,
      );

      if (response is Map && response.containsKey('coins')) {
        return response['coins'] as int;
      }
      return -1;
    } catch (e) {
      rethrow;
    }
  }
}
