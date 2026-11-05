import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/modelos.dart';
import '../../core/tema.dart';
import '../assistant/assistant_view.dart';
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
        lista.add(Tarea(
          t['id'],
          t['title'],
          [
            for (final s in t['steps'] as List)
              Paso(s['id'], s['title'], s['minutes'], s['done'] == true)
          ],
          fechaProgramada: t['scheduled_date']?.toString(),
        ));
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
    final datos = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => const _DialogoNuevaMisionManual(),
    );
    if (datos == null) return;

    setState(() => creando = true);
    try {
      await dio.post('/tasks/manual', data: datos);
      await cargar();
      if (mounted) aviso('¡Misión agregada exitosamente!');
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${t.hechos} de ${t.pasos.length} pasos completados (${t.minutosTotales} min foco)',
                    style: const TextStyle(color: Colores.tenue, fontSize: 13),
                  ),
                ),
                if (t.fechaProgramada != null && t.fechaProgramada!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colores.violeta.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colores.violeta.withValues(alpha: 0.6), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 12, color: Colores.sol),
                        const SizedBox(width: 4),
                        Text(
                          t.fechaProgramada!,
                          style: const TextStyle(
                            color: Colores.luna,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
    if (pestana == 4) {
      return const DistractionSettingsPage(embedded: true);
    }
    if (pestana == 3) {
      return ProgressView(
        xp: xpTotal(tareas),
        misionesCompletas: tareas.where((t) => t.completa).length,
      );
    }
    if (pestana == 2) {
      return RoadmapView(tareas: tareas, onIniciar: iniciarSesion);
    }
    if (pestana == 1) {
      return AssistantView(
        onMisionCreada: cargar,
        onIrAMisiones: () => setState(() => pestana = 0),
      );
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
                    'Aún no tienes misiones.\nToca «Nueva misión» para crear una manualmente\no usa la pestaña «Ayudante» para dividirlas con IA.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colores.tenue),
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
              pestana == 4 ? Icons.shield_rounded : Icons.shield_outlined,
              color: pestana == 4 ? Colores.sol : Colores.cian,
            ),
            tooltip: 'Control de distracciones',
            onPressed: () {
              setState(() => pestana = 4);
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
                        'GUARDANDO TU MISIÓN...',
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
          NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy_rounded),
              label: 'Ayudante'),
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

class _DialogoNuevaMisionManual extends StatefulWidget {
  const _DialogoNuevaMisionManual();

  @override
  State<_DialogoNuevaMisionManual> createState() => _DialogoNuevaMisionManualState();
}

class _DialogoNuevaMisionManualState extends State<_DialogoNuevaMisionManual> {
  final tituloCtrl = TextEditingController();
  final detallesCtrl = TextEditingController();
  final minutosPersonalizadosCtrl = TextEditingController();
  int minutosSeleccionados = 25;
  bool duracionPersonalizada = false;
  DateTime fechaSeleccionada = DateTime.now();

  bool expandirPasos = false;
  final List<TextEditingController> pasosTitulos = [];
  final List<int> pasosMinutos = [];

  final duracionesRapidas = [15, 25, 30, 45, 60];

  @override
  void dispose() {
    tituloCtrl.dispose();
    detallesCtrl.dispose();
    minutosPersonalizadosCtrl.dispose();
    for (final c in pasosTitulos) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> elegirFecha() async {
    final ahora = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada,
      firstDate: ahora.subtract(const Duration(days: 30)),
      lastDate: ahora.add(const Duration(days: 365)),
      helpText: 'CALENDARIO DE MISIÓN',
      cancelText: 'CANCELAR',
      confirmText: 'SELECCIONAR',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colores.cian,
              onPrimary: Colores.noche,
              surface: Colores.nocheClara,
              onSurface: Colores.luna,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colores.nocheClara),
          ),
          child: child!,
        );
      },
    );
    if (f != null) {
      setState(() => fechaSeleccionada = f);
    }
  }

  String textoFecha(DateTime d) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final comp = DateTime(d.year, d.month, d.day);
    if (comp == hoy) return 'Hoy (${d.day}/${d.month})';
    if (comp == hoy.add(const Duration(days: 1))) return 'Mañana (${d.day}/${d.month})';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  void agregarPasoManual() {
    setState(() {
      pasosTitulos.add(TextEditingController());
      pasosMinutos.add(15);
    });
  }

  void quitarPaso(int index) {
    setState(() {
      pasosTitulos[index].dispose();
      pasosTitulos.removeAt(index);
      pasosMinutos.removeAt(index);
    });
  }

  void guardar() {
    final t = tituloCtrl.text.trim();
    if (t.isEmpty) return;

    var mins = minutosSeleccionados;
    if (duracionPersonalizada) {
      final p = int.tryParse(minutosPersonalizadosCtrl.text.trim());
      if (p != null && p > 0) mins = p.clamp(1, 480);
    }

    final fechaStr =
        '${fechaSeleccionada.year}-${fechaSeleccionada.month.toString().padLeft(2, '0')}-${fechaSeleccionada.day.toString().padLeft(2, '0')}';

    final pasos = <Map<String, dynamic>>[];
    for (var i = 0; i < pasosTitulos.length; i++) {
      final st = pasosTitulos[i].text.trim();
      if (st.isNotEmpty) {
        pasos.add({'title': st, 'minutes': pasosMinutos[i]});
      }
    }

    Navigator.pop(context, {
      'title': t,
      'details': detallesCtrl.text.trim(),
      'minutes': mins,
      'scheduled_date': fechaStr,
      'steps': pasos,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colores.nocheClara,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Colores.cian, width: 2),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colores.violeta.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.edit_calendar_rounded, color: Colores.sol, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('NUEVA MISIÓN', style: hud(12, color: Colores.sol))),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              TextField(
                controller: tituloCtrl,
                maxLength: 200,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '¿Qué tienes que hacer?',
                  hintText: 'Ej: Leer capítulo 3 de Historia',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),

              // Selector de Fecha con Calendario
              Text('FECHA DE REALIZACIÓN', style: hud(8, color: Colores.luna)),
              const SizedBox(height: 6),
              InkWell(
                onTap: elegirFecha,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colores.noche,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colores.bordeBrillante, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Colores.cian, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          textoFecha(fechaSeleccionada),
                          style: const TextStyle(
                            color: Colores.luna,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text('CAMBIAR', style: hud(8, color: Colores.cian)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Selector de Duración / Tiempo
              Text('DURACIÓN ESTIMADA', style: hud(8, color: Colores.luna)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final d in duracionesRapidas)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          minutosSeleccionados = d;
                          duracionPersonalizada = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (!duracionPersonalizada && minutosSeleccionados == d)
                              ? Colores.violeta
                              : Colores.noche,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: (!duracionPersonalizada && minutosSeleccionados == d)
                                ? Colores.cian
                                : Colores.borde,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '$d min',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: (!duracionPersonalizada && minutosSeleccionados == d)
                                ? Colors.white
                                : Colores.tenue,
                          ),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      setState(() => duracionPersonalizada = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: duracionPersonalizada ? Colores.violeta : Colores.noche,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: duracionPersonalizada ? Colores.cian : Colores.borde,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'Otro',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: duracionPersonalizada ? Colors.white : Colores.tenue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (duracionPersonalizada) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: minutosPersonalizadosCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Minutos personalizados (ej: 40)',
                    counterText: '',
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Pasos manuales opcionales
              Row(
                children: [
                  Expanded(
                    child: Text('PASOS MANUALES', style: hud(8, color: Colores.tenue)),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    onPressed: () {
                      setState(() {
                        expandirPasos = true;
                      });
                      agregarPasoManual();
                    },
                    icon: const Icon(Icons.add, size: 16, color: Colores.cian),
                    label: const Text('Añadir paso', style: TextStyle(color: Colores.cian, fontSize: 12)),
                  ),
                ],
              ),

              if (expandirPasos && pasosTitulos.isNotEmpty) ...[
                for (var i = 0; i < pasosTitulos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: pasosTitulos[i],
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Paso ${i + 1}',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colores.noche,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colores.borde),
                          ),
                          child: DropdownButton<int>(
                            value: pasosMinutos[i],
                            underline: const SizedBox(),
                            isDense: true,
                            dropdownColor: Colores.nocheClara,
                            items: [5, 10, 15, 20, 25, 30, 45]
                                .map((m) => DropdownMenuItem(
                                      value: m,
                                      child: Text('$m m', style: const TextStyle(fontSize: 12, color: Colores.luna)),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => pasosMinutos[i] = v);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: Colores.coral),
                          onPressed: () => quitarPaso(i),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colores.tenue)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colores.violeta,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: guardar,
          child: const Text('Crear Misión', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
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
