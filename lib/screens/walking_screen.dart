import 'package:caminhandojuntos/providers/tracking_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/widgets/speakable_widget.dart';
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
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    // Requisito: Mover a câmera conforme a posição REAL muda
    ref.listen(trackingProvider, (previous, next) {
      if (next.currentPosition != null) {
        if (previous?.currentPosition != next.currentPosition) {
          _mapController.move(next.currentPosition!, _mapController.camera.zoom);
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary, size: 30),
          onPressed: () => context.pop(),
        ),
        title: Row(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CaminhaJuntos", 
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  "Caminhada Ativa", 
                  style: TextStyle(
                    fontSize: 14, 
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        shape: isHighContrast ? const Border(bottom: BorderSide(color: Colors.white, width: 2)) : null,
      ),
      body: SafeArea(
        child: Speakable(
          announceOnLoad: true,
          text: "Caminhada iniciada! Coletando seus passos e localização. Mantenha o celular com você.",
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildStatusBar(tracking.status, context),
                const SizedBox(height: 16),
                _buildMap(tracking, context),
                const SizedBox(height: 16),
                _buildLiveMetrics(tracking, context),
                const SizedBox(height: 16),
                _buildFeedbackCard(context),
                const SizedBox(height: 16),
                _buildControls(tracking, notifier, context),
                const SizedBox(height: 12),
                if (tracking.status != TrackingStatus.syncing)
                  ElevatedButton.icon(
                    onPressed: () => _showFinishDialog(context, notifier),
                    icon: const Icon(Icons.stop_circle, size: 32),
                    label: const Text("FINALIZAR E VALIDAR"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 72),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isHighContrast ? const BorderSide(color: Colors.white, width: 3) : BorderSide.none,
                      ),
                    ),
                  ),
                if (tracking.status == TrackingStatus.syncing)
                  const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(TrackingStatus status, BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.fiber_manual_record, 
            color: isHighContrast ? Colors.black : const Color(0xFFB1F1C5), 
            size: 12,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status == TrackingStatus.syncing ? "Sincronizando com servidor..." : "Coletando coordenadas GPS...",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary, 
                fontWeight: FontWeight.bold, 
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(TrackingState tracking, BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 3) : null,
        boxShadow: !isHighContrast ? [const BoxShadow(color: Colors.black12, blurRadius: 8)] : null,
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
              tileBuilder: isHighContrast ? (context, tileWidget, tile) {
                return ColorFiltered(
                  colorFilter: const ColorFilter.matrix([
                    -1, 0, 0, 0, 255,
                    0, -1, 0, 0, 255,
                    0, 0, -1, 0, 255,
                    0, 0, 0, 1, 0,
                  ]),
                  child: tileWidget,
                );
              } : null,
            ),
            if (tracking.mapPath.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: tracking.mapPath,
                    color: isHighContrast ? Colors.yellow : AppTheme.primaryColor,
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
                    child: Icon(
                      Icons.directions_walk, 
                      color: isHighContrast ? Colors.cyanAccent : AppTheme.primaryColor, 
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMetrics(TrackingState tracking, BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _MetricCard(
            icon: Icons.timer,
            label: "Tempo",
            value: _formatDuration(tracking.duration),
            subValue: "decorrido",
            isHighContrast: isHighContrast,
          ),
          _MetricCard(
            icon: Icons.gps_fixed,
            label: "Pontos",
            value: tracking.rawPath.length.toString(),
            subValue: "coletados",
            isHighContrast: isHighContrast,
          ),
          _MetricCard(
            icon: Icons.straighten,
            label: "Distância",
            value: "--",
            unit: "km",
            subValue: "aguardando server",
            isHighContrast: isHighContrast,
          ),
          _MetricCard(
            icon: Icons.monetization_on,
            label: "Moedas",
            value: "--",
            unit: "🪙",
            subValue: "aguardando server",
            isHighContrast: isHighContrast,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : const Color(0xFFF1F3FF), 
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.security, 
            color: isHighContrast ? Colors.yellow : AppTheme.primaryColor, 
            size: 30,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Seus dados estão sendo coletados e serão validados pelo servidor ao final.",
              style: TextStyle(
                fontSize: 14, 
                color: isHighContrast ? Colors.white : AppTheme.onSurfaceVariant,
                fontWeight: isHighContrast ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(TrackingState tracking, TrackingNotifier notifier, BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Row(
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
            icon: Icon(tracking.status == TrackingStatus.paused ? Icons.play_circle : Icons.pause_circle, size: 32),
            label: Text(tracking.status == TrackingStatus.paused ? "Retomar" : "Pausar"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isHighContrast ? Colors.black : Colors.white, 
              foregroundColor: isHighContrast ? Colors.white : AppTheme.secondaryColor, 
              minimumSize: const Size(0, 64),
              side: isHighContrast ? const BorderSide(color: Colors.white, width: 2) : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hidrate-se! 💧"))),
            icon: const Icon(Icons.water_drop, size: 32),
            label: const Text("Água"),
            style: ElevatedButton.styleFrom(
              backgroundColor: isHighContrast ? Colors.black : const Color(0xFFCAE6FF), 
              foregroundColor: isHighContrast ? Colors.cyanAccent : AppTheme.secondaryColor, 
              minimumSize: const Size(0, 64),
              side: isHighContrast ? const BorderSide(color: Colors.cyanAccent, width: 2) : null,
            ),
          ),
        ),
      ],
    );
  }

  void _showFinishDialog(BuildContext context, TrackingNotifier notifier) {
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
              await notifier.finishAndSync();
              if (!context.mounted) return;
              context.go('/summary');
            },
            child: const Text("Sim, Sincronizar"),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final String subValue;
  final bool isHighContrast;

  const _MetricCard({
    required this.icon, 
    required this.label, 
    required this.value, 
    this.unit, 
    required this.subValue,
    this.isHighContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighContrast ? Colors.black : Colors.white, 
        borderRadius: BorderRadius.circular(16),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: isHighContrast ? Colors.yellow : null), 
              const SizedBox(width: 4), 
              Expanded(
                child: Text(
                  label, 
                  style: TextStyle(
                    fontSize: 14,
                    color: isHighContrast ? Colors.white : null,
                    fontWeight: isHighContrast ? FontWeight.bold : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Flexible(
                child: Text(
                  value, 
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: isHighContrast ? Colors.yellow : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit != null) Text(unit!, style: TextStyle(fontSize: 14, color: isHighContrast ? Colors.white : null)),
            ],
          ),
          Text(
            subValue, 
            style: TextStyle(
              fontSize: 11, 
              color: isHighContrast ? Colors.white70 : Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
