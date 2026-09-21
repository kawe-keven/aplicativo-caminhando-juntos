import 'package:caminhandojuntos/services/local_db.dart';
import 'package:flutter/foundation.dart';

class CaminhadaLocalRepository {
  final LocalDb _localDb = LocalDb();

  Future<Result<String>> criarEmAndamento(String id) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _localDb.runWithRetry(() async {
        final db = await _localDb.database;
        await db.insert('caminhadas', {
          'id': id,
          'inicio_ms': now,
          'status': 'em_andamento',
          'criada_em_ms': now,
          'atualizada_em_ms': now,
          'pausada': 0,
          'tempo_ativo_ms': 0,
        });
      });
      return Result.success(id);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('EXCEÇÃO REPOSITORY: ${e.runtimeType} - $e\n$stack');
      }
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> gravarPontos(String caminhadaId, List<Map<String, dynamic>> pontos) async {
    try {
      await _localDb.runWithRetry(() async {
        final db = await _localDb.database;
        await db.transaction((txn) async {
          final batch = txn.batch();
          for (var ponto in pontos) {
            batch.insert('pontos', {
              'caminhada_id': caminhadaId,
              'lat': ponto['lat'],
              'lng': ponto['lng'],
              'precisao': ponto['precisao'],
              'timestamp_ms': ponto['timestamp_ms'],
            });
          }
          await batch.commit(noResult: true);
          await txn.update(
            'caminhadas',
            {'atualizada_em_ms': DateTime.now().millisecondsSinceEpoch},
            where: 'id = ?',
            whereArgs: [caminhadaId],
          );
        });
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> atualizarProgresso(String id, int tempoAtivoMs, bool pausada) async {
    try {
      await _localDb.runWithRetry(() async {
        final db = await _localDb.database;
        await db.update(
          'caminhadas',
          {
            'tempo_ativo_ms': tempoAtivoMs,
            'pausada': pausada ? 1 : 0,
            'atualizada_em_ms': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> finalizar(String id) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _localDb.runWithRetry(() async {
        final db = await _localDb.database;
        await db.update(
          'caminhadas',
          {
            'status': 'pendente',
            'fim_ms': now,
            'atualizada_em_ms': now,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Map<String, dynamic>>>> listarPendentes() async {
    try {
      final db = await _localDb.database;
      final maps = await db.query(
        'caminhadas',
        where: 'status = ?',
        whereArgs: ['pendente'],
        orderBy: 'criada_em_ms ASC',
      );
      return Result.success(maps);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Map<String, dynamic>?>> obterCaminhada(String id) async {
    try {
      final db = await _localDb.database;
      final maps = await db.query('caminhadas', where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        return Result.success(maps.first);
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<List<Map<String, dynamic>>>> listarPontos(String caminhadaId) async {
    try {
      final db = await _localDb.database;
      final maps = await db.query('pontos', where: 'caminhada_id = ?', whereArgs: [caminhadaId]);
      return Result.success(maps);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<bool>> reservar(String id) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final leaseExpira = now + 10 * 60 * 1000; // 10 min
      final db = await _localDb.database;
      final count = await db.rawUpdate('''
        UPDATE caminhadas 
        SET status = 'enviando', lease_expira_ms = ? 
        WHERE id = ? AND (status = 'pendente' OR (status = 'enviando' AND lease_expira_ms < ?))
      ''', [leaseExpira, id, now]);
      return Result.success(count == 1);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> marcarPendente(String id, String? erro) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final db = await _localDb.database;
      await db.rawUpdate('''
        UPDATE caminhadas 
        SET status = 'pendente', tentativas = tentativas + 1, ultima_tentativa_ms = ?, ultimo_erro = ?
        WHERE id = ?
      ''', [now, erro, id]);
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> marcarRejeitada(String id, String erro) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final db = await _localDb.database;
      await db.update(
        'caminhadas',
        {
          'status': 'rejeitada',
          'ultimo_erro': erro,
          'atualizada_em_ms': now,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> apagarCaminhada(String id) async {
    try {
      await _localDb.runWithRetry(() async {
        final db = await _localDb.database;
        await db.delete('caminhadas', where: 'id = ?', whereArgs: [id]);
        await _localDb.autoCleanup();
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<void>> limparTudo() async {
    try {
      await _localDb.runWithRetry(() async {
        final db = await _localDb.database;
        await db.delete('caminhadas');
        await db.delete('pontos');
        await _localDb.autoCleanup();
      });
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }

  Future<Result<Map<String, dynamic>?>> obterEmAndamento() async {
    try {
      final db = await _localDb.database;
      final maps = await db.query('caminhadas', where: 'status = ?', whereArgs: ['em_andamento'], limit: 1);
      if (maps.isNotEmpty) {
        return Result.success(maps.first);
      }
      return Result.success(null);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
