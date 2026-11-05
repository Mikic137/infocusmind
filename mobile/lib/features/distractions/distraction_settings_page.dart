import 'package:flutter/material.dart';
import '../../core/tema.dart';
import '../../core/usage_service.dart';

class DistractionSettingsPage extends StatefulWidget {
  final bool embedded;
  const DistractionSettingsPage({super.key, this.embedded = false});

  @override
  State<DistractionSettingsPage> createState() => _DistractionSettingsPageState();
}

class _DistractionSettingsPageState extends State<DistractionSettingsPage> {
  bool tienePermiso = false;
  bool cargando = true;
  List<AppInfo> apps = [];
  Set<String> distractoras = {};
  Set<String> utiles = {};
  int modoLista = 0; // 0 = Apps Útiles para Launcher, 1 = Apps Distractoras
  final busquedaCtrl = TextEditingController();
  String filtro = '';

  @override
  void initState() {
    super.initState();
    cargar();
  }

  @override
  void dispose() {
    busquedaCtrl.dispose();
    super.dispose();
  }

  Future<void> cargar() async {
    setState(() => cargando = true);
    final permiso = await UsageService.tienePermiso();
    final seleccionadas = await UsageService.obtenerAppsDistractoras();
    final seleccionadasUtiles = await UsageService.obtenerAppsUtiles();
    List<AppInfo> listaApps = [];

    if (permiso) {
      listaApps = await UsageService.obtenerAppsInstaladas();
    }

    if (!mounted) return;
    setState(() {
      tienePermiso = permiso;
      distractoras = seleccionadas.toSet();
      utiles = seleccionadasUtiles.toSet();
      apps = listaApps;
      cargando = false;
    });
  }

  Future<void> alternarAppDistractora(String package) async {
    setState(() {
      if (distractoras.contains(package)) {
        distractoras.remove(package);
      } else {
        distractoras.add(package);
        utiles.remove(package);
      }
    });
    await UsageService.guardarAppsDistractoras(distractoras.toList());
    await UsageService.guardarAppsUtiles(utiles.toList());
  }

  Future<void> alternarAppUtil(String package) async {
    setState(() {
      if (utiles.contains(package)) {
        utiles.remove(package);
      } else {
        utiles.add(package);
        distractoras.remove(package);
      }
    });
    await UsageService.guardarAppsUtiles(utiles.toList());
    await UsageService.guardarAppsDistractoras(distractoras.toList());
  }

  @override
  Widget build(BuildContext context) {
    final contenido = cargando
        ? const Center(child: CircularProgressIndicator(color: Colores.sol))
        : RefreshIndicator(
            onRefresh: cargar,
            color: Colores.sol,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, widget.embedded ? 100 : 20),
              children: [
                // Tarjeta de Permiso y Privacidad
                TarjetaJuego(
                  borde: tienePermiso ? Colores.menta : Colores.sol,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            tienePermiso
                                ? Icons.verified_user_rounded
                                : Icons.security_rounded,
                            color: tienePermiso ? Colores.menta : Colores.sol,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              tienePermiso
                                  ? 'DETECCIÓN ACTIVADA'
                                  : 'PERMISO REQUERIDO',
                              style: hud(9,
                                  color: tienePermiso
                                      ? Colores.menta
                                      : Colores.sol),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tienePermiso
                            ? 'InfocusMind puede certificar si tu sesión fue de enfoque real o si abriste apps distractoras.'
                            : 'Para detectar si sales a redes sociales durante tu estudio, Android necesita que autorices el "Acceso a datos de uso".',
                        style: const TextStyle(color: Colores.luna, fontSize: 13, height: 1.25),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colores.noche,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colores.borde, width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.lock_rounded, size: 16, color: Colores.tenue),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Privacidad absoluta: InfocusMind NUNCA accede a chats, fotos, contraseñas ni datos bancarios. Solo mide el tiempo en pantalla.',
                                style: TextStyle(color: Colores.tenue, fontSize: 11, height: 1.2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!tienePermiso) ...[
                        const SizedBox(height: 14),
                        BotonJuego(
                          texto: 'Activar en Ajustes',
                          color: Colores.sol,
                          sombra: Colores.solSombra,
                          colorTexto: Colores.noche,
                          icono: Icons.settings_rounded,
                          onPressed: () async {
                            await UsageService.abrirAjustes();
                            // Al regresar de ajustes, recargamos
                            Future.delayed(const Duration(seconds: 1), cargar);
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tarjeta de Modo Launcher / Pantalla de Inicio de Enfoque
                TarjetaJuego(
                  borde: Colores.violeta,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.home_rounded,
                              color: Colores.violeta, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'MODO ENFOQUE PURO (LAUNCHER)',
                              style: hud(9, color: Colores.luna),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Convierte InfocusMind en tu pantalla de inicio mientras estudias. '
                        'Al presionar el botón Home no verás redes sociales, solo tu progreso y tus herramientas autorizadas.',
                        style: TextStyle(
                            color: Colores.luna, fontSize: 13, height: 1.25),
                      ),
                      const SizedBox(height: 14),
                      BotonJuego(
                        texto: 'Activar Pantalla de Inicio',
                        color: Colores.violeta,
                        sombra: Colores.violetaSombra,
                        colorTexto: Colors.white,
                        icono: Icons.apps_rounded,
                        onPressed: UsageService.abrirSelectorLauncher,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Selector de modo: Apps Útiles (Launcher) vs Apps Distractoras
                if (tienePermiso) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colores.nocheClara,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colores.borde, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => modoLista = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: modoLista == 0 ? Colores.violeta : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.apps_rounded,
                                      size: 16,
                                      color: modoLista == 0 ? Colors.white : Colores.tenue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ÚTILES (${utiles.length})',
                                      style: hud(8, color: modoLista == 0 ? Colors.white : Colores.tenue),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => modoLista = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: modoLista == 1 ? Colores.coral : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.block_rounded,
                                      size: 16,
                                      color: modoLista == 1 ? Colors.white : Colores.tenue,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'DISTRACTORAS (${distractoras.length})',
                                      style: hud(8, color: modoLista == 1 ? Colors.white : Colores.tenue),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Explicación del modo activo
                  Text(
                    modoLista == 0
                        ? 'Selecciona las apps autorizadas para tu estudio. Solo estas se mostrarán en el Launcher durante el Modo Focus (ej. Calculadora, Navegador, Libros...):'
                        : 'Marca las aplicaciones que consideras una tentación o distracción. Si las abres durante tu sesión de foco, quedarán registradas:',
                    style: const TextStyle(color: Colores.tenue, fontSize: 12, height: 1.25),
                  ),

                  const SizedBox(height: 10),

                  // Buscador de apps
                  TextField(
                    controller: busquedaCtrl,
                    onChanged: (v) => setState(() => filtro = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Buscar aplicación...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Colores.tenue),
                      suffixIcon: filtro.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                busquedaCtrl.clear();
                                setState(() => filtro = '');
                              },
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Lista filtrada de aplicaciones
                  for (final app in apps.where((a) =>
                      filtro.isEmpty ||
                      a.name.toLowerCase().contains(filtro) ||
                      a.package.toLowerCase().contains(filtro)))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: modoLista == 0
                              ? (utiles.contains(app.package)
                                  ? Colores.violeta.withValues(alpha: 0.18)
                                  : Colores.nocheClara)
                              : (distractoras.contains(app.package)
                                  ? Colores.coral.withValues(alpha: 0.15)
                                  : Colores.nocheClara),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: modoLista == 0
                                ? (utiles.contains(app.package)
                                    ? Colores.cian
                                    : Colores.borde)
                                : (distractoras.contains(app.package)
                                    ? Colores.coral
                                    : Colores.borde),
                            width: 1.2,
                          ),
                        ),
                        child: CheckboxListTile(
                          dense: true,
                          title: Text(
                            app.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colores.luna,
                            ),
                          ),
                          subtitle: Text(
                            app.package,
                            style: const TextStyle(color: Colores.tenue, fontSize: 10),
                          ),
                          activeColor: modoLista == 0 ? Colores.cian : Colores.coral,
                          checkColor: Colores.noche,
                          value: modoLista == 0
                              ? utiles.contains(app.package)
                              : distractoras.contains(app.package),
                          onChanged: (_) {
                            if (modoLista == 0) {
                              alternarAppUtil(app.package);
                            } else {
                              alternarAppDistractora(app.package);
                            }
                          },
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );

    if (widget.embedded) {
      return contenido;
    }

    return Scaffold(
      backgroundColor: Colores.noche,
      appBar: AppBar(
        title: Text('CONTROL DE DISTRACCIONES', style: hud(11, color: Colores.luna)),
        centerTitle: true,
      ),
      body: contenido,
    );
  }
}
