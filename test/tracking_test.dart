import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/models/user_progress.dart';
import 'package:caminhandojuntos/providers/dashboard_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tracking & Dashboard Unit Tests', () {
    test('Calcula distancia total em metros a partir do mapPath', () {
      final state = TrackingState(
        mapPath: const [
          LatLng(-23.550520, -46.633308), // São Paulo
          LatLng(-23.551520, -46.633308), // ~111 metros ao sul
        ],
      );

      final distanceMeters = state.totalDistanceMeters;
      expect(distanceMeters, greaterThan(100));
      expect(distanceMeters, lessThan(120));
    });

    test('DashboardNotifier adiciona caminhada concluida corretamente', () {
      final notifier = DashboardNotifier();
      expect(notifier.state.progress.coins, equals(0));
      expect(notifier.state.progress.distanceKm, equals(0.0));

      notifier.addCompletedWalk(
        distanceKm: 1.5,
        coins: 15,
        durationMinutes: 20,
      );

      expect(notifier.state.progress.coins, equals(15));
      expect(notifier.state.progress.distanceKm, equals(1.5));
      expect(notifier.state.progress.durationMinutes, equals(20));
    });

    test('DashboardNotifier resets steps and daily metrics on day change while preserving coins', () {
      final notifier = DashboardNotifier();
      
      // Simulate progress from a previous day
      final oldProgress = UserProgress(
        steps: 4000,
        goalSteps: 5000,
        coins: 50,
        distanceKm: 3.5,
        durationMinutes: 45,
        calories: 200,
        lastDate: '2020-01-01',
      );
      
      notifier.updateProgressFromServer(oldProgress);
      expect(notifier.state.progress.steps, equals(4000));
      expect(notifier.state.progress.coins, equals(50));

      // Trigger day check (e.g. by adding steps or checking day change)
      notifier.addSteps(100);

      // Steps should have reset to 0 plus the 100 new steps = 100 steps
      // Coins should be preserved (50)
      // Daily distance, duration, calories should be reset
      expect(notifier.state.progress.steps, equals(100));
      expect(notifier.state.progress.coins, equals(50));
      expect(notifier.state.progress.distanceKm, equals(0.0));
      expect(notifier.state.progress.durationMinutes, equals(0));
      expect(notifier.state.progress.calories, equals(0));
      expect(notifier.state.progress.goalSteps, equals(5000));
    });
  });
}
