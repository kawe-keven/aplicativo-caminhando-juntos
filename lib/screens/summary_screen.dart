import 'package:caminhandojuntos/providers/user_provider.dart';
import 'package:caminhandojuntos/providers/tracking_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/botao_grande_widget.dart';
import 'package:caminhandojuntos/widgets/speakable_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trackingProvider);
    final user = ref.watch(userProvider);
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    final String summaryMsg = "Parabéns, ${user.name.isEmpty ? 'Seu Antônio' : user.name}! "
        "Sua caminhada foi validada. Você percorreu ${tracking.validatedDistanceKm.toStringAsFixed(2)} quilômetros "
        "e ganhou ${tracking.validatedCoins} moedas de recompensa.";

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary, size: 30),
          onPressed: () {
            ref.read(trackingProvider.notifier).reset();
            context.go('/dashboard');
          },
        ),
        title: Text(
          "Caminhada Validada", 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        shape: isHighContrast ? const Border(bottom: BorderSide(color: Colors.white, width: 2)) : null,
      ),
      body: SafeArea(
        child: Speakable(
          announceOnLoad: true,
          text: summaryMsg,
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
                      decoration: BoxDecoration(
                        color: isHighContrast ? Colors.yellow : const Color(0xFFFFDCC3), 
                        shape: BoxShape.circle,
                        border: isHighContrast ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                      child: Icon(
                        Icons.verified, 
                        size: 64, 
                        color: isHighContrast ? Colors.black : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Tudo certo, ${user.name.isEmpty ? 'Seu Antônio' : user.name}! 🎊",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "O servidor validou seus dados e suas moedas já foram creditadas.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18, 
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isHighContrast ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Validated Reward Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    border: isHighContrast ? Border.all(color: Colors.white, width: 3) : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        "MOEDAS CREDITADAS PELO SERVIDOR", 
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isHighContrast ? Colors.black : Colors.white70, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12, 
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.monetization_on, 
                            color: isHighContrast ? Colors.black : const Color(0xFFFFDCC3), 
                            size: 40,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "+${tracking.validatedCoins}",
                            style: TextStyle(
                              fontSize: 48, 
                              fontWeight: FontWeight.w900, 
                              color: isHighContrast ? Colors.black : const Color(0xFFFFDCC3),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "Saldo Atualizado com Sucesso!", 
                        style: TextStyle(
                          color: isHighContrast ? Colors.black : Colors.white, 
                          fontSize: 20, 
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Validated Metrics Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.1, // Aumentado para evitar overflow de texto
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _SummaryMetricCard(
                      label: "Pontos GPS",
                      value: tracking.rawPath.length.toString(),
                      unit: "validados",
                      icon: Icons.gps_fixed,
                      iconColor: isHighContrast ? Colors.cyanAccent : AppTheme.primaryColor,
                      iconBgColor: isHighContrast ? Colors.black : const Color(0xFFB1F1C5),
                    ),
                    _SummaryMetricCard(
                      label: "Distância Real",
                      value: tracking.validatedDistanceKm.toStringAsFixed(2),
                      unit: "quilômetros",
                      icon: Icons.route,
                      iconColor: isHighContrast ? Colors.yellow : AppTheme.secondaryColor,
                      iconBgColor: isHighContrast ? Colors.black : AppTheme.secondaryContainer,
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
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary, 
                      width: 3,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: isHighContrast ? Colors.black : null,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
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
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: !isHighContrast ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label, 
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor, 
                  shape: BoxShape.circle,
                  border: isHighContrast ? Border.all(color: iconColor, width: 1) : null,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                child: Text(
                  value, 
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.w900, 
                    color: isHighContrast ? Colors.yellow : iconColor,
                  ),
                ),
              ),
              Text(
                unit, 
                style: TextStyle(
                  fontSize: 12, 
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isHighContrast ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
