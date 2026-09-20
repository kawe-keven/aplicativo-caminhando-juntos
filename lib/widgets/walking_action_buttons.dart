import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';

class WalkingActionButtons extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botão SOS Crítico destacado sozinho em cima dos controles padrão para evitar acionamento errôneo
        Semantics(
          button: true,
          label: 'SOS Central de ajuda emergencial',
          child: Tooltip(
            message: 'Pedir auxílio emergencial',
            child: ElevatedButton.icon(
              onPressed: onSOS,
              icon: const Icon(Icons.phone_in_talk, size: 28),
              label: const Text(
                "SOS - LIGAR PARA AJUDA",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isHighContrast ? Colors.red : AppTheme.errorColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isHighContrast ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
                ),
                elevation: 4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Fileira inferior com Pausar/Retomar e Finalizar
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: trackingStatus == TrackingStatus.paused ? 'Retomar caminhada' : 'Pausar caminhada',
                child: Tooltip(
                  message: trackingStatus == TrackingStatus.paused ? 'Continuar atividade' : 'Suspender temporariamente',
                  child: ElevatedButton.icon(
                    onPressed: onPauseToggle,
                    icon: Icon(
                      trackingStatus == TrackingStatus.paused ? Icons.play_circle : Icons.pause_circle,
                      size: 28,
                    ),
                    label: Text(
                      trackingStatus == TrackingStatus.paused ? "Retomar" : "Pausar",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHighContrast ? Colors.black : Colors.white,
                      foregroundColor: isHighContrast ? Colors.white : AppTheme.secondaryColor,
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isHighContrast ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Finalizar e validar caminhada',
                child: Tooltip(
                  message: 'Encerrar atividade e sincronizar moedas',
                  child: ElevatedButton.icon(
                    onPressed: onFinish,
                    icon: const Icon(Icons.stop_circle, size: 28),
                    label: const Text(
                      "Finalizar",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isHighContrast ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
