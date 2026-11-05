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
      final r = await dio.post('/sessions/${widget.sesionId}/finish',
          data: {'confirmed': confirmado});
      timer?.cancel();
      if (!mounted) return;
      final cuenta = r.data['counts'] == true;
      final minReales = ((r.data['elapsed_seconds'] as int) / 60).round();
      final appsUsadas = await UsageService.obtenerUso(inicio, DateTime.now());
      final distractorasConfig = await UsageService.obtenerAppsDistractoras();
      final distracciones = appsUsadas.where((a) =>
          distractorasConfig.isEmpty || distractorasConfig.contains(a.package)).toList();

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
          title: Text('ZONA DE ENFOQUE', style: hud(12, color: Colores.luna)),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tarjeta con el título del paso
                TarjetaJuego(
                  borde: Colores.cian,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on_rounded,
                          color: Colores.sol, size: 24),
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

                const SizedBox(height: 38),

                // Radar / Temporizador Arcade
                Container(
                  width: 250,
                  height: 250,
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
                        width: 236,
                        height: 236,
                        child: CircularProgressIndicator(
                          value: progreso,
                          strokeWidth: 12,
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
                            style: hud(26, color: Colores.luna),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
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

                const SizedBox(height: 48),

                // Botones de acción
                BotonJuego(
                  texto: enviando ? 'Guardando...' : 'Terminé el paso',
                  color: Colores.menta,
                  sombra: Colores.mentaSombra,
                  colorTexto: Colores.noche,
                  icono: Icons.check_circle_rounded,
                  onPressed: enviando ? null : terminar,
                ),

                const SizedBox(height: 12),

                BotonJuego(
                  texto: 'Herramientas de estudio',
                  color: Colores.nocheClara,
                  sombra: Colores.sombraCarta,
                  colorTexto: Colores.cian,
                  icono: Icons.construction_rounded,
                  onPressed: mostrarAppsPermitidas,
                ),

                const SizedBox(height: 10),

                TextButton(
                  onPressed: enviando ? null : abandonar,
                  child: Text(
                    'Abandonar sesión',
                    style: GoogleFonts.baloo2(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colores.tenue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
