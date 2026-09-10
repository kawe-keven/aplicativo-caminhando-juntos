import 'package:cached_network_image/cached_network_image.dart';
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
import 'package:shimmer/shimmer.dart';

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
              child: ListView(
                cacheExtent: 500.0,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Text(
                    "Bom dia, ${user.name.isEmpty ? 'Seu Antônio' : user.name}! ☀️",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 4),
                  Row(
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
                  _BalanceCard(coins: dashboardState.progress.coins),
                  const SizedBox(height: 24),
                  _ProgressCard(progress: dashboardState.progress),
                  const SizedBox(height: 24),
                  const _StartWalkingButton(),
                  const SizedBox(height: 24),
                  const _GroupWalkingCard(),
                  const SizedBox(height: 24),
                  const _HealthTipCard(),
                  const SizedBox(height: 24),
                  const _EmergencyCard(),
                  const SizedBox(height: 40),
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
      color: Colors.white,
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              "assets/images/logo.png",
              width: 32,
              height: 32,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "CaminhaJuntos",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  "Início",
                  style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFFFDCC3), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: AppTheme.tertiaryColor, size: 20),
                const SizedBox(width: 4),
                Text(
                  progress.coins.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.tertiaryColor, fontSize: 16),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFFDAD6),
              child: Icon(Icons.sos, color: AppTheme.errorColor, size: 20),
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuB4bBrCH-K87v2E0POR41wB46ns8x2X6PU040ygG7FPnO7VunknowdfRCSvh3gZfDi4yG-r95RXjQ4OcoiYlKrwRUe7-tJlxSl71HmuQS5R2BF21Oylk9xG0_ZaLWyUaLCCrXt64doojktc4Hg1-phxjr9K8AnEjPpa-mNWRtb5ZHmA82g0B2KuDaOL-m7ic5UZtuFVa-Q8GfUSpklQ6_X9eSM9I4aUdbDEE-ppAMQFN8yi7B_wxt-5",
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  memCacheWidth: 72,
                  placeholder: (context, url) => Container(color: Colors.grey[300]),
                  errorWidget: (context, url, error) => const CircleAvatar(backgroundColor: AppTheme.secondaryColor, child: Icon(Icons.person, color: Colors.white, size: 20)),
                ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: Color(0xFFFFDCC3), shape: BoxShape.circle),
                  child: const Icon(Icons.monetization_on, color: AppTheme.tertiaryColor, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Saldo Acumulado", style: TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis),
                      Text("$coins Moedas", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.tertiaryColor), overflow: TextOverflow.ellipsis),
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
              minimumSize: const Size(100, 48),
              elevation: 0,
            ),
            child: const Text("Ver Prêmios"),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final UserProgress progress;
  const _ProgressCard({required this.progress});

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
                const Icon(Icons.stars, color: AppTheme.tertiaryContainer, size: 30),
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
  const _StartWalkingButton();

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
  const _GroupWalkingCard();
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
                CachedNetworkImage(
                  imageUrl: "https://lh3.googleusercontent.com/aida-public/AB6AXuDfer8iCyb76m1itiaMW06vXG91fGyue40VbMvUs8aOGMFtg5unt9Usr895JK_S9gUyGFblawH161wqqQ_ultpvllSwh2whPGTM_0sWqKDltmOYCRP44qj2deRdhwiRIaYAQ8gi60rdMtz9b-uaVU7Nwi3bhbqoIDvVWUdBSu4JXXmNsEmZ4fi1PBPYAAIW7gJ-fcKbll7lMa29yejJoHPL2skGmc05i5_0VSsAl2YUjnFMAk18vytj",
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  memCacheWidth: 600,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(height: 160, color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 160,
                    color: Colors.grey[300],
                    child: const Icon(Icons.park, size: 40, color: Colors.grey),
                  ),
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
  const _HealthTipCard();
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
  const _EmergencyCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFDAD6)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
            child: const Icon(Icons.call, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ajuda & Emergência", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text("Contato de apoio imediato", style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.sos, size: 20),
            label: const Text("Ligar SOS"),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
}
