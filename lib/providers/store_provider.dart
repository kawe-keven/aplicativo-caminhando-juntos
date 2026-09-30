import 'package:caminhandojuntos/models/reward.dart';
import 'package:caminhandojuntos/services/rewards_api_client.dart';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeProvider = StateNotifierProvider<StoreNotifier, List<Reward>>((ref) {
  return StoreNotifier();
});

class StoreNotifier extends StateNotifier<List<Reward>> {
  final RewardsApiClient _rewardsApiClient = RewardsApiClient();

  StoreNotifier() : super([]);

  Future<void> fetchRewards() async {
    try {
      final rewards = await _rewardsApiClient.fetchRewards();
      state = rewards;
    } catch (e) {
      AppLogger.e('Erro ao buscar recompensas do servidor', e);
      // Mantém lista vazia ou estado atual em caso de falha de rede/offline
    }
  }
}

final storeFilterProvider = StateProvider<RewardCategory>((ref) => RewardCategory.all);

final filteredRewardsProvider = Provider<List<Reward>>((ref) {
  final rewards = ref.watch(storeProvider);
  final filter = ref.watch(storeFilterProvider);

  if (filter == RewardCategory.all) return rewards;
  return rewards.where((r) => r.category == filter).toList();
});
