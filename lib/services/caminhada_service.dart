import 'package:caminhandojuntos/services/base_api_service.dart';

/// Serviço responsável por sincronizar os dados brutos da caminhada com o Backend Java.
/// Segue a regra de segurança: o app envia apenas coordenadas e tempo, o servidor calcula moedas.
class CaminhadaService extends BaseApiService {
  
  /// Envia as coordenadas coletadas para validação e crédito de moedas.
  /// Retorna um Map contendo {distanceKm: double, coinsEarned: int}.
  Future<Map<String, dynamic>> syncCaminhada(Map<String, dynamic> payload) async {
    try {
      // Endpoint definido na especificação do backend
      final response = await post('/api/caminhada/sync', payload);
      return {
        'distanceKm': response['distanceKm'] ?? 0.0,
        'coinsEarned': response['coinsEarned'] ?? 0,
      };
    } catch (e) {
      rethrow;
    }
  }
}
