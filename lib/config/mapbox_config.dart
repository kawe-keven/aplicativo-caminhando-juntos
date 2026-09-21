import 'package:caminhandojuntos/config/secrets.dart';

class MapboxConfig {
  // Constante do estilo padrão do Mapbox (Streets v12)
  static const String style = 'mapbox/streets-v12';

  // Constante do userAgentPackageName (applicationId do build.gradle.kts)
  static const String userAgentPackageName = 'com.example.caminhandojuntos';

  // URL do template de tiles do Mapbox usando 512px para economia de requisições
  static const String urlTemplate =
      'https://api.mapbox.com/styles/v1/{id}/tiles/512/{z}/{x}/{y}@2x?access_token={accessToken}';

  // Getter para validar se o token do Mapbox foi preenchido via dart-define
  static bool get mapboxTokenValido {
    return kMapboxAccessToken.isNotEmpty && kMapboxAccessToken.startsWith('pk.');
  }
}
