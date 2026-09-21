import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:caminhandojuntos/widgets/compass_arrow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalkingInfoPanel extends ConsumerWidget {
  final String formattedTime;
  final double distanceMetresOrKm; // já em formato legível ou double calculado

  const WalkingInfoPanel({
    super.key,
    required this.formattedTime,
    required this.distanceMetresOrKm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(accessibilityProvider).highContrastEnabled;

    // Distância legível com 2 casas decimais
    final String displayDistance = distanceMetresOrKm >= 1000
        ? '${(distanceMetresOrKm / 1000).toStringAsFixed(2)} km'
        : '${distanceMetresOrKm.toStringAsFixed(0)} m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: isHighContrast ? 1.0 : 0.92),
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bloco do Tempo
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  "Tempo",
                  style: TextStyle(
                    fontSize: 14,
                    color: isHighContrast ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Divisor vertical
            Container(width: 1, height: 32, color: isHighContrast ? Colors.white38 : Colors.grey[300]),
            const SizedBox(width: 10),
            // Bloco da Distância
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayDistance,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  "Distância",
                  style: TextStyle(
                    fontSize: 14,
                    color: isHighContrast ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Divisor vertical
            Container(width: 1, height: 32, color: isHighContrast ? Colors.white38 : Colors.grey[300]),
            const SizedBox(width: 10),
            // Bloco de Direção / Bússola
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 32,
                  width: 32,
                  child: CompassArrow(size: 24),
                ),
                SizedBox(height: 2),
                Text(
                  "Direção",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
