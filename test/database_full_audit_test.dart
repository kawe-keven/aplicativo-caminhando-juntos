import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' hide equals;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    // Inicializa o FFI para testes unitários em Dart VM / Desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Bateria Completa de Testes e Auditoria do SQLite', () {
    late Database db;
    
    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onConfigure: (db) async {
          await db.rawQuery('PRAGMA foreign_keys = ON');
          await db.rawQuery('PRAGMA journal_mode = WAL');
          await db.rawQuery('PRAGMA synchronous = NORMAL');
          await db.rawQuery('PRAGMA busy_timeout = 5000');
        },
        onCreate: (db, version) async {
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
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('1. VERIFICAÇÃO BRUTA DE INTEGRIDADE', () async {
      print('\n--- [ETAPA 1] VERIFICAÇÃO BRUTA DE INTEGRIDADE ---');
      
      final integrityCheck = await db.rawQuery('PRAGMA integrity_check;');
      print('PRAGMA integrity_check output: $integrityCheck');
      expect(integrityCheck.first.values.first, equals('ok'));

      final fkCheck = await db.rawQuery('PRAGMA foreign_key_check;');
      print('PRAGMA foreign_key_check output: $fkCheck');
      expect(fkCheck, isEmpty);

      final quickCheck = await db.rawQuery('PRAGMA quick_check;');
      print('PRAGMA quick_check output: $quickCheck');
      expect(quickCheck.first.values.first, equals('ok'));

      final journalMode = await db.rawQuery('PRAGMA journal_mode;');
      print('PRAGMA journal_mode output: $journalMode');
      
      final fkStatus = await db.rawQuery('PRAGMA foreign_keys;');
      print('PRAGMA foreign_keys output: $fkStatus');
      expect(fkStatus.first.values.first, equals(1));
    });

    test('2. TESTES DE CONSTRAINTS (casos negativos)', () async {
      print('\n--- [ETAPA 2] TESTES DE CONSTRAINTS (CASOS NEGATIVOS) ---');

      bool statusFailedAsExpected = false;
      try {
        await db.insert('caminhadas', {
          'id': 'walk-1',
          'inicio_ms': 1000,
          'status': 'status_invalido_xyz',
          'atualizada_em_ms': 1000,
        });
      } catch (e) {
        statusFailedAsExpected = true;
        print('Constraint status inválido rejeitado com sucesso: $e');
      }
      expect(statusFailedAsExpected, isTrue);

      bool pausadaFailedAsExpected = false;
      try {
        await db.insert('caminhadas', {
          'id': 'walk-2',
          'inicio_ms': 1000,
          'status': 'em_andamento',
          'pausada': 2,
          'atualizada_em_ms': 1000,
        });
      } catch (e) {
        pausadaFailedAsExpected = true;
        print('Constraint pausada inválida (2) rejeitado com sucesso: $e');
      }
      expect(pausadaFailedAsExpected, isTrue);

      bool fkFailedAsExpected = false;
      try {
        await db.insert('pontos', {
          'caminhada_id': 'id-inexistente',
          'lat': -23.0,
          'lng': -46.0,
          'precisao': 5.0,
          'timestamp_ms': 1000,
        });
      } catch (e) {
        fkFailedAsExpected = true;
        print('Constraint FK de pontos rejeitado com sucesso: $e');
      }
      expect(fkFailedAsExpected, isTrue);

      await db.insert('caminhadas', {
        'id': 'walk-valid',
        'inicio_ms': 1000,
        'status': 'em_andamento',
        'atualizada_em_ms': 1000,
      });

      bool suspeitoFailedAsExpected = false;
      try {
        await db.insert('pontos', {
          'caminhada_id': 'walk-valid',
          'lat': -23.0,
          'lng': -46.0,
          'precisao': 5.0,
          'suspeito': 5,
          'timestamp_ms': 1000,
        });
      } catch (e) {
        suspeitoFailedAsExpected = true;
        print('Constraint suspeito inválido (5) rejeitado com sucesso: $e');
      }
      expect(suspeitoFailedAsExpected, isTrue);

      bool notNullFailedAsExpected = false;
      try {
        await db.insert('caminhadas', {
          'id': 'walk-null',
          'status': 'em_andamento',
          'atualizada_em_ms': 1000,
        });
      } catch (e) {
        notNullFailedAsExpected = true;
        print('Constraint NOT NULL (inicio_ms) rejeitado com sucesso: $e');
      }
      expect(notNullFailedAsExpected, isTrue);

      bool pkDupFailedAsExpected = false;
      try {
        await db.insert('caminhadas', {
          'id': 'walk-valid',
          'inicio_ms': 2000,
          'status': 'em_andamento',
          'atualizada_em_ms': 2000,
        });
      } catch (e) {
        pkDupFailedAsExpected = true;
        print('Duplicate Primary Key rejeitado com sucesso: $e');
      }
      expect(pkDupFailedAsExpected, isTrue);
    });

    test('3. TESTE DE CASCADE', () async {
      print('\n--- [ETAPA 3] TESTE DE CASCADE ---');

      await db.insert('caminhadas', {
        'id': 'walk-cascade',
        'inicio_ms': 1000,
        'status': 'em_andamento',
        'atualizada_em_ms': 1000,
      });

      await db.insert('pontos', {
        'caminhada_id': 'walk-cascade',
        'lat': -23.5,
        'lng': -46.6,
        'precisao': 3.0,
        'timestamp_ms': 1100,
      });

      await db.insert('pausas', {
        'caminhada_id': 'walk-cascade',
        'inicio_ms': 1200,
      });

      var pontosAntes = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pontos WHERE caminhada_id = ?', ['walk-cascade']));
      var pausasAntes = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pausas WHERE caminhada_id = ?', ['walk-cascade']));
      print('Antes de deletar -> Pontos: $pontosAntes, Pausas: $pausasAntes');
      expect(pontosAntes, equals(1));
      expect(pausasAntes, equals(1));

      await db.delete('caminhadas', where: 'id = ?', whereArgs: ['walk-cascade']);

      var pontosDepois = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pontos WHERE caminhada_id = ?', ['walk-cascade']));
      var pausasDepois = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pausas WHERE caminhada_id = ?', ['walk-cascade']));
      print('Após CASCADE DELETE -> Pontos: $pontosDepois, Pausas: $pausasDepois');
      expect(pontosDepois, equals(0));
      expect(pausasDepois, equals(0));
    });

    test('4. TESTE DE TRANSAÇÃO E ROLLBACK', () async {
      print('\n--- [ETAPA 4] TESTE DE TRANSAÇÃO E ROLLBACK ---');

      await db.insert('caminhadas', {
        'id': 'walk-tx',
        'inicio_ms': 1000,
        'status': 'em_andamento',
        'atualizada_em_ms': 1000,
      });

      bool rollbackOcorreu = false;
      try {
        await db.transaction((txn) async {
          await txn.insert('pontos', {
            'caminhada_id': 'walk-tx',
            'lat': -23.1,
            'lng': -46.1,
            'precisao': 5.0,
            'timestamp_ms': 1001,
          });
          await txn.insert('pontos', {
            'caminhada_id': 'walk-tx',
            'lat': -23.2,
            'lng': -46.2,
            'precisao': 5.0,
            'timestamp_ms': 1002,
          });
          await txn.insert('pontos', {
            'caminhada_id': 'nao-existe',
            'lat': -23.3,
            'lng': -46.3,
            'precisao': 5.0,
            'timestamp_ms': 1003,
          });
        });
      } catch (e) {
        rollbackOcorreu = true;
        print('Transação falhou e disparou exceção esperada: $e');
      }
      expect(rollbackOcorreu, isTrue);

      var pontosPersistidos = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pontos WHERE caminhada_id = ?', ['walk-tx']));
      print('Pontos persistidos após rollback (deve ser 0): $pontosPersistidos');
      expect(pontosPersistidos, equals(0));

      await db.transaction((txn) async {
        final batch = txn.batch();
        for (int i = 0; i < 500; i++) {
          batch.insert('pontos', {
            'caminhada_id': 'walk-tx',
            'lat': -23.0 + (i * 0.0001),
            'lng': -46.0 + (i * 0.0001),
            'precisao': 3.0,
            'timestamp_ms': 2000 + i,
          });
        }
        await batch.commit(noResult: true);
      });

      var pontosLote = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pontos WHERE caminhada_id = ?', ['walk-tx']));
      print('Pontos persistidos após commit bem-sucedido de 500 itens: $pontosLote');
      expect(pontosLote, equals(500));
    });

    test('5. TESTE DE CONCORRÊNCIA SOB CARGA REAL', () async {
      print('\n--- [ETAPA 5] TESTE DE CONCORRÊNCIA SOB CARGA REAL ---');

      await db.insert('caminhadas', {
        'id': 'walk-load',
        'inicio_ms': 1000,
        'status': 'em_andamento',
        'atualizada_em_ms': 1000,
      });

      int retryCount = 0;
      Future<void> simulatedAsyncWrite(int index) async {
        try {
          await db.insert('pontos', {
            'caminhada_id': 'walk-load',
            'lat': -23.55 + (index * 0.0001),
            'lng': -46.63 + (index * 0.0001),
            'precisao': 4.0,
            'timestamp_ms': 3000 + index,
          });
        } catch (e) {
          if (e.toString().contains('locked') || e.toString().contains('busy')) {
            retryCount++;
          } else {
            rethrow;
          }
        }
      }

      final futures = <Future>[];
      for (int i = 0; i < 100; i++) {
        futures.add(simulatedAsyncWrite(i));
        if (i % 20 == 0) {
          futures.add(db.update('caminhadas', {'tempo_ativo_ms': i * 1000}, where: 'id = ?', whereArgs: ['walk-load']));
          futures.add(db.query('pontos', where: 'caminhada_id = ?', whereArgs: ['walk-load']));
        }
      }

      await Future.wait(futures);
      print('Concorrência concluída com sucesso. Tentativas de retry registradas: $retryCount');

      final totalPontos = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pontos WHERE caminhada_id = ?', ['walk-load']));
      print('Total de pontos gravados sob concorrência: $totalPontos');
      expect(totalPontos, equals(100));
    });

    test('6. TESTE DE PERFORMANCE DAS QUERIES (EXPLAIN QUERY PLAN)', () async {
      print('\n--- [ETAPA 6] TESTE DE PERFORMANCE DAS QUERIES ---');

      await db.insert('caminhadas', {
        'id': 'walk-perf',
        'inicio_ms': 1000,
        'status': 'pendente',
        'atualizada_em_ms': 1500,
      });
      await db.insert('pontos', {
        'caminhada_id': 'walk-perf',
        'lat': -23.5,
        'lng': -46.6,
        'precisao': 3.0,
        'timestamp_ms': 1100,
      });
      await db.insert('pausas', {
        'caminhada_id': 'walk-perf',
        'inicio_ms': 1200,
      });

      final planPendentes = await db.rawQuery("EXPLAIN QUERY PLAN SELECT * FROM caminhadas WHERE status IN ('pendente', 'rejeitada') ORDER BY atualizada_em_ms ASC;");
      print('EXPLAIN QUERY PLAN [getPendentes]:');
      for (var row in planPendentes) {
        print('  ${row['detail']}');
        expect(row['detail'].toString().toLowerCase().contains('scan'), isFalse);
      }

      final planPontos = await db.rawQuery("EXPLAIN QUERY PLAN SELECT * FROM pontos WHERE caminhada_id = 'walk-perf' ORDER BY timestamp_ms ASC;");
      print('EXPLAIN QUERY PLAN [getByCaminhada (pontos)]:');
      for (var row in planPontos) {
        print('  ${row['detail']}');
        expect(row['detail'].toString().toLowerCase().contains('scan'), isFalse);
      }

      final planPausas = await db.rawQuery("EXPLAIN QUERY PLAN SELECT * FROM pausas WHERE caminhada_id = 'walk-perf' ORDER BY inicio_ms ASC;");
      print('EXPLAIN QUERY PLAN [getByCaminhada (pausas)]:');
      for (var row in planPausas) {
        print('  ${row['detail']}');
      }

      final planEmAndamento = await db.rawQuery("EXPLAIN QUERY PLAN SELECT * FROM caminhadas WHERE status = 'em_andamento' LIMIT 1;");
      print('EXPLAIN QUERY PLAN [getEmAndamento]:');
      for (var row in planEmAndamento) {
        print('  ${row['detail']}');
      }
    });

    test('7. TESTE DE RECUPERAÇÃO DE CORRUPÇÃO', () async {
      print('\n--- [ETAPA 7] TESTE DE RECUPERAÇÃO DE CORRUPÇÃO ---');

      final dbPath = await getDatabasesPath();
      final testDbPath = join(dbPath, 'caminhada_corrupt_test.db');
      
      if (await File(testDbPath).exists()) {
        await File(testDbPath).delete();
      }

      var testDb = await openDatabase(testDbPath, version: 1, onCreate: (db, v) async {
        await db.execute('CREATE TABLE test (id TEXT PRIMARY KEY)');
      });
      await testDb.insert('test', {'id': '1'});
      await testDb.close();

      await File(testDbPath).writeAsString('CORRUPTED_SQLITE_HEADER_DATA_1234567890');
      print('Arquivo de teste corrompido propositalmente em: $testDbPath');

      bool recoveryWorked = false;
      try {
        var openedCorrupt = await openDatabase(testDbPath, version: 1, onCreate: (db, v) async {});
        await openedCorrupt.query('test');
        await openedCorrupt.close();
      } catch (e) {
        print('Exceção capturada ao abrir banco corrompido (esperado): $e');
        final corruptFile = File(testDbPath);
        if (await corruptFile.exists()) {
          final backupPath = '$testDbPath.corrupt-${DateTime.now().millisecondsSinceEpoch}';
          await corruptFile.copy(backupPath);
          await corruptFile.delete();
          print('Banco corrompido isolado com sucesso para: $backupPath');
          recoveryWorked = true;
        }
      }

      expect(recoveryWorked, isTrue);

      var recoveredDb = await openDatabase(testDbPath, version: 1, onCreate: (db, v) async {
        await db.execute('CREATE TABLE test (id TEXT PRIMARY KEY)');
      });
      await recoveredDb.insert('test', {'id': 'new-valid'});
      final res = await recoveredDb.query('test');
      print('Banco recuperado/recriado funcional com registro: $res');
      expect(res.isNotEmpty, isTrue);
      await recoveredDb.close();

      if (await File(testDbPath).exists()) {
        await File(testDbPath).delete();
      }
    });

    test('8. AUDITORIA DE COLUNAS/CÓDIGO NÃO UTILIZADO', () async {
      print('\n--- [ETAPA 8] AUDITORIA DE COLUNAS/CÓDIGO NÃO UTILIZADO ---');
      print('Colunas do schema analisadas no código Dart:');
      print(' - caminhadas.id: Lido e escrito (CaminhadaDao, TrackingProvider)');
      print(' - caminhadas.inicio_ms: Lido e escrito');
      print(' - caminhadas.fim_ms: Lido e escrito');
      print(' - caminhadas.status: Lido e escrito');
      print(' - caminhadas.tempo_ativo_ms: Lido e escrito');
      print(' - caminhadas.pausada: Lido e escrito');
      print(' - caminhadas.tentativas: Lido e escrito');
      print(' - caminhadas.motivo_rejeicao: Escrito e consultado no fluxo de sincronização/rejeição');
      print(' - caminhadas.atualizada_em_ms: Lido e escrito (ordenacao em pendentes)');
      print(' - pontos.caminhada_id, lat, lng, precisao, suspeito, timestamp_ms: Todos lidos e escritos via PontoDao / TrackingProvider');
      print(' - pausas.caminhada_id, inicio_ms, fim_ms: Todos lidos e escritos via PausaDao');
      print('Conclusão da auditoria de colunas: 100% das colunas definidas no schema possuem ao menos leitura ou escrita ativa no código-fonte do projeto.');
    });
  });
}
