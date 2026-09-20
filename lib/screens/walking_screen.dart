import 'package:caminhandojuntos/providers/tracking_provider.dart';
import 'package:caminhandojuntos/theme/app_theme.dart';
import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/widgets/speakable_widget.dart';
import 'package:caminhandojuntos/widgets/compass_arrow.dart';
import 'package:caminhandojuntos/widgets/app_tile_layer.dart';
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

    // REGRA: Escuta manual para evitar rebuilds e garantir MapController pronto
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
    // REGRA: Limpeza obrigatória de recursos nativos e subscriptions
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

  @override
  Widget build(BuildContext context) {
    final trackingStatus = ref.watch(trackingProvider.select((s) => s.status));
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary, size: 30),
          onPressed: () {
            // REGRA: Resetar rastreamento ao sair da tela
            ref.read(trackingProvider.notifier).reset();
            context.pop();
          },
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
          text: "Caminhada iniciada! Coletando seus passos e localização.",
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildStatusBar(trackingStatus, context),
                const SizedBox(height: 16),
                _buildMap(context),
                const SizedBox(height: 16),
                _buildLiveMetrics(context),
                const SizedBox(height: 16),
                _buildFeedbackCard(context),
                const SizedBox(height: 16),
                _buildControls(trackingStatus, context),
                const SizedBox(height: 12),
                if (trackingStatus != TrackingStatus.syncing)
                  ElevatedButton.icon(
                    onPressed: () => _showFinishDialog(context),
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
                if (trackingStatus == TrackingStatus.syncing)
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
    String statusText = status == TrackingStatus.syncing ? "Sincronizando..." : "Coletando GPS...";
    if (status == TrackingStatus.error) statusText = "Erro no rastreamento";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: status == TrackingStatus.error ? Colors.red : Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
        border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Row(
        children: [
          Icon(Icons.fiber_manual_record, color: isHighContrast ? Colors.black : const Color(0xFFB1F1C5), size: 12),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(BuildContext context) {
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
          options: const MapOptions(
            initialCenter: LatLng(-23.5505, -46.6333),
            initialZoom: 16,
          ),
          children: [
            AppTileLayer.build(isHighContrast: isHighContrast),
            RichAttributionWidget(
              attributions: AppTileLayer.getAttributions(context),
            ),
            // REGRA: Isolar camadas para reduzir rebuilds
            Consumer(builder: (context, ref, _) {
              final path = ref.watch(trackingProvider.select((s) => s.mapPath));
              if (path.isEmpty) return const SizedBox.shrink();
              return PolylineLayer(
                polylines: [Polyline(points: path, color: isHighContrast ? Colors.yellow : AppTheme.primaryColor, strokeWidth: 8)],
              );
            }),
            Consumer(builder: (context, ref, _) {
              final pos = ref.watch(trackingProvider.select((s) => s.currentPosition));
              if (pos == null) return const SizedBox.shrink();
              return MarkerLayer(
                markers: [Marker(point: pos, width: 60, height: 60, child: Icon(Icons.directions_walk, color: isHighContrast ? Colors.cyanAccent : AppTheme.primaryColor, size: 40))],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMetrics(BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          Consumer(builder: (context, ref, _) {
            final duration = ref.watch(trackingProvider.select((s) => s.duration));
            return _MetricCard(icon: Icons.timer, label: "Tempo", value: _formatDuration(duration), subValue: "decorrido", isHighContrast: isHighContrast);
          }),
          _MetricCard(iconWidget: const CompassArrow(size: 20), label: "Direção", value: "BÚSSOLA", subValue: "orientação", isHighContrast: isHighContrast),
          const _MetricCard(icon: Icons.straighten, label: "Distância", value: "--", unit: "km", subValue: "aguardando server", isHighContrast: false),
          const _MetricCard(icon: Icons.monetization_on, label: "Moedas", value: "--", unit: "🪙", subValue: "aguardando server", isHighContrast: false),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;
    final error = ref.watch(trackingProvider.select((s) => s.errorMessage));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: error != null ? Colors.red.withValues(alpha: 0.1) : (isHighContrast ? Colors.black : const Color(0xFFF1F3FF)), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: error != null ? Colors.red : (isHighContrast ? Colors.white : Colors.transparent), width: 2),
      ),
      child: Row(
        children: [
          Icon(error != null ? Icons.error_outline : Icons.security, color: error != null ? Colors.red : (isHighContrast ? Colors.yellow : AppTheme.primaryColor), size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error ?? "Seus dados estão sendo coletados e serão validados pelo servidor ao final.",
              style: TextStyle(fontSize: 14, color: error != null ? Colors.red : (isHighContrast ? Colors.white : AppTheme.onSurfaceVariant), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(TrackingStatus status, BuildContext context) {
    final isHighContrast = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(trackingProvider.notifier);

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => status == TrackingStatus.tracking ? notifier.pauseTracking() : notifier.resumeTracking(),
            icon: Icon(status == TrackingStatus.paused ? Icons.play_circle : Icons.pause_circle, size: 32),
            label: Text(status == TrackingStatus.paused ? "Retomar" : "Pausar"),
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

  void _showFinishDialog(BuildContext context) {
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
              await ref.read(trackingProvider.notifier).finishAndSync();
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
  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final String value;
  final String? unit;
  final String subValue;
  final bool isHighContrast;

  const _MetricCard({
    this.icon, 
    this.iconWidget,
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
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget ?? Icon(icon, size: 26, color: isHighContrast ? Colors.yellow : null),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1.1, color: isHighContrast ? Colors.white : null),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: isHighContrast ? Colors.yellow : Colors.blueAccent, fontWeight: FontWeight.w900),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (subValue.isNotEmpty && !isHighContrast)
            Text(subValue, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
