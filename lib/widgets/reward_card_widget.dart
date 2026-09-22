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
              child: _buildRewardImage(context),
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

  Widget _buildRewardImage(BuildContext context) {
    // Mapeamento de Cores e Ícones específicos de alta nitidez para cada prêmio (Essencial para acessibilidade do Idoso)
    Color startColor;
    Color endColor;
    IconData icon;

    switch (reward.title.toLowerCase()) {
      case 'candy crush':
        startColor = Colors.pink;
        endColor = Colors.purple;
        icon = Icons.cake; // Cake como substituto visual para doces
        break;
      case 'palavras cruzadas':
        startColor = Colors.blue;
        endColor = Colors.teal;
        icon = Icons.grid_on;
        break;
      case 'buraco & tranca':
        startColor = Colors.orange;
        endColor = Colors.deepOrange;
        icon = Icons.style; // Cartas de baralho
        break;
      case 'caça-palavras':
        startColor = Colors.green;
        endColor = Colors.lightGreen;
        icon = Icons.search;
        break;
      case 'dominó online':
        startColor = Colors.indigo;
        endColor = Colors.blueAccent;
        icon = Icons.view_module;
        break;
      case 'farm heroes':
        startColor = Colors.amber;
        endColor = Colors.orangeAccent;
        icon = Icons.eco;
        break;
      default:
        startColor = AppTheme.primaryColor;
        endColor = AppTheme.secondaryColor;
        icon = Icons.card_giftcard;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 54,
          color: Colors.white,
        ),
      ),
    );
  }
}
