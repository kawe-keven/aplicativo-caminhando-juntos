import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caminhandojuntos/providers/dashboard_provider.dart';
import 'package:caminhandojuntos/providers/store_provider.dart';
import 'package:caminhandojuntos/providers/achievements_provider.dart';
import 'package:caminhandojuntos/models/reward.dart';
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

  test('DashboardProvider initial state and actions', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(dashboardProvider);
    expect(state.progress, isNotNull);
    expect(state.isRedeeming, isFalse);
    expect(state.error, isNull);

    container.read(dashboardProvider.notifier).addSteps(100);
    expect(container.read(dashboardProvider).progress.steps, greaterThan(3850));

    container.read(dashboardProvider.notifier).addCompletedWalk(
      distanceKm: 1.5,
      coins: 15,
      durationMinutes: 15,
    );
    expect(container.read(dashboardProvider).progress.coins, greaterThan(340));
  });

  test('StoreProvider initial state and filtering', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final rewards = container.read(storeProvider);
    expect(rewards, isNotEmpty);

    container.read(storeFilterProvider.notifier).state = RewardCategory.popular;
    final filtered = container.read(filteredRewardsProvider);
    expect(filtered, isNotEmpty);
    expect(filtered.every((r) => r.category == RewardCategory.popular), isTrue);
  });

  test('AchievementsProvider initial state and count', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final achievements = container.read(achievementsProvider);
    expect(achievements, isNotEmpty);

    final notifier = container.read(achievementsProvider.notifier);
    expect(notifier.totalCount, equals(6));
  });
}
