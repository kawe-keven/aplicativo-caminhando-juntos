import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:caminhandojuntos/routes/app_router.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/services/sync/sync_worker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:developer' as developer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  
  // Inicializa o Sincronizador em Segundo Plano
  try {
    await SyncWorker.initialize();
    await SyncWorker.schedulePeriodic();
  } catch (e) {
    developer.log('Erro ao inicializar SyncWorker', error: e);
  }

  runApp(
    const ProviderScope(
      child: CaminhaJuntosApp(),
    ),
  );
}

class CaminhaJuntosApp extends ConsumerWidget {
  const CaminhaJuntosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final accessibility = ref.watch(accessibilityProvider);

    return MaterialApp.router(
      title: 'CaminhaJuntos',
      debugShowCheckedModeBanner: false,
      theme: accessibility.highContrastEnabled 
          ? AppTheme.highContrastTheme 
          : AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        final clampedFontScale = accessibility.fontScale.clamp(1.0, 1.8);

        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(clampedFontScale),
          ),
          child: child ?? const Material(child: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }
}
