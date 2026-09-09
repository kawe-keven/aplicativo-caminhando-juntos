import 'package:caminhandojuntos/models/reward.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storeProvider = StateNotifierProvider<StoreNotifier, List<Reward>>((ref) {
  return StoreNotifier();
});

class StoreNotifier extends StateNotifier<List<Reward>> {
  StoreNotifier() : super(_mockRewards);

  static final List<Reward> _mockRewards = [
    Reward(
      id: '1',
      title: 'Candy Crush',
      description: '10 Barras de Ouro ou 3 Vidas Extras',
      cost: 150,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBOi2jxKqz8HhGQwG3JyfI1SL2B_51npW2hHiVgDIA7awIIjZr8sBskD97J1EIVrP4IMJsMxQ2kvGY4rFMaLLHx-AtHbZwsMfwvzHpCxPtPPTGuuNdQi-Lz11SNLZoorZXUaG-EEqzEGEQOajAXEhSRlHC_tpJCnODc-Yl1c5tW_OagWLF9lvv_nBF9AASje1xLM3EwxGhKUSz2NcY1VSuA3BrhuHXrV35hx158zS9VV4I2ubxOEHwn',
      category: RewardCategory.popular,
      tag: 'Top 1',
    ),
    Reward(
      id: '2',
      title: 'Palavras Cruzadas',
      description: 'Revista Digital Sem Anúncios',
      cost: 100,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAA-rVNNrD2Yvnrcd9LXTy_w_dnIBozLq_H5Cm_tPd7k-pSK4uF0aDo2IfzorSXup6USKQAgrACxgQYng0dmLnVl6WVlfLXQK1I96dfS9RKEboFyTSKVU7b12Xwes9DedDo8sO073e7eFR8K1qKiaHQ2W2igpVTxJaiqsGPSa9Pl7RRXdQkPacENMY07wEmr-sJYmN0iemUZ-2rs_uBg6_9_jVdB0Es-63c3PfnhmocTpmdLmsUylnd',
      category: RewardCategory.popular,
    ),
    Reward(
      id: '3',
      title: 'Buraco & Tranca',
      description: 'Moedas e Fichas de Jogo',
      cost: 120,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAU7fPppSFuqm6PibyexKpX-vcHtH9VocXcz8ATJGzj_yxsCifRSxIoPB_ssUIQ5YXvUbdFWUumZw5IhGNWzm2XUtUrXjNJsbeulE_xcALMKBqiuIxspDeXXlRSMulVr562cy7vdMyBc3BMMQq4bUbRO0xJH8VTwVBGWhYDf66qJxQ35ZBwHMmVG_Vyx23gVfyxso0zDkkXYbXLWp3fvUc6W_Qf_NiemP95qgwbG4vxspOu-Ht5kIn9',
      category: RewardCategory.popular,
    ),
    Reward(
      id: '4',
      title: 'Caça-Palavras',
      description: 'Dicas Infinitas por 7 dias',
      cost: 80,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuB1ZjWdKbLtPN8I6FSxx9mIFd6_BZtfInugiA8KMb-BGzGzQUq9qCM26txYFFDpI3ZraGD26Y19CWIDbMIVt-3ZAuWl341T2F61SfDHupMmJn-GzrziBDVVh5Al7unsAufWHQjLWUOYF916qB4jfQr3jb-C5A4uEhiDK1WM2sSgbxGAX_ZantliybP70iLy0o2yuex_WGdB_Y2j6k9A0xNhOzQNnUZ5LDs_pHlnxHWab6Ek-WjA1xL0',
      category: RewardCategory.all,
    ),
    Reward(
      id: '5',
      title: 'Dominó Online',
      description: 'Pacote de Mesas Especiais',
      cost: 110,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDI7ll3ELBh4Q3--IuAFR02G_6LyNxChzg1QykoBkNu8g32zDL84BD5O9wC0bqAGdaiOn0epDfn8CRoIdNvoQW2fBDfHr1thygKApe-TEUv0pxcZcBELO7f4RvxJd4vvi3NP2zT52ivv-J6-ju6QkVzqbcue74QpOrX8VYGMh-YSpMysMb0pnJLLkE3vsmZR5fiBqBM3d1aMjAgVOR78cVB3B3Apk2RVafBQetIYmXEPOBcVzppSLdf',
      category: RewardCategory.all,
    ),
    Reward(
      id: '6',
      title: 'Farm Heroes',
      description: 'Feijões Mágicos & Boosters',
      cost: 140,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDpOy3126rijOEwk0Ek2lPek6_1o14AvIfI_WU0A9W99XVrmhwtBUKjK34y8EYBT64qNjf6l3m4Psc_pTIQVuvDCKcd2usnQqUCTUy8Rj7n14xilfF72twcs4LjQ3UODJXnTrNxl4CTiIepql8HYCqkix6DmGg5b6bxfvDbhS_kM8-nWRayTroTPR5NwzdD4r2-BJLHtTbTbCxs0JbwIayIy0-x7oqd7rnttMymO3AI2tHJf6Jq3CbL',
      category: RewardCategory.all,
    ),
  ];
}

final storeFilterProvider = StateProvider<RewardCategory>((ref) => RewardCategory.all);

final filteredRewardsProvider = Provider<List<Reward>>((ref) {
  final rewards = ref.watch(storeProvider);
  final filter = ref.watch(storeFilterProvider);

  if (filter == RewardCategory.all) return rewards;
  return rewards.where((r) => r.category == filter).toList();
});
