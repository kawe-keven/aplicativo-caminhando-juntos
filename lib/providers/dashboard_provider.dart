import 'package:caminhandojuntos/models/user_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  ));

  void addSteps(int count) {
    state = state.copyWith(progress: state.progress.copyWith(steps: state.progress.steps + count));
  }

  /// Requisito de Segurança (Escopo 6): Proteção contra cliques duplos (Rate Limiting UI)
  Future<bool> redeemReward(int cost) async {
    if (state.isRedeeming) return false; // Bloqueia cliques simultâneos
    if (state.progress.coins < cost) return false;

    state = state.copyWith(isRedeeming: true, error: null);

    try {
      // Simula chamada ao Backend Java
      // AÇÃO NECESSÁRIA NO BACKEND: O servidor deve validar o saldo real antes de descontar.
      await Future.delayed(const Duration(seconds: 2));
      
      state = state.copyWith(
        progress: state.progress.copyWith(coins: state.progress.coins - cost),
        isRedeeming: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isRedeeming: false, error: 'Falha no resgate.');
      return false;
    }
  }

  /// Requisito de Segurança (Escopo 2): Atualiza saldo vindo do backend.
  /// AÇÃO NECESSÁRIA NO BACKEND: Enviar o novo saldo calculado pelo Java.
  void updateProgressFromServer(UserProgress newProgress) {
    state = state.copyWith(progress: newProgress);
  }
}
