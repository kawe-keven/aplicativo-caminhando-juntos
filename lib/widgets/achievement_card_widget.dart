import 'package:caminhandojuntos/models/achievement.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AchievementCardWidget extends StatelessWidget {
  final Achievement achievement;

  const AchievementCardWidget({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: achievement.iconBackgroundColor ?? Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              size: 40,
              color: achievement.iconColor ?? Colors.grey[600],
            ),
          ),
          Column(
            children: [
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                achievement.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.2,
                ),
              ),
            ],
          ),
          if (achievement.isUnlocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFB1F1C5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 20, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    achievement.dateUnlocked ?? "Conquistada",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${(achievement.progress * 100).toInt()}%",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                    ),
                    if (achievement.progressText != null)
                      Text(
                        achievement.progressText!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: achievement.progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    color: achievement.icon == Icons.lock ? Colors.grey[400] : AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
