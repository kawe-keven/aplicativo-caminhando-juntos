import 'dart:async';
import 'dart:convert';
import 'package:caminhandojuntos/config/api_config.dart';
import 'package:caminhandojuntos/services/local/caminhada_dao.dart';
import 'package:caminhandojuntos/services/local/ponto_dao.dart';
import 'package:caminhandojuntos/services/local/pausa_dao.dart';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      final success = await SyncWorker().run();
      return success;
    } catch (e) {
      AppLogger.e('SyncWorker background error', e);
      return false;
    }
  });
}

class SyncWorker {
  final CaminhadaDao _caminhadaDao = CaminhadaDao();
  final PontoDao _pontoDao = PontoDao();
  final PausaDao _pausaDao = PausaDao();

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> schedulePeriodic() async {
    await Workmanager().registerPeriodicTask(
      'sync-caminhadas',
      'sync-caminhadas-task',
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> scheduleOneOff() async {
    await Workmanager().registerOneOffTask(
      'sync-caminhadas-now-${DateTime.now().millisecondsSinceEpoch}',
      'sync-caminhadas-task',
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  Future<bool> run() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return true;

    await _autoFinalize();
    
    final pendentes = await _caminhadaDao.getPendentes();
    if (pendentes.isEmpty) return true;

    for (var caminhada in pendentes) {
      final id = caminhada['id'] as String;
      
      // Update status to 'enviando'
      await _caminhadaDao.update({...caminhada, 'status': 'enviando'});

      try {
        final pontos = await _pontoDao.getByCaminhada(id);
        final payload = {
          'id': id,
          'inicio_ms': caminhada['inicio_ms'],
          'fim_ms': caminhada['fim_ms'],
          'tempo_ativo_ms': caminhada['tempo_ativo_ms'],
          'pontos': pontos.map((p) => {
            'lat': p['lat'],
            'lng': p['lng'],
            'precisao': p['precisao'],
            'suspeito': p['suspeito'],
            'timestamp_ms': p['timestamp_ms'],
          }).toList(),
        };

        // Lê o token diretamente do SecureStorage no isolate de background
        const secureStorage = FlutterSecureStorage();
        final token = await secureStorage.read(key: 'auth_token');

        final headers = {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        };

        final baseHost = ApiConfig.baseUrl.replaceAll('/v1', '');
        final response = await http.post(
          Uri.parse('$baseHost/api/caminhada/sync'),
          headers: headers,
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          await _caminhadaDao.update({...caminhada, 'status': 'sincronizada'});
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('sync_requer_login', true);
          return true; // Stop worker
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          await _caminhadaDao.update({
            ...caminhada, 
            'status': 'rejeitada', 
            'motivo_rejeicao': 'HTTP ${response.statusCode}: ${response.body}'
          });
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }

      } catch (e) {
        final tentativas = (caminhada['tentativas'] as int? ?? 0) + 1;
        // Exponential backoff logic would go here, updating atualizada_em_ms
        await _caminhadaDao.update({
          ...caminhada, 
          'status': 'pendente', 
          'tentativas': tentativas,
          'atualizada_em_ms': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }

    return true;
  }

  Future<void> _autoFinalize() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - 30 * 60 * 1000; // 30 min
    final antigas = await _caminhadaDao.getEmAndamentoAntigas(cutoff);

    for (var caminhada in antigas) {
      final id = caminhada['id'] as String;
      final inicioMs = caminhada['inicio_ms'] as int;
      final atualizadaEmMs = caminhada['atualizada_em_ms'] as int;

      final tempoAtivoMs = await _calcularTempoAtivo(id, inicioMs, atualizadaEmMs);
      
      await _caminhadaDao.update({
        ...caminhada,
        'fim_ms': atualizadaEmMs,
        'status': 'pendente',
        'tempo_ativo_ms': tempoAtivoMs,
        'atualizada_em_ms': now,
      });
    }
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
}
