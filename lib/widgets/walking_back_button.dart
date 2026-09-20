import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:flutter/material.dart';

class WalkingBackButton extends StatelessWidget {
  final TrackingStatus trackingStatus;
  final VoidCallback onPop;

  const WalkingBackButton({
    super.key,
    required this.trackingStatus,
    required this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Voltar para a tela inicial',
      child: Material(
        elevation: 4,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        shadowColor: Colors.black38,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPop,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Voltar",
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
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
