import 'dart:async';
import 'package:caminhandojuntos/models/coordinate_model.dart';
import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/services/caminhada_api_client.dart';
import 'package:caminhandojuntos/services/caminhada_local_repository.dart';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:caminhandojuntos/services/local_db.dart';
import 'package:caminhandojuntos/services/sync_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

final caminhadaLocalRepositoryProvider = Provider((ref) => CaminhadaLocalRepository());
final caminhadaApiClientProvider = Provider((ref) => CaminhadaApiClient());

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  final localRepo = ref.watch(caminhadaLocalRepositoryProvider);
  final syncService = ref.watch(syncServiceProvider);
  final apiClient = ref.watch(caminhadaApiClientProvider);
  return TrackingNotifier(localRepo, syncService, apiClient);
});

class TrackingNotifier extends StateNotifier<TrackingState> with WidgetsBindingObserver {
  final CaminhadaLocalRepository _localRepo;
  final SyncService _syncService;
  final CaminhadaApiClient _apiClient;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  
  final List<Map<String, dynamic>> _buffer = [];
  DateTime _lastSave = DateTime.now();

  TrackingNotifier(this._localRepo, this._syncService, this._apiClient) : super(TrackingState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _flushBuffer();
      _saveCurrentRoute();
    } else if (state == AppLifecycleState.resumed) {
      _syncService.triggerSync();
    }
  }

  Future<void> _saveCurrentRoute() async {
    // Note: In a real app, this should be triggered by GoRouter listener or similar.
    // For now, we manually save the 'walking' route if we are in it.
    if (state.caminhadaEmAndamento) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ultima_rota', '/walking');
    }
  }

  Future<void> restoreTracking() async {
    final res = await _localRepo.obterEmAndamento();
    if (res.isSuccess && res.data != null) {
      final data = res.data!;
      final id = data['id'] as String;
      
      // Auto-finalize if > 24h
      final atualizadaEm = data['atualizada_em_ms'] as int;
      if (DateTime.now().millisecondsSinceEpoch - atualizadaEm > 24 * 60 * 60 * 1000) {
        await _localRepo.finalizar(id);
        _syncService.triggerSync();
        return;
      }

      final pontosRes = await _localRepo.listarPontos(id);
      final List<CoordinateModel> rawPath = [];
      final List<LatLng> mapPath = [];
      
      if (pontosRes.isSuccess && pontosRes.data != null) {
        for (var p in pontosRes.data!) {
          final coord = CoordinateModel.fromMap(p);
          rawPath.add(coord);
          
          final latLng = LatLng(coord.latitude, coord.longitude);
          if (mapPath.isEmpty) {
            mapPath.add(latLng);
          } else {
            final last = mapPath.last;
            if (Geolocator.distanceBetween(last.latitude, last.longitude, latLng.latitude, latLng.longitude) > 10) {
              mapPath.add(latLng);
            }
          }
        }
      }

      state = state.copyWith(
        caminhadaId: id,
        status: TrackingStatus.paused,
        rawPath: rawPath,
        mapPath: mapPath,
        duration: Duration(milliseconds: data['tempo_ativo_ms'] as int),
        currentPosition: mapPath.isNotEmpty ? mapPath.last : null,
      );
    }
  }

  Future<void> startTracking() async {
    try {
      if (state.caminhadaId != null && state.status != TrackingStatus.initial) {
        resumeTracking();
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(status: TrackingStatus.error, errorMessage: 'gps_disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(status: TrackingStatus.error, errorMessage: 'permission_denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(status: TrackingStatus.error, errorMessage: 'permission_denied_permanent');
        return;
      }

      final id = UuidUtils.generateV4();
      final res = await _localRepo.criarEmAndamento(id);
      
      state = state.copyWith(
        caminhadaId: res.isSuccess ? id : null,
        status: TrackingStatus.tracking, 
        errorMessage: null,
        duration: Duration.zero,
        rawPath: [],
        mapPath: [],
      );

      if (!res.isSuccess) {
        AppLogger.e('Falha ao iniciar banco local, rastreando apenas em memória', res.error);
        // Não notificamos erro impeditivo se pudermos seguir em memória
      }
      
      _startTimer();
      _startGpsStream();

    } catch (e) {
      AppLogger.e('Erro ao iniciar rastreamento', e);
      state = state.copyWith(status: TrackingStatus.error, errorMessage: 'unexpected_gps_error');
    }
  }

  void _startGpsStream() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Caminhando Juntos",
          notificationText: "Caminhada em andamento",
          notificationIcon: AndroidResource(name: 'launcher_icon'),
          enableWakeLock: true,
        ),
      ),
    ).listen((Position position) {
      if (state.status == TrackingStatus.tracking) {
        _handleNewPosition(position);
      }
    });
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

    _buffer.add({
      'lat': position.latitude,
      'lng': position.longitude,
      'precisao': position.accuracy,
      'timestamp_ms': position.timestamp.millisecondsSinceEpoch,
    });

    if (_buffer.length >= 5 || DateTime.now().difference(_lastSave).inSeconds >= 10) {
      _flushBuffer();
    }

    final updatedRawPath = [...state.rawPath, newCoordinate];
    
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

  Future<void> _flushBuffer() async {
    if (_buffer.isEmpty || state.caminhadaId == null) return;
    
    final pointsToSave = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();
    _lastSave = DateTime.now();

    final id = state.caminhadaId!;
    await _localRepo.gravarPontos(id, pointsToSave);
    await _localRepo.atualizarProgresso(id, state.duration.inMilliseconds, state.status == TrackingStatus.paused);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(duration: state.duration + const Duration(seconds: 1));
    });
  }

  Future<void> finishAndSync() async {
    if (state.status == TrackingStatus.syncing) return;
    
    _stopAllActions();
    final id = state.caminhadaId;

    if (id != null) {
      await _flushBuffer();
      await _localRepo.finalizar(id);
      
      state = state.copyWith(status: TrackingStatus.syncing);

      try {
        await _syncService.triggerSync();
        final check = await _localRepo.obterCaminhada(id);
        if (check.isSuccess && check.data == null) {
          state = state.copyWith(status: TrackingStatus.finished);
        } else {
          state = state.copyWith(status: TrackingStatus.finished, errorMessage: "offline_sync_pending");
        }
      } catch (e) {
         state = state.copyWith(status: TrackingStatus.finished, errorMessage: "offline_sync_pending");
      }
    } else {
      // Fallback: tenta enviar direto da memória se o banco falhou
      state = state.copyWith(status: TrackingStatus.syncing);
      try {
        final payload = {
          'coordinates': state.rawPath.map((c) => c.toJson()).toList(),
          'totalDurationSeconds': state.duration.inSeconds,
        };
        await _apiClient.syncCaminhada(payload);
        state = state.copyWith(status: TrackingStatus.finished);
      } catch (e) {
        AppLogger.e('Falha no sync de emergência sem banco local', e);
        state = state.copyWith(status: TrackingStatus.finished, errorMessage: "offline_sync_pending");
      }
    }
  }

  void pauseTracking() {
    _timer?.cancel();
    state = state.copyWith(status: TrackingStatus.paused);
    _flushBuffer();
  }

  void resumeTracking() {
    _startTimer();
    state = state.copyWith(status: TrackingStatus.tracking);
    _startGpsStream();
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
    WidgetsBinding.instance.removeObserver(this);
    _stopAllActions();
    super.dispose();
  }
}
