import 'package:caminhandojuntos/models/reward.dart';
import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/speakable_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardCardWidget extends ConsumerWidget {
  final Reward reward;
  final VoidCallback onRedeem;

  const RewardCardWidget({
    super.key,
    required this.reward,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(accessibilityProvider).highContrastEnabled;
    final String speechText = "Prêmio: ${reward.title}. Descrição: ${reward.description}. Custa ${reward.cost} moedas.";

    return Speakable(
      text: speechText,
      child: Container(
        decoration: BoxDecoration(
          color: isHighContrast ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: !isHighContrast ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildRewardImage(context, isHighContrast),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isHighContrast ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: isHighContrast ? Colors.yellow : AppTheme.tertiaryColor, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${reward.cost} Moedas",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isHighContrast ? Colors.white : AppTheme.tertiaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: onRedeem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHighContrast ? Colors.white : AppTheme.primaryColor,
                      foregroundColor: isHighContrast ? Colors.black : Colors.white,
                      minimumSize: const Size(double.infinity, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: isHighContrast ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
                      ),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text("Resgatar", style: TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardImage(BuildContext context, bool isHighContrast) {
    Color startColor;
    Color endColor;
    IconData icon;
    String badgeText = reward.tag ?? '';

    switch (reward.title.toLowerCase()) {
      case 'candy crush':
        startColor = const Color(0xFFFF2E93);
        endColor = const Color(0xFF7B1FA2);
        icon = Icons.cake;
        break;
      case 'palavras cruzadas':
        startColor = const Color(0xFF00B0FF);
        endColor = const Color(0xFF00695C);
        icon = Icons.grid_on;
        break;
      case 'buraco & tranca':
        startColor = const Color(0xFFFF6D00);
        endColor = const Color(0xFFBF360C);
        icon = Icons.style;
        break;
      case 'caça-palavras':
        startColor = const Color(0xFF00E676);
        endColor = const Color(0xFF1B5E20);
        icon = Icons.search;
        break;
      case 'dominó online':
        startColor = const Color(0xFF3F51B5);
        endColor = const Color(0xFF0D47A1);
        icon = Icons.view_module;
        break;
      case 'farm heroes':
        startColor = const Color(0xFFFFAB00);
        endColor = const Color(0xFFE65100);
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
        boxShadow: [
          BoxShadow(
            color: startColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (badgeText.isNotEmpty)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: startColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

