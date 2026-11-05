import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api_client.dart';
import '../../core/modelos.dart';
import '../../core/tema.dart';
import '../../core/usage_service.dart';

class FocusPage extends StatefulWidget {
  final int sesionId;
  final String titulo;
  final int minutos;
  const FocusPage({
    super.key,
    required this.sesionId,
    required this.titulo,
    required this.minutos,
  });

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  final inicio = DateTime.now();
  Timer? timer;
  Duration transcurrido = Duration.zero;
  bool enviando = false;
  int vistaModo = 0; // 0 = Temporizador Arcade, 1 = Launcher de Estudio
  List<AppInfo> appsPermitidas = [];
  bool cargandoApps = true;

  @override
  void initState() {
    super.initState();
    // Solicita al sistema el permiso de notificaciones si es Android 13+
    UsageService.solicitarPermisoNotificaciones();

    // Notificación inicial al arrancar el foco
    UsageService.mostrarNotificacion(
      titulo: widget.titulo,
      tiempo: formato(Duration(minutes: widget.minutos)),
    );

    // Cargar aplicaciones útiles permitidas para el Launcher
    UsageService.obtenerAppsPermitidasParaLauncher().then((list) {
      if (mounted) {
        setState(() {
          appsPermitidas = list;
          cargandoApps = false;
        });
      }
    });

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        final ahora = DateTime.now().difference(inicio);
        setState(() => transcurrido = ahora);

        // Actualizamos la notificación cada 5 segundos
        if (ahora.inSeconds % 5 == 0) {
          final total = Duration(minutes: widget.minutos);
          final restante = total - ahora;
          final cumplido = restante <= Duration.zero;
          UsageService.mostrarNotificacion(
            titulo: widget.titulo,
            tiempo: cumplido ? '+${formato(restante)}' : formato(restante),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    UsageService.cancelarNotificacion();
    timer?.cancel();
    super.dispose();
  }

  String formato(Duration d) {
    final s = d.inSeconds.abs();
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  Future<void> mostrarAppsPermitidas() async {
    final distractoras = (await UsageService.obtenerAppsDistractoras()).toSet();
    final apps = await UsageService.obtenerAppsInstaladas();
    final permitidas = apps.where((a) => !distractoras.contains(a.package)).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colores.nocheClara,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Colores.cian, width: 2),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.apps_rounded, color: Colores.cian, size: 22),
                const SizedBox(width: 8),
                Text('HERRAMIENTAS DE ESTUDIO',
                    style: hud(10, color: Colores.luna)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Abre tus herramientas autorizadas sin salir de tu foco:',
              style: TextStyle(color: Colores.tenue, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: permitidas.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No hay herramientas autorizadas.',
                          style: TextStyle(color: Colores.tenue),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: permitidas.length,
                      itemBuilder: (_, i) {
                        final app = permitidas[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: Colores.cian),
                          title: Text(
                            app.name,
                            style: const TextStyle(
                                color: Colores.luna, fontWeight: FontWeight.w600),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            UsageService.abrirApp(app.package);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> abandonar() async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¿ABANDONAR SESIÓN?', style: hud(12, color: Colores.coral)),
        content: const Text(
          'Este tiempo no se guardará como paso completado.',
          style: TextStyle(color: Colores.luna),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Seguir enfocado')),
          FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colores.coral,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Abandonar')),
        ],
      ),
    );
    if (seguro != true) return;
    await UsageService.cancelarNotificacion();
    try {
      await dio.post('/sessions/${widget.sesionId}/cancel');
    } on DioException catch (_) {}
    if (!mounted) return;
    Navigator.pop(context, false);
  }

  Future<void> terminar({bool confirmado = false}) async {
    setState(() => enviando = true);
    await UsageService.cancelarNotificacion();
    try {
      final appsUsadas = await UsageService.obtenerUso(inicio, DateTime.now());
      final distractorasConfig = (await UsageService.obtenerAppsDistractoras()).toSet();
      final distracciones = appsUsadas.where((a) =>
          distractorasConfig.isEmpty || distractorasConfig.contains(a.package)).toList();

      // Guardar registro de distracciones tanto en local como en la nube
      await UsageService.registrarDistraccionLocal(distracciones);

      final r = await dio.post('/sessions/${widget.sesionId}/finish', data: {
        'confirmed': confirmado,
        'distractions': [
          for (final d in distracciones)
            {'package': d.package, 'name': d.name, 'seconds': d.seconds}
        ],
      });
      timer?.cancel();
      if (!mounted) return;
      final cuenta = r.data['counts'] == true;
      final minReales = ((r.data['elapsed_seconds'] as int) / 60).round();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Center(
            child: Text('¡PASO COMPLETADO!', style: hud(13, color: Colores.sol)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colores.sol.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colores.sol, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, color: Colores.sol, size: 26),
                    const SizedBox(width: 6),
                    Text('+${widget.minutos} XP', style: hud(16, color: Colores.sol)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                cuenta
                    ? 'Tardaste $minReales min (estimado: ${widget.minutos} min).\n\n'
                        '¡Excelente trabajo! La IA usará este tiempo para calibrar tus futuras misiones.'
                    : 'Tardaste $minReales min (estimado: ${widget.minutos} min).\n\n'
                        'Este tiempo no se usará para aprender porque se desvió de lo estimado, pero tu paso quedó registrado.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colores.luna, height: 1.25),
              ),
              if (distracciones.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colores.noche,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colores.coral.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('APPS USADAS DURANTE EL FOCO:',
                          style: hud(7, color: Colores.coral)),
                      const SizedBox(height: 6),
                      for (final a in distracciones.take(3))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '• ${a.name}: ${(a.seconds / 60).ceil()} min',
                            style: const TextStyle(
                                color: Colores.tenue, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            Center(
              child: BotonJuego(
                texto: 'Continuar',
                expandir: false,
                color: Colores.menta,
                sombra: Colores.mentaSombra,
                colorTexto: Colores.noche,
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => enviando = false);
      final datos = e.response?.data;
      if (e.response?.statusCode == 409 &&
          datos is Map &&
          datos['code'] == 'too_fast') {
        final seguro = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('¿TERMINASTE TAN RÁPIDO?',
                style: hud(11, color: Colores.sol)),
            content: Text(
              datos['error'].toString(),
              style: const TextStyle(color: Colores.luna),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Seguir trabajando')),
              FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colores.sol,
                    foregroundColor: Colores.noche,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Sí, ya terminé')),
            ],
          ),
        );
        if (seguro == true) terminar(confirmado: true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensajeError(e))));
      }
    }
  }

  Widget _vistaTemporizador(Duration restante, bool cumplido, double progreso) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tarjeta con el título del paso
        TarjetaJuego(
          borde: Colores.cian,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Colores.sol, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Radar / Temporizador Arcade
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: Colores.nocheClara,
            shape: BoxShape.circle,
            border: Border.all(color: Colores.borde, width: 3),
            boxShadow: [
              BoxShadow(
                color: (cumplido ? Colores.menta : Colores.cian)
                    .withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 0),
              ),
              const BoxShadow(
                color: Colores.sombraCarta,
                offset: Offset(0, 6),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 206,
                height: 206,
                child: CircularProgressIndicator(
                  value: progreso,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colores.noche,
                  color: cumplido ? Colores.menta : Colores.cian,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cumplido ? '+${formato(restante)}' : formato(restante),
                    style: hud(22, color: Colores.luna),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cumplido
                          ? Colores.menta.withValues(alpha: 0.2)
                          : Colores.noche,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: cumplido ? Colores.menta : Colores.borde,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      cumplido
                          ? '¡TIEMPO CUMPLIDO!'
                          : 'ESTIMADO: ${widget.minutos} MIN',
                      style: hud(7,
                          color: cumplido ? Colores.menta : Colores.tenue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Dock de acceso rápido a herramientas útiles
        if (appsPermitidas.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'HERRAMIENTAS ÚTILES AUTORIZADAS:',
              style: hud(7, color: Colores.cian),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: appsPermitidas.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final a = appsPermitidas[i];
                return InkWell(
                  onTap: () => UsageService.abrirApp(a.package),
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colores.nocheClara,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colores.bordeBrillante, width: 1.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.open_in_new_rounded, size: 14, color: Colores.cian),
                        const SizedBox(width: 6),
                        Text(
                          a.name,
                          style: const TextStyle(
                            color: Colores.luna,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Botones de acción
        BotonJuego(
          texto: enviando ? 'Guardando...' : 'Terminé el paso',
          color: Colores.menta,
          sombra: Colores.mentaSombra,
          colorTexto: Colores.noche,
          icono: Icons.check_circle_rounded,
          onPressed: enviando ? null : terminar,
        ),

        const SizedBox(height: 10),

        BotonJuego(
          texto: 'Abrir Launcher de Estudio',
          color: Colores.nocheClara,
          sombra: Colores.sombraCarta,
          colorTexto: Colores.cian,
          icono: Icons.apps_rounded,
          onPressed: () => setState(() => vistaModo = 1),
        ),

        const SizedBox(height: 6),

        TextButton(
          onPressed: enviando ? null : abandonar,
          child: Text(
            'Abandonar sesión',
            style: GoogleFonts.baloo2(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colores.tenue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _vistaLauncher(Duration restante, bool cumplido) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra flotante persistente del foco
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colores.nocheClara,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colores.cian, width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colores.sombraCarta,
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: cumplido ? Colores.menta : Colores.sol, size: 20),
              const SizedBox(width: 8),
              Text(
                cumplido ? '+${formato(restante)}' : formato(restante),
                style: hud(10, color: cumplido ? Colores.menta : Colores.sol),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colores.luna),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: enviando ? null : terminar,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colores.menta,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('TERMINAR', style: hud(7, color: Colores.noche)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Subtítulo del launcher
        Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colores.menta, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'LAUNCHER DE ESTUDIO PURO',
                style: hud(9, color: Colores.luna),
              ),
            ),
            Text(
              '${appsPermitidas.length} APPS',
              style: hud(8, color: Colores.cian),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Solo las herramientas útiles autorizadas están activas durante tu foco:',
          style: TextStyle(color: Colores.tenue, fontSize: 12),
        ),

        const SizedBox(height: 14),

        // Cuadrícula de aplicaciones útiles
        Expanded(
          child: cargandoApps
              ? const Center(child: CircularProgressIndicator(color: Colores.cian))
              : appsPermitidas.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.apps_rounded, size: 48, color: Colores.tenue),
                            const SizedBox(height: 12),
                            const Text(
                              'Aún no tienes herramientas útiles seleccionadas.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colores.luna),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Puedes configurarlas en la pestaña Bloqueo seleccionando "Útiles".',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colores.tenue, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            BotonJuego(
                              texto: 'Cargar todas las no distractoras',
                              expandir: false,
                              color: Colores.violeta,
                              sombra: Colores.violetaSombra,
                              onPressed: () async {
                                final todas = await UsageService.obtenerAppsInstaladas();
                                final dist = (await UsageService.obtenerAppsDistractoras()).toSet();
                                setState(() {
                                  appsPermitidas = todas.where((a) => !dist.contains(a.package)).toList();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.45,
                      ),
                      itemCount: appsPermitidas.length,
                      itemBuilder: (_, i) {
                        final a = appsPermitidas[i];
                        final inicial = a.name.isNotEmpty ? a.name.substring(0, 1).toUpperCase() : '?';

                        return TarjetaJuego(
                          borde: Colores.bordeBrillante,
                          padding: const EdgeInsets.all(10),
                          child: InkWell(
                            onTap: () => UsageService.abrirApp(a.package),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colores.violeta.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colores.cian, width: 1.2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          inicial,
                                          style: hud(11, color: Colores.sol),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_outward_rounded, size: 16, color: Colores.cian),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colores.luna,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Herramienta de estudio',
                                      style: hud(6, color: Colores.tenue),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Botón inferior para regresar al temporizador
        BotonJuego(
          texto: 'Ver Temporizador Completo',
          color: Colores.nocheClara,
          sombra: Colores.sombraCarta,
          colorTexto: Colores.cian,
          icono: Icons.timer_rounded,
          onPressed: () => setState(() => vistaModo = 0),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = Duration(minutes: widget.minutos);
    final restante = total - transcurrido;
    final cumplido = restante <= Duration.zero;
    final progreso = total.inSeconds == 0
        ? 1.0
        : (transcurrido.inSeconds / total.inSeconds).clamp(0.0, 1.0).toDouble();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) abandonar();
      },
      child: Scaffold(
        backgroundColor: Colores.noche,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => vistaModo = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: vistaModo == 0 ? Colores.violeta : Colores.nocheClara,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: vistaModo == 0 ? Colores.cian : Colores.borde,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 15, color: vistaModo == 0 ? Colors.white : Colores.tenue),
                          const SizedBox(width: 5),
                          Text('TEMPORIZADOR', style: hud(8, color: vistaModo == 0 ? Colors.white : Colores.tenue)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => vistaModo = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: vistaModo == 1 ? Colores.violeta : Colores.nocheClara,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: vistaModo == 1 ? Colores.cian : Colores.borde,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.apps_rounded, size: 15, color: vistaModo == 1 ? Colors.white : Colores.tenue),
                          const SizedBox(width: 5),
                          Text('LAUNCHER', style: hud(8, color: vistaModo == 1 ? Colors.white : Colores.tenue)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: vistaModo == 0
                ? SingleChildScrollView(child: _vistaTemporizador(restante, cumplido, progreso))
                : _vistaLauncher(restante, cumplido),
          ),
        ),
      ),
    );
  }
}
