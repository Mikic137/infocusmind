import 'package:flutter/material.dart';
import 'api_client.dart';
import 'tema.dart';
import 'usage_service.dart';

class UpdateService {
  static const int codigoVersionActual = 3; // v1.1.2
  static const String nombreVersionActual = '1.1.2';

  static bool _dialogoMostrado = false;

  /// Consulta al backend si hay una actualización obligatoria requerida
  static Future<void> comprobarActualizacion(BuildContext context) async {
    if (_dialogoMostrado) return;

    try {
      final r = await dio.get('/app/version');
      if (r.statusCode == 200 && r.data is Map) {
        final data = r.data as Map;
        final minCode = (data['min_required_version_code'] as num?)?.toInt() ?? 1;
        final latestCode = (data['latest_version_code'] as num?)?.toInt() ?? 1;
        final latestVersion = data['latest_version']?.toString() ?? '1.1.2';
        final urlDescarga = data['download_url']?.toString() ??
            'https://infocusmind-production.up.railway.app/download/InfocusMind_v1.1.2.apk';
        final mensaje = data['message']?.toString() ??
            'Hay una nueva versión obligatoria disponible con mejoras de seguridad y nuevas funciones.';
        final force = data['force_update'] == true || codigoVersionActual < minCode;

        if (codigoVersionActual < latestCode && force) {
          _dialogoMostrado = true;
          if (!context.mounted) return;
          await _mostrarDialogoActualizacion(
            context,
            version: latestVersion,
            mensaje: mensaje,
            url: urlDescarga,
          );
        }
      }
    } catch (_) {
      // Si falla la red, no bloqueamos la app localmente
    }
  }

  /// Muestra la tarjeta elegante de actualización obligatoria
  static Future<void> mostrarTarjetaActualizacion(
    BuildContext context, {
    String version = '1.1.2',
    String? mensaje,
    String? url,
  }) async {
    final urlFinal = url ?? 'https://infocusmind-production.up.railway.app/download/InfocusMind_v1.1.2.apk';
    final mensajeFinal = mensaje ??
        'Hemos lanzado una versión con acceso directo por Google, mayor seguridad en contraseñas, tutorial interactivo, bloqueo de dominios web y selector de estilos de estudio.';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1E2E),
                  Color(0xFF181825),
                  Color(0xFF11111B),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colores.sol, width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: Colores.sol.withValues(alpha: 0.30),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encabezado con Icono Luminoso
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colores.sol, Color(0xFFFFA502)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colores.sol.withValues(alpha: 0.5),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.system_update_rounded,
                        color: Color(0xFF11111B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colores.sol.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colores.sol.withValues(alpha: 0.6)),
                            ),
                            child: const Text(
                              '⚡ ACTUALIZACIÓN REQUERIDA',
                              style: TextStyle(
                                color: Colores.sol,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'InfocusMind v$version',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mensaje descriptivo
                Text(
                  mensajeFinal,
                  style: const TextStyle(
                    color: Colores.luna,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),

                // Tarjeta de Novedades
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colores.sol, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Novedades Principales',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _itemNovedad('Acceso directo con cuenta Google / Gmail'),
                      _itemNovedad('Bloqueo de sitios web (YouTube, TikTok, Juegos)'),
                      _itemNovedad('Selector de temas (Maduro, Juvenil, Cálido)'),
                      _itemNovedad('Tutorial guiado interactivo de bienvenida'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Botón principal de descarga
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.sol,
                      foregroundColor: const Color(0xFF11111B),
                      elevation: 8,
                      shadowColor: Colores.sol.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await UsageService.abrirUrl(urlFinal);
                    },
                    icon: const Icon(Icons.download_rounded, size: 24),
                    label: const Text(
                      'DESCARGAR E INSTALAR AHORA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Subtexto informativo
                const Center(
                  child: Text(
                    'Descarga directa oficial sin esperas',
                    style: TextStyle(color: Colores.tenue, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _itemNovedad(String texto) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colores.menta, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: Colores.luna, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _mostrarDialogoActualizacion(
    BuildContext context, {
    required String version,
    required String mensaje,
    required String url,
  }) async {
    await mostrarTarjetaActualizacion(
      context,
      version: version,
      mensaje: mensaje,
      url: url,
    );
  }
}
