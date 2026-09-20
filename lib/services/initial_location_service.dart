import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provedor que mantém a instância do serviço de localização inicial.
final initialLocationServiceProvider = Provider((ref) => InitialLocationService());

/// Provider que expõe a posição inicial carregada.
final initialLocationProvider = FutureProvider<LatLng?>((ref) async {
  return await ref.watch(initialLocationServiceProvider).obterPosicaoInicial();
});

class InitialLocationService {
  LatLng? _memCache;

  /// Tenta obter a posição inicial do usuário usando cache, GPS rápido ou histórico.
  Future<LatLng?> obterPosicaoInicial() async {
    try {
      // 1. Cache em memória
      if (_memCache != null) return _memCache;

      // Verifica permissão sem solicitar
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        return await _tryLoadFromPrefs();
      }

      // Verifica se o serviço está ligado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return await _tryLoadFromPrefs();

      // 2. Última posição conhecida do sistema (instantâneo)
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return await _saveAndReturn(LatLng(lastKnown.latitude, lastKnown.longitude));
      }

      // 3. Tenta carregar do SharedPreferences
      LatLng? fromPrefs = await _tryLoadFromPrefs();
      if (fromPrefs != null) return fromPrefs;

      // 4. Obtém posição atual com precisão baixa (mais rápido) e timeout
      // Compatibilidade com versões que não usam locationSettings nomeado no getCurrentPosition
      Position current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
      return await _saveAndReturn(LatLng(current.latitude, current.longitude));
    } catch (e) {
      // Retorna o que houver no prefs em caso de erro/timeout
      return await _tryLoadFromPrefs();
    }
  }

  Future<LatLng?> _tryLoadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('ultima_lat');
      final lng = prefs.getDouble('ultima_lng');
      if (lat != null && lng != null) {
        _memCache = LatLng(lat, lng);
        return _memCache;
      }
    } catch (_) {}
    return null;
  }

  Future<LatLng?> _saveAndReturn(LatLng pos) async {
    _memCache = pos;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('ultima_lat', pos.latitude);
      await prefs.setDouble('ultima_lng', pos.longitude);
    } catch (_) {}
    return pos;
  }
}
