import 'package:flutter/material.dart';
import '../../core/modelos.dart';
import '../../core/tema.dart';

const _xs = [0.5, 0.2, 0.5, 0.8];
const _alto = 118.0;

enum _Estado { hecho, actual, pendiente, meta, metaLograda }

class RoadmapView extends StatelessWidget {
  final List<Tarea> tareas;
  final void Function(Tarea, Paso) onIniciar;
  const RoadmapView({super.key, required this.tareas, required this.onIniciar});

  @override
  Widget build(BuildContext context) {
    if (tareas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 64, color: Colores.tenue),
              const SizedBox(height: 16),
              const Text(
                'Tu mapa está vacío.\nCrea una misión y aparecerá aquí como un camino de niveles.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colores.tenue),
              ),
            ],
          ),
        ),
      );
    }
    final pendientes = tareas.where((t) => !t.completa).toList();
    final completas = tareas.where((t) => t.completa).toList();
    final orden = [...pendientes, ...completas];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      children: [
        for (final t in orden) _Zona(tarea: t, onIniciar: onIniciar),
      ],
    );
  }
}

class _Zona extends StatelessWidget {
  final Tarea tarea;
  final void Function(Tarea, Paso) onIniciar;
  const _Zona({required this.tarea, required this.onIniciar});

  @override
  Widget build(BuildContext context) {
    final n = tarea.pasos.length;
    final actual = tarea.siguiente;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TarjetaJuego(
          borde: tarea.completa ? Colores.menta : Colores.bordeBrillante,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: tarea.completa
                      ? Colores.menta.withValues(alpha: 0.2)
                      : Colores.sol.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: tarea.completa ? Colores.menta : Colores.sol,
                    width: 1,
                  ),
                ),
                child: Text(
                  tarea.completa ? 'COMPLETA' : 'EN RUTA',
                  style: hud(7, color: tarea.completa ? Colores.menta : Colores.sol),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tarea.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, height: 1.1),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colores.noche,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colores.borde, width: 1),
                ),
                child: Text(
                  '${tarea.hechos}/$n',
                  style: hud(10,
                      color: tarea.completa ? Colores.menta : Colores.sol),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: _alto * (n + 1) + 20,
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final puntos = [
              for (var i = 0; i <= n; i++)
                Offset(w * _xs[i % 4], _alto * i + _alto / 2)
            ];
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CaminoPainter(
                        puntos, [for (final p in tarea.pasos) p.hecho]),
                  ),
                ),
                for (var i = 0; i < n; i++)
                  _Nodo(
                    centro: puntos[i],
                    etiqueta: tarea.pasos[i].titulo,
                    estado: tarea.pasos[i].hecho
                        ? _Estado.hecho
                        : (identical(tarea.pasos[i], actual)
                            ? _Estado.actual
                            : _Estado.pendiente),
                    onTap: tarea.pasos[i].hecho
                        ? null
                        : () => onIniciar(tarea, tarea.pasos[i]),
                  ),
                _Nodo(
                  centro: puntos[n],
                  etiqueta: tarea.completa ? '¡Misión Cumplida!' : 'Meta Final',
                  estado: tarea.completa ? _Estado.metaLograda : _Estado.meta,
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _Nodo extends StatelessWidget {
  final Offset centro;
  final String etiqueta;
  final _Estado estado;
  final VoidCallback? onTap;
  const _Nodo({
    required this.centro,
    required this.etiqueta,
    required this.estado,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color fondo = Colores.nocheClara;
    Color sombra = Colores.sombraCarta;
    Color colorIcono = Colores.tenue;
    IconData forma = Icons.play_arrow_rounded;
    Color bordeColor = Colores.borde;

    if (estado == _Estado.hecho) {
      fondo = Colores.menta;
      sombra = Colores.mentaSombra;
      colorIcono = Colores.noche;
      forma = Icons.check_rounded;
      bordeColor = Colores.mentaSombra;
    } else if (estado == _Estado.actual) {
      fondo = Colores.sol;
      sombra = Colores.solSombra;
      colorIcono = Colores.noche;
      bordeColor = Colores.cian;
    } else if (estado == _Estado.meta) {
      forma = Icons.flag_rounded;
      fondo = Colores.noche;
      bordeColor = Colores.borde;
    } else if (estado == _Estado.metaLograda) {
      fondo = Colores.sol;
      sombra = Colores.solSombra;
      colorIcono = Colores.noche;
      forma = Icons.emoji_events_rounded;
      bordeColor = Colores.cian;
    }

    Widget token = Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bordeColor, width: estado == _Estado.actual ? 3 : 2),
        boxShadow: [
          BoxShadow(
            color: sombra,
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Icon(forma, size: 32, color: colorIcono),
    );

    if (estado == _Estado.actual) {
      token = _Pulso(child: token);
    }

    return Positioned(
      left: centro.dx - 60,
      top: centro.dy - 32,
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(onTap: onTap, child: token),
          const SizedBox(height: 6),
          if (estado == _Estado.actual)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colores.cian,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('¡AQUÍ!', style: hud(7, color: Colores.noche)),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colores.noche.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colores.borde, width: 1),
            ),
            child: Text(
              etiqueta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.1,
                color: estado == _Estado.hecho ? Colores.tenue : Colores.luna,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El nodo del paso siguiente late suavemente (estilo pulso arcade).
class _Pulso extends StatefulWidget {
  final Widget child;
  const _Pulso({required this.child});
  @override
  State<_Pulso> createState() => _PulsoState();
}

class _PulsoState extends State<_Pulso> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);
  late final Animation<double> _escala = Tween<double>(begin: 1.0, end: 1.08)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return ScaleTransition(scale: _escala, child: widget.child);
  }
}

class _CaminoPainter extends CustomPainter {
  final List<Offset> p;
  final List<bool> hecho;
  _CaminoPainter(this.p, this.hecho);

  @override
  void paint(Canvas canvas, Size size) {
    final rutaBorde = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..color = Colores.sombraCarta;

    final ruta = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = Colores.borde;

    for (var i = 0; i < p.length - 1; i++) {
      final a = p[i];
      final b = p[i + 1];
      final medio = (a.dy + b.dy) / 2;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, medio, b.dx, medio, b.dx, b.dy);

      // Sombra exterior de la pista
      canvas.drawPath(path, rutaBorde);
      // Carretera base
      canvas.drawPath(path, ruta);

      final linea = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = hecho[i]
            ? Colores.menta
            : Colores.cian.withValues(alpha: 0.35);

      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 22) {
          final fin = d + 11 > m.length ? m.length : d + 11;
          canvas.drawPath(m.extractPath(d, fin), linea);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CaminoPainter old) => true;
}
