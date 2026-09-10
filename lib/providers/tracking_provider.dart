import 'dart:async';
import 'package:caminhandojuntos/models/coordinate_model.dart';
import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier();
});

class TrackingNotifier extends StateNotifier<TrackingState> {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;

  TrackingNotifier() : super(TrackingState());

  Future<void> startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS desativado.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Permissão negada.');
    }

    state = state.copyWith(status: TrackingStatus.tracking);
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
  }

  void _handleNewPosition(Position position) {
    // REGRA FLUTTER: Filtro de GPS Drift (ignorar precisão > 20 metros)
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

    state = state.copyWith(
      currentPosition: LatLng(position.latitude, position.longitude),
      rawPath: [...state.rawPath, newCoordinate],
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == TrackingStatus.tracking) {
        state = state.copyWith(duration: state.duration + const Duration(seconds: 1));
      }
    });
  }

  /// REGRA: Enviar coordenadas para o backend e receber validação
  Future<void> finishAndSync() async {
    if (state.rawPath.isEmpty) {
      state = state.copyWith(status: TrackingStatus.initial);
      return;
    }

    state = state.copyWith(status: TrackingStatus.syncing);
    _positionSubscription?.cancel();
    _timer?.cancel();

    try {
      final payload = {
        'coordinates': state.rawPath.map((c) => c.toJson()).toList(),
        'totalDurationSeconds': state.duration.inSeconds,
      };

      final response = await _mockSyncApi(payload);

      state = state.copyWith(
        status: TrackingStatus.finished,
        validatedDistanceKm: response['distanceKm'],
        validatedCoins: response['coins'],
      );
    } catch (e) {
      AppLogger.e('Erro ao sincronizar com backend', e);
      state = state.copyWith(status: TrackingStatus.paused);
    }
  }

  Future<Map<String, dynamic>> _mockSyncApi(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(seconds: 2));
    return {
      'distanceKm': 1.5,
      'coins': 15,
    };
  }

  void pauseTracking() => state = state.copyWith(status: TrackingStatus.paused);
  void resumeTracking() => state = state.copyWith(status: TrackingStatus.tracking);
  
  void reset() {
    _positionSubscription?.cancel();
    _timer?.cancel();
    state = TrackingState();
  }
}
