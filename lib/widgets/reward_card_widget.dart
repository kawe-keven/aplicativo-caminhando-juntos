import 'package:caminhandojuntos/models/reward.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/speakable_widget.dart';
import 'package:flutter/material.dart';

class RewardCardWidget extends StatelessWidget {
  final Reward reward;
  final VoidCallback onRedeem;

  const RewardCardWidget({
    super.key,
    required this.reward,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final String speechText = "Prêmio: ${reward.title}. Descrição: ${reward.description}. Custa ${reward.cost} moedas.";

    return Speakable(
      text: speechText,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.asset(
                  "assets/images/logo_launcher.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: AppTheme.tertiaryColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "${reward.cost} Moedas",
                        style: const TextStyle(color: AppTheme.tertiaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onRedeem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text("Resgatar"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
