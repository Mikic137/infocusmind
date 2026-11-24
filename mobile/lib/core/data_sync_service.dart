import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'tema.dart';
import 'usage_service.dart';

class DataSyncService {
  static const _almacen = FlutterSecureStorage();
  static const _claveDataVersion = 'app_data_version_installed';
  static bool _dialogoActivo = false;

  /// Obtiene la versión de datos local instalada (por defecto 0 si nunca ha descargado parche)
  static Future<int> obtenerVersionDatosLocal() async {
    try {
      final v = await _almacen.read(key: _claveDataVersion);
      return int.tryParse(v ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Guarda la versión de datos aplicada
  static Future<void> guardarVersionDatosLocal(int version) async {
    await _almacen.write(key: _claveDataVersion, value: version.toString());
  }

  /// Consulta al backend si hay un paquete de datos pendiente estilo DB Legends
  static Future<void> comprobarDatosAlIniciar(BuildContext context) async {
    if (_dialogoActivo) return;

    try {
      final r = await dio.get('/app/data-sync');
      if (r.statusCode == 200 && r.data is Map) {
        final data = r.data as Map<String, dynamic>;
        final versionRemota = (data['data_version'] as num?)?.toInt() ?? 1;
        final versionLocal = await obtenerVersionDatosLocal();

        if (versionLocal < versionRemota) {
          _dialogoActivo = true;
          if (!context.mounted) return;
          await mostrarDialogoDescargaDatos(context, data);
          _dialogoActivo = false;
        }
      }
    } catch (_) {
      // Si falla la red no bloqueamos la app
    }
  }

  /// Consulta manual invocada por el usuario desde el menú
  static Future<void> comprobarManualmente(BuildContext context) async {
    try {
      final r = await dio.get('/app/data-sync');
      if (r.statusCode == 200 && r.data is Map) {
        final data = r.data as Map<String, dynamic>;
        if (!context.mounted) return;
        await mostrarDialogoDescargaDatos(context, data);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colores.coral,
            content: Text('Error al conectar con el servidor de datos: $e'),
          ),
        );
      }
    }
  }

  /// Muestra el modal estilo juego (Dragon Ball Legends) para descargar solo los datos de actualización
  static Future<bool?> mostrarDialogoDescargaDatos(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ModalDescargaDatos(data: data),
    );
  }
}

class _ModalDescargaDatos extends StatefulWidget {
  final Map<String, dynamic> data;
  const _ModalDescargaDatos({required this.data});

  @override
  State<_ModalDescargaDatos> createState() => _ModalDescargaDatosState();
}

class _ModalDescargaDatosState extends State<_ModalDescargaDatos> {
  bool _descargando = false;
  double _progreso = 0.0;
  String _fase = '';
  bool _completado = false;

  Future<void> _iniciarDescargaDatos() async {
    setState(() {
      _descargando = true;
      _progreso = 0.1;
      _fase = 'Conectando con el servidor de datos...';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() {
      _progreso = 0.45;
      _fase = 'Descargando paquete de reglas de bloqueo web...';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _progreso = 0.85;
      _fase = 'Aplicando parches de subdominios móviles (m.youtube.com)...';
    });

    // Inyectar dominios recibidos
    try {
      final dominios = (widget.data['blocked_domains'] as List?)
              ?.map((e) => e.toString().toLowerCase().trim())
              .toList() ??
          [];

      if (dominios.isNotEmpty) {
        final actuales = await UsageService.obtenerDominiosBloqueados();
        for (final d in dominios) {
          if (!actuales.contains(d)) {
            actuales.add(d);
          }
        }
        await UsageService.guardarDominiosBloqueados(actuales);
      }

      final version = (widget.data['data_version'] as num?)?.toInt() ?? 7;
      await DataSyncService.guardarVersionDatosLocal(version);
    } catch (e) {
      debugPrint('Error aplicando datos: $e');
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() {
      _progreso = 1.0;
      _fase = '¡Datos de actualización sincronizados con éxito!';
      _descargando = false;
      _completado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title']?.toString() ?? 'Parche de Datos';
    final desc = widget.data['description']?.toString() ??
        'Se actualizarán las reglas de bloqueo web y optimizaciones de IA sin reinstalar la app.';
    final sizeKb = (widget.data['size_kb'] as num?)?.toInt() ?? 42;

    return PopScope(
      canPop: !_descargando,
      child: Dialog(
        backgroundColor: Colores.nocheClara,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colores.sol, width: 2),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado tipo cápsula de juego (Dragon Ball Legends)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colores.sol, Color(0xFFFF9100)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colores.sol.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.cloud_download_rounded, color: Colores.noche, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colores.sol.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTUALIZACIÓN DE DATOS (OTA)',
                            style: TextStyle(
                              color: Colores.sol,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                desc,
                style: const TextStyle(color: Colores.luna, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colores.noche,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colores.borde),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colores.menta, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Descarga en caliente solo de datos ($sizeKb KB). No requiere descargar la APK completa ni entrar a Play Store.',
                        style: const TextStyle(color: Colores.menta, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_descargando || _completado) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _progreso,
                        backgroundColor: Colores.borde,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _completado ? Colores.menta : Colores.sol,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fase,
                      style: TextStyle(
                        color: _completado ? Colores.menta : Colores.sol,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (!_descargando && !_completado) ...[
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.sol,
                      foregroundColor: Colores.noche,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                    ),
                    onPressed: _iniciarDescargaDatos,
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      'DESCARGAR DATOS AHORA ($sizeKb KB)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Descargar más tarde', style: TextStyle(color: Colores.tenue, fontSize: 11)),
                ),
              ] else if (_completado) ...[
                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.menta,
                      foregroundColor: Colores.noche,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: const Text(
                      '¡LISTO! CONTINUAR',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
