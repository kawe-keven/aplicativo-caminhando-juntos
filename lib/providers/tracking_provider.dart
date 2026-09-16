import 'dart:async';
import 'package:caminhandojuntos/models/coordinate_model.dart';
import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/services/caminhada_service.dart';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

final caminhadaServiceProvider = Provider((ref) => CaminhadaService());

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  final service = ref.watch(caminhadaServiceProvider);
  return TrackingNotifier(service);
});

class TrackingNotifier extends StateNotifier<TrackingState> {
  final CaminhadaService _service;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;

  TrackingNotifier(this._service) : super(TrackingState());

  Future<void> startTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(status: TrackingStatus.error, errorMessage: 'GPS desativado. Por favor, ligue a localização.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(status: TrackingStatus.error, errorMessage: 'Permissão de localização negada.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(status: TrackingStatus.error, errorMessage: 'Permissão negada permanentemente. Ajuste nas configurações.');
        return;
      }

      state = state.copyWith(status: TrackingStatus.tracking, errorMessage: null);
      _startTimer();

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) {
        if (state.status == TrackingStatus.tracking) {
          _handleNewPosition(position);
        }
      });
    } catch (e) {
      AppLogger.e('Erro ao iniciar rastreamento', e);
      state = state.copyWith(status: TrackingStatus.error, errorMessage: 'Erro inesperado ao iniciar GPS.');
    }
  }

  void _handleNewPosition(Position position) {
    if (position.accuracy > 20) {
      AppLogger.d('GPS Drift detectado: precisão de ${position.accuracy}m. Ponto ignorado.');
      return;
    }

    final newCoordinate = CoordinateModel(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      accuracy: position.accuracy,
    );

    // REGRA: rawPath armazena todos os pontos para validação no backend
    final updatedRawPath = [...state.rawPath, newCoordinate];
    
    // REGRA: mapPath (visual) limitado para evitar lentidão no desenho do mapa
    // Adicionamos apenas se houver uma distância mínima de 10m do último ponto visual
    List<LatLng> updatedMapPath = state.mapPath;
    final newPoint = LatLng(position.latitude, position.longitude);
    
    if (state.mapPath.isEmpty) {
      updatedMapPath = [newPoint];
    } else {
      final lastPoint = state.mapPath.last;
      final distance = Geolocator.distanceBetween(
        lastPoint.latitude, lastPoint.longitude,
        newPoint.latitude, newPoint.longitude,
      );
      if (distance > 10) {
        updatedMapPath = [...state.mapPath, newPoint];
      }
    }

    state = state.copyWith(
      currentPosition: newPoint,
      rawPath: updatedRawPath,
      mapPath: updatedMapPath,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(duration: state.duration + const Duration(seconds: 1));
    });
  }

  Future<void> finishAndSync() async {
    if (state.status == TrackingStatus.syncing) return; // Guard contra duplo clique

    if (state.rawPath.isEmpty) {
      state = state.copyWith(status: TrackingStatus.initial);
      return;
    }

    state = state.copyWith(status: TrackingStatus.syncing);
    _stopAllActions();

    try {
      final payload = {
        'coordinates': state.rawPath.map((c) => c.toJson()).toList(),
        'totalDurationSeconds': state.duration.inSeconds,
      };

      final response = await _service.syncCaminhada(payload);

      state = state.copyWith(
        status: TrackingStatus.finished,
        validatedDistanceKm: response['distanceKm'],
        validatedCoins: response['coinsEarned'],
      );
    } catch (e) {
      AppLogger.e('Erro ao sincronizar com backend', e);
      state = state.copyWith(status: TrackingStatus.error, errorMessage: 'Falha ao salvar caminhada no servidor.');
    }
  }

  void pauseTracking() {
    _timer?.cancel();
    state = state.copyWith(status: TrackingStatus.paused);
  }

  void resumeTracking() {
    _startTimer();
    state = state.copyWith(status: TrackingStatus.tracking);
  }

  void _stopAllActions() {
    _positionSubscription?.cancel();
    _timer?.cancel();
  }
  
  void reset() {
    _stopAllActions();
    state = TrackingState();
  }

  @override
  void dispose() {
    _stopAllActions();
    super.dispose();
  }
}
