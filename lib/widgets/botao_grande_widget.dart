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
    return ElevatedButton(
      onPressed: () {
        // SEGURANÇA E ACESSIBILIDADE: Lê o botão ao clicar
        ref.read(accessibilityProvider.notifier).speak("Botão selecionado: $text");
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              text.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 32),
          ],
        ],
      ),
    );
  }
}
