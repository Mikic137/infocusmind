import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/modelos.dart';
import '../../core/tema.dart';

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
      if (!mounted) return;
      setState(() {
        datos = Map<String, dynamic>.from(r.data);
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
          _logros(racha),
        ],
      ),
    );
  }
}
