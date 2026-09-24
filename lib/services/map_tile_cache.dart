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
        version: 3, // Incrementado para suportar coluna 'provedor' na chave primária
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA journal_mode=WAL;');
          await db.rawQuery('PRAGMA synchronous=NORMAL;');
        },
        onCreate: (db, version) async {
          await _createTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 3) {
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
        provedor TEXT NOT NULL,
        estilo TEXT NOT NULL,
        z INTEGER NOT NULL,
        x INTEGER NOT NULL,
        y INTEGER NOT NULL,
        dados BLOB NOT NULL,
        tamanho INTEGER NOT NULL,
        criado_ms INTEGER NOT NULL,
        acessado_ms INTEGER NOT NULL,
        PRIMARY KEY (provedor, estilo, z, x, y)
      )
    ''');
    await db.execute('CREATE INDEX idx_tiles_acessado ON tiles(acessado_ms)');
    await db.execute('CREATE INDEX idx_tiles_provedor ON tiles(provedor, estilo)');
  }

  Future<Uint8List?> getTile(String provedor, String estilo, int z, int x, int y) async {
    try {
      final db = await database;
      final maps = await db.query(
        'tiles',
        where: 'provedor = ? AND estilo = ? AND z = ? AND x = ? AND y = ?',
        whereArgs: [provedor, estilo, z, x, y],
      );

      if (maps.isNotEmpty) {
        final dados = maps.first['dados'] as Uint8List;
        final tamanho = maps.first['tamanho'] as int;
        
        if (dados.length != tamanho) {
          AppLogger.e('Cache corrompido (tamanho): $provedor/$estilo/$z/$x/$y');
          await db.delete(
            'tiles',
            where: 'provedor = ? AND estilo = ? AND z = ? AND x = ? AND y = ?',
            whereArgs: [provedor, estilo, z, x, y],
          );
          return null;
        }

        final now = DateTime.now().millisecondsSinceEpoch;
        await db.update(
          'tiles',
          {'acessado_ms': now},
          where: 'provedor = ? AND estilo = ? AND z = ? AND x = ? AND y = ?',
          whereArgs: [provedor, estilo, z, x, y],
        );
        return dados;
      }
    } catch (e) {
      AppLogger.e('Erro ao ler tile do cache', e);
    }
    return null;
  }

  Future<bool> isTileExpired(String provedor, String estilo, int z, int x, int y, {int maxAgeDays = kMaxAgeDays}) async {
    try {
      final db = await database;
      final maps = await db.query(
        'tiles',
        columns: ['criado_ms'],
        where: 'provedor = ? AND estilo = ? AND z = ? AND x = ? AND y = ?',
        whereArgs: [provedor, estilo, z, x, y],
      );

      if (maps.isNotEmpty) {
        final criadoMs = maps.first['criado_ms'] as int;
        final age = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(criadoMs));
        return age.inDays >= maxAgeDays;
      }
    } catch (_) {}
    return true;
  }

  Future<void> putTile(String provedor, String estilo, int z, int x, int y, Uint8List dados) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      await db.transaction((txn) async {
        await txn.insert(
          'tiles',
          {
            'provedor': provedor,
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
      });

      await _checkSizeAndCleanup(db);
    } catch (e) {
      if (e.toString().contains('SQLITE_FULL')) {
        try {
          final db = await database;
          await _cleanupLRU(db, targetSize: (kMaxCacheSize * 0.5).toInt());
        } catch (_) {}
      }
      AppLogger.e('Erro ao gravar tile no cache', e);
    }
  }

  Future<void> _checkSizeAndCleanup(Database db) async {
    try {
      final result = await db.rawQuery('SELECT SUM(tamanho) as total FROM tiles');
      final total = result.first['total'] as int? ?? 0;
      if (total > kMaxCacheSize) {
        await _cleanupLRU(db);
      }
    } catch (_) {}
  }

  Future<void> _cleanupLRU(Database db, {int? targetSize}) async {
    try {
      final limit = targetSize ?? (kMaxCacheSize * 0.8).toInt();
      
      await db.transaction((txn) async {
        final rows = await txn.query('tiles', columns: ['provedor', 'estilo', 'z', 'x', 'y', 'tamanho'], orderBy: 'acessado_ms ASC');
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
            where: 'provedor = ? AND estilo = ? AND z = ? AND x = ? AND y = ?',
            whereArgs: [row['provedor'], row['estilo'], row['z'], row['x'], row['y']],
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
