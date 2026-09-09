import 'package:google_maps_flutter/google_maps_flutter.dart';

enum TrackingStatus { initial, tracking, paused, finished }

class TrackingState {
  final TrackingStatus status;
  final List<LatLng> path;
  final Duration duration;
  final double distanceKm;
  final int steps;
  final int coinsEarned;
  final LatLng? currentPosition;

  TrackingState({
    this.status = TrackingStatus.initial,
    this.path = const [],
    this.duration = Duration.zero,
    this.distanceKm = 0.0,
    this.steps = 0,
    this.coinsEarned = 0,
    this.currentPosition,
  });

  TrackingState copyWith({
    TrackingStatus? status,
    List<LatLng>? path,
    Duration? duration,
    double? distanceKm,
    int? steps,
    int? coinsEarned,
    LatLng? currentPosition,
  }) {
    return TrackingState(
      status: status ?? this.status,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      distanceKm: distanceKm ?? this.distanceKm,
      steps: steps ?? this.steps,
      coinsEarned: coinsEarned ?? this.coinsEarned,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }
}
