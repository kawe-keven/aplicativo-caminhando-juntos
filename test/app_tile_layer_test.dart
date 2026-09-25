import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:caminhandojuntos/widgets/app_tile_layer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTileLayer Tests', () {
    test('Builds TileLayer successfully', () {
      final tileLayer = AppTileLayer.build(isHighContrast: false);
      expect(tileLayer, isA<TileLayer>());
    });

    test('Attributions return expected sources', () {
      final attributions = AppTileLayer.getAttributions(const MockBuildContext());
      expect(attributions, isNotEmpty);
    });
  });
}

class MockBuildContext extends StatelessWidget implements BuildContext {
  const MockBuildContext({super.key});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
