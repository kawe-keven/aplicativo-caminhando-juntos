import 'package:caminhandojuntos/models/user_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardProvider = StateNotifierProvider<DashboardNotifier, UserProgress>((ref) {
  return DashboardNotifier();
});

class DashboardNotifier extends StateNotifier<UserProgress> {
  DashboardNotifier() : super(UserProgress(
    steps: 3850,
    goalSteps: 5000,
    coins: 340,
    distanceKm: 2.4,
    durationMinutes: 35,
    calories: 180,
  ));

  void addSteps(int count) {
    state = state.copyWith(steps: state.steps + count);
  }

  void resetDaily() {
    state = UserProgress(goalSteps: state.goalSteps);
  }

  bool redeemReward(int cost) {
    if (state.coins >= cost) {
      state = state.copyWith(coins: state.coins - cost);
      return true;
    }
    return false;
  }
}
