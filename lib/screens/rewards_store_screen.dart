import 'package:caminhandojuntos/models/reward.dart';
import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:caminhandojuntos/providers/dashboard_provider.dart';
import 'package:caminhandojuntos/providers/store_provider.dart';
import 'package:caminhandojuntos/models/user_progress.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/reward_card_widget.dart';
import 'package:caminhandojuntos/widgets/speakable_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RewardsStoreScreen extends ConsumerStatefulWidget {
  const RewardsStoreScreen({super.key});

  @override
  ConsumerState<RewardsStoreScreen> createState() => _RewardsStoreScreenState();
}

class _RewardsStoreScreenState extends ConsumerState<RewardsStoreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeProvider.notifier).fetchRewards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final DashboardState dashboardState = ref.watch(dashboardProvider);
    final rewards = ref.watch(storeProvider);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Speakable(
        announceOnLoad: true,
        text: "Loja de prêmios aberta. Você tem ${dashboardState.progress.coins} moedas. "
            "Toque em um prêmio para ouvir detalhes ou resgatar.",
        child: Column(
          children: [
            _buildHeader(context, dashboardState.progress),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _BalanceCard(coins: dashboardState.progress.coins),
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
                        onRedeem: () => _showRedeemDialog(context, ref, reward, dashboardState),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const _InfoFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProgress progress) {
    return Consumer(
      builder: (context, ref, _) {
        final isHighContrast = ref.watch(accessibilityProvider).highContrastEnabled;

        return Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 8, left: 16, right: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: isHighContrast 
                ? const Border(bottom: BorderSide(color: Colors.white, width: 2))
                : null,
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("CaminhaJuntos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isHighContrast ? Colors.white : Theme.of(context).colorScheme.primary)),
                  Text("Prêmios", style: TextStyle(fontSize: 12, color: isHighContrast ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isHighContrast ? Colors.black : const Color(0xFFFFDCC3), 
                  borderRadius: BorderRadius.circular(20),
                  border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: Row(
                  children: [
                    Icon(Icons.monetization_on, color: isHighContrast ? Colors.white : AppTheme.tertiaryColor, size: 24),
                    const SizedBox(width: 4),
                    Text(
                      progress.coins.toString(), 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: isHighContrast ? Colors.white : AppTheme.tertiaryColor, 
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  void _showRedeemDialog(BuildContext context, WidgetRef ref, Reward reward, DashboardState dashboardState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Resgatar Prêmio", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Deseja resgatar ${reward.title} por ${reward.cost} moedas?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: dashboardState.isRedeeming == true 
              ? null 
              : () async {
                  final success = await ref.read(dashboardProvider.notifier).redeemReward(reward.cost);
                  if (context.mounted) Navigator.pop(context);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Prêmio resgatado! Código: CXJ-${reward.id}88")));
                  }
                },
            child: dashboardState.isRedeeming == true 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Resgatar"),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  final int coins;
  const _BalanceCard({required this.coins});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(accessibilityProvider).highContrastEnabled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: !isHighContrast ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isHighContrast ? Colors.black : const Color(0xFFFFDCC3), 
              shape: BoxShape.circle,
              border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Icon(Icons.monetization_on, color: isHighContrast ? Colors.white : AppTheme.tertiaryColor, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Seu Saldo Disponível", style: TextStyle(fontSize: 16)),
                Text(
                  "$coins Moedas", 
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold,
                    color: isHighContrast ? Colors.white : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoFooter extends ConsumerWidget {
  const _InfoFooter();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = ref.watch(accessibilityProvider).highContrastEnabled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : AppTheme.secondaryContainer, 
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline, color: isHighContrast ? Colors.cyanAccent : AppTheme.secondaryColor, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "O resgate é instantâneo e você recebe o código na hora!", 
              style: TextStyle(fontSize: 16, fontWeight: isHighContrast ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
