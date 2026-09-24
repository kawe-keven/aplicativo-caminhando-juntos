import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:caminhandojuntos/widgets/app_tile_layer.dart';
import 'package:caminhandojuntos/config/mapbox_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTileLayer Tests', () {
    test('Builds TileLayer successfully', () {
      final tileLayer = AppTileLayer.build(isHighContrast: false);
      expect(tileLayer, isA<TileLayer>());
    });

    test('Attributions return expected sources', () {
      final attributions = AppTileLayer.getAttributions(MockBuildContext());
      expect(attributions, isNotEmpty);
    });
  });
}

class MockBuildContext extends StatelessWidget implements BuildContext {
  @override
  // TODO: implement buildContext
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
