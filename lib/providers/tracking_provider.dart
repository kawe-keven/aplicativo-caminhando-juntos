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
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    state = state.copyWith(status: TrackingStatus.tracking);

    _startTimer();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Rastreando sua caminhada para o CaminhaJuntos",
          notificationTitle: "Caminhada Ativa",
          enableWakeLock: true,
        ),
      ),
    ).listen(
      (Position position) {
        _updatePosition(position);
      },
      onError: (error) {
        // Handle stream errors (e.g. GPS signal lost)
        state = state.copyWith(status: TrackingStatus.paused);
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
        lastPoint.latitude,
        lastPoint.longitude,
        newPoint.latitude,
        newPoint.longitude,
      ) / 1000; // Convert to km
    }

    final double newDistance = state.distanceKm + addedDistance;
    
    // Mocking steps and coins for simplicity
    final int newSteps = (newDistance * 1500).toInt(); // ~1500 steps per km
    final int newCoins = (newDistance * 10).toInt(); // 1 coin every 100m = 10 coins per km

    state = state.copyWith(
      currentPosition: newPoint,
      path: newPath,
      distanceKm: newDistance,
      steps: newSteps,
      coinsEarned: newCoins,
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

  void pauseTracking() {
    state = state.copyWith(status: TrackingStatus.paused);
  }

  void resumeTracking() {
    state = state.copyWith(status: TrackingStatus.tracking);
  }

  void finishTracking() {
    state = state.copyWith(status: TrackingStatus.finished);
    _positionSubscription?.cancel();
    _timer?.cancel();
  }

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
