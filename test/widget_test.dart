import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caminhandojuntos/main.dart';

void main() {
  testWidgets('Aplicativo inicializa corretamente no ProviderScope', (WidgetTester tester) async {
    // Força o empacotamento dos métodos de inicialização concorrentes para não dispararem I/O real na árvore de teste de widgets simulada
    await tester.pumpWidget(
      const ProviderScope(
        child: CaminhaJuntosApp(),
      ),
    );

    // Como o Future.wait roda de forma concorrente em paralelo, verificamos se a UI renderiza o estado de fumaça inicial estável
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
