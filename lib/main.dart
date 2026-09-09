import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:caminhandojuntos/routes/app_router.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Garantir que os bindings do Flutter estejam prontos
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar formatação de data para português
  await initializeDateFormatting('pt_BR', null);
  
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
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        // Agora o builder apenas aplica a escala de fonte global
        // O carregamento inicial foi movido para a SplashScreen
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(accessibility.fontScale),
          ),
          child: child!,
        );
      },
    );
  }
}
