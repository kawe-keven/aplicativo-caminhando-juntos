import 'package:caminhandojuntos/services/caminhada_api_client.dart';

/// Serviço responsável por sincronizar os dados brutos da caminhada com o Backend Java.
/// Segue a regra de segurança: o app envia apenas coordenadas e tempo, o servidor calcula moedas.
class CaminhadaService {
  final CaminhadaApiClient _apiClient = CaminhadaApiClient();
  
  /// Envia as coordenadas coletadas para validação e crédito de moedas.
  /// Retorna um Map contendo {distanceKm: double, coinsEarned: int}.
  Future<Map<String, dynamic>> syncCaminhada(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.syncCaminhada(payload);
      return {
        'distanceKm': response['distanceKm'] ?? 0.0,
        'coinsEarned': response['coinsEarned'] ?? 0,
      };
    } catch (e) {
      rethrow;
    }
  }
}
