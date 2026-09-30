import 'package:caminhandojuntos/models/reward.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeProvider = StateNotifierProvider<StoreNotifier, List<Reward>>((ref) {
  return StoreNotifier();
});

class StoreNotifier extends StateNotifier<List<Reward>> {
  StoreNotifier() : super([]);

  Future<void> fetchRewards() async {
    // TODO: Buscar recompensas dinamicamente da API do servidor
  }
}

final storeFilterProvider = StateProvider<RewardCategory>((ref) => RewardCategory.all);

final filteredRewardsProvider = Provider<List<Reward>>((ref) {
  final rewards = ref.watch(storeProvider);
  final filter = ref.watch(storeFilterProvider);

  if (filter == RewardCategory.all) return rewards;
  return rewards.where((r) => r.category == filter).toList();
});
