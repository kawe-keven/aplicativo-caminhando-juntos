import 'dart:async';
import 'package:caminhandojuntos/services/sync_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();
  ref.onDispose(() => service.dispose());
  return service;
});

class SyncService {
  final SyncCore _syncCore = SyncCore();
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
    await _syncCore.runSync();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
