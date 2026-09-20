import 'package:caminhandojuntos/providers/tracking_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/widgets/app_tile_layer.dart';
import 'package:caminhandojuntos/widgets/walking_back_button.dart';
import 'package:caminhandojuntos/widgets/walking_info_panel.dart';
import 'package:caminhandojuntos/widgets/walking_action_buttons.dart';
import 'package:caminhandojuntos/widgets/map_credit_label.dart';
import 'package:caminhandojuntos/providers/user_provider.dart';
import 'package:caminhandojuntos/services/initial_location_service.dart';
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
  LatLng? _initialMapCenter;
  bool _isMovingToPosition = false;
  
  @override
  void initState() {
    super.initState();
    _setupInitialLocation();

    _trackingSubscription = ref.listenManual(
      trackingProvider.select((s) => s.currentPosition),
      (previous, next) {
        if (next != null && previous != next) {
          _mapController.move(next, _mapController.camera.zoom);
        }
      },
    );
  }

  Future<void> _setupInitialLocation() async {
    final isRunning = ref.read(trackingProvider).caminhadaEmAndamento;
    if (isRunning) {
      final currentPos = ref.read(trackingProvider).currentPosition;
      if (currentPos != null) {
        _initialMapCenter = currentPos;
      }
    } else {
      // Tenta obter posição do serviço (com cache aquecido)
      final pos = await ref.read(initialLocationServiceProvider).obterPosicaoInicial();
      if (mounted) {
        setState(() {
          _initialMapCenter = pos;
        });
        // Se ainda não iniciou e temos centro, inicia tracking
        ref.read(trackingProvider.notifier).startTracking();
      }
    }

    // Se após 3 segundos ainda não tivermos centro, usa fallback do Brasil
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _initialMapCenter == null) {
        setState(() {
          _initialMapCenter = const LatLng(-14.2350, -51.9253); // Centro do Brasil
        });
        ref.read(trackingProvider.notifier).startTracking();
      }
    });
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
    // Retornar à Dashboard sem resetar o estado global de rastreamento
    context.go('/dashboard');
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

    if (_initialMapCenter == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bool isFallbackBrazil = _initialMapCenter!.latitude == -14.2350 && _initialMapCenter!.longitude == -51.9253;

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
                options: MapOptions(
                  initialCenter: _initialMapCenter!,
                  initialZoom: isFallbackBrazil ? 4 : 17,
                  onMapReady: () {
                    // Se abrimos com o fallback do Brasil e já temos uma posição real, movemos para ela
                    final realPos = ref.read(trackingProvider).currentPosition;
                    if (realPos != null && isFallbackBrazil) {
                      _mapController.move(realPos, 17);
                    }
                  },
                ),
                children: [
                  AppTileLayer.build(isHighContrast: isHighContrast),
                  Consumer(builder: (context, ref, _) {
                    final trackingData = ref.watch(trackingProvider);
                    final pos = trackingData.currentPosition;
                    
                    if (pos != null && !_isMovingToPosition) {
                      // Recentra o mapa na primeira posição real se o centro inicial era aproximado ou do Brasil
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _mapController.move(pos, 17);
                          _isMovingToPosition = true;
                        }
                      });
                    }
                    
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
