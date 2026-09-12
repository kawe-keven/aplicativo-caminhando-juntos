import 'package:caminhandojuntos/providers/dashboard_provider.dart';
import 'package:caminhandojuntos/providers/user_provider.dart';
import 'package:caminhandojuntos/providers/weather_provider.dart';
import 'package:caminhandojuntos/models/user_progress.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/dashboard_stats_grid.dart';
import 'package:caminhandojuntos/widgets/step_progress_widget.dart';
import 'package:caminhandojuntos/widgets/speakable_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DashboardState dashboardState = ref.watch(dashboardProvider);
    final user = ref.watch(userProvider);
    final weather = ref.watch(weatherProvider);

    final String welcomeMsg = "Bom dia, ${user.name.isEmpty ? 'Seu Antônio' : user.name}. "
        "Seu saldo atual é de ${dashboardState.progress.coins} moedas. "
        "Hoje você já completou ${dashboardState.progress.steps} passos de sua meta.";

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Speakable(
          announceOnLoad: true,
          text: welcomeMsg,
          child: Column(
            children: [
              // Cabeçalho Customizado
              _buildHeader(context, ref, dashboardState.progress),
              
              Expanded(
                child: CustomScrollView(
                  scrollCacheExtent: const ScrollCacheExtent.pixels(500.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Text(
                            "Bom dia, ${user.name.isEmpty ? 'Seu Antônio' : user.name}! ☀️",
                            key: const ValueKey('welcome_text'),
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            key: const ValueKey('weather_row'),
                            children: [
                              Icon(Icons.sunny, color: Theme.of(context).colorScheme.secondary, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${weather.formattedDate} • ${weather.temperature} - ${weather.isLoading ? 'Buscando clima...' : 'Ótimo para caminhar'}",
                                  style: TextStyle(
                                    fontSize: 16, 
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, UserProgress progress) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: isHighContrast 
            ? const Border(bottom: BorderSide(color: Colors.white, width: 2))
            : null,
        boxShadow: !isHighContrast 
            ? [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
            : null,
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
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Início",
                  style: TextStyle(
                    fontSize: 11, 
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isHighContrast ? Colors.yellow : const Color(0xFFFFDCC3), 
                borderRadius: BorderRadius.circular(20),
                border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.monetization_on, 
                    color: isHighContrast ? Colors.black : AppTheme.tertiaryColor, 
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      progress.coins.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: isHighContrast ? Colors.black : AppTheme.tertiaryColor, 
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _triggerEmergency(context, ref),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: isHighContrast ? Colors.red : const Color(0xFFFFDAD6),
                child: Icon(
                  Icons.sos, 
                  color: isHighContrast ? Colors.white : AppTheme.errorColor, 
                  size: 18,
                ),
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

  void _triggerEmergency(BuildContext context, WidgetRef ref) {
    final user = ref.read(userProvider);
    if (user.emergencyContactPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cadastre um contato de emergência no perfil primeiro."),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      context.go('/profile');
      return;
    }
    
    context.push('/emergency', extra: {
      'name': user.emergencyContactName,
      'phone': user.emergencyContactPhone,
    });
  }
}

class _BalanceCard extends StatelessWidget {
  final int coins;
  const _BalanceCard({super.key, required this.coins});

  @override
  Widget build(BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: !isHighContrast 
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
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
                  decoration: BoxDecoration(
                    color: isHighContrast ? Colors.yellow : const Color(0xFFFFDCC3), 
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.monetization_on, 
                    color: isHighContrast ? Colors.black : AppTheme.tertiaryColor, 
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Saldo Acumulado", 
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isHighContrast ? FontWeight.bold : FontWeight.normal,
                        ), 
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "$coins Moedas", 
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold, 
                          color: isHighContrast ? Colors.yellow : AppTheme.tertiaryColor,
                        ), 
                        overflow: TextOverflow.ellipsis,
                      ),
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
              backgroundColor: isHighContrast ? Colors.white : AppTheme.secondaryContainer,
              foregroundColor: isHighContrast ? Colors.black : AppTheme.secondaryColor,
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
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: !isHighContrast 
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
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
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

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
        backgroundColor: isHighContrast ? Colors.yellow : AppTheme.primaryContainer,
        foregroundColor: isHighContrast ? Colors.black : Colors.white,
        minimumSize: const Size(double.infinity, 72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isHighContrast ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_run, size: 32),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              "INICIAR CAMINHADA",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.w900,
                color: isHighContrast ? Colors.black : Colors.white,
              ),
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
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: !isHighContrast 
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
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
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: isHighContrast ? Colors.yellow : AppTheme.primaryColor,
                ),
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
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, 
                      end: Alignment.topCenter, 
                      colors: [
                        isHighContrast ? Colors.black.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.7), 
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Praça das Flores • Turma das 16h30", 
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 18,
                          backgroundColor: isHighContrast ? Colors.black : Colors.transparent,
                        ),
                      ),
                      Text(
                        "7 vizinhos já confirmaram presença!", 
                        style: TextStyle(
                          color: isHighContrast ? Colors.yellow : Colors.white70, 
                          fontSize: 16,
                          fontWeight: isHighContrast ? FontWeight.bold : FontWeight.normal,
                          backgroundColor: isHighContrast ? Colors.black : Colors.transparent,
                        ),
                      ),
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

class _EmergencyCard extends ConsumerWidget {
  const _EmergencyCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider);

    return Speakable(
      text: "Central de ajuda. Botão para ligar para seu contato seguro em caso de necessidade.",
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isHighContrast ? null : const LinearGradient(
            colors: [Color(0xFFFF8A80), AppTheme.errorColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: isHighContrast ? Colors.red : null,
          borderRadius: BorderRadius.circular(20),
          border: isHighContrast ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: AppTheme.errorColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emergency_share, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "CENTRAL DE AJUDA",
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
                      ),
                      Text(
                        "Precisa de auxílio?",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (user.emergencyContactPhone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Cadastre um contato no perfil primeiro."),
                      backgroundColor: Colors.black,
                    ),
                  );
                  return;
                }
                context.push('/emergency', extra: {
                  'name': user.emergencyContactName,
                  'phone': user.emergencyContactPhone,
                });
              },
              icon: const Icon(Icons.phone_in_talk, size: 28),
              label: const Text("LIGAR PARA CONTATO SEGURO"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.errorColor,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isHighContrast ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
                ),
                elevation: 0,
                textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
