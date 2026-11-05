import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/modelos.dart';
import '../../core/tema.dart';
import '../../core/usage_service.dart';

class ProgressView extends StatefulWidget {
  final int xp;
  final int misionesCompletas;
  const ProgressView({
    super.key,
    required this.xp,
    required this.misionesCompletas,
  });

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  Map<String, dynamic>? datos;
  String? error;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    try {
      final r = await dio.get('/stats/summary', queryParameters: {
        'tz': DateTime.now().timeZoneOffset.inMinutes,
      });
      final loc = await UsageService.obtenerDistraccionesLocales();
      if (!mounted) return;
      final serverMap = Map<String, dynamic>.from(r.data);
      final distList = (serverMap['distractions'] as List?) ?? [];
      if (distList.isEmpty && loc.isNotEmpty) {
        serverMap['distractions'] = loc;
      }
      setState(() {
        datos = serverMap;
        error = null;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => error = mensajeError(e));
    }
  }

  int _n(String clave) => (datos![clave] as num).toInt();

  Widget _racha(int racha, int hoyMin) {
    final activa = racha > 0;
    String mensaje;
    if (!activa) {
      mensaje = 'Completa una sesión hoy para empezar tu racha de fuego.';
    } else if (hoyMin == 0) {
      mensaje = 'Estudia hoy para no perder tu racha de fuego.';
    } else {
      mensaje = 'Hoy ya sumaste $hoyMin min de foco. ¡Mantén la llama!';
    }
    return TarjetaJuego(
      borde: activa ? Colores.coral : Colores.borde,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: activa ? Colores.coral : Colores.noche,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activa ? Colores.sol : Colores.borde,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: activa ? Colores.coralSombra : Colores.sombraCarta,
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 40,
              color: activa ? Colores.sol : Colores.tenue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('$racha',
                        style: hud(22, color: activa ? Colores.sol : Colores.tenue)),
                    const SizedBox(width: 8),
                    Text(
                      racha == 1 ? 'DÍA SEGUIDO' : 'DÍAS SEGUIDOS',
                      style: hud(9, color: activa ? Colores.coral : Colores.tenue),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  mensaje,
                  style: const TextStyle(
                      color: Colores.luna, fontSize: 13, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(String valor, String etiqueta, IconData icono, Color colorIcono) {
    return Expanded(
      child: TarjetaJuego(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Column(
          children: [
            Icon(icono, size: 20, color: colorIcono),
            const SizedBox(height: 6),
            Text(valor, style: hud(14, color: Colores.luna)),
            const SizedBox(height: 6),
            Text(
              etiqueta,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colores.tenue, fontSize: 11, height: 1.1, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ritmo() {
    final activo = datos!['active'] == true;
    final factor = (datos!['factor'] as num).toDouble();
    final validas = _n('learning_sessions');
    String texto;
    if (factor < 0.95) {
      texto = 'Terminas más rápido de lo estimado. Tus próximas misiones saldrán con menos minutos.';
    } else if (factor > 1.05) {
      texto = 'Necesitas más tiempo del estimado. Tus próximas misiones saldrán con más minutos.';
    } else {
      texto = 'Tus estimaciones están muy ajustadas a tu ritmo real.';
    }
    return TarjetaJuego(
      borde: activo ? Colores.menta : Colores.borde,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: activo
                      ? Colores.menta.withValues(alpha: 0.2)
                      : Colores.violeta.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: activo ? Colores.menta : Colores.violeta,
                    width: 1,
                  ),
                ),
                child: Text(
                  activo ? 'APRENDIZAJE ACTIVO' : 'CALIBRANDO',
                  style: hud(7, color: activo ? Colores.menta : Colores.lila),
                ),
              ),
              const Spacer(),
              if (!activo)
                Text(
                  '$validas / 3 SESIONES',
                  style: hud(8, color: Colores.sol),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Ritmo de concentración',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (activo) ...[
            Text('${(factor * 100).round()}% del tiempo estimado',
                style: hud(12, color: Colores.sol)),
            const SizedBox(height: 6),
            Text(texto,
                style: const TextStyle(color: Colores.luna, height: 1.2, fontSize: 13)),
          ] else ...[
            BarraJuego(valor: validas / 3, color: Colores.violeta, alto: 10),
            const SizedBox(height: 8),
            Text(
              validas == 2
                  ? 'Te falta 1 sesión válida para que la IA adapte tus tiempos.'
                  : 'Te faltan ${3 - validas} sesiones válidas para que la IA adapte tus tiempos.',
              style: const TextStyle(color: Colores.tenue, height: 1.2, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _logro(IconData icono, String nombre, String desc, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ok
              ? Colores.sol.withValues(alpha: 0.1)
              : Colores.noche.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: ok ? Colores.sol.withValues(alpha: 0.5) : Colores.borde,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ok ? Colores.sol : Colores.noche,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: ok ? Colors.black.withValues(alpha: 0.3) : Colores.borde,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ok ? Colores.solSombra : Colores.sombraCarta,
                    offset: const Offset(0, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(icono, color: ok ? Colores.noche : Colores.tenue, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nombre,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ok ? Colores.luna : Colores.tenue,
                          ),
                        ),
                      ),
                      if (ok)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colores.menta,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text('LOGRADO',
                              style: hud(6, color: Colores.noche)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(color: Colores.tenue, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logros(int racha) {
    final lista = <(IconData, String, String, bool)>[
      (Icons.flag_rounded, 'Primer paso', 'Completa tu primer paso de estudio.', _n('steps_done') >= 1),
      (Icons.emoji_events_rounded, 'Misión cumplida', 'Termina todos los pasos de una misión.', widget.misionesCompletas >= 1),
      (Icons.local_fire_department_rounded, 'Constante', 'Mantén una racha de 3 días seguidos.', racha >= 3),
      (Icons.whatshot_rounded, 'Imparable', 'Mantén una racha de 7 días seguidos.', racha >= 7),
      (Icons.timer_rounded, 'Una hora de foco', 'Acumula 60 minutos de concentración.', _n('minutes') >= 60),
      (Icons.military_tech_rounded, 'Nivel 5', 'Alcanza el nivel 5 de estudiante.', widget.xp >= 400),
      (Icons.auto_awesome_rounded, 'En sincronía', 'Permite que la IA ajuste tus tiempos a tu ritmo.', datos!['active'] == true),
    ];
    final logrados = lista.where((l) => l.$4).length;

    return TarjetaJuego(
      borde: Colores.bordeBrillante,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('LOGROS Y MEDALLAS', style: hud(10, color: Colores.luna)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colores.sol.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colores.sol, width: 1),
                ),
                child: Text('$logrados/${lista.length}', style: hud(9, color: Colores.sol)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final l in lista) _logro(l.$1, l.$2, l.$3, l.$4),
        ],
      ),
    );
  }

  Widget _seccionAvanceTareas() {
    final tareas = (datos!['tasks_progress'] as List?) ?? [];
    return TarjetaJuego(
      borde: Colores.cian,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: Colores.cian, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('AVANCE DE CADA MISIÓN', style: hud(9, color: Colores.luna)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colores.cian.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${tareas.length} MISIONES', style: hud(7, color: Colores.cian)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Progreso detallado y minutos invertidos en tus misiones:',
            style: TextStyle(color: Colores.tenue, fontSize: 12),
          ),
          const SizedBox(height: 12),
          if (tareas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No tienes misiones registradas aún.',
                  style: TextStyle(color: Colores.tenue, fontSize: 13),
                ),
              ),
            )
          else
            for (final t in tareas) ...[
              Builder(builder: (ctx) {
                final totalSteps = (t['total_steps'] as num?)?.toInt() ?? 0;
                final doneSteps = (t['done_steps'] as num?)?.toInt() ?? 0;
                final totalMins = (t['total_minutes'] as num?)?.toInt() ?? 0;
                final doneMins = (t['done_minutes'] as num?)?.toInt() ?? 0;
                final status = (t['status'] ?? '').toString();
                final completa = status == 'done' || (totalSteps > 0 && doneSteps >= totalSteps);
                final enProgreso = !completa && doneSteps > 0;
                final fecha = t['scheduled_date']?.toString();
                final ratio = totalSteps == 0 ? 0.0 : (doneSteps / totalSteps).clamp(0.0, 1.0);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: completa
                        ? Colores.menta.withValues(alpha: 0.08)
                        : Colores.noche,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: completa
                          ? Colores.menta.withValues(alpha: 0.6)
                          : (enProgreso ? Colores.bordeBrillante : Colores.borde),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: completa
                                  ? Colores.menta
                                  : (enProgreso ? Colores.cian : Colores.nocheClara),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              completa ? 'LOGRADA' : (enProgreso ? 'EN FOCO' : 'PENDIENTE'),
                              style: hud(6, color: completa ? Colores.noche : (enProgreso ? Colores.noche : Colores.tenue)),
                            ),
                          ),
                          if (fecha != null && fecha.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colores.violeta.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colores.violeta.withValues(alpha: 0.5), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_month_rounded, size: 10, color: Colores.sol),
                                  const SizedBox(width: 3),
                                  Text(fecha, style: const TextStyle(color: Colores.luna, fontSize: 10, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            '${(ratio * 100).round()}%',
                            style: hud(9, color: completa ? Colores.menta : Colores.sol),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (t['title'] ?? '').toString(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colores.luna),
                      ),
                      const SizedBox(height: 8),
                      BarraJuego(valor: ratio, color: completa ? Colores.menta : Colores.cian, alto: 7),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            '$doneSteps de $totalSteps pasos',
                            style: const TextStyle(color: Colores.tenue, fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            '$doneMins de $totalMins min foco',
                            style: const TextStyle(color: Colores.sol, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
        ],
      ),
    );
  }

  Widget _seccionAppsDistractoras() {
    final distracciones = (datos!['distractions'] as List?) ?? [];
    final totalSegs = distracciones.fold<int>(0, (sum, d) => sum + ((d['seconds'] as num?)?.toInt() ?? 0));
    final totalMins = (totalSegs / 60).ceil();

    return TarjetaJuego(
      borde: distracciones.isEmpty ? Colores.menta : Colores.coral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                distracciones.isEmpty ? Icons.verified_user_rounded : Icons.shield_outlined,
                color: distracciones.isEmpty ? Colores.menta : Colores.coral,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'APLICACIONES DISTRACTORAS',
                  style: hud(9, color: distracciones.isEmpty ? Colores.menta : Colores.coral),
                ),
              ),
              if (distracciones.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colores.coral.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colores.coral, width: 1),
                  ),
                  child: Text('$totalMins MIN PERDIDOS', style: hud(7, color: Colores.coral)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (distracciones.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colores.menta.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colores.menta.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colores.menta, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '¡Excelente disciplina! No se registraron aplicaciones distractoras durante tus sesiones de enfoque.',
                      style: TextStyle(color: Colores.luna, fontSize: 13, height: 1.25),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text(
              'Aplicaciones que interrumpieron o consumieron tu atención mientras estudiabas:',
              style: TextStyle(color: Colores.tenue, fontSize: 12),
            ),
            const SizedBox(height: 12),
            for (final d in distracciones) ...[
              Builder(builder: (ctx) {
                final nom = (d['name'] ?? d['package'] ?? 'Desconocida').toString();
                final segs = (d['seconds'] as num?)?.toInt() ?? 0;
                final mins = (segs / 60).ceil();
                final count = (d['count'] as num?)?.toInt() ?? 1;
                final inicial = nom.isNotEmpty ? nom.substring(0, 1).toUpperCase() : '?';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colores.noche,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colores.borde, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colores.coral.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colores.coral.withValues(alpha: 0.6), width: 1),
                        ),
                        child: Center(
                          child: Text(inicial, style: hud(12, color: Colores.coral)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nom,
                              style: const TextStyle(color: Colores.luna, fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Detectada en $count ${count == 1 ? 'sesión' : 'sesiones'}',
                              style: const TextStyle(color: Colores.tenue, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colores.coral.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colores.coral.withValues(alpha: 0.5), width: 1),
                        ),
                        child: Text(
                          '$mins min',
                          style: hud(8, color: Colores.coral),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 6),
            const Text(
              '💡 Consejo: Puedes bloquear estas aplicaciones o activar el Launcher en la pestaña Bloqueo.',
              style: TextStyle(color: Colores.tenue, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (error != null && datos == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colores.coral)),
              const SizedBox(height: 14),
              BotonJuego(texto: 'Reintentar', expandir: false, onPressed: cargar),
            ],
          ),
        ),
      );
    }
    if (datos == null) {
      return const Center(child: CircularProgressIndicator(color: Colores.sol));
    }
    final racha = _n('streak');
    return RefreshIndicator(
      onRefresh: cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          _racha(racha, _n('today_minutes')),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tile('${_n('sessions')}', 'Sesiones', Icons.play_circle_outline_rounded, Colores.menta),
              const SizedBox(width: 8),
              _tile('${_n('minutes')}', 'Minutos Foco', Icons.timer_outlined, Colores.cian),
              const SizedBox(width: 8),
              _tile('${_n('steps_done')}', 'Pasos Hechos', Icons.task_alt_rounded, Colores.sol),
            ],
          ),
          const SizedBox(height: 14),
          _ritmo(),
          const SizedBox(height: 14),
          _seccionAvanceTareas(),
          const SizedBox(height: 14),
          _seccionAppsDistractoras(),
          const SizedBox(height: 14),
          _logros(racha),
        ],
      ),
    );
  }
}
