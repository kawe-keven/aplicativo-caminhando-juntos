import 'package:flutter_test/flutter_test.dart';
import 'package:caminhandojuntos/services/local_tile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CircuitBreakerState Tests', () {
    test('Starts in closed state and allows attempts', () {
      final cb = CircuitBreakerState();
      expect(cb.state, 'closed');
      expect(cb.canAttempt(), true);
    });

    test('Opens after 10 consecutive failures', () {
      final cb = CircuitBreakerState();
      for (int i = 0; i < 10; i++) {
        cb.recordFailure();
      }
      expect(cb.state, 'open');
      expect(cb.canAttempt(), false);
    });

    test('Transitions to halfOpen after timeout', () {
      final cb = CircuitBreakerState();
      for (int i = 0; i < 10; i++) {
        cb.recordFailure();
      }
      // Force openUntil to the past
      cb.openUntil = DateTime.now().subtract(const Duration(seconds: 1));
      expect(cb.canAttempt(), true);
      expect(cb.state, 'halfOpen');
    });

    test('Resets on success', () {
      final cb = CircuitBreakerState();
      cb.recordFailure();
      cb.recordSuccess();
      expect(cb.state, 'closed');
      expect(cb.consecutiveFailures, 0);
    });
  });
}
