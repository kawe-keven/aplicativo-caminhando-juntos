import 'package:caminhandojuntos/config/mapbox_config.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapCreditBar extends StatelessWidget {
  const MapCreditBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Escolhe o texto adequado conforme a validade do token do Mapbox
    final texto = MapboxConfig.mapboxTokenValido
        ? '© Mapbox © OpenStreetMap'
        : '© OpenStreetMap contributors';

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () async {
          try {
            await launchUrl(
              Uri.parse('https://www.openstreetmap.org/copyright'),
              mode: LaunchMode.externalApplication,
            );
          } catch (_) {} // Nunca crashar ao tocar no link de copyright
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
