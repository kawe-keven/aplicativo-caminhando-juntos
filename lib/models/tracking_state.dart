import 'package:caminhandojuntos/models/coordinate_model.dart';
import 'package:latlong2/latlong.dart';

enum TrackingStatus { initial, tracking, paused, finished, syncing }

class TrackingState {
  final TrackingStatus status;
  final List<CoordinateModel> rawPath;
  final Duration duration;
  final LatLng? currentPosition;
  
  // Dados retornados pelo Backend após o sync
  final double validatedDistanceKm;
  final int validatedCoins;

  TrackingState({
    this.status = TrackingStatus.initial,
    this.rawPath = const [],
    this.duration = Duration.zero,
    this.currentPosition,
    this.validatedDistanceKm = 0.0,
    this.validatedCoins = 0,
  });

  // Auxiliar para o mapa continuar desenhando a linha
  List<LatLng> get mapPath => rawPath.map((c) => LatLng(c.latitude, c.longitude)).toList();

  TrackingState copyWith({
    TrackingStatus? status,
    List<CoordinateModel>? rawPath,
    Duration? duration,
    LatLng? currentPosition,
    double? validatedDistanceKm,
    int? validatedCoins,
  }) {
    return TrackingState(
      status: status ?? this.status,
      rawPath: rawPath ?? this.rawPath,
      duration: duration ?? this.duration,
      currentPosition: currentPosition ?? this.currentPosition,
      validatedDistanceKm: validatedDistanceKm ?? this.validatedDistanceKm,
      validatedCoins: validatedCoins ?? this.validatedCoins,
    );
  }
}
