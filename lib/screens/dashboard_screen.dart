import 'package:caminhandojuntos/providers/dashboard_provider.dart';
import 'package:caminhandojuntos/providers/user_provider.dart';
import 'package:caminhandojuntos/providers/weather_provider.dart';
import 'package:caminhandojuntos/models/user_progress.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/dashboard_stats_grid.dart';
import 'package:caminhandojuntos/widgets/step_progress_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DashboardState dashboardState = ref.watch(dashboardProvider);
    final user = ref.watch(userProvider);
    final weather = ref.watch(weatherProvider);

    return Material(
      color: AppTheme.backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Cabeçalho Customizado
            _buildHeader(context, dashboardState.progress),
            
            Expanded(
              child: CustomScrollView(
                cacheExtent: 500.0,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          "Bom dia, ${user.name.isEmpty ? 'Seu Antônio' : user.name}! ☀️",
                          key: const ValueKey('welcome_text'),
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          key: const ValueKey('weather_row'),
                          children: [
                            const Icon(Icons.sunny, color: AppTheme.secondaryColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "${weather.formattedDate} • ${weather.temperature} - ${weather.isLoading ? 'Buscando clima...' : 'Ótimo para caminhar'}",
                                style: const TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _BalanceCard(
                          key: const ValueKey('balance_card'),
                          coins: dashboardState.progress.coins,
                        ),
                        const SizedBox(height: 24),
                        _ProgressCard(
                          key: const ValueKey('progress_card'),
                          progress: dashboardState.progress,
                        ),
                        const SizedBox(height: 24),
                        const _StartWalkingButton(key: ValueKey('start_button')),
                        const SizedBox(height: 24),
                        const _GroupWalkingCard(key: ValueKey('group_card')),
                        const SizedBox(height: 24),
                        const _HealthTipCard(key: ValueKey('tip_card')),
                        const SizedBox(height: 24),
                        const _EmergencyCard(key: ValueKey('emergency_card')),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProgress progress) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              "assets/images/logo_launcher.png",
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "CaminhaJuntos",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  "Início",
                  style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          // Coins Card Otimizado para não vazar
          Flexible(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFFFDCC3), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: AppTheme.tertiaryColor, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      progress.coins.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.tertiaryColor, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFFFDAD6),
                child: Icon(Icons.sos, color: AppTheme.errorColor, size: 18),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: ClipOval(
              child: Image.asset(
                "assets/images/logo_launcher.png",
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final int coins;
  const _BalanceCard({super.key, required this.coins});

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: Color(0xFFFFDCC3), shape: BoxShape.circle),
                  child: const Icon(Icons.monetization_on, color: AppTheme.tertiaryColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Saldo Acumulado", style: TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis),
                      Text("$coins Moedas", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.tertiaryColor), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => context.push('/store'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.secondaryContainer,
              foregroundColor: AppTheme.secondaryColor,
              minimumSize: const Size(80, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              elevation: 0,
            ),
            child: const Text("Prêmios"),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final UserProgress progress;
  const _ProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          StepProgressWidget(
            steps: progress.steps,
            goalSteps: progress.goalSteps,
            progress: progress.progressPercentage,
          ),
          const SizedBox(height: 24),
          DashboardStatsGrid(
            distance: progress.distanceKm,
            duration: progress.durationMinutes,
            calories: progress.calories,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFFDCC3).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.stars, color: AppTheme.tertiaryContainer, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: "Faltam só "),
                        TextSpan(text: "${progress.remainingSteps} passos", style: const TextStyle(fontWeight: FontWeight.bold)),
                        const TextSpan(text: " para ganhar "),
                        const TextSpan(text: "+50 moedas", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.tertiaryColor)),
                        const TextSpan(text: " hoje! Você consegue!"),
                      ],
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.4),
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

class _StartWalkingButton extends StatefulWidget {
  const _StartWalkingButton({super.key});

  @override
  State<_StartWalkingButton> createState() => _StartWalkingButtonState();
}

class _StartWalkingButtonState extends State<_StartWalkingButton> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isNavigating
          ? null
          : () async {
              setState(() => _isNavigating = true);
              try {
                await context.push('/permission');
              } finally {
                if (mounted) setState(() => _isNavigating = false);
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryContainer,
        minimumSize: const Size(double.infinity, 72),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_run, size: 32),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              "INICIAR CAMINHADA",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupWalkingCard extends StatelessWidget {
  const _GroupWalkingCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Caminhada em Grupo Hoje",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "16:30",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.asset(
                  "assets/images/logo_launcher.png",
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent]),
                  ),
                ),
                const Positioned(
                  bottom: 12,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Praça das Flores • Turma das 16h30", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      Text("7 vizinhos já confirmaram presença!", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    ],
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

class _HealthTipCard extends StatelessWidget {
  const _HealthTipCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppTheme.secondaryContainer, shape: BoxShape.circle),
            child: const Icon(Icons.water_drop, color: AppTheme.secondaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dica de Saúde do Dia", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 4),
                Text("Beba água antes e durante seu passeio! 💧 Levar uma garrafinha garante mais energia.", style: TextStyle(fontSize: 16, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDAD6)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Se houver pouco espaço horizontal, empilha o botão abaixo do texto
          if (constraints.maxWidth < 320) {
            return Column(
              children: [
                _buildContent(),
                const SizedBox(height: 16),
                _buildButton(fullWidth: true),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: _buildContent()),
              const SizedBox(width: 8),
              _buildButton(fullWidth: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
          child: const Icon(Icons.call, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Emergência", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              Text("Apoio imediato", style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton({required bool fullWidth}) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.sos, size: 20),
      label: const Text("Ligar SOS"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
        minimumSize: Size(fullWidth ? double.infinity : 0, 48),
      ),
    );
  }
}
