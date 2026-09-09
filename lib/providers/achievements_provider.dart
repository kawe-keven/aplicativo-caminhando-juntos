import 'package:caminhandojuntos/models/achievement.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final achievementsProvider = StateNotifierProvider<AchievementsNotifier, List<Achievement>>((ref) {
  return AchievementsNotifier();
});

class AchievementsNotifier extends StateNotifier<List<Achievement>> {
  AchievementsNotifier() : super(_mockAchievements);

  static final List<Achievement> _mockAchievements = [
    Achievement(
      id: '1',
      title: 'Primeiro Passo',
      description: 'Completou a 1ª caminhada',
      icon: Icons.directions_run,
      isUnlocked: true,
      dateUnlocked: '12/Out',
      iconBackgroundColor: const Color(0xFFFFDCC3),
      iconColor: AppTheme.tertiaryColor,
    ),
    Achievement(
      id: '2',
      title: 'Caminhante Semanal',
      description: 'Caminhou 7 dias seguidos',
      icon: Icons.military_tech,
      isUnlocked: true,
      dateUnlocked: 'Conquistada',
      iconBackgroundColor: const Color(0xFFFFDCC3),
      iconColor: AppTheme.tertiaryColor,
    ),
    Achievement(
      id: '3',
      title: 'Meta Batida',
      description: 'Atingiu 5.000 passos em 1 dia',
      icon: Icons.wb_sunny,
      isUnlocked: true,
      dateUnlocked: 'Conquistada',
      iconBackgroundColor: const Color(0xFFFFDCC3),
      iconColor: AppTheme.tertiaryColor,
    ),
    Achievement(
      id: '4',
      title: 'Hidratação Nota 10',
      description: 'Bebeu água em 5 caminhadas',
      icon: Icons.water_drop,
      isUnlocked: true,
      dateUnlocked: 'Conquistada',
      iconBackgroundColor: AppTheme.secondaryContainer,
      iconColor: AppTheme.secondaryColor,
    ),
    Achievement(
      id: '5',
      title: 'Explorador do Bairro',
      description: 'Faltam 2,3 km para 10 km',
      icon: Icons.explore,
      progress: 0.77,
      progressText: '7,7 / 10 km',
      iconBackgroundColor: AppTheme.surfaceContainerHigh,
      iconColor: AppTheme.secondaryColor,
    ),
    Achievement(
      id: '6',
      title: 'Mestre da Vitalidade',
      description: '50.000 passos no mês',
      icon: Icons.lock,
      progress: 0.45,
      progressText: '22.500 passos',
      iconBackgroundColor: Colors.grey[200],
      iconColor: Colors.grey[600],
    ),
  ];

  int get unlockedCount => state.where((a) => a.isUnlocked).length;
  int get totalCount => state.length;
}
