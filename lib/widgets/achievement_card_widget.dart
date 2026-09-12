import 'package:caminhandojuntos/models/achievement.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/speakable_widget.dart';
import 'package:flutter/material.dart';

class AchievementCardWidget extends StatelessWidget {
  final Achievement achievement;

  const AchievementCardWidget({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;
    final String speechText = "Medalha: ${achievement.title}. ${achievement.description}. "
        "${achievement.isUnlocked ? "Já conquistada em ${achievement.dateUnlocked}." : "Falta pouco para conquistar!"}";

    return Speakable(
      text: speechText,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isHighContrast ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isHighContrast 
                  ? (achievement.isUnlocked ? Colors.yellow : Colors.white12) 
                  : (achievement.iconBackgroundColor ?? Colors.grey[200]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                achievement.icon,
                size: 40,
                color: isHighContrast 
                  ? (achievement.isUnlocked ? Colors.black : Colors.white38) 
                  : (achievement.iconColor ?? Colors.grey[600]),
              ),
            ),
            Column(
              children: [
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isHighContrast ? Colors.white : AppTheme.primaryColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isHighContrast ? Colors.white70 : AppTheme.onSurfaceVariant,
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
                  color: isHighContrast ? Colors.yellow : const Color(0xFFB1F1C5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle, 
                      size: 20, 
                      color: isHighContrast ? Colors.black : AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      achievement.dateUnlocked ?? "Conquistada",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isHighContrast ? Colors.black : AppTheme.primaryColor,
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
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          color: isHighContrast ? Colors.yellow : AppTheme.secondaryColor,
                        ),
                      ),
                      if (achievement.progressText != null)
                        Text(
                          achievement.progressText!,
                          style: TextStyle(
                            fontSize: 12, 
                            color: isHighContrast ? Colors.white70 : AppTheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: achievement.progress,
                      minHeight: 8,
                      backgroundColor: isHighContrast ? Colors.white12 : Colors.grey[200],
                      color: isHighContrast 
                        ? Colors.yellow 
                        : (achievement.icon == Icons.lock ? Colors.grey[400] : AppTheme.secondaryColor),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
