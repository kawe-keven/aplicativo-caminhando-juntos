import 'package:caminhandojuntos/services/local_db.dart';

class PausaDao {
  final LocalDb _localDb = LocalDb();

  Future<void> insert(Map<String, dynamic> row) async {
    final db = await _localDb.database;
    await db.insert('pausas', row);
  }

  Future<void> finalizarPausa(String caminhadaId, int fimMs) async {
    final db = await _localDb.database;
    await db.update(
      'pausas',
      {'fim_ms': fimMs},
      where: 'caminhada_id = ? AND fim_ms IS NULL',
      whereArgs: [caminhadaId],
    );
  }

  Future<List<Map<String, dynamic>>> getByCaminhada(String caminhadaId) async {
    final db = await _localDb.database;
    return await db.query(
      'pausas',
      where: 'caminhada_id = ?',
      whereArgs: [caminhadaId],
      orderBy: 'inicio_ms ASC',
    );
  }
}
