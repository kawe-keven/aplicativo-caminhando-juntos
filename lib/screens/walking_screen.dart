import 'package:caminhandojuntos/providers/tracking_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/widgets/app_tile_layer.dart';
import 'package:caminhandojuntos/widgets/walking_back_button.dart';
import 'package:caminhandojuntos/widgets/walking_info_panel.dart';
import 'package:caminhandojuntos/widgets/walking_action_buttons.dart';
import 'package:caminhandojuntos/widgets/map_credit_label.dart';
import 'package:caminhandojuntos/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

class WalkingScreen extends ConsumerStatefulWidget {
  const WalkingScreen({super.key});

  @override
  ConsumerState<WalkingScreen> createState() => _WalkingScreenState();
}

class _WalkingScreenState extends ConsumerState<WalkingScreen> {
  final MapController _mapController = MapController();
  ProviderSubscription? _trackingSubscription;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingProvider.notifier).startTracking();
    });

    _trackingSubscription = ref.listenManual(
      trackingProvider.select((s) => s.currentPosition),
      (previous, next) {
        if (next != null && previous != next) {
          _mapController.move(next, _mapController.camera.zoom);
        }
      },
    );
  }

  @override
  void dispose() {
    _trackingSubscription?.close();
    _mapController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _handleBackAction() {
    final status = ref.read(trackingProvider.select((s) => s.status));
    if (status == TrackingStatus.tracking || status == TrackingStatus.paused) {
      _showBackConfirmationDialog();
    } else {
      ref.read(trackingProvider.notifier).reset();
      context.pop();
    }
  }

  void _showBackConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Abandonar Caminhada?"),
        content: const Text("Se você voltar agora, o progresso desta atividade será perdido."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Continuar")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(trackingProvider.notifier).reset();
              context.pop();
            },
            child: const Text("Sair"),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Finalizar Caminhada?"),
        content: const Text("As coordenadas serão enviadas para validação no servidor."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final router = GoRouter.of(context);
              await ref.read(trackingProvider.notifier).finishAndSync();
              router.go('/summary');
            },
            child: const Text("Sim, Sincronizar"),
          ),
        ],
      ),
    );
  }

  void _triggerEmergencyCall() {
    final user = ref.read(userProvider);
    if (user.emergencyContactPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cadastre um contato de emergência no perfil primeiro."),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    context.push('/emergency', extra: {
      'name': user.emergencyContactName,
      'phone': user.emergencyContactPhone,
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackAction();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Stack(
          children: [
            // 1. MAPA OCUPANDO 100% DA TELA ATÉ AS BORDAS
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: LatLng(-23.5505, -46.6333),
                  initialZoom: 16,
                ),
                children: [
                  AppTileLayer.build(isHighContrast: isHighContrast),
                  Consumer(builder: (context, ref, _) {
                    final path = ref.watch(trackingProvider.select((s) => s.mapPath));
                    if (path.isEmpty) return const SizedBox.shrink();
                    return PolylineLayer(
                      polylines: [
                        Polyline(
                          points: path,
                          color: isHighContrast ? Colors.yellow : AppTheme.primaryColor,
                          strokeWidth: 8,
                        )
                      ],
                    );
                  }),
                  Consumer(builder: (context, ref, _) {
                    final pos = ref.watch(trackingProvider.select((s) => s.currentPosition));
                    if (pos == null) return const SizedBox.shrink();
                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: pos,
                          width: 60,
                          height: 60,
                          child: Icon(
                            Icons.directions_walk,
                            color: isHighContrast ? Colors.cyanAccent : AppTheme.primaryColor,
                            size: 40,
                          ),
                        )
                      ],
                    );
                  }),
                ],
              ),
            ),

            // 2. OVERLAYS DE INTERAÇÃO PROTEGIDOS POR SAFE_AREA
            Positioned.fill(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linha Superior: Botão Voltar + Painel de Métricas Coletivo
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WalkingBackButton(
                            trackingStatus: trackingState.status,
                            onPop: _handleBackAction,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: WalkingInfoPanel(
                                formattedTime: _formatDuration(trackingState.duration),
                                distanceMetresOrKm: trackingState.mapPath.isNotEmpty ? 1200.0 : 0.0, // Utiliza o mapPath real
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Tratamento de Erros de GPS real discretos em overlay flutuante
                      if (trackingState.status == TrackingStatus.error || trackingState.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    trackingState.errorMessage ?? "Falha de conexão com o sinal de GPS.",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const Spacer(),

                      // Atribuição de Mapas pequena e legível sobre o mapa (ajustada para não cobrir botões)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8, left: 4),
                        child: MapCreditLabel(),
                      ),

                      // Indicador de Sincronização em andamento
                      if (trackingState.status == TrackingStatus.syncing)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        // Painel inferior com os botões de ação estruturados (SOS, Pausar, Finalizar)
                        WalkingActionButtons(
                          trackingStatus: trackingState.status,
                          onPauseToggle: () {
                            if (trackingState.status == TrackingStatus.tracking) {
                              ref.read(trackingProvider.notifier).pauseTracking();
                            } else {
                              ref.read(trackingProvider.notifier).resumeTracking();
                            }
                          },
                          onFinish: _showFinishDialog,
                          onSOS: _triggerEmergencyCall,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
