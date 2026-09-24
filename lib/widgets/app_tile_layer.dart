import 'package:caminhandojuntos/config/mapbox_config.dart';
import 'package:caminhandojuntos/config/secrets.dart';
import 'package:caminhandojuntos/services/local_tile_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

class AppTileLayer {
  static const bool kUsarCacheMapa = true;
  static bool _fallbackForced = false;

  /// Força o uso imediato do OpenStreetMap se o cache ou Mapbox falharem criticamente.
  static void forceNetworkFallback() {
    if (!_fallbackForced) {
      if (kDebugMode) {
        debugPrint('[TileLayer] Falha crítica no Mapbox ou token inválido. Alternando permanentemente para OpenStreetMap.');
      }
      _fallbackForced = true;
    }
  }

  /// Retorna o [TileLayer] configurado de acordo com a validade do token do Mapbox.
  /// Se o token for inválido, usa o OpenStreetMap como fallback estável.
  static TileLayer build({
    required bool isHighContrast,
    Key? key,
  }) {
    final tokenValido = MapboxConfig.mapboxTokenValido;

    if (!tokenValido || _fallbackForced) {
      if (kDebugMode) {
        debugPrint('AVISO: Token do Mapbox inválido ou ausente! Usando OpenStreetMap como fallback.');
      }

      return TileLayer(
        key: key,
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: MapboxConfig.userAgentPackageName,
        maxZoom: 19,
        minZoom: 2,
        tileProvider: kUsarCacheMapa 
            ? LocalTileProvider(provedor: 'osm', estilo: 'osm') 
            : NetworkTileProvider(),
        errorTileCallback: (tile, error, stackTrace) {
          // Trata erro de tile sem crashar o app
        },
        tileBuilder: null,
      );
    }

    // Caso o token seja válido, configura o Mapbox
    return TileLayer(
      key: key,
      urlTemplate: MapboxConfig.urlTemplate,
      additionalOptions: const {
        'id': MapboxConfig.style,
        'accessToken': kMapboxAccessToken,
      },
      userAgentPackageName: MapboxConfig.userAgentPackageName,
      maxZoom: 22,
      minZoom: 2,
      tileSize: 512, // Otimizado conforme plano
      zoomOffset: -1, // Necessário para tiles de 512px no flutter_map
      tileProvider: kUsarCacheMapa 
          ? LocalTileProvider(provedor: 'mapbox', estilo: MapboxConfig.style) 
          : NetworkTileProvider(),
      errorTileCallback: (tile, error, stackTrace) {
        // Trata erro de tile sem crashar o app
      },
      tileBuilder: null,
    );
  }

  /// Retorna a lista de atribuições obrigatórias conforme ToS do Mapbox.
  static List<SourceAttribution> getAttributions(BuildContext context) {
    if (!MapboxConfig.mapboxTokenValido || _fallbackForced) {
      return [
        TextSourceAttribution(
          '© OpenStreetMap contributors',
          onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
        ),
      ];
    }

    return [
      TextSourceAttribution(
        '© Mapbox',
        onTap: () => launchUrl(Uri.parse('https://www.mapbox.com/about/maps/')),
      ),
      TextSourceAttribution(
        '© OpenStreetMap',
        onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
      ),
      TextSourceAttribution(
        'Improve this map',
        onTap: () => launchUrl(Uri.parse('https://www.mapbox.com/map-feedback/')),
      ),
    ];
  }
}
