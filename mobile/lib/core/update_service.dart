import 'dart:async';
import 'package:flutter/material.dart';
import 'api_client.dart';
import 'tema.dart';
import 'usage_service.dart';

class UpdateService {
  static const int codigoVersionActual = 9; // v1.1.8
  static const String nombreVersionActual = '1.1.8';

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
        final latestVersion = data['latest_version']?.toString() ?? '1.1.6';
        final urlDescarga = data['download_url']?.toString() ??
            'https://infocusmind-production.up.railway.app/download/InfocusMind_v1.1.6.apk';
        final mensaje = data['message']?.toString() ??
            'Nueva actualización de rendimiento, seguridad bancaria PayPal y optimización de misiones disponible.';
        final force = data['force_update'] == true || codigoVersionActual < minCode;

        if (codigoVersionActual < latestCode) {
          _dialogoMostrado = true;
          if (!context.mounted) return;
          await _mostrarDialogoActualizacion(
            context,
            version: latestVersion,
            mensaje: mensaje,
            url: urlDescarga,
            esObligatoria: force,
          );
        }
      }
    } catch (_) {
      // Si falla la red, no bloqueamos la app localmente
    }
  }

  /// Muestra la pantalla gamer de descarga de parche estilo Dragon Ball Legends
  static Future<void> mostrarTarjetaActualizacion(
    BuildContext context, {
    String version = '1.1.6',
    String? mensaje,
    String? url,
    bool obligatoria = true,
  }) async {
    final urlFinal = url ?? 'https://infocusmind-production.up.railway.app/download/InfocusMind_v1.1.6.apk';
    final mensajeFinal = mensaje ??
        'Se requiere descargar un paquete de datos para optimizar la seguridad bancaria PayPal, límites de IA y mapas de enfoque.';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoParcheGamer(
        version: version,
        mensaje: mensajeFinal,
        urlFinal: urlFinal,
      ),
    );
  }

  static Future<void> _mostrarDialogoActualizacion(
    BuildContext context, {
    required String version,
    required String mensaje,
    required String url,
    bool esObligatoria = true,
  }) async {
    await mostrarTarjetaActualizacion(
      context,
      version: version,
      mensaje: mensaje,
      url: url,
      obligatoria: esObligatoria,
    );
  }
}

class _DialogoParcheGamer extends StatefulWidget {
  final String version;
  final String mensaje;
  final String urlFinal;

  const _DialogoParcheGamer({
    required this.version,
    required this.mensaje,
    required this.urlFinal,
  });

  @override
  State<_DialogoParcheGamer> createState() => _DialogoParcheGamerState();
}

class _DialogoParcheGamerState extends State<_DialogoParcheGamer> {
  bool _descargando = false;
  double _progreso = 0.0;
  String _estadoDescarga = '';
  String? _errorDescarga;
  bool _descargaCompleta = false;
  String? _rutaApkDescargada;

  int _indiceConsejo = 0;
  Timer? _timerConsejos;

  final List<Map<String, String>> _consejos = [
    {
      'tag': '⚡ KI DE ESTUDIO',
      'texto': 'Un bloque Pomodoro de 25 min recarga tu energía mental al máximo sin agotar tu cerebro.',
    },
    {
      'tag': '⚔️ COMBO DE MISIÓN',
      'texto': 'Dividir una tarea difícil en 3 misiones pequeñas aumenta un 300% tu probabilidad de completarla.',
    },
    {
      'tag': '🛡️ ESCUDO LAUNCHER',
      'texto': 'El Modo Launcher bloquea las redes sociales como una barrera de energía impenetrable.',
    },
    {
      'tag': '⭐ RANGO PLUS',
      'texto': 'InfocusMind Plus desbloquea IA ilimitada y mapas de ruta infinitos para tus exámenes.',
    },
    {
      'tag': '🧘 ONDAS BINAURALES',
      'texto': 'Usa sonidos de lluvia o frecuencias alfa para alcanzar hiper-concentración en menos de 5 min.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _iniciarRotacionConsejos();
  }

  void _iniciarRotacionConsejos() {
    _timerConsejos = Timer.periodic(const Duration(milliseconds: 3800), (t) {
      if (!mounted) return;
      setState(() {
        _indiceConsejo = (_indiceConsejo + 1) % _consejos.length;
      });
    });
  }

  @override
  void dispose() {
    _timerConsejos?.cancel();
    super.dispose();
  }

  Future<void> _iniciarDescarga() async {
    setState(() {
      _descargando = true;
      _progreso = 0.01;
      _estadoDescarga = 'Conectando con el servidor de datos...';
      _errorDescarga = null;
      _descargaCompleta = false;
    });

    try {
      final cacheDir = await UsageService.obtenerRutaCache() ??
          '/data/user/0/com.infocusmind.mobile/cache';
      final targetPath = '$cacheDir/InfocusMind_v${widget.version}.apk';

      await dio.download(
        widget.urlFinal,
        targetPath,
        onReceiveProgress: (rec, total) {
          if (total > 0 && mounted) {
            final frac = rec / total;
            final mbRec = (rec / (1024 * 1024)).toStringAsFixed(1);
            final mbTot = (total / (1024 * 1024)).toStringAsFixed(1);
            setState(() {
              _progreso = frac;
              _estadoDescarga = '$mbRec MB / $mbTot MB (${(frac * 100).toInt()}%)';
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _progreso = 1.0;
        _descargando = false;
        _descargaCompleta = true;
        _rutaApkDescargada = targetPath;
        _estadoDescarga = '¡Parche descargado! Listo para instalar.';
      });

      // Abre el instalador del sistema automáticamente
      await UsageService.instalarApk(targetPath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _descargando = false;
        _errorDescarga = 'Error al descargar el parche de datos: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final consejoActual = _consejos[_indiceConsejo];

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF0A0F1D),
                Color(0xFF060912),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colores.cian, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colores.cian.withValues(alpha: 0.35),
                blurRadius: 30,
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
              // Header Gamer
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colores.cian, Color(0xFF0079C1)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colores.cian.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
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
                            border: Border.all(color: Colores.sol.withValues(alpha: 0.7)),
                          ),
                          child: const Text(
                            '⚡ PARCHE DE DATOS REQUERIDO',
                            style: TextStyle(
                              color: Colores.sol,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'InfocusMind v${widget.version}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                widget.mensaje,
                style: const TextStyle(
                  color: Colores.luna,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // Carrusel rotativo de Tips estilo DB Legends
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: Container(
                  key: ValueKey<int>(_indiceConsejo),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colores.cian.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tips_and_updates_rounded, color: Colores.sol, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            consejoActual['tag']!,
                            style: const TextStyle(
                              color: Colores.sol,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        consejoActual['texto']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_errorDescarga != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colores.coral.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colores.coral, width: 1),
                  ),
                  child: Text(
                    _errorDescarga!,
                    style: const TextStyle(color: Colores.coral, fontSize: 11),
                  ),
                ),
              ],

              // Barra de descarga tipo Ki Energy Bar
              if (_descargando) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colores.sol.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progreso > 0 ? _progreso : null,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colores.sol),
                          minHeight: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _estadoDescarga,
                            style: const TextStyle(
                              color: Colores.sol,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colores.sol,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Descargando paquetes de datos... Por favor no salgas de la app.',
                        style: TextStyle(color: Colores.tenue, fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
              ] else if (_descargaCompleta) ...[
                // Botón si terminó y el usuario quiere reinstalar
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.menta,
                      foregroundColor: Colores.noche,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (_rutaApkDescargada != null) {
                        await UsageService.instalarApk(_rutaApkDescargada!);
                      }
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 22),
                    label: const Text(
                      'INSTALAR PARCHE Y CONTINUAR',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),
                ),
              ] else ...[
                // Botón principal de descarga del parche
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.cian,
                      foregroundColor: Colores.noche,
                      elevation: 8,
                      shadowColor: Colores.cian.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _iniciarDescarga,
                    icon: const Icon(Icons.cloud_download_rounded, size: 22),
                    label: const Text(
                      'DESCARGAR PARCHE DE DATOS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),

              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colores.tenue,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  ),
                  onPressed: () async {
                    await UsageService.abrirUrl(widget.urlFinal);
                  },
                  icon: const Icon(Icons.open_in_browser_rounded, size: 14),
                  label: const Text(
                    'Descargar vía navegador (enlace directo)',
                    style: TextStyle(fontSize: 10.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
