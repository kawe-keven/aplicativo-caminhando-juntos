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
      label: 'Voltar',
      child: Material(
        elevation: 4,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        shadowColor: Colors.black38,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPop,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 4),
                Text(
                  "Voltar",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
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
