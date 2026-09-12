import 'dart:io';
import 'package:caminhandojuntos/providers/achievements_provider.dart';
import 'package:caminhandojuntos/providers/dashboard_provider.dart';
import 'package:caminhandojuntos/models/user_progress.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/achievement_card_widget.dart';
import 'package:caminhandojuntos/widgets/speakable_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareAchievements() async {
    try {
      final image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 10),
        pixelRatio: 2.0,
      );

      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/minhas_conquistas.png').create();
        await imagePath.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'Olha só as medalhas que conquistei no CaminhaJuntos! 🏆🚶‍♂️',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Não foi possível gerar a imagem para compartilhar.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievements = ref.watch(achievementsProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;
    final overallProgress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Speakable(
        announceOnLoad: true,
        text: "Tela de medalhas. Você já conquistou $unlockedCount medalhas de um total de $totalCount.",
        child: Column(
          children: [
            // Cabeçalho Customizado
            _buildHeader(context, dashboardState.progress),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Screenshot(
                    controller: _screenshotController,
                    child: Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Minhas Conquistas 🏆", 
                            style: TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold, 
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ProgressOverview(unlocked: unlockedCount, total: totalCount, progress: overallProgress),
                          const SizedBox(height: 24),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.6,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: achievements.length,
                            itemBuilder: (context, index) {
                              return AchievementCardWidget(achievement: achievements[index]);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _shareAchievements,
                    icon: const Icon(Icons.share, size: 28),
                    label: const Text("Compartilhar com a Família", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isHighContrast ? Colors.yellow : AppTheme.secondaryColor,
                      foregroundColor: isHighContrast ? Colors.black : Colors.white,
                      minimumSize: const Size(double.infinity, 72),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isHighContrast ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProgress progress) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: isHighContrast ? const Border(bottom: BorderSide(color: Colors.white, width: 2)) : null,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "CaminhaJuntos", 
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                "Conquistas", 
                style: TextStyle(
                  fontSize: 12, 
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isHighContrast ? Colors.yellow : const Color(0xFFFFDCC3), 
              borderRadius: BorderRadius.circular(20),
              border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.monetization_on, 
                  color: isHighContrast ? Colors.black : AppTheme.tertiaryColor, 
                  size: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  progress.coins.toString(), 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: isHighContrast ? Colors.black : AppTheme.tertiaryColor, 
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  final int unlocked;
  final int total;
  final double progress;
  const _ProgressOverview({required this.unlocked, required this.total, required this.progress});
  @override
  Widget build(BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: !isHighContrast ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Você já conquistou $unlocked de $total medalhas!", 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress, 
            minHeight: 12, 
            borderRadius: BorderRadius.circular(8),
            backgroundColor: isHighContrast ? Colors.white24 : null,
            color: isHighContrast ? Colors.yellow : null,
          ),
        ],
      ),
    );
  }
}
