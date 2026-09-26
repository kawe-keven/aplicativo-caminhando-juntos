import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caminhandojuntos/providers/dashboard_provider.dart';
import 'package:caminhandojuntos/providers/achievements_provider.dart';
import 'package:caminhandojuntos/services/local/caminhada_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('DashboardProvider persists state and reloads after restart', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(dashboardProvider.notifier).loadProgress();

    container.read(dashboardProvider.notifier).addSteps(500);
    container.read(dashboardProvider.notifier).addCompletedWalk(distanceKm: 2.0, coins: 50, durationMinutes: 20);

    await Future.delayed(const Duration(milliseconds: 100));

    final progressBefore = container.read(dashboardProvider).progress;

    final containerReloaded = ProviderContainer();
    addTearDown(containerReloaded.dispose);

    await containerReloaded.read(dashboardProvider.notifier).loadProgress();

    final progressAfter = containerReloaded.read(dashboardProvider).progress;

    expect(progressAfter.steps, equals(progressBefore.steps));
    expect(progressAfter.coins, equals(progressBefore.coins));
    expect(progressAfter.distanceKm, equals(progressBefore.distanceKm));
  });

  test('AchievementsProvider reacts to completed walks in CaminhadaDao', () async {
    final dao = CaminhadaDao();
    await dao.insert({
      'id': 'walk-test-1',
      'inicio_ms': DateTime.now().millisecondsSinceEpoch - 100000,
      'fim_ms': DateTime.now().millisecondsSinceEpoch,
      'status': 'sincronizada',
      'tempo_ativo_ms': 30 * 60 * 1000,
      'pausada': 0,
      'tentativas': 0,
      'atualizada_em_ms': DateTime.now().millisecondsSinceEpoch,
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final achievementsNotifier = container.read(achievementsProvider.notifier);
    await achievementsNotifier.refreshAchievements();

    final achievements = container.read(achievementsProvider);
    
    final primeiroPasso = achievements.firstWhere((a) => a.id == '1');
    expect(primeiroPasso.isUnlocked, isTrue);

    await dao.deleteById('walk-test-1');
  });
}
