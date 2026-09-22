import 'dart:async';
import 'package:caminhandojuntos/services/sync/sync_worker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();
  ref.onDispose(() => service.dispose());
  return service;
});

class SyncService {
  final SyncWorker _worker = SyncWorker();
  StreamSubscription? _connectivitySubscription;

  SyncService() {
    _init();
  }

  void _init() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        triggerSync();
      }
    });
  }

  Future<void> triggerSync() async {
    await _worker.run();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
