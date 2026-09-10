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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Status Bar
              _buildStatusBar(tracking.status),

              const SizedBox(height: 16),

              // Map
              _buildMap(tracking),

              const SizedBox(height: 16),

              // Metrics Grid (Nota: Moedas e Distância removidas daqui se não houver cálculo local)
              // No entanto, para UX, o prompt diz: "Remova QUALQUER código... que some moedas ou calcule... O app deve apenas exibir o resultado que o backend devolver."
              // Isso implica que durante a caminhada os campos ficam vazios ou mostram "--".
              _buildLiveMetrics(tracking),

              const SizedBox(height: 16),

              // Feedback
              _buildFeedbackCard(),

              const SizedBox(height: 16),

              // Controls
              _buildControls(tracking, notifier),

              const SizedBox(height: 12),

              if (tracking.status != TrackingStatus.syncing)
                ElevatedButton.icon(
                  onPressed: () => _showFinishDialog(context, notifier),
                  icon: const Icon(Icons.stop_circle, size: 32),
                  label: const Text("FINALIZAR E VALIDAR"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 72),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              if (tracking.status == TrackingStatus.syncing)
                const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(TrackingStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, color: Color(0xFFB1F1C5), size: 12),
          const SizedBox(width: 8),
          Text(
            status == TrackingStatus.syncing ? "Sincronizando com servidor..." : "Coletando coordenadas GPS...",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(TrackingState tracking) {
    return Container(
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
            if (tracking.mapPath.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: tracking.mapPath,
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
                    child: const Icon(Icons.directions_walk, color: AppTheme.primaryColor, size: 40),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMetrics(TrackingState tracking) {
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
          ),
          _MetricCard(
            icon: Icons.gps_fixed,
            label: "Pontos",
            value: tracking.rawPath.length.toString(),
            subValue: "coletados",
          ),
          const _MetricCard(
            icon: Icons.straighten,
            label: "Distância",
            value: "--",
            unit: "km",
            subValue: "aguardando server",
          ),
          const _MetricCard(
            icon: Icons.monetization_on,
            label: "Moedas",
            value: "--",
            unit: "🪙",
            subValue: "aguardando server",
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF1F3FF), borderRadius: BorderRadius.circular(16)),
      child: const Row(
        children: [
          Icon(Icons.security, color: AppTheme.primaryColor, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Seus dados estão sendo coletados e serão validados pelo servidor ao final.",
              style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(TrackingState tracking, TrackingNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => tracking.status == TrackingStatus.tracking ? notifier.pauseTracking() : notifier.resumeTracking(),
            icon: Icon(tracking.status == TrackingStatus.paused ? Icons.play_circle : Icons.pause_circle, size: 32),
            label: Text(tracking.status == TrackingStatus.paused ? "Retomar" : "Pausar"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.secondaryColor, minimumSize: const Size(0, 64)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hidrate-se! 💧"))),
            icon: const Icon(Icons.water_drop, size: 32),
            label: const Text("Água"),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFCAE6FF), foregroundColor: AppTheme.secondaryColor, minimumSize: const Size(0, 64)),
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
              if (mounted) context.go('/summary');
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

  const _MetricCard({required this.icon, required this.label, required this.value, this.unit, required this.subValue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [Icon(icon, size: 20), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 14))]),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              if (unit != null) Text(unit!, style: const TextStyle(fontSize: 14)),
            ],
          ),
          Text(subValue, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
