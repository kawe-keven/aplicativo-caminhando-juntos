import 'package:caminhandojuntos/providers/tracking_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/models/tracking_state.dart';
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
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(trackingProvider.notifier).startTracking();
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingProvider);
    final notifier = ref.read(trackingProvider.notifier);

    // Requisito: Mover a câmera conforme a posição REAL muda
    ref.listen(trackingProvider, (previous, next) {
      if (next.currentPosition != null) {
        if (previous?.currentPosition != next.currentPosition) {
          _mapController.move(next.currentPosition!, _mapController.camera.zoom);
        }
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor, size: 30),
          onPressed: () => context.pop(),
        ),
        title: Row(
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("CaminhaJuntos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                Text("Caminhada Ativa", style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const CircleAvatar(
              backgroundColor: Color(0xFFFFDAD6),
              child: Icon(Icons.sos, color: AppTheme.errorColor, size: 24),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Status Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.fiber_manual_record, color: Color(0xFFB1F1C5), size: 12),
                        SizedBox(width: 8),
                        Text(
                          "Gravando sua caminhada ao vivo",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.emergency, size: 20),
                    label: const Text("Pedir Ajuda"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Map (OpenStreetMap via flutter_map)
              Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: tracking.currentPosition ?? const LatLng(-23.5505, -46.6333),
                      initialZoom: 16,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.caminhandojuntos',
                      ),
                      if (tracking.path.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: tracking.path,
                              color: AppTheme.primaryColor,
                              strokeWidth: 8,
                            ),
                          ],
                        ),
                      if (tracking.currentPosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: tracking.currentPosition!,
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.directions_walk,
                                color: AppTheme.primaryColor,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Metrics Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _MetricCard(
                      icon: Icons.directions_walk,
                      iconColor: AppTheme.primaryColor,
                      label: "Passos",
                      value: tracking.steps.toString(),
                      subValue: "Meta: 5.000",
                    ),
                    _MetricCard(
                      icon: Icons.straighten,
                      iconColor: AppTheme.secondaryColor,
                      label: "Distância",
                      value: tracking.distanceKm.toStringAsFixed(1),
                      unit: "km",
                      subValue: "Ritmo confortável",
                    ),
                    _MetricCard(
                      icon: Icons.timer,
                      iconColor: AppTheme.primaryContainer,
                      label: "Tempo",
                      value: _formatDuration(tracking.duration),
                      subValue: "minutos ativos",
                    ),
                    _MetricCard(
                      icon: Icons.monetization_on,
                      iconColor: AppTheme.tertiaryColor,
                      label: "Moedas",
                      value: "+${tracking.coinsEarned}",
                      unit: "🪙",
                      backgroundColor: const Color(0xFFFFDCC3),
                      subValue: "Caminhada premiada",
                    ),
                  ],
                ),
              ),

              // Feedback message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: Color(0xFFB1F1C5), shape: BoxShape.circle),
                      child: const Icon(Icons.sentiment_very_satisfied, color: AppTheme.primaryColor, size: 30),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Excelente ritmo!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor)),
                          Text("Você está indo muito bem hoje.", style: TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Controls
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (tracking.status == TrackingStatus.tracking) {
                          notifier.pauseTracking();
                        } else {
                          notifier.resumeTracking();
                        }
                      },
                      icon: Icon(
                        tracking.status == TrackingStatus.paused ? Icons.play_circle : Icons.pause_circle,
                        size: 32,
                      ),
                      label: Text(tracking.status == TrackingStatus.paused ? "Retomar" : "Pausar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.secondaryColor,
                        minimumSize: const Size(0, 64),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Lembre-se de hidratar o corpo! 💧")),
                        );
                      },
                      icon: const Icon(Icons.water_drop, size: 32),
                      label: const Text("Beber Água"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCAE6FF),
                        foregroundColor: AppTheme.secondaryColor,
                        minimumSize: const Size(0, 64),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: () => _showFinishDialog(context, notifier, tracking.coinsEarned),
                icon: const Icon(Icons.stop_circle, size: 32),
                label: const Text("FINALIZAR CAMINHADA"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 72),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinishDialog(BuildContext context, TrackingNotifier notifier, int coins) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 64),
            SizedBox(height: 16),
            Text("Deseja terminar o treino?", textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          "Sua caminhada será salva e você receberá suas $coins moedas.",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowButtonSpacing: 12,
        actions: [
          ElevatedButton(
            onPressed: () {
              notifier.finishTracking();
              Navigator.pop(context); // Close dialog
              context.go('/summary'); // Go to summary
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text("Sim, Finalizar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Continuar Caminhando", style: TextStyle(fontSize: 18, color: AppTheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? unit;
  final String subValue;
  final Color backgroundColor;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.unit,
    required this.subValue,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: backgroundColor == Colors.white 
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.onSurface)),
              if (unit != null) ...[
                const SizedBox(width: 4),
                const Text("🪙", style: TextStyle(fontSize: 18)),
              ],
            ],
          ),
          Text(subValue, style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
