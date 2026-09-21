import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class MapTileCache {
  static final MapTileCache _instance = MapTileCache._internal();
  factory MapTileCache() => _instance;
  MapTileCache._internal();

  static const int kMaxCacheSize = 60 * 1024 * 1024; // 60 MB
  static const int kMaxAgeDays = 30;
  static const bool kPrefetchMapaAtivo = false;
  static const bool kApagarMapaAposEnvio = false;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mapa_cache.db');

    try {
      return await openDatabase(
        path,
        version: 2,
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('DROP TABLE IF EXISTS tiles');
            await _createTables(db);
          }
        },
      );
    } catch (e) {
      AppLogger.e('Erro ao abrir cache de mapa, limpando arquivo', e);
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE tiles (
        estilo TEXT,
        z INTEGER,
        x INTEGER,
        y INTEGER,
        dados BLOB NOT NULL,
        tamanho INTEGER,
        criado_ms INTEGER,
        acessado_ms INTEGER,
        PRIMARY KEY (estilo, z, x, y)
      )
    ''');
    await db.execute('CREATE INDEX idx_tiles_acessado ON tiles(acessado_ms)');
  }

  Future<Uint8List?> getTile(String estilo, int z, int x, int y) async {
    try {
      final db = await database;
      final maps = await db.query(
        'tiles',
        where: 'estilo = ? AND z = ? AND x = ? AND y = ?',
        whereArgs: [estilo, z, x, y],
      );

      if (maps.isNotEmpty) {
        final dados = maps.first['dados'] as Uint8List;
        final tamanho = maps.first['tamanho'] as int;
        
        if (dados.length != tamanho) {
          AppLogger.e('Cache corrompido (tamanho): $estilo/$z/$x/$y');
          return null;
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        db.update(
          'tiles',
          {'acessado_ms': now},
          where: 'estilo = ? AND z = ? AND x = ? AND y = ?',
          whereArgs: [estilo, z, x, y],
        );
        return maps.first['dados'] as Uint8List;
      }
    } catch (e) {
      AppLogger.e('Erro ao ler tile do cache', e);
    }
    return null;
  }

  Future<bool> isTileExpired(String estilo, int z, int x, int y) async {
    try {
      final db = await database;
      final maps = await db.query(
        'tiles',
        columns: ['criado_ms'],
        where: 'estilo = ? AND z = ? AND x = ? AND y = ?',
        whereArgs: [estilo, z, x, y],
      );

      if (maps.isNotEmpty) {
        final criadoMs = maps.first['criado_ms'] as int;
        final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(criadoMs));
        return age.inDays >= kMaxAgeDays;
      }
    } catch (_) {}
    return true;
  }

  Future<void> putTile(String estilo, int z, int x, int y, Uint8List dados) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'tiles',
        {
          'estilo': estilo,
          'z': z,
          'x': x,
          'y': y,
          'dados': dados,
          'tamanho': dados.length,
          'criado_ms': now,
          'acessado_ms': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _checkSizeAndCleanup();
    } catch (e) {
      if (e.toString().contains('SQLITE_FULL')) {
        _cleanupLRU(targetSize: (kMaxCacheSize * 0.5).toInt());
      }
      AppLogger.e('Erro ao gravar tile no cache', e);
    }
  }

  Future<void> _checkSizeAndCleanup() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT SUM(tamanho) as total FROM tiles');
      final total = result.first['total'] as int? ?? 0;
      if (total > kMaxCacheSize) {
        await _cleanupLRU();
      }
    } catch (_) {}
  }

  Future<void> _cleanupLRU({int? targetSize}) async {
    try {
      final db = await database;
      final limit = targetSize ?? (kMaxCacheSize * 0.8).toInt();
      
      await db.transaction((txn) async {
        final rows = await txn.query('tiles', columns: ['estilo', 'z', 'x', 'y', 'tamanho'], orderBy: 'acessado_ms ASC');
        int currentTotal = 0;
        for (var row in rows) {
          currentTotal += row['tamanho'] as int;
        }

        int toDelete = currentTotal - limit;
        if (toDelete <= 0) return;

        for (var row in rows) {
          if (toDelete <= 0) break;
          await txn.delete(
            'tiles',
            where: 'estilo = ? AND z = ? AND x = ? AND y = ?',
            whereArgs: [row['estilo'], row['z'], row['x'], row['y']],
          );
          toDelete -= row['tamanho'] as int;
        }
      });
    } catch (e) {
      AppLogger.e('Erro no cleanup LRU do mapa', e);
    }
  }

  Future<void> limparTudo() async {
    try {
      final db = await database;
      await db.delete('tiles');
      await db.execute('VACUUM');
    } catch (e) {
      AppLogger.e('Erro ao limpar cache de mapa', e);
    }
  }
}
