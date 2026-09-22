import 'package:caminhandojuntos/services/local_db.dart';

class CaminhadaDao {
  final LocalDb _localDb = LocalDb();

  Future<void> insert(Map<String, dynamic> row) async {
    final db = await _localDb.database;
    await db.insert('caminhadas', row);
  }

  Future<void> update(Map<String, dynamic> row) async {
    final db = await _localDb.database;
    await db.update('caminhadas', row, where: 'id = ?', whereArgs: [row['id']]);
  }

  Future<Map<String, dynamic>?> getById(String id) async {
    final db = await _localDb.database;
    final results = await db.query('caminhadas', where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getPendentes() async {
    final db = await _localDb.database;
    return await db.query(
      'caminhadas',
      where: "status IN ('pendente', 'rejeitada')",
      orderBy: 'atualizada_em_ms ASC',
    );
  }

  Future<void> deleteById(String id) async {
    final db = await _localDb.database;
    await db.delete('caminhadas', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getEmAndamentoAntigas(int cutoffMs) async {
    final db = await _localDb.database;
    return await db.query(
      'caminhadas',
      where: "status = 'em_andamento' AND atualizada_em_ms < ?",
      whereArgs: [cutoffMs],
    );
  }

  Future<Map<String, dynamic>?> getEmAndamento() async {
    final db = await _localDb.database;
    final results = await db.query('caminhadas', where: "status = 'em_andamento'", limit: 1);
    return results.isNotEmpty ? results.first : null;
  }
}
