import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/widgets/botao_grande_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

/// Tela unificada de permissões. 
/// Garante que Localização (Rastreamento) e Telefone (SOS) sejam solicitados antes do uso.
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingPermission();
  }

  Future<void> _checkExistingPermission() async {
    try {
      final status = await Permission.location.status;
      if (status.isGranted && mounted) {
        context.pushReplacement('/walking');
      }
    } catch (_) {}
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      // Solicita Localização, Telefone e Notificações (Android 13+) simultaneamente
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.phone,
        Permission.notification,
      ].request();

      final locStatus = statuses[Permission.location];
      
      if (locStatus != null && locStatus.isGranted) {
        if (mounted) context.pushReplacement('/walking');
      } else if (locStatus != null && locStatus.isPermanentlyDenied) {
        openAppSettings();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("A localização é obrigatória para iniciar a caminhada.")),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Sua segurança em primeiro lugar",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                "Para registrar sua caminhada e permitir chamadas de emergência rápidas, precisamos de permissão para Localização e Telefone.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                BotaoGrandeWidget(
                  text: "Concordo, permitir",
                  onPressed: _requestPermissions,
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
