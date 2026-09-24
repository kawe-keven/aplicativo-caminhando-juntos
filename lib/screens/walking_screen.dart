import 'package:caminhandojuntos/config/ui_texts.dart';
import 'package:caminhandojuntos/providers/accessibility_provider.dart';
import 'package:caminhandojuntos/providers/tracking_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/utils/route_utils.dart';
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
  bool _isFollowingUser = true;
  
  @override
  void initState() {
    super.initState();
    _setupInitialLocation();

    _trackingSubscription = ref.listenManual(
      trackingProvider.select((s) => s.currentPosition),
      (previous, next) {
        if (next != null && previous != next && mounted && _isFollowingUser) {
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
      final pos = await ref.read(initialLocationServiceProvider).obterPosicaoInicial();
      if (mounted) {
        setState(() {
          _initialMapCenter = pos;
        });
        ref.read(trackingProvider.notifier).startTracking();
      }
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _initialMapCenter == null) {
        setState(() {
          _initialMapCenter = const LatLng(-14.2350, -51.9253); 
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
    final state = ref.read(trackingProvider);
    
    if (state.status == TrackingStatus.tracking || state.status == TrackingStatus.paused) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Sair da caminhada?"),
          content: const Text("Escolha o que deseja fazer com a atividade atual:"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Continuar caminhando")
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final router = GoRouter.of(context);
                Navigator.pop(context);
                await ref.read(trackingProvider.notifier).discardTracking();
                messenger.showSnackBar(
                  const SnackBar(content: Text("Caminhada descartada."))
                );
                router.go('/dashboard');
              }, 
              child: const Text("Descartar", style: TextStyle(color: Colors.red))
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(trackingProvider.notifier).pauseTracking();
                Navigator.pop(context);
                context.go('/dashboard');
              }, 
              child: const Text("Pausar e Sair")
            ),
          ],
        ),
      );
      return;
    }

    ref.read(trackingProvider.notifier).reset();
    context.go('/dashboard');
  }

  void _showFinishDialog() {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(UiTexts.finishDialogTitle),
        actionsOverflowDirection: VerticalDirection.down,
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              UiTexts.finishDialogNo,
              textAlign: TextAlign.center,
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(context);
              final notifier = ref.read(trackingProvider.notifier);
              
              await notifier.finishAndSync();
              
              final state = ref.read(trackingProvider);
              if (state.errorMessage == "offline_sync_pending") {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(UiTexts.walkFinishedMessage),
                    duration: Duration(seconds: 5),
                  ),
                );
              }
              router.go('/summary');
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              UiTexts.finishDialogYes,
              textAlign: TextAlign.center,
            ),
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
    if (_initialMapCenter == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final bool isFallbackBrazil = _initialMapCenter!.latitude == -14.2350 && _initialMapCenter!.longitude == -51.9253;
    final isHighContrast = ref.watch(accessibilityProvider).highContrastEnabled;

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
            // 1. Mapa Otimizado (Não reconstrói a árvore inteira a cada tick de timer ou GPS)
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialMapCenter!,
                  initialZoom: isFallbackBrazil ? 4 : 17,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onPositionChanged: (camera, hasGesture) {
                    if (hasGesture && _isFollowingUser) {
                      setState(() {
                        _isFollowingUser = false;
                      });
                    }
                  },
                  onMapReady: () {
                    final realPos = ref.read(trackingProvider).currentPosition;
                    if (realPos != null && isFallbackBrazil) {
                      _mapController.move(realPos, 17);
                    }
                  },
                ),
                children: [
                  AppTileLayer.build(isHighContrast: isHighContrast),
                  // Marker Layer Otimizado (Reconstrói apenas quando currentPosition muda)
                  Consumer(
                    key: const ValueKey('marker_layer_consumer'),
                    builder: (context, ref, _) {
                      final pos = ref.watch(trackingProvider.select((s) => s.currentPosition));
                      
                      if (pos != null && !_isMovingToPosition) {
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
                    },
                  ),
                  // Polyline Layer Otimizado (Reconstrói apenas quando mapPath muda)
                  Consumer(
                    key: const ValueKey('polyline_layer_consumer'),
                    builder: (context, ref, _) {
                      final path = ref.watch(trackingProvider.select((s) => s.mapPath));
                      if (path.isEmpty) return const SizedBox.shrink();
                      
                      // Suavização Douglas-Peucker (epsilon = 3m)
                      final smoothedPath = RouteUtils.simplify(path, 3.0);
                      
                      return PolylineLayer(
                        polylines: [
                          Polyline(
                            points: smoothedPath,
                            color: isHighContrast ? Colors.yellow : AppTheme.primaryColor,
                            strokeWidth: 8,
                          )
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // 2. Botão Flutuante de Re-centralizar
            if (!_isFollowingUser)
              Positioned(
                right: 16,
                bottom: 180,
                child: FloatingActionButton.small(
                  heroTag: 'recenter_map',
                  backgroundColor: isHighContrast ? Colors.black : Theme.of(context).colorScheme.primary,
                  foregroundColor: isHighContrast ? Colors.white : Theme.of(context).colorScheme.onPrimary,
                  onPressed: () {
                    setState(() {
                      _isFollowingUser = true;
                    });
                    final currentPos = ref.read(trackingProvider).currentPosition;
                    if (currentPos != null) {
                      _mapController.move(currentPos, 17);
                    }
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),

            // 3. Painel Superior (Isolado com Consumer para atualizar timer sem reconstruir o mapa)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final status = ref.watch(trackingProvider.select((s) => s.status));
                      final duration = ref.watch(trackingProvider.select((s) => s.duration));
                      final hasPath = ref.watch(trackingProvider.select((s) => s.mapPath.isNotEmpty));
                      final errorMessage = ref.watch(trackingProvider.select((s) => s.errorMessage));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WalkingBackButton(
                                trackingStatus: status,
                                onPop: _handleBackAction,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: WalkingInfoPanel(
                                    formattedTime: _formatDuration(duration),
                                    distanceMetresOrKm: hasPath ? 1200.0 : 0.0, 
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (status == TrackingStatus.error || (errorMessage != null && errorMessage != "offline_sync_pending"))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
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
                                        UiTexts.messageForUser(errorMessage),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // 4. Painel Inferior (Isolado com Consumer para status e botões de ação)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final status = ref.watch(trackingProvider.select((s) => s.status));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(bottom: 6, left: 4),
                            child: MapCreditLabel(),
                          ),
                          if (status == TrackingStatus.syncing)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else
                            WalkingActionButtons(
                              trackingStatus: status,
                              onPauseToggle: () {
                                if (status == TrackingStatus.tracking) {
                                  ref.read(trackingProvider.notifier).pauseTracking();
                                } else {
                                  ref.read(trackingProvider.notifier).resumeTracking();
                                }
                              },
                              onFinish: _showFinishDialog,
                              onSOS: _triggerEmergencyCall,
                            ),
                        ],
                      );
                    },
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
