import 'package:dio/dio.dart';

class Paso {
  final int id;
  final String titulo;
  final int minutos;
  bool hecho;
  Paso(this.id, this.titulo, this.minutos, this.hecho);
}

class Tarea {
  final int id;
  final String titulo;
  final List<Paso> pasos;
  final String? fechaProgramada;
  Tarea(this.id, this.titulo, this.pasos, {this.fechaProgramada});

  int get hechos => pasos.where((p) => p.hecho).length;
  int get minutosTotales => pasos.fold(0, (s, p) => s + p.minutos);
  bool get completa => pasos.isNotEmpty && hechos == pasos.length;

  Paso? get siguiente {
    for (final p in pasos) {
      if (!p.hecho) return p;
    }
    return null;
  }
}

/// Cada paso completado da tantos XP como minutos estimados.
int xpTotal(List<Tarea> tareas) {
  var total = 0;
  for (final t in tareas) {
    for (final p in t.pasos) {
      if (p.hecho) total += p.minutos;
    }
  }
  return total;
}

String mensajeError(DioException e) {
  final datos = e.response?.data;
  if (datos is Map && datos['error'] != null) return datos['error'].toString();
  return 'No se pudo conectar con el servidor';
}