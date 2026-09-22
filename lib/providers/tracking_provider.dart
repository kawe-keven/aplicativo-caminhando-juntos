import 'dart:async';
import 'package:caminhandojuntos/models/coordinate_model.dart';
import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/services/caminhada_api_client.dart';
import 'package:caminhandojuntos/services/local/caminhada_dao.dart';
import 'package:caminhandojuntos/services/local/ponto_dao.dart';
import 'package:caminhandojuntos/services/local/pausa_dao.dart';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:caminhandojuntos/services/local_db.dart';
import 'package:caminhandojuntos/services/sync_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

final caminhadaDaoProvider = Provider((ref) => CaminhadaDao());
final pontoDaoProvider = Provider((ref) => PontoDao());
final pausaDaoProvider = Provider((ref) => PausaDao());
final caminhadaApiClientProvider = Provider((ref) => CaminhadaApiClient());

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  final caminhadaDao = ref.watch(caminhadaDaoProvider);
  final pontoDao = ref.watch(pontoDaoProvider);
  final pausaDao = ref.watch(pausaDaoProvider);
  final syncService = ref.watch(syncServiceProvider);
  final apiClient = ref.watch(caminhadaApiClientProvider);
  return TrackingNotifier(caminhadaDao, pontoDao, pausaDao, syncService, apiClient);
});

class TrackingNotifier extends StateNotifier<TrackingState> with WidgetsBindingObserver {
  final CaminhadaDao _caminhadaDao;
  final PontoDao _pontoDao;
  final PausaDao _pausaDao;
  final SyncService _syncService;
  final CaminhadaApiClient _apiClient;
  
  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  
  final List<Map<String, dynamic>> _buffer = [];
  DateTime _lastSave = DateTime.now();

  TrackingNotifier(
    this._caminhadaDao, 
    this._pontoDao, 
    this._pausaDao, 
    this._syncService, 
    this._apiClient
  ) : super(TrackingState()) {
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
    if (state.caminhadaEmAndamento) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ultima_rota', '/walking');
    }
  }

  Future<void> restoreTracking() async {
    final data = await _caminhadaDao.getEmAndamento();
    if (data != null) {
      final id = data['id'] as String;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Auto-finalize if > 24h
      final atualizadaEm = data['atualizada_em_ms'] as int;
      if (now - atualizadaEm > 24 * 60 * 60 * 1000) {
        await _finalizeLocal(id, atualizadaEm);
        _syncService.triggerSync();
        return;
      }

      final pontos = await _pontoDao.getByCaminhada(id);
      final List<CoordinateModel> rawPath = [];
      final List<LatLng> mapPath = [];
      
      for (var p in pontos) {
        final coord = CoordinateModel.fromMap(p);
        rawPath.add(coord);
        
        if (!coord.isSuspect) {
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

      final duracaoMs = await _calcularTempoAtivo(id, data['inicio_ms'] as int, now);

      state = state.copyWith(
        caminhadaId: id,
        status: TrackingStatus.paused,
        rawPath: rawPath,
        mapPath: mapPath,
        duration: Duration(milliseconds: duracaoMs),
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
      final now = DateTime.now().millisecondsSinceEpoch;
      
      try {
        await _caminhadaDao.insert({
          'id': id,
          'inicio_ms': now,
          'status': 'em_andamento',
          'pausada': 0,
          'tempo_ativo_ms': 0,
          'atualizada_em_ms': now,
        });
        
        state = state.copyWith(
          caminhadaId: id,
          status: TrackingStatus.tracking, 
          errorMessage: null,
          duration: Duration.zero,
          rawPath: [],
          mapPath: [],
        );
      } catch (e) {
        AppLogger.e('Erro ao iniciar banco local, rastreando apenas em memória', e);
        state = state.copyWith(
          caminhadaId: null,
          status: TrackingStatus.tracking,
          errorMessage: null,
          duration: Duration.zero,
          rawPath: [],
          mapPath: [],
        );
      }
      
      _startTimer();
      _startGpsStream();

    } catch (e) {
      AppLogger.e('Erro ao iniciar rastreamento', e);
      _stopAllActions();
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
    final bool isSuspect = position.accuracy > 20;
    final now = DateTime.now();

    final newCoordinate = CoordinateModel(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
      accuracy: position.accuracy,
      isSuspect: isSuspect,
    );

    _buffer.add({
      'lat': position.latitude,
      'lng': position.longitude,
      'precisao': position.accuracy,
      'suspeito': isSuspect ? 1 : 0,
      'timestamp_ms': position.timestamp.millisecondsSinceEpoch,
    });

    if (_buffer.length >= 5 || now.difference(_lastSave).inSeconds >= 10) {
      _flushBuffer();
    }

    final updatedRawPath = [...state.rawPath, newCoordinate];
    List<LatLng> updatedMapPath = state.mapPath;
    final newPoint = LatLng(position.latitude, position.longitude);
    
    if (!isSuspect) {
      if (state.mapPath.isEmpty) {
        updatedMapPath = [newPoint];
      } else {
        final lastPoint = state.mapPath.last;
        if (Geolocator.distanceBetween(lastPoint.latitude, lastPoint.longitude, newPoint.latitude, newPoint.longitude) > 10) {
          updatedMapPath = [...state.mapPath, newPoint];
        }
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
    
    final id = state.caminhadaId!;
    final pointsToSave = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();
    _lastSave = DateTime.now();

    await _pontoDao.insertBatch(id, pointsToSave);
    await _caminhadaDao.update({
      'id': id,
      'atualizada_em_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(duration: state.duration + const Duration(seconds: 1));
    });
  }

  Future<void> pauseTracking() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _timer?.cancel();
    _stopAllActions();
    
    if (state.caminhadaId != null) {
      final id = state.caminhadaId!;
      await _flushBuffer();
      await _pausaDao.insert({
        'caminhada_id': id,
        'inicio_ms': now,
        'fim_ms': null,
      });
      await _caminhadaDao.update({
        'id': id,
        'pausada': 1,
        'atualizada_em_ms': now,
      });
    }

    state = state.copyWith(status: TrackingStatus.paused);
  }

  Future<void> resumeTracking() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (state.caminhadaId != null) {
      final id = state.caminhadaId!;
      await _pausaDao.finalizarPausa(id, now);
      await _caminhadaDao.update({
        'id': id,
        'pausada': 0,
        'atualizada_em_ms': now,
      });
    }

    _startTimer();
    _startGpsStream();
    state = state.copyWith(status: TrackingStatus.tracking);
  }

  Future<void> finishAndSync() async {
    if (state.status == TrackingStatus.syncing) return;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    _stopAllActions();
    final id = state.caminhadaId;

    if (id != null) {
      await _flushBuffer();
      await _finalizeLocal(id, now);
      
      state = state.copyWith(status: TrackingStatus.syncing);

      try {
        await _syncService.triggerSync();
        final check = await _caminhadaDao.getById(id);
        if (check == null || check['status'] == 'sincronizada') {
          state = state.copyWith(status: TrackingStatus.finished);
        } else {
          state = state.copyWith(status: TrackingStatus.finished, errorMessage: "offline_sync_pending");
        }
      } catch (e) {
         state = state.copyWith(status: TrackingStatus.finished, errorMessage: "offline_sync_pending");
      }
    } else {
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

  Future<void> _finalizeLocal(String id, int fimMs) async {
    final caminhada = await _caminhadaDao.getById(id);
    if (caminhada == null) return;

    final inicioMs = caminhada['inicio_ms'] as int;
    final tempoAtivoMs = await _calcularTempoAtivo(id, inicioMs, fimMs);

    await _caminhadaDao.update({
      'id': id,
      'fim_ms': fimMs,
      'status': 'pendente',
      'tempo_ativo_ms': tempoAtivoMs,
      'atualizada_em_ms': fimMs,
    });
  }

  Future<int> _calcularTempoAtivo(String id, int inicioMs, int fimMs) async {
    final totalDuration = fimMs - inicioMs;
    final pausas = await _pausaDao.getByCaminhada(id);
    
    int totalPausasMs = 0;
    for (var pausa in pausas) {
      final pInicio = pausa['inicio_ms'] as int;
      final pFim = pausa['fim_ms'] as int? ?? fimMs;
      totalPausasMs += (pFim - pInicio);
    }
    
    return totalDuration - totalPausasMs;
  }

  void _stopAllActions() {
    _positionSubscription?.cancel();
    _timer?.cancel();
  }
  
  void reset() {
    _stopAllActions();
    _buffer.clear();
    state = TrackingState();
  }

  Future<void> discardTracking() async {
    final id = state.caminhadaId;
    _stopAllActions();
    if (id != null) {
      await _caminhadaDao.deleteById(id);
    }
    reset();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAllActions();
    super.dispose();
  }
}
