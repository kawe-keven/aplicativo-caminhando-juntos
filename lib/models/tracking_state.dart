import 'package:caminhandojuntos/models/coordinate_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Status do rastreamento tipado para tratamento de erros e estados da UI.
enum TrackingStatus { initial, tracking, paused, finished, syncing, error }

class TrackingState {
  final String? caminhadaId;
  final TrackingStatus status;
  final List<CoordinateModel> rawPath;
  final List<LatLng> mapPath; // Pontos simplificados para visualização
  final Duration duration;
  final LatLng? currentPosition;
  
  // Dados retornados pelo Backend após o sync
  final double validatedDistanceKm;
  final int validatedCoins;

  // Mensagem de erro amigável para o usuário idoso
  final String? errorMessage;

  TrackingState({
    this.caminhadaId,
    this.status = TrackingStatus.initial,
    this.rawPath = const [],
    this.mapPath = const [],
    this.duration = Duration.zero,
    this.currentPosition,
    this.validatedDistanceKm = 0.0,
    this.validatedCoins = 0,
    this.errorMessage,
  });

  TrackingState copyWith({
    String? caminhadaId,
    TrackingStatus? status,
    List<CoordinateModel>? rawPath,
    List<LatLng>? mapPath,
    Duration? duration,
    LatLng? currentPosition,
    double? validatedDistanceKm,
    int? validatedCoins,
    String? errorMessage,
  }) {
    return TrackingState(
      caminhadaId: caminhadaId ?? this.caminhadaId,
      status: status ?? this.status,
      rawPath: rawPath ?? this.rawPath,
      mapPath: mapPath ?? this.mapPath,
      duration: duration ?? this.duration,
      currentPosition: currentPosition ?? this.currentPosition,
      validatedDistanceKm: validatedDistanceKm ?? this.validatedDistanceKm,
      validatedCoins: validatedCoins ?? this.validatedCoins,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get caminhadaEmAndamento =>
      status == TrackingStatus.tracking ||
      status == TrackingStatus.paused ||
      status == TrackingStatus.syncing ||
      status == TrackingStatus.error;

  double get totalDistanceMeters {
    if (mapPath.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 0; i < mapPath.length - 1; i++) {
      total += Geolocator.distanceBetween(
        mapPath[i].latitude,
        mapPath[i].longitude,
        mapPath[i + 1].latitude,
        mapPath[i + 1].longitude,
      );
    }
    return total;
  }
}
