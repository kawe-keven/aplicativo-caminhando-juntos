import 'package:caminhandojuntos/providers/achievements_provider.dart';
import 'package:caminhandojuntos/providers/dashboard_provider.dart';
import 'package:caminhandojuntos/models/user_progress.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/achievement_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    final dashboardState = ref.watch(dashboardProvider);

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    final totalCount = achievements.length;
    final overallProgress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Material(
      color: AppTheme.backgroundColor,
      child: Column(
        children: [
          // Cabeçalho Customizado
          _buildHeader(context, dashboardState.progress),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text("Suas Medalhas de Conquista 🏆", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _ProgressOverview(unlocked: unlockedCount, total: totalCount, progress: overallProgress),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, index) {
                    return AchievementCardWidget(achievement: achievements[index]);
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share),
                  label: const Text("Compartilhar com a Família"),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 64)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProgress progress) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 8, left: 16, right: 16),
      color: Colors.white,
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("CaminhaJuntos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              Text("Conquistas", style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFFFDCC3), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: AppTheme.tertiaryColor, size: 24),
                const SizedBox(width: 4),
                Text(progress.coins.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.tertiaryColor, fontSize: 18)),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Você já conquistou $unlocked de $total medalhas!", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress, minHeight: 12, borderRadius: BorderRadius.circular(8)),
        ],
      ),
    );
  }
}
