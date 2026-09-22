import 'dart:async';
import 'package:caminhandojuntos/providers/user_provider.dart';
import 'package:caminhandojuntos/providers/tracking_provider.dart';
import 'package:caminhandojuntos/services/sync_service.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Inicialização Concorrente em Paralelo das leituras físicas de disco (I/O).
    // O tempo total passa a ser o da tarefa mais demorada, eliminando o gargalo sequencial.
    await Future.wait([
      ref.read(userProvider.notifier).init(),
      ref.read(trackingProvider.notifier).restoreTracking(),
    ]);
    
    // Dispara a sincronização de background de forma totalmente não-bloqueante (fire-and-forget),
    // liberando o fluxo da UI e a navegação da Splash Screen imediatamente.
    unawaited(ref.read(syncServiceProvider).triggerSync());
    
    if (mounted) {
      final user = ref.read(userProvider);
      
      if (!user.isRegistered) {
        context.go('/welcome');
        return;
      }

      // Tenta restaurar a última rota
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final ultimaRota = prefs.getString('ultima_rota');
      
      final allowedRoutes = ['/dashboard', '/walking', '/store', '/achievements', '/profile', '/accessibility'];
      
      if (ultimaRota != null && allowedRoutes.contains(ultimaRota)) {
        if (ultimaRota == '/walking' && !ref.read(trackingProvider).caminhadaEmAndamento) {
          context.go('/dashboard');
        } else {
          context.go(ultimaRota);
        }
      } else {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Carregando CaminhaJuntos..."),
          ],
        ),
      ),
    );
  }
}
