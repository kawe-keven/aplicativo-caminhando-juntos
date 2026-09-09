import 'dart:async';
import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier();
});

class TrackingNotifier extends StateNotifier<TrackingState> {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;

  TrackingNotifier() : super(TrackingState());

  Future<void> startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    state = state.copyWith(status: TrackingStatus.tracking);
    _startTimer();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      (Position position) {
        _updatePosition(position);
      },
    );
  }

  void _updatePosition(Position position) {
    if (state.status != TrackingStatus.tracking) return;

    final newPoint = LatLng(position.latitude, position.longitude);
    final List<LatLng> newPath = List.from(state.path)..add(newPoint);
    
    double addedDistance = 0;
    if (state.path.isNotEmpty) {
      final lastPoint = state.path.last;
      addedDistance = Geolocator.distanceBetween(
        lastPoint.latitude, lastPoint.longitude,
        newPoint.latitude, newPoint.longitude,
      ) / 1000;
    }

    final double newDistance = state.distanceKm + addedDistance;
    
    // REQUISITO DE SEGURANÇA (Escopo 2): 
    // O App Flutter calcula apenas a distância estimada para feedback visual.
    // O valor FINAL das moedas será calculado pelo Backend Java ao receber os dados brutos.
    state = state.copyWith(
      currentPosition: newPoint,
      path: newPath,
      distanceKm: newDistance,
      // Moedas mostradas em tempo real são APENAS UMA ESTIMATIVA.
      coinsEarned: (newDistance * 10).toInt(), 
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

  void finishTracking() {
    state = state.copyWith(status: TrackingStatus.finished);
    _positionSubscription?.cancel();
    _timer?.cancel();

    // AÇÃO NECESSÁRIA NO BACKEND:
    // Chamar endpoint POST /activity/sync enviando {distanceKm, durationSeconds, steps}.
    // O Java validará se a distância é compatível com o tempo (prevenindo spoofing de GPS) 
    // e retornará o saldo REAL de moedas.
  }

  void pauseTracking() => state = state.copyWith(status: TrackingStatus.paused);
  void resumeTracking() => state = state.copyWith(status: TrackingStatus.tracking);

  void reset() {
    _positionSubscription?.cancel();
    _timer?.cancel();
    state = TrackingState();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
