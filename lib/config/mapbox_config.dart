import 'package:caminhandojuntos/config/secrets.dart';

class MapboxConfig {
  // Constante do estilo padrão do Mapbox
  static const String style = 'mapbox/streets-v12';

  // Constante do userAgentPackageName (applicationId do build.gradle.kts)
  static const String userAgentPackageName = 'com.example.caminhandojuntos';

  // URL do template de tiles do Mapbox usando o formato especificado
  static const String urlTemplate =
      'https://api.mapbox.com/styles/v1/{id}/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}';

  // Getter para validar se o token do Mapbox foi preenchido corretamente
  static bool get mapboxTokenValido {
    if (kMapboxAccessToken.isEmpty ||
        kMapboxAccessToken == 'COLE_SUA_CHAVE_AQUI' ||
        !kMapboxAccessToken.startsWith('pk.')) {
      return false;
    }
    return true;
  }
}
