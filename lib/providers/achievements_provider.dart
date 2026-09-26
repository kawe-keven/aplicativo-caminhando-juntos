import 'package:caminhandojuntos/models/achievement.dart';
import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:caminhandojuntos/services/local/caminhada_dao.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final achievementsProvider = StateNotifierProvider<AchievementsNotifier, List<Achievement>>((ref) {
  return AchievementsNotifier(ref);
});

class AchievementsNotifier extends StateNotifier<List<Achievement>> {
  final CaminhadaDao _caminhadaDao = CaminhadaDao();
  final Ref _ref;

  AchievementsNotifier(this._ref) : super(_defaultAchievements) {
    refreshAchievements();
  }

  static final List<Achievement> _defaultAchievements = [
    Achievement(
      id: '1',
      title: 'Primeiro Passo',
      description: 'Completou a 1ª caminhada',
      icon: Icons.directions_run,
      isUnlocked: false,
      iconBackgroundColor: const Color(0xFFFFDCC3),
      iconColor: AppTheme.tertiaryColor,
    ),
    Achievement(
      id: '2',
      title: 'Caminhante Semanal',
      description: 'Caminhou 7 dias diferentes',
      icon: Icons.military_tech,
      isUnlocked: false,
      iconBackgroundColor: const Color(0xFFFFDCC3),
      iconColor: AppTheme.tertiaryColor,
    ),
    Achievement(
      id: '3',
      title: 'Meta Batida',
      description: 'Completou pelo menos 1 caminhada',
      icon: Icons.wb_sunny,
      isUnlocked: false,
      iconBackgroundColor: const Color(0xFFFFDCC3),
      iconColor: AppTheme.tertiaryColor,
    ),
    Achievement(
      id: '4',
      title: 'Hidratação Nota 10',
      description: 'Completou 5 caminhadas',
      icon: Icons.water_drop,
      isUnlocked: false,
      iconBackgroundColor: AppTheme.secondaryContainer,
      iconColor: AppTheme.secondaryColor,
    ),
    Achievement(
      id: '5',
      title: 'Explorador do Bairro',
      description: '10 km acumulados',
      icon: Icons.explore,
      progress: 0.0,
      progressText: '0 / 10 km',
      iconBackgroundColor: AppTheme.surfaceContainerHigh,
      iconColor: AppTheme.secondaryColor,
    ),
    Achievement(
      id: '6',
      title: 'Mestre da Vitalidade',
      description: '50.000 passos acumulados',
      icon: Icons.lock,
      progress: 0.0,
      progressText: '0 passos',
      iconBackgroundColor: Colors.grey[200],
      iconColor: Colors.grey[600],
    ),
  ];

  Future<void> refreshAchievements() async {
    try {
      final completedWalks = await _caminhadaDao.getAllCompleted();
      final totalWalks = completedWalks.length;

      double totalDistanceKm = 0.0;
      int totalSteps = 0;
      for (var walk in completedWalks) {
        final tempoAtivoMs = walk['tempo_ativo_ms'] as int? ?? 0;
        final dist = (tempoAtivoMs / 60000.0) * 0.075;
        totalDistanceKm += dist;
        totalSteps += (dist * 1300).round();
      }

      final uniqueDays = completedWalks.map((w) {
        final dt = DateTime.fromMillisecondsSinceEpoch(w['inicio_ms'] as int);
        return '${dt.year}-${dt.month}-${dt.day}';
      }).toSet().length;

      final oldUnlockedIds = state.where((a) => a.isUnlocked).map((a) => a.id).toSet();

      final newState = [
        Achievement(
          id: '1',
          title: 'Primeiro Passo',
          description: 'Completou a 1ª caminhada',
          icon: Icons.directions_run,
          isUnlocked: totalWalks >= 1,
          dateUnlocked: totalWalks >= 1 ? 'Conquistada' : null,
          iconBackgroundColor: const Color(0xFFFFDCC3),
          iconColor: AppTheme.tertiaryColor,
        ),
        Achievement(
          id: '2',
          title: 'Caminhante Semanal',
          description: 'Caminhou 7 dias diferentes',
          icon: Icons.military_tech,
          isUnlocked: uniqueDays >= 7,
          dateUnlocked: uniqueDays >= 7 ? 'Conquistada' : null,
          progress: (uniqueDays / 7.0).clamp(0.0, 1.0),
          progressText: '$uniqueDays / 7 dias',
          iconBackgroundColor: const Color(0xFFFFDCC3),
          iconColor: AppTheme.tertiaryColor,
        ),
        Achievement(
          id: '3',
          title: 'Meta Batida',
          description: 'Completou pelo menos 1 caminhada',
          icon: Icons.wb_sunny,
          isUnlocked: totalWalks >= 1,
          dateUnlocked: totalWalks >= 1 ? 'Conquistada' : null,
          iconBackgroundColor: const Color(0xFFFFDCC3),
          iconColor: AppTheme.tertiaryColor,
        ),
        Achievement(
          id: '4',
          title: 'Hidratação Nota 10',
          description: 'Completou 5 caminhadas',
          icon: Icons.water_drop,
          isUnlocked: totalWalks >= 5,
          dateUnlocked: totalWalks >= 5 ? 'Conquistada' : null,
          progress: (totalWalks / 5.0).clamp(0.0, 1.0),
          progressText: '$totalWalks / 5',
          iconBackgroundColor: AppTheme.secondaryContainer,
          iconColor: AppTheme.secondaryColor,
        ),
        Achievement(
          id: '5',
          title: 'Explorador do Bairro',
          description: '10 km acumulados',
          icon: Icons.explore,
          isUnlocked: totalDistanceKm >= 10.0,
          dateUnlocked: totalDistanceKm >= 10.0 ? 'Conquistada' : null,
          progress: (totalDistanceKm / 10.0).clamp(0.0, 1.0),
          progressText: '${totalDistanceKm.toStringAsFixed(1)} / 10 km',
          iconBackgroundColor: AppTheme.surfaceContainerHigh,
          iconColor: AppTheme.secondaryColor,
        ),
        Achievement(
          id: '6',
          title: 'Mestre da Vitalidade',
          description: '50.000 passos acumulados',
          icon: totalSteps >= 50000 ? Icons.military_tech : Icons.lock,
          isUnlocked: totalSteps >= 50000,
          dateUnlocked: totalSteps >= 50000 ? 'Conquistada' : null,
          progress: (totalSteps / 50000.0).clamp(0.0, 1.0),
          progressText: '$totalSteps / 50k passos',
          iconBackgroundColor: totalSteps >= 50000 ? const Color(0xFFFFDCC3) : Colors.grey[200],
          iconColor: totalSteps >= 50000 ? AppTheme.tertiaryColor : Colors.grey[600],
        ),
      ];

      final newlyUnlocked = newState.any((a) => a.isUnlocked && !oldUnlockedIds.contains(a.id));
      state = newState;

      if (newlyUnlocked) {
        try {
          _ref.read(accessibilityProvider.notifier).notify();
        } catch (_) {}
      }
    } catch (e) {
      // Keep state on error
    }
  }

  int get unlockedCount => state.where((a) => a.isUnlocked).length;
  int get totalCount => state.length;
}
