import 'package:caminhandojuntos/services/local_db.dart';

class PontoDao {
  final LocalDb _localDb = LocalDb();

  Future<void> insertBatch(String caminhadaId, List<Map<String, dynamic>> points) async {
    final db = await _localDb.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var point in points) {
        batch.insert('pontos', {
          ...point,
          'caminhada_id': caminhadaId,
        });
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, dynamic>>> getByCaminhada(String caminhadaId) async {
    final db = await _localDb.database;
    return await db.query(
      'pontos',
      where: 'caminhada_id = ?',
      whereArgs: [caminhadaId],
      orderBy: 'timestamp_ms ASC',
    );
  }
}
