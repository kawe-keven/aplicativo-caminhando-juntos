import 'package:caminhandojuntos/models/achievement.dart';
import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:caminhandojuntos/services/achievements_api_client.dart';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final achievementsProvider = StateNotifierProvider<AchievementsNotifier, List<Achievement>>((ref) {
  return AchievementsNotifier(ref);
});

class AchievementsNotifier extends StateNotifier<List<Achievement>> {
  final AchievementsApiClient _apiClient = AchievementsApiClient();
  final Ref _ref;

  AchievementsNotifier(this._ref) : super([]) {
    refreshAchievements();
  }

  Future<void> refreshAchievements() async {
    try {
      final serverAchievements = await _apiClient.fetchAchievements();
      final oldUnlockedIds = state.where((a) => a.isUnlocked).map((a) => a.id).toSet();
      
      state = serverAchievements;

      final newlyUnlocked = serverAchievements.any((a) => a.isUnlocked && !oldUnlockedIds.contains(a.id));
      if (newlyUnlocked) {
        try {
          _ref.read(accessibilityProvider.notifier).notify();
        } catch (_) {}
      }
    } catch (e) {
      AppLogger.e('Erro ao buscar conquistas do servidor', e);
      // Mantém estado atual em caso de falha/offline
    }
  }

  int get unlockedCount => state.where((a) => a.isUnlocked).length;
  int get totalCount => state.length;
}
