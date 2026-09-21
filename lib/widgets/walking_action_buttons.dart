import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalkingActionButtons extends ConsumerWidget {
  final TrackingStatus trackingStatus;
  final VoidCallback onPauseToggle;
  final VoidCallback onFinish;
  final VoidCallback onSOS;

  const WalkingActionButtons({
    super.key,
    required this.trackingStatus,
    required this.onPauseToggle,
    required this.onFinish,
    required this.onSOS,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(accessibilityProvider).highContrastEnabled;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Decide se empilha os botões ou usa Row baseado na largura disponível e escala da fonte
        final textScaler = MediaQuery.textScalerOf(context);
        final bool useVerticalLayout = constraints.maxWidth < 400 || textScaler.scale(18) > 28;

        final sosButton = _ActionButton(
          onPressed: onSOS,
          icon: Icons.phone_in_talk,
          label: "SOS - LIGAR PARA AJUDA",
          isSOS: true,
          isHighContrast: isHighContrast,
        );

        final pauseButton = _ActionButton(
          onPressed: onPauseToggle,
          icon: trackingStatus == TrackingStatus.paused ? Icons.play_circle : Icons.pause_circle,
          label: trackingStatus == TrackingStatus.paused ? "Retomar" : "Pausar",
          isSecondary: true,
          isHighContrast: isHighContrast,
        );

        final finishButton = _ActionButton(
          onPressed: onFinish,
          icon: Icons.stop_circle,
          label: "Finalizar",
          isPrimary: true,
          isHighContrast: isHighContrast,
        );

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              sosButton,
              const SizedBox(height: 12),
              if (useVerticalLayout) ...[
                pauseButton,
                const SizedBox(height: 12),
                finishButton,
              ] else
                Row(
                  children: [
                    Expanded(child: pauseButton),
                    const SizedBox(width: 12),
                    Expanded(child: finishButton),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool isSOS;
  final bool isPrimary;
  final bool isSecondary;
  final bool isHighContrast;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isSOS = false,
    this.isPrimary = false,
    this.isSecondary = false,
    this.isHighContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide? border;

    if (isSOS) {
      bgColor = isHighContrast ? Color(0xFFFFD600) : AppTheme.errorColor;
      fgColor = isHighContrast ? Colors.black : Colors.white;
      border = isHighContrast ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none;
    } else if (isPrimary) {
      bgColor = isHighContrast ? Color(0xFFFAFAFA) : Theme.of(context).colorScheme.primary;
      fgColor = isHighContrast ? Color(0xFF0A0A0A) : Theme.of(context).colorScheme.onPrimary;
      border = isHighContrast ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none;
    } else {
      bgColor = isHighContrast ? Colors.black : Colors.white;
      fgColor = isHighContrast ? Colors.white : AppTheme.secondaryColor;
      border = isHighContrast ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none;
    }

    return Semantics(
      button: true,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: border,
            ),
            elevation: 4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
