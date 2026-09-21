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
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onOpen: (db) async {
          // PRAGMAs que retornam valores devem usar rawQuery no sqflite/Android
          await db.rawQuery('PRAGMA journal_mode = WAL');
          await db.rawQuery('PRAGMA synchronous = NORMAL');
          await db.rawQuery('PRAGMA busy_timeout = 5000');
          
          final result = await db.rawQuery('PRAGMA quick_check');
          if (result.first['quick_check'] != 'ok') {
            throw Exception('Quick check failed');
          }
        },
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
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onOpen: (db) async {
          await db.rawQuery('PRAGMA journal_mode = WAL');
          await db.rawQuery('PRAGMA synchronous = NORMAL');
          await db.rawQuery('PRAGMA busy_timeout = 5000');
        },
      );
      _database = db;
      return db;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE caminhadas (
        id TEXT PRIMARY KEY,
        inicio_ms INTEGER,
        fim_ms INTEGER,
        status TEXT,
        tentativas INTEGER DEFAULT 0,
        ultima_tentativa_ms INTEGER,
        ultimo_erro TEXT,
        criada_em_ms INTEGER,
        lease_expira_ms INTEGER,
        tempo_ativo_ms INTEGER DEFAULT 0,
        pausada INTEGER DEFAULT 0,
        atualizada_em_ms INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE pontos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        caminhada_id TEXT,
        lat REAL,
        lng REAL,
        precisao REAL,
        timestamp_ms INTEGER,
        FOREIGN KEY (caminhada_id) REFERENCES caminhadas (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_pontos_caminhada_id ON pontos(caminhada_id)');
    await db.execute('CREATE INDEX idx_caminhadas_status ON caminhadas(status)');
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
        // Tenta recuperar dados básicos se possível antes de apagar
        // (Isso é complexo e omitirei para manter estabilidade, apenas preservamos o arquivo)
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
        if (e is DatabaseException && e.toString().contains('SQLITE_FULL')) {
           AppLogger.e('Disco cheio (SQLITE_FULL)', e);
           // Not throwing to avoid crash, but the caller should handle Result
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
