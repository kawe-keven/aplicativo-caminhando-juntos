import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/botao_grande_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Precisamos ver seu caminho",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Text(
                "Para contar seus passos corretamente e garantir sua segurança durante a caminhada, precisamos acessar sua localização.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              BotaoGrandeWidget(
                text: "Entendi, permitir",
                onPressed: () async {
                  final status = await Permission.location.request();
                  if (status.isGranted) {
                    if (context.mounted) context.pushReplacement('/walking');
                  } else if (status.isPermanentlyDenied) {
                    openAppSettings();
                  }
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text(
                  "Agora não",
                  style: TextStyle(fontSize: 18, color: AppTheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
