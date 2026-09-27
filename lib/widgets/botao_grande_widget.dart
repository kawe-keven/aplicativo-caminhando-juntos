import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BotaoGrandeWidget extends ConsumerWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const BotaoGrandeWidget({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Usa LayoutBuilder e MediaQuery para decidir dinamicamente a orientação e distribuição proporcional
        final bool useVertical = constraints.maxWidth < 300 || textScaleFactor > 1.3;

        return SizedBox(
          width: double.infinity,
          height: useVertical ? 80 : 64,
          child: ElevatedButton(
            onPressed: () {
              ref.read(accessibilityProvider.notifier).speak("Botão selecionado: $text");
              ref.read(accessibilityProvider.notifier).notify();
              onPressed();
            },
            style: ElevatedButton.styleFrom(
              elevation: 8,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              shadowColor: Colors.black.withValues(alpha: 0.4),
            ),
            child: useVertical
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 26),
                        const SizedBox(height: 4),
                      ],
                      Expanded(
                        child: Center(
                          child: Text(
                            text.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          text.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 12),
                        Icon(icon, size: 32),
                      ],
                    ],
                  ),
          ),
        );
      },
    );
  }
}
