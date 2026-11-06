import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/tema.dart';
import '../../core/usage_service.dart';
import '../distractions/distraction_settings_page.dart';

class LauncherScreen extends StatefulWidget {
  final VoidCallback? onAbrirAppCompleta;

  const LauncherScreen({super.key, this.onAbrirAppCompleta});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  List<AppInfo> appsPermitidas = [];
  bool cargando = true;
  bool esLauncherDefault = false;
  DateTime ahora = DateTime.now();
  Timer? relojTimer;
  final busquedaCtrl = TextEditingController();
  String filtro = '';

  @override
  void initState() {
    super.initState();
    cargarApps();
    relojTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => ahora = DateTime.now());
    });
  }

  @override
  void dispose() {
    relojTimer?.cancel();
    busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> cargarApps() async {
    setState(() => cargando = true);
    final lista = await UsageService.obtenerAppsPermitidasParaLauncher();
    final isDefault = await UsageService.esLauncherPredeterminado();
    if (!mounted) return;
    setState(() {
      appsPermitidas = lista;
      esLauncherDefault = isDefault;
      cargando = false;
    });
  }

  String _formatoHora(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatoFecha(DateTime d) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    final diaSemana = dias[d.weekday - 1];
    final mes = meses[d.month - 1];
    return '$diaSemana, ${d.day} de $mes';
  }

  void _abrirAjustesApps() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DistractionSettingsPage(embedded: false),
      ),
    );
    cargarApps();
  }

  void _mostrarMenuSalir() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colores.nocheClara,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Colores.borde, width: 1.5),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.exit_to_app_rounded,
                        color: Colores.coral, size: 24),
                    const SizedBox(width: 10),
                    Text('OPCIONES DEL LAUNCHER',
                        style: hud(11, color: Colores.coral)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Elige si deseas desactivar el modo Launcher para volver a tu pantalla de inicio habitual, o abrir la app completa:',
                  style: TextStyle(color: Colores.tenue, fontSize: 13),
                ),
                const SizedBox(height: 16),
                BotonJuego(
                  texto: 'Desactivar y volver a mi pantalla normal',
                  color: Colores.coral,
                  sombra: Colores.coralSombra,
                  icono: Icons.restore_rounded,
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await UsageService.desactivarLauncher();
                    widget.onAbrirAppCompleta?.call();
                  },
                ),
                const SizedBox(height: 10),
                BotonJuego(
                  texto: 'Cambiar launcher en Ajustes del teléfono',
                  color: Colores.noche,
                  sombra: Colores.sombraCarta,
                  colorTexto: Colores.luna,
                  icono: Icons.settings_rounded,
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await UsageService.abrirAjustesAppsPredeterminadas();
                  },
                ),
                if (widget.onAbrirAppCompleta != null) ...[
                  const SizedBox(height: 10),
                  BotonJuego(
                    texto: 'Ir a InfocusMind completo (Misiones/Logros)',
                    color: Colores.violeta,
                    sombra: Colores.violetaSombra,
                    icono: Icons.dashboard_rounded,
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onAbrirAppCompleta!();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listaFiltrada = appsPermitidas.where((a) {
      if (filtro.isEmpty) return true;
      return a.name.toLowerCase().contains(filtro) ||
          a.package.toLowerCase().contains(filtro);
    }).toList();

    return PopScope(
      canPop: false, // Es un Launcher: presionar "Atrás" no sale de la pantalla de inicio
      child: Scaffold(
        backgroundColor: Colores.noche,
        body: SafeArea(
          child: Column(
            children: [
              // Reloj digital grande estilo Minimalist Launcher
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  children: [
                    Text(
                      _formatoHora(ahora),
                      style: hud(36, color: Colores.luna),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatoFecha(ahora).toUpperCase(),
                      style: hud(9, color: Colores.tenue),
                    ),
                  ],
                ),
              ),

              // Banner de Estado de Enfoque y Launcher
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TarjetaJuego(
                  borde: esLauncherDefault ? Colores.menta : Colores.sol,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        esLauncherDefault
                            ? Icons.verified_rounded
                            : Icons.info_outline_rounded,
                        color: esLauncherDefault ? Colores.menta : Colores.sol,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          esLauncherDefault
                              ? 'PANTALLA DE INICIO ACTIVA'
                              : 'MODO ENFOQUE: SOLO APPS AUTORIZADAS',
                          style: hud(8,
                              color: esLauncherDefault
                                  ? Colores.menta
                                  : Colores.sol),
                        ),
                      ),
                      if (!esLauncherDefault)
                        InkWell(
                          onTap: UsageService.abrirSelectorLauncher,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colores.sol.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colores.sol, width: 1),
                            ),
                            child: Text('FIJAR DEFAULT',
                                style: hud(7, color: Colores.sol)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Buscador de apps rápidas si hay más de 4
              if (appsPermitidas.length > 4)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: TextField(
                    controller: busquedaCtrl,
                    onChanged: (v) =>
                        setState(() => filtro = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Buscar herramienta...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 18, color: Colores.tenue),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      suffixIcon: filtro.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                busquedaCtrl.clear();
                                setState(() => filtro = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),

              // Cuadrícula de Aplicaciones Permitidas
              Expanded(
                child: cargando
                    ? const Center(
                        child: CircularProgressIndicator(color: Colores.sol))
                    : appsPermitidas.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.apps_rounded,
                                      size: 48, color: Colores.tenue),
                                  const SizedBox(height: 14),
                                  Text(
                                    'SIN HERRAMIENTAS SELECCIONADAS',
                                    style: hud(10, color: Colores.sol),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Selecciona las aplicaciones útiles que necesitas para estudiar (Calculadora, Navegador, Libros...).',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colores.tenue, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  BotonJuego(
                                    texto: 'Seleccionar aplicaciones útiles',
                                    expandir: false,
                                    color: Colores.violeta,
                                    sombra: Colores.violetaSombra,
                                    icono: Icons.settings_rounded,
                                    onPressed: _abrirAjustesApps,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: listaFiltrada.length,
                            itemBuilder: (_, i) {
                              final a = listaFiltrada[i];
                              final inicial = a.name.isNotEmpty
                                  ? a.name.substring(0, 1).toUpperCase()
                                  : '?';

                              return TarjetaJuego(
                                borde: Colores.bordeBrillante,
                                padding: const EdgeInsets.all(10),
                                child: InkWell(
                                  onTap: () => UsageService.abrirApp(a.package),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colores.violeta
                                                  .withValues(alpha: 0.3),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                  color: Colores.cian,
                                                  width: 1.2),
                                            ),
                                            child: Center(
                                              child: Text(
                                                inicial,
                                                style: hud(11,
                                                    color: Colores.sol),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.arrow_outward_rounded,
                                              size: 16, color: Colores.cian),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            'HERRAMIENTA ÚTIL',
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

              // Dock inferior con accesos de control del Launcher
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: Colores.nocheClara,
                  border: const Border(
                      top: BorderSide(color: Colores.borde, width: 1.5)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colores.sombraCarta,
                      offset: Offset(0, -3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Botón para entrar a la app completa
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colores.violeta,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: widget.onAbrirAppCompleta,
                        icon: const Icon(Icons.dashboard_rounded, size: 18),
                        label: Text('INFOCUSMIND', style: hud(9)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botón de Configuración de apps útiles
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colores.noche,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        side: const BorderSide(color: Colores.borde, width: 1.2),
                      ),
                      tooltip: 'Ajustar herramientas útiles',
                      onPressed: _abrirAjustesApps,
                      icon: const Icon(Icons.tune_rounded,
                          color: Colores.cian, size: 20),
                    ),
                    const SizedBox(width: 8),

                    // Botón para salir / cambiar launcher
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colores.noche,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        side: const BorderSide(color: Colores.borde, width: 1.2),
                      ),
                      tooltip: 'Cambiar launcher / Salir',
                      onPressed: _mostrarMenuSalir,
                      icon: const Icon(Icons.exit_to_app_rounded,
                          color: Colores.coral, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
