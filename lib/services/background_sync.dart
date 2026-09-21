import 'package:caminhandojuntos/services/sync_core.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter/widgets.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final syncCore = SyncCore();
      await syncCore.runSync();
      return true;
    } catch (e) {
      return false;
    }
  });
}

class BackgroundSync {
  static const String kSyncTaskName = "com.caminhandojuntos.sync_task";
  static const String kPeriodicSyncTaskName = "com.caminhandojuntos.periodic_sync_task";

  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  static Future<void> scheduleOneOffSync() async {
    await Workmanager().registerOneOffTask(
      DateTime.now().millisecondsSinceEpoch.toString(),
      kSyncTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> schedulePeriodicSync() async {
    await Workmanager().registerPeriodicTask(
      kPeriodicSyncTaskName,
      kPeriodicSyncTaskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
