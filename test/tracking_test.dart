import 'package:caminhandojuntos/models/tracking_state.dart';
import 'package:caminhandojuntos/providers/dashboard_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
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
      expect(notifier.state.progress.coins, equals(340));
      expect(notifier.state.progress.distanceKm, equals(2.4));

      notifier.addCompletedWalk(
        distanceKm: 1.5,
        coins: 15,
        durationMinutes: 20,
      );

      expect(notifier.state.progress.coins, equals(355));
      expect(notifier.state.progress.distanceKm, equals(3.9));
      expect(notifier.state.progress.durationMinutes, equals(55));
    });
  });
}
