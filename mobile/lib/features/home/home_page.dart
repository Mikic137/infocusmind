import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/modelos.dart';
import '../../core/tema.dart';
import '../auth/auth_page.dart';
import '../distractions/distraction_settings_page.dart';
import '../focus/focus_page.dart';
import '../roadmap/roadmap_view.dart';
import '../progress/progress_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Tarea> tareas = [];
  bool cargando = true;
  bool creando = false;
  String? error;
  int pestana = 0;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  void aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> salir() async {
    await AuthService.cerrarSesion();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const AuthPage()));
  }

  Future<void> cargar() async {
    try {
      final r = await dio.get('/tasks');
      final lista = <Tarea>[];
      for (final t in r.data['tasks'] as List) {
        lista.add(Tarea(t['id'], t['title'], [
          for (final s in t['steps'] as List)
            Paso(s['id'], s['title'], s['minutes'], s['done'] == true)
        ]));
      }
      if (!mounted) return;
      setState(() {
        tareas = lista;
        cargando = false;
        error = null;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 401) {
        await salir();
        return;
      }
      setState(() {
        cargando = false;
        error = mensajeError(e);
      });
    }
  }

  Future<void> nuevaTarea() async {
    final titulo = TextEditingController();
    final detalles = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('NUEVA MISIÓN', style: hud(12, color: Colores.sol)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titulo,
                maxLength: 200,
                decoration: const InputDecoration(
                    labelText: '¿Qué tienes que hacer?', counterText: ''),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detalles,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Detalles (fecha, tema...)', counterText: ''),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colores.violeta,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Dividir con IA')),
        ],
      ),
    );
    final t = titulo.text.trim();
    final d = detalles.text.trim();
    if (ok != true || t.isEmpty) return;

    setState(() => creando = true);
    try {
      final r = await dio.post('/tasks', data: {'title': t, 'details': d});
      await cargar();
      if (mounted && r.data['adjusted'] == true) {
        final pct = ((r.data['factor'] as num) * 100).round();
        aviso('Ajustamos los tiempos al $pct% según tu ritmo real.');
      }
    } on DioException catch (e) {
      if (mounted) aviso(mensajeError(e));
    } finally {
      if (mounted) setState(() => creando = false);
    }
  }

  Future<void> marcar(Tarea tarea, Paso paso, bool valor) async {
    setState(() => paso.hecho = valor);
    try {
      await dio.patch('/tasks/${tarea.id}/steps/${paso.id}',
          data: {'done': valor});
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => paso.hecho = !valor);
      aviso(mensajeError(e));
    }
  }

  Future<void> iniciarSesion(Tarea tarea, Paso paso) async {
    try {
      final r = await dio.post('/sessions', data: {'step_id': paso.id});
      if (!mounted) return;
      final terminada = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => FocusPage(
            sesionId: r.data['id'],
            titulo: paso.titulo,
            minutos: r.data['est_minutes'],
          ),
        ),
      );
      if (terminada == true) await cargar();
    } on DioException catch (e) {
      if (mounted) aviso(mensajeError(e));
    }
  }

  Future<void> eliminar(Tarea tarea) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿ELIMINAR MISIÓN?', style: hud(11, color: Colores.coral)),
        content: Text(tarea.titulo),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colores.coral,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (seguro != true) return;
    try {
      await dio.delete('/tasks/${tarea.id}');
      if (!mounted) return;
      setState(() => tareas.remove(tarea));
    } on DioException catch (e) {
      if (mounted) aviso(mensajeError(e));
    }
  }

  Widget fila(Tarea t, Paso p) {
    final esActual = !p.hecho && identical(p, t.siguiente);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: esActual
            ? Colores.violeta.withValues(alpha: 0.16)
            : (p.hecho ? Colors.transparent : Colores.noche.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: esActual
              ? Colores.cian
              : (p.hecho ? Colors.transparent : Colores.borde),
          width: esActual ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Checkbox cuadrado tipo pixel
          GestureDetector(
            onTap: () => marcar(t, p, !p.hecho),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: p.hecho ? Colores.menta : Colores.noche,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: p.hecho
                      ? Colores.mentaSombra
                      : (esActual ? Colores.cian : Colores.bordeBrillante),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: p.hecho ? Colores.mentaSombra : Colores.sombraCarta,
                    offset: const Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: p.hecho
                  ? const Icon(Icons.check_rounded, size: 20, color: Colores.noche)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Título y Chips retro de Tiempo y XP
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.titulo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: esActual ? FontWeight.w700 : FontWeight.w500,
                    height: 1.2,
                    color: p.hecho
                        ? Colores.tenue
                        : (esActual ? Colores.luna : Colores.luna.withValues(alpha: 0.95)),
                    decoration: p.hecho ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Chip minutos
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colores.noche,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colores.borde, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded, size: 12, color: Colores.tenue),
                          const SizedBox(width: 4),
                          Text('${p.minutos} min',
                              style: const TextStyle(
                                  color: Colores.tenue, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Chip XP
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colores.sol.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: Colores.sol.withValues(alpha: 0.7), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 13, color: Colores.sol),
                          const SizedBox(width: 2),
                          Text('+${p.minutos} XP',
                              style: const TextStyle(
                                  color: Colores.sol, fontSize: 11, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    if (esActual) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colores.cian,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text('ACTUAL', style: hud(7, color: Colores.noche)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Botón Arcade de Iniciar Sesión con animación de pulso si es el actual
          if (!p.hecho)
            _PulsoBoton(
              activo: esActual,
              child: GestureDetector(
                onTap: () => iniciarSesion(t, p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: esActual ? Colores.sol : Colores.violeta,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: esActual ? Colores.solSombra : Colores.violetaSombra,
                        offset: const Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: esActual ? Colores.noche : Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget tarjeta(Tarea t) {
    final progreso = t.pasos.isEmpty ? 0.0 : t.hechos / t.pasos.length;
    final porcentaje = (progreso * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TarjetaJuego(
        borde: t.completa
            ? Colores.menta
            : (t.siguiente != null ? Colores.bordeBrillante : Colores.borde),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de la misión
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.completa
                        ? Colores.menta.withValues(alpha: 0.2)
                        : Colores.cian.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: t.completa ? Colores.menta : Colores.cian,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    t.completa ? 'LOGRADA' : 'MISIÓN',
                    style: hud(8, color: t.completa ? Colores.menta : Colores.cian),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colores.tenue, size: 22),
                  tooltip: 'Eliminar misión',
                  onPressed: () => eliminar(t),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Barra de progreso y contador
            Row(
              children: [
                Expanded(
                  child: BarraJuego(
                    valor: progreso,
                    color: t.completa ? Colores.menta : Colores.cian,
                    alto: 8,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$porcentaje%',
                  style: hud(9, color: t.completa ? Colores.menta : Colores.sol),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${t.hechos} de ${t.pasos.length} pasos completados (${t.minutosTotales} min foco)',
              style: const TextStyle(color: Colores.tenue, fontSize: 13),
            ),
            const SizedBox(height: 10),
            const Divider(color: Colores.borde, height: 1),
            const SizedBox(height: 8),
            for (final p in t.pasos) fila(t, p),
          ],
        ),
      ),
    );
  }

  Widget cuerpo() {
    if (cargando) {
      return const Center(child: CircularProgressIndicator(color: Colores.sol));
    }
    if (error != null && tareas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colores.coral)),
              const SizedBox(height: 12),
              BotonJuego(
                  texto: 'Reintentar', expandir: false, onPressed: cargar),
            ],
          ),
        ),
      );
    }
    if (pestana == 3) {
      return const DistractionSettingsPage(embedded: true);
    }
    if (pestana == 2) {
      return ProgressView(
        xp: xpTotal(tareas),
        misionesCompletas: tareas.where((t) => t.completa).length,
      );
    }
    if (pestana == 1) {
      return RoadmapView(tareas: tareas, onIniciar: iniciarSesion);
    }
    return RefreshIndicator(
      onRefresh: cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: tareas.isEmpty
            ? const [
                Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'Aún no tienes misiones.\nToca «Nueva misión» y la IA la dividirá en pasos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colores.tenue),
                  ),
                )
              ]
            : [for (final t in tareas) tarjeta(t)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colores.cian, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/images/logo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.psychology, size: 20, color: Colores.cian),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text('InfocusMind', style: hud(13, color: Colores.luna)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              pestana == 3 ? Icons.shield_rounded : Icons.shield_outlined,
              color: pestana == 3 ? Colores.sol : Colores.cian,
            ),
            tooltip: 'Control de distracciones',
            onPressed: () {
              setState(() => pestana = 3);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colores.tenue),
            tooltip: 'Cerrar sesión',
            onPressed: salir,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: HudNivel(xp: xpTotal(tareas)),
          ),
          if (creando)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TarjetaJuego(
                borde: Colores.sol,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: Colores.sol),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'LA IA ESTÁ CREANDO TU MISIÓN...',
                        style: GoogleFonts.pressStart2p(fontSize: 9, color: Colores.sol),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: cuerpo()),
        ],
      ),
      floatingActionButton: pestana == 0
          ? BotonJuego(
              texto: 'Nueva misión',
              icono: Icons.add_rounded,
              color: Colores.violeta,
              sombra: Colores.violetaSombra,
              expandir: false,
              onPressed: creando ? null : nuevaTarea,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: pestana,
        onDestinationSelected: (i) => setState(() => pestana = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.checklist_rounded), label: 'Misiones'),
          NavigationDestination(icon: Icon(Icons.map_rounded), label: 'Mapa'),
          NavigationDestination(
              icon: Icon(Icons.emoji_events_rounded), label: 'Logros'),
          NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield_rounded),
              label: 'Bloqueo'),
        ],
      ),
    );
  }
}

class _PulsoBoton extends StatefulWidget {
  final Widget child;
  final bool activo;
  const _PulsoBoton({required this.child, required this.activo});
  @override
  State<_PulsoBoton> createState() => _PulsoBotonState();
}

class _PulsoBotonState extends State<_PulsoBoton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);
  late final Animation<double> _s = Tween<double>(begin: 1.0, end: 1.08)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.activo) return widget.child;
    return ScaleTransition(scale: _s, child: widget.child);
  }
}
