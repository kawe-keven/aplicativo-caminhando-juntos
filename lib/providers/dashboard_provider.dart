import 'dart:convert';
import 'package:caminhandojuntos/models/user_progress.dart';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:caminhandojuntos/services/rewards_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardState {
  final UserProgress progress;
  final bool isRedeeming;
  final String? error;

  DashboardState({
    required this.progress,
    this.isRedeeming = false,
    this.error,
  });

  DashboardState copyWith({
    UserProgress? progress,
    bool? isRedeeming,
    String? error,
  }) {
    return DashboardState(
      progress: progress ?? this.progress,
      isRedeeming: isRedeeming ?? this.isRedeeming,
      error: error,
    );
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(DashboardState(
    progress: UserProgress(
      steps: 3850,
      goalSteps: 5000,
      coins: 340,
      distanceKm: 2.4,
      durationMinutes: 35,
      calories: 180,
    ),
  )) {
    loadProgress();
  }

  Future<void> loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('user_progress');
      if (jsonString != null) {
        final data = json.decode(jsonString) as Map<String, dynamic>;
        state = state.copyWith(progress: UserProgress.fromJson(data));
      }
    } catch (e) {
      AppLogger.e('Erro ao carregar progresso do dashboard', e);
    }
  }

  Future<void> _saveProgress(UserProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_progress', json.encode(progress.toJson()));
    } catch (e) {
      AppLogger.e('Erro ao salvar progresso do dashboard', e);
    }
  }

  void addSteps(int count) {
    final newProgress = state.progress.copyWith(steps: state.progress.steps + count);
    state = state.copyWith(progress: newProgress);
    _saveProgress(newProgress);
  }

  void addCompletedWalk({
    required double distanceKm,
    required int coins,
    required int durationMinutes,
    int steps = 0,
  }) {
    final current = state.progress;
    final estimatedSteps = steps > 0 ? steps : (distanceKm * 1300).round();
    final estimatedCalories = (distanceKm * 60).round();
    final newProgress = current.copyWith(
      steps: current.steps + estimatedSteps,
      coins: current.coins + coins,
      distanceKm: double.parse((current.distanceKm + distanceKm).toStringAsFixed(2)),
      durationMinutes: current.durationMinutes + durationMinutes,
      calories: current.calories + estimatedCalories,
    );
    state = state.copyWith(progress: newProgress);
    _saveProgress(newProgress);
  }

  /// Requisito de Segurança (Escopo 6): Proteção contra cliques duplos (Rate Limiting UI)
  /// O servidor Java deve validar o saldo antes de debitar (não confiar no cliente).
  Future<bool> redeemReward(int cost, {String rewardId = 'default_reward'}) async {
    if (state.isRedeeming) return false;
    if (state.progress.coins < cost) return false;

    state = state.copyWith(isRedeeming: true, error: null);

    try {
      final rewardsClient = RewardsApiClient();
      final newCoins = await rewardsClient.redeemReward(rewardId, cost);
      
      final updatedCoins = newCoins >= 0 ? newCoins : state.progress.coins - cost;
      final newProgress = state.progress.copyWith(coins: updatedCoins);
      
      state = state.copyWith(
        progress: newProgress,
        isRedeeming: false,
      );
      _saveProgress(newProgress);
      return true;
    } catch (e) {
      AppLogger.e('Falha na API de resgate, aplicando fallback otimista', e);
      final newCoins = state.progress.coins - cost;
      final newProgress = state.progress.copyWith(coins: newCoins);
      state = state.copyWith(
        progress: newProgress,
        isRedeeming: false,
        error: 'Sem conexão com o servidor. Resgate aplicado localmente.',
      );
      _saveProgress(newProgress);
      return true;
    }
  }

  void updateProgressFromServer(UserProgress newProgress) {
    state = state.copyWith(progress: newProgress);
    _saveProgress(newProgress);
  }
}
