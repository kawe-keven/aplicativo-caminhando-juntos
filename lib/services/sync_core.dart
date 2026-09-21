import 'dart:async';
import 'package:caminhandojuntos/services/caminhada_api_client.dart';
import 'package:caminhandojuntos/services/caminhada_local_repository.dart';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncCore {
  final CaminhadaLocalRepository _repo = CaminhadaLocalRepository();
  final CaminhadaApiClient _apiClient = CaminhadaApiClient();

  static bool _isSyncing = false;

  Future<void> runSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final res = await _repo.listarPendentes();
      if (!res.isSuccess || res.data == null || res.data!.isEmpty) return;

      for (var caminhada in res.data!) {
        final id = caminhada['id'] as String;
        
        // Lease atômico
        final reservado = await _repo.reservar(id);
        if (!reservado.isSuccess || !reservado.data!) continue;

        try {
          final pontosRes = await _repo.listarPontos(id);
          if (!pontosRes.isSuccess) {
             await _repo.marcarPendente(id, 'Erro ao listar pontos');
             continue;
          }

          final payload = {
            'caminhadaId': id, // UUID for idempotency
            'coordinates': pontosRes.data!.map((p) => {
              'latitude': p['lat'],
              'longitude': p['lng'],
              'accuracy': p['precisao'],
              'timestamp': DateTime.fromMillisecondsSinceEpoch(p['timestamp_ms']).toIso8601String(),
            }).toList(),
            'totalDurationSeconds': (caminhada['tempo_ativo_ms'] as int) ~/ 1000,
          };

          await _apiClient.syncCaminhada(payload);
          // Success
          await _repo.apagarCaminhada(id);
          AppLogger.d('Caminhada $id sincronizada e removida.');

        } catch (e) {
          final erroStr = e.toString();
          if (erroStr.contains('401') || erroStr.contains('403')) {
            await _repo.marcarPendente(id, 'Autenticação necessária');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('sync_requer_login', true);
            break; // Stop sync until login
          } else if (erroStr.contains('409')) {
            // Duplicity treated as success
            await _repo.apagarCaminhada(id);
          } else if (erroStr.contains('4') && !erroStr.contains('408') && !erroStr.contains('429')) {
            // Other 4xx are rejected
            await _repo.marcarRejeitada(id, erroStr);
          } else {
            // Transitient failure
            await _repo.marcarPendente(id, erroStr);
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
