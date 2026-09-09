import 'package:caminhandojuntos/models/reward.dart';
import 'package:caminhandojuntos/providers/dashboard_provider.dart';
import 'package:caminhandojuntos/providers/store_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/reward_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardsStoreScreen extends ConsumerWidget {
  const RewardsStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final filter = ref.watch(storeFilterProvider);
    final rewards = ref.watch(filteredRewardsProvider);

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
                _BalanceCard(coins: dashboardState.progress.coins),
                const SizedBox(height: 24),
                _FilterSection(filter: filter, ref: ref),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    final reward = rewards[index];
                    return RewardCardWidget(
                      reward: reward,
                      // Passa o estado de carregamento para o botão no futuro se necessário
                      onRedeem: () => _showRedeemDialog(context, ref, reward, dashboardState),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _InfoFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic progress) {
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
              Text("Prêmios", style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
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

  void _showRedeemDialog(BuildContext context, WidgetRef ref, Reward reward, DashboardState dashboardState) {
    if (dashboardState.progress.coins < reward.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Saldo insuficiente para resgatar este prêmio.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Resgatar Prêmio", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Deseja resgatar ${reward.title} por ${reward.cost} moedas?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: dashboardState.isRedeeming 
              ? null 
              : () async {
                  final success = await ref.read(dashboardProvider.notifier).redeemReward(reward.cost);
                  if (context.mounted) Navigator.pop(context);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Prêmio resgatado! Código: CXJ-${reward.id}88")));
                  }
                },
            child: dashboardState.isRedeeming 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Resgatar"),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int coins;
  const _BalanceCard({required this.coins});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Color(0xFFFFDCC3), shape: BoxShape.circle),
            child: const Icon(Icons.monetization_on, color: AppTheme.tertiaryColor, size: 30),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Seu Saldo Disponível", style: TextStyle(fontSize: 16)),
              Text("$coins Moedas", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final RewardCategory filter;
  final WidgetRef ref;
  const _FilterSection({required this.filter, required this.ref});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppTheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _FilterTab(label: "Todos", isSelected: filter == RewardCategory.all, onTap: () => ref.read(storeFilterProvider.notifier).state = RewardCategory.all),
          _FilterTab(label: "Populares", isSelected: filter == RewardCategory.popular, onTap: () => ref.read(storeFilterProvider.notifier).state = RewardCategory.popular),
          _FilterTab(label: "Vales", isSelected: filter == RewardCategory.vouchers, onTap: () => ref.read(storeFilterProvider.notifier).state = RewardCategory.vouchers),
        ],
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterTab({required this.label, required this.isSelected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: isSelected ? BoxDecoration(color: AppTheme.primaryContainer, borderRadius: BorderRadius.circular(12)) : null,
          child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}

class _InfoFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppTheme.secondaryContainer, borderRadius: BorderRadius.circular(16)),
      child: const Row(
        children: [
          Icon(Icons.help_outline, color: AppTheme.secondaryColor, size: 30),
          SizedBox(width: 12),
          Expanded(child: Text("O resgate é instantâneo e você recebe o código na hora!", style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
