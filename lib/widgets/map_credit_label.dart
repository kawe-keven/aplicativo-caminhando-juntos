import 'package:caminhandojuntos/config/mapbox_config.dart';
import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class MapCreditLabel extends ConsumerWidget {
  const MapCreditLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(accessibilityProvider).highContrastEnabled;
    final texto = MapboxConfig.mapboxTokenValido
        ? '© Mapbox © OpenStreetMap'
        : '© OpenStreetMap contributors';

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: isHighContrast ? 1.0 : 0.85),
      borderRadius: BorderRadius.circular(6),
      shape: isHighContrast ? RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Colors.white, width: 1),
      ) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () async {
          try {
            await launchUrl(
              Uri.parse('https://www.openstreetmap.org/copyright'),
              mode: LaunchMode.externalApplication,
            );
          } catch (_) {}
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
