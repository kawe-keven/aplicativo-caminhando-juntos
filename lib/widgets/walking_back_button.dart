import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalkingBackButton extends ConsumerWidget {
  final TrackingStatus trackingStatus;
  final VoidCallback onPop;

  const WalkingBackButton({
    super.key,
    required this.trackingStatus,
    required this.onPop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(accessibilityProvider).highContrastEnabled;

    return Semantics(
      button: true,
      label: 'Voltar para a tela inicial',
      child: Material(
        elevation: 4,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        shadowColor: Colors.black38,
        shape: isHighContrast ? RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Colors.white, width: 2),
        ) : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPop,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back,
                  color: isHighContrast ? Colors.white : Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    "Voltar",
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isHighContrast ? Colors.white : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
