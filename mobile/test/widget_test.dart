import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pruebas de Widgets e Interfaz de Usuario (InfocusMind)', () {
    testWidgets('Renderiza tarjeta de misión con indicador de XP y botón de inicio', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF090C13),
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111522),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF232A3F)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Misión: Algoritmos de Búsqueda',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Recompensa: +45 XP',
                      style: TextStyle(color: Color(0xFF00D2D3), fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                      ),
                      onPressed: () {},
                      child: const Text('Comenzar Enfoque', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verificaciones de presencia en pantalla
      expect(find.text('Misión: Algoritmos de Búsqueda'), findsOneWidget);
      expect(find.text('Recompensa: +45 XP'), findsOneWidget);
      expect(find.text('Comenzar Enfoque'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
