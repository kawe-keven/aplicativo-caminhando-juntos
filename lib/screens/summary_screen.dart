import 'package:caminhandojuntos/providers/user_provider.dart';
import 'package:caminhandojuntos/providers/tracking_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/botao_grande_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trackingProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor, size: 30),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text("Caminhada Validada", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Celebration Header
              Column(
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: const BoxDecoration(color: Color(0xFFFFDCC3), shape: BoxShape.circle),
                    child: const Icon(Icons.verified, size: 64, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tudo certo, ${user.name.isEmpty ? 'Seu Antônio' : user.name}! 🎊",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "O servidor validou seus dados e suas moedas já foram creditadas.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: AppTheme.onSurfaceVariant),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Validated Reward Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Text("MOEDAS CREDITADAS PELO SERVIDOR", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFFFFDCC3), size: 40),
                        const SizedBox(width: 12),
                        Text(
                          "+${tracking.validatedCoins}",
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFFFFDCC3)),
                        ),
                      ],
                    ),
                    const Text("Saldo Atualizado com Sucesso!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Validated Metrics Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _SummaryMetricCard(
                    label: "Pontos GPS",
                    value: tracking.rawPath.length.toString(),
                    unit: "validados",
                    icon: Icons.gps_fixed,
                    iconColor: AppTheme.primaryColor,
                    iconBgColor: const Color(0xFFB1F1C5),
                  ),
                  _SummaryMetricCard(
                    label: "Distância Real",
                    value: tracking.validatedDistanceKm.toStringAsFixed(2),
                    unit: "quilômetros",
                    icon: Icons.route,
                    iconColor: AppTheme.secondaryColor,
                    iconBgColor: AppTheme.secondaryContainer,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // CTAs
              BotaoGrandeWidget(
                text: "Ver meus prêmios 🎁",
                onPressed: () => context.push('/store'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(trackingProvider.notifier).reset();
                  context.go('/dashboard');
                },
                icon: const Icon(Icons.home, size: 30),
                label: const Text("Voltar ao Início", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 64),
                  side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  foregroundColor: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const _SummaryMetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.onSurfaceVariant)),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: iconColor)),
              Text(unit, style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
