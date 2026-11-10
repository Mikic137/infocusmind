import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/modelos.dart';

void main() {
  group('Pruebas Unitarias - Modelo de Tareas y Gamificación (InfocusMind)', () {
    test('Calcula correctamente minutos totales, completitud y siguiente paso', () {
      final pasos = [
        Paso(1, 'Leer capítulo 3 de Sistemas Distribuidos', 25, true),
        Paso(2, 'Elaborar diagrama de arquitectura', 30, false),
        Paso(3, 'Configurar Docker Compose y PostgreSQL', 45, false),
      ];

      final tarea = Tarea(101, 'Práctica 2 de Aplicaciones Móviles', pasos, fechaProgramada: '2026-11-10');

      expect(tarea.minutosTotales, equals(100));
      expect(tarea.hechos, equals(1));
      expect(tarea.completa, isFalse);
      expect(tarea.siguiente?.id, equals(2));
      expect(tarea.siguiente?.titulo, equals('Elaborar diagrama de arquitectura'));

      // Marcar pasos restantes como completados
      pasos[1].hecho = true;
      pasos[2].hecho = true;

      expect(tarea.hechos, equals(3));
      expect(tarea.completa, isTrue);
      expect(tarea.siguiente, isNull);
    });

    test('Cálculo de XP total según minutos de pasos finalizados', () {
      final tarea1 = Tarea(1, 'Revisión bibliográfica', [
        Paso(1, 'Buscar papers IEEE', 20, true),
        Paso(2, 'Resumir conclusiones', 15, false),
      ]);

      final tarea2 = Tarea(2, 'Modelado UI en Flutter', [
        Paso(3, 'Diseñar widgets de la pantalla de inicio', 40, true),
        Paso(4, 'Crear vistas de autenticación', 25, true),
      ]);

      final totalXp = xpTotal([tarea1, tarea2]);
      // XP = 20 (paso 1) + 40 (paso 3) + 25 (paso 4) = 85 XP
      expect(totalXp, equals(85));
    });

    test('Tarea sin pasos tiene 0 minutos y no está completa', () {
      final tareaVacia = Tarea(99, 'Tarea vacía', []);
      expect(tareaVacia.minutosTotales, equals(0));
      expect(tareaVacia.hechos, equals(0));
      expect(tareaVacia.completa, isFalse);
      expect(tareaVacia.siguiente, isNull);
    });
  });
}
