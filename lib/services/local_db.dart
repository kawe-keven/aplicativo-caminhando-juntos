import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:caminhandojuntos/services/logger_service.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDb {
  static final LocalDb _instance = LocalDb._internal();
  factory LocalDb() => _instance;
  LocalDb._internal();

  Database? _database;
  Completer<Database>? _dbOpenCompleter;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    
    if (_dbOpenCompleter != null) return _dbOpenCompleter!.future;
    
    _dbOpenCompleter = Completer<Database>();
    try {
      final db = await _openAndValidate();
      _dbOpenCompleter!.complete(db);
      return db;
    } catch (e) {
      _dbOpenCompleter!.completeError(e);
      _dbOpenCompleter = null;
      rethrow;
    }
  }

  Future<Database> _openAndValidate() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'caminhadas.db');

    try {
      final db = await openDatabase(
        path,
        version: 1,
        onConfigure: (db) async {
          // Configurações de estado global da conexão (rawQuery para Android/sqflite)
          await db.rawQuery('PRAGMA foreign_keys = ON');
          await db.rawQuery('PRAGMA journal_mode = WAL');
          await db.rawQuery('PRAGMA synchronous = NORMAL');
          await db.rawQuery('PRAGMA busy_timeout = 5000');
        },
        onCreate: _onCreate,
      );
      _database = db;
      return db;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('EXCEÇÃO SQLITE (Abri): ${e.runtimeType} - $e\n$stack');
      }
      AppLogger.e('Database corruption or open error', e);
      await _handleCorruption(path);
      
      final db = await openDatabase(
        path,
        version: 1,
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA foreign_keys = ON');
          await db.rawQuery('PRAGMA journal_mode = WAL');
          await db.rawQuery('PRAGMA synchronous = NORMAL');
          await db.rawQuery('PRAGMA busy_timeout = 5000');
        },
        onCreate: _onCreate,
      );
      _database = db;
      return db;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE caminhadas (
        id TEXT PRIMARY KEY,
        inicio_ms INTEGER NOT NULL,
        fim_ms INTEGER,
        status TEXT NOT NULL CHECK (status IN ('em_andamento','pendente','enviando','sincronizada','rejeitada')),
        tempo_ativo_ms INTEGER NOT NULL DEFAULT 0,
        pausada INTEGER NOT NULL DEFAULT 0 CHECK (pausada IN (0,1)),
        tentativas INTEGER NOT NULL DEFAULT 0,
        motivo_rejeicao TEXT,
        atualizada_em_ms INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pontos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        caminhada_id TEXT NOT NULL,
        lat REAL NOT NULL,
        lng REAL NOT NULL,
        precisao REAL NOT NULL,
        suspeito INTEGER NOT NULL DEFAULT 0 CHECK (suspeito IN (0,1)),
        timestamp_ms INTEGER NOT NULL,
        FOREIGN KEY (caminhada_id) REFERENCES caminhadas (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pausas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        caminhada_id TEXT NOT NULL,
        inicio_ms INTEGER NOT NULL,
        fim_ms INTEGER,
        FOREIGN KEY (caminhada_id) REFERENCES caminhadas (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_caminhadas_status ON caminhadas(status, atualizada_em_ms)');
    await db.execute('CREATE INDEX idx_pontos_caminhada_ts ON pontos(caminhada_id, timestamp_ms)');
    await db.execute('CREATE INDEX idx_pausas_caminhada ON pausas(caminhada_id)');
  }

  Future<void> _handleCorruption(String path) async {
    final corruptPath = '$path.corrupt-${DateTime.now().millisecondsSinceEpoch}';
    try {
      if (_database != null) {
        await _database!.close();
        _database = null;
      }
      final originalFile = File(path);
      if (await originalFile.exists()) {
        await originalFile.copy(corruptPath);
        await originalFile.delete();
        AppLogger.d('Corrupted database moved to $corruptPath');
      }
    } catch (e) {
      AppLogger.e('Failed to rename corrupted database', e);
    }
  }

  Future<T> runWithRetry<T>(Future<T> Function() action) async {
    int attempts = 0;
    final delays = [100, 300, 900];
    
    while (true) {
      try {
        return await action();
      } catch (e) {
        if (e is DatabaseException && (e.isDatabaseClosedError() || e.toString().contains('locked') || e.toString().contains('busy'))) {
          if (attempts < delays.length) {
            await Future.delayed(Duration(milliseconds: delays[attempts]));
            attempts++;
            continue;
          }
        }
        rethrow;
      }
    }
  }

  Future<void> autoCleanup() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM caminhadas'));
    if (count == 0) {
      try {
        await db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
        await db.execute('VACUUM');
      } catch (e) {
        AppLogger.e('Failed to vacuum database', e);
      }
    }
  }
}

class UuidUtils {
  static String generateV4() {
    final random = Random.secure();
    return List.generate(32, (i) {
      if (i == 8 || i == 12 || i == 16 || i == 20) return '-';
      final n = random.nextInt(16);
      if (i == 12) return '4';
      if (i == 16) return ((n & 0x3) | 0x8).toRadixString(16);
      return n.toRadixString(16);
    }).join();
  }
}

class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result.success(this.data) : error = null, isSuccess = true;
  Result.failure(this.error) : data = null, isSuccess = false;
}
