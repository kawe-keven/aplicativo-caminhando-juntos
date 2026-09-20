import 'package:caminhandojuntos/config/mapbox_config.dart';
import 'package:caminhandojuntos/config/secrets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:url_launcher/url_launcher.dart';

class AppTileLayer {
  /// Retorna o [TileLayer] configurado de acordo com a validade do token do Mapbox.
  /// Se o token for inválido, usa o OpenStreetMap como fallback estável.
  static TileLayer build({
    required bool isHighContrast,
    Key? key,
  }) {
    final tokenValido = MapboxConfig.mapboxTokenValido;

    if (!tokenValido) {
      if (kDebugMode) {
        debugPrint('AVISO: Token do Mapbox inválido ou ausente! Usando OpenStreetMap como fallback.');
      }

      return TileLayer(
        key: key,
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: MapboxConfig.userAgentPackageName,
        maxZoom: 19,
        minZoom: 2,
        tileProvider: FMTCTileProvider(
          stores: const {'mapCache': BrowseStoreStrategy.readUpdateCreate},
        ),
        errorTileCallback: (tile, error, stackTrace) {
          // Trata erro de tile sem crashar o app e sem spam de logs
        },
        tileBuilder: isHighContrast
            ? (context, tileWidget, tile) {
                return ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -1, 0, 0, 0, 255,
                     0, -1, 0, 0, 255,
                     0, 0, -1, 0, 255,
                     0, 0, 0, 1, 0
                  ]),
                  child: tileWidget,
                );
              }
            : null,
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
      tileProvider: FMTCTileProvider(
        stores: const {'mapCache': BrowseStoreStrategy.readUpdateCreate},
      ),
      errorTileCallback: (tile, error, stackTrace) {
        // Trata erro de tile sem crashar o app e sem spam de logs
      },
      tileBuilder: isHighContrast
          ? (context, tileWidget, tile) {
              return ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  -1, 0, 0, 0, 255,
                   0, -1, 0, 0, 255,
                   0, 0, -1, 0, 255,
                   0, 0, 0, 1, 0
                ]),
                child: tileWidget,
              );
            }
          : null,
    );
  }

  /// Retorna a lista de atribuições obrigatórias via [RichAttributionWidget] baseada na origem dos tiles.
  static List<SourceAttribution> getAttributions(BuildContext context) {
    if (!MapboxConfig.mapboxTokenValido) {
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
    ];
  }
}
