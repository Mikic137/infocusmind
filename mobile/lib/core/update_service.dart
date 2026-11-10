import 'package:flutter/material.dart';
import 'api_client.dart';
import 'tema.dart';
import 'usage_service.dart';

class UpdateService {
  static const int codigoVersionActual = 2; // v1.1.0
  static const String nombreVersionActual = '1.1.0';

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
        final latestVersion = data['latest_version']?.toString() ?? '1.1.0';
        final urlDescarga = data['download_url']?.toString() ??
            'https://infocusmind-production.up.railway.app/download/InfocusMind.apk';
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

  static Future<void> _mostrarDialogoActualizacion(
    BuildContext context, {
    required String version,
    required String mensaje,
    required String url,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false, // Obligatorio: no se puede cerrar
      builder: (ctx) => PopScope(
        canPop: false, // Bloquear botón atrás de Android
        child: AlertDialog(
          backgroundColor: Colores.nocheClara,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colores.sol, width: 2),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colores.sol.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.system_update_rounded, color: Colores.sol, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Actualización Requerida!',
                  style: hud(10, color: Colores.luna),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colores.menta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'NUEVA VERSIÓN v$version DISPONIBLE',
                  style: const TextStyle(
                    color: Colores.menta,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                mensaje,
                style: const TextStyle(color: Colores.luna, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colores.noche,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colores.borde),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🚀 Novedades v1.1.0:',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    SizedBox(height: 6),
                    Text('• Acceso rápido con Google / Gmail.', style: TextStyle(color: Colores.tenue, fontSize: 11)),
                    Text('• Bloqueador de sitios web y juegos.', style: TextStyle(color: Colores.tenue, fontSize: 11)),
                    Text('• Tutorial interactivo de la app.', style: TextStyle(color: Colores.tenue, fontSize: 11)),
                    Text('• Letras más grandes en el asistente IA.', style: TextStyle(color: Colores.tenue, fontSize: 11)),
                    Text('• Selector de temas (Maduro / Juvenil).', style: TextStyle(color: Colores.tenue, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colores.sol,
                  foregroundColor: Colores.noche,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  await UsageService.abrirUrl(url);
                },
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text(
                  'Descargar e Instalar Actualización',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
