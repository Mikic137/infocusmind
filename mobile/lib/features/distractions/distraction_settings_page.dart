import 'package:flutter/material.dart';
import '../../core/tema.dart';
import '../../core/usage_service.dart';

class DistractionSettingsPage extends StatefulWidget {
  const DistractionSettingsPage({super.key});

  @override
  State<DistractionSettingsPage> createState() => _DistractionSettingsPageState();
}

class _DistractionSettingsPageState extends State<DistractionSettingsPage> {
  bool tienePermiso = false;
  bool cargando = true;
  List<AppInfo> apps = [];
  Set<String> distractoras = {};

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    setState(() => cargando = true);
    final permiso = await UsageService.tienePermiso();
    final seleccionadas = await UsageService.obtenerAppsDistractoras();
    List<AppInfo> listaApps = [];

    if (permiso) {
      listaApps = await UsageService.obtenerAppsInstaladas();
    }

    if (!mounted) return;
    setState(() {
      tienePermiso = permiso;
      distractoras = seleccionadas.toSet();
      apps = listaApps;
      cargando = false;
    });
  }

  Future<void> alternarApp(String package) async {
    setState(() {
      if (distractoras.contains(package)) {
        distractoras.remove(package);
      } else {
        distractoras.add(package);
      }
    });
    await UsageService.guardarAppsDistractoras(distractoras.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.noche,
      appBar: AppBar(
        title: Text('CONTROL DE DISTRACCIONES', style: hud(11, color: Colores.luna)),
        centerTitle: true,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: Colores.sol))
          : ListView(
              padding: const EdgeInsets.all(16),
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

                // Lista de apps para seleccionar distracciones
                if (tienePermiso) ...[
                  Row(
                    children: [
                      Text('TUS APPS DISTRACTORAS', style: hud(9, color: Colores.luna)),
                      const Spacer(),
                      Text(
                        '${distractoras.length} seleccionadas',
                        style: const TextStyle(color: Colores.tenue, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Marca las aplicaciones que consideras una tentación o distracción para tus sesiones de estudio:',
                    style: TextStyle(color: Colores.tenue, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  for (final app in apps)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: distractoras.contains(app.package)
                              ? Colores.coral.withValues(alpha: 0.12)
                              : Colores.nocheClara,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: distractoras.contains(app.package)
                                ? Colores.coral
                                : Colores.borde,
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
                              color: distractoras.contains(app.package)
                                  ? Colores.luna
                                  : Colores.luna.withValues(alpha: 0.85),
                            ),
                          ),
                          subtitle: Text(
                            app.package,
                            style: const TextStyle(color: Colores.tenue, fontSize: 10),
                          ),
                          activeColor: Colores.coral,
                          checkColor: Colors.white,
                          value: distractoras.contains(app.package),
                          onChanged: (_) => alternarApp(app.package),
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
