import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppUso {
  final String package;
  final String name;
  final int seconds;
  AppUso({required this.package, required this.name, required this.seconds});

  factory AppUso.fromMap(Map<dynamic, dynamic> map) {
    return AppUso(
      package: (map['package'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      seconds: (map['seconds'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppInfo {
  final String package;
  final String name;
  AppInfo({required this.package, required this.name});

  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppInfo(
      package: (map['package'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
    );
  }
}

class UsageService {
  static const _canal = MethodChannel('com.infocusmind.mobile/usage');
  static const _almacen = FlutterSecureStorage();
  static const _claveDistractoras = 'apps_distractoras';
  static const _claveUtiles = 'apps_utiles';
  static const _claveHistorialDistracciones = 'historial_distracciones';

  /// Comprueba si el usuario ya concedió el permiso de "Acceso a datos de uso".
  static Future<bool> tienePermiso() async {
    try {
      final res = await _canal.invokeMethod<bool>('hasUsagePermission');
      return res ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error al verificar permiso de uso: $e');
      return false;
    }
  }

  /// Abre la pantalla del sistema de Android para activar el permiso.
  static Future<void> abrirAjustes() async {
    try {
      await _canal.invokeMethod('openUsageSettings');
    } on PlatformException catch (e) {
      debugPrint('Error al abrir ajustes de uso: $e');
    }
  }

  /// Obtiene la lista de apps usadas y sus segundos entre dos instantes de tiempo.
  static Future<List<AppUso>> obtenerUso(DateTime inicio, DateTime fin) async {
    try {
      final res = await _canal.invokeListMethod<Map<dynamic, dynamic>>(
        'getUsageDuring',
        {
          'startTime': inicio.millisecondsSinceEpoch,
          'endTime': fin.millisecondsSinceEpoch,
        },
      );
      if (res == null) return [];
      return res.map((m) => AppUso.fromMap(m)).toList();
    } on PlatformException catch (e) {
      debugPrint('Error al obtener uso de apps: $e');
      return [];
    }
  }

  /// Obtiene la lista de apps que se pueden abrir en el teléfono.
  static Future<List<AppInfo>> obtenerAppsInstaladas() async {
    try {
      final res = await _canal.invokeListMethod<Map<dynamic, dynamic>>('getInstalledApps');
      if (res == null) return [];
      return res.map((m) => AppInfo.fromMap(m)).toList();
    } on PlatformException catch (e) {
      debugPrint('Error al obtener apps instaladas: $e');
      return [];
    }
  }

  /// Carga los identificadores de paquetes marcados como distracciones por el usuario.
  static Future<List<String>> obtenerAppsDistractoras() async {
    final raw = await _almacen.read(key: _claveDistractoras);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Guarda la lista de paquetes marcados como distracciones.
  static Future<void> guardarAppsDistractoras(List<String> paquetes) async {
    await _almacen.write(key: _claveDistractoras, value: jsonEncode(paquetes));
  }

  /// Carga los paquetes seleccionados explícitamente como "Herramientas Útiles" para el Launcher de foco.
  static Future<List<String>> obtenerAppsUtiles() async {
    final raw = await _almacen.read(key: _claveUtiles);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Guarda los paquetes seleccionados como "Herramientas Útiles" para el Launcher de foco.
  static Future<void> guardarAppsUtiles(List<String> paquetes) async {
    await _almacen.write(key: _claveUtiles, value: jsonEncode(paquetes));
  }

  /// Devuelve las aplicaciones que se mostrarán en el Launcher durante el Modo Focus:
  /// - Si el usuario seleccionó "Apps útiles", muestra esas apps.
  /// - Si no seleccionó útiles, muestra todas las apps instaladas MENOS las distractoras.
  static Future<List<AppInfo>> obtenerAppsPermitidasParaLauncher() async {
    final todas = await obtenerAppsInstaladas();
    final utiles = (await obtenerAppsUtiles()).toSet();
    if (utiles.isNotEmpty) {
      return todas.where((a) => utiles.contains(a.package)).toList();
    }
    final distractoras = (await obtenerAppsDistractoras()).toSet();
    return todas.where((a) => !distractoras.contains(a.package)).toList();
  }

  /// Registra localmente las aplicaciones que se usaron como distracción durante una sesión.
  static Future<void> registrarDistraccionLocal(List<AppUso> distracciones) async {
    if (distracciones.isEmpty) return;
    try {
      final raw = await _almacen.read(key: _claveHistorialDistracciones);
      final List<dynamic> actual = raw != null && raw.isNotEmpty ? jsonDecode(raw) : [];
      final ahora = DateTime.now().toIso8601String();
      for (final d in distracciones) {
        actual.add({
          'package': d.package,
          'name': d.name,
          'seconds': d.seconds,
          'date': ahora,
        });
      }
      // Guardar máximo últimos 100 registros
      final recortado = actual.length > 100 ? actual.sublist(actual.length - 100) : actual;
      await _almacen.write(key: _claveHistorialDistracciones, value: jsonEncode(recortado));
    } catch (e) {
      debugPrint('Error guardando distracciones locales: $e');
    }
  }

  /// Obtiene un resumen consolidado de las distracciones registradas en el dispositivo.
  static Future<List<Map<String, dynamic>>> obtenerDistraccionesLocales() async {
    try {
      final raw = await _almacen.read(key: _claveHistorialDistracciones);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> lista = jsonDecode(raw);
      final mapa = <String, Map<String, dynamic>>{};
      for (final item in lista) {
        final pkg = item['package']?.toString() ?? '';
        final nom = item['name']?.toString() ?? pkg;
        final segs = (item['seconds'] as num?)?.toInt() ?? 0;
        if (pkg.isEmpty || segs <= 0) continue;
        if (!mapa.containsKey(pkg)) {
          mapa[pkg] = {'package': pkg, 'name': nom, 'seconds': 0, 'count': 0};
        }
        mapa[pkg]!['seconds'] = (mapa[pkg]!['seconds'] as int) + segs;
        mapa[pkg]!['count'] = (mapa[pkg]!['count'] as int) + 1;
      }
      final res = mapa.values.toList();
      res.sort((a, b) => (b['seconds'] as int).compareTo(a['seconds'] as int));
      return res;
    } catch (_) {
      return [];
    }
  }

  /// Muestra o actualiza la notificación persistente del temporizador de enfoque.
  static Future<void> mostrarNotificacion({
    required String titulo,
    required String tiempo,
  }) async {
    try {
      await _canal.invokeMethod('showFocusNotification', {
        'title': titulo,
        'time': tiempo,
      });
    } on PlatformException catch (e) {
      debugPrint('Error al mostrar notificación: $e');
    }
  }

  /// Cancela y retira la notificación persistente de enfoque.
  static Future<void> cancelarNotificacion() async {
    try {
      await _canal.invokeMethod('cancelFocusNotification');
    } on PlatformException catch (e) {
      debugPrint('Error al cancelar notificación: $e');
    }
  }

  /// Pide al sistema de Android que muestre el diálogo de "Permitir notificaciones" (Android 13+).
  static Future<void> solicitarPermisoNotificaciones() async {
    try {
      await _canal.invokeMethod('requestNotificationPermission');
    } on PlatformException catch (e) {
      debugPrint('Error solicitando permiso notificaciones: $e');
    }
  }

  /// Abre una aplicación del teléfono por su identificador de paquete.
  static Future<bool> abrirApp(String package) async {
    try {
      final res = await _canal.invokeMethod<bool>('launchApp', {'package': package});
      return res ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error al abrir app $package: $e');
      return false;
    }
  }

  /// Abre el selector nativo de Android para activar/desactivar InfocusMind como pantalla de inicio (Launcher).
  static Future<void> abrirSelectorLauncher() async {
    try {
      await _canal.invokeMethod('openHomeSettings');
    } on PlatformException catch (e) {
      debugPrint('Error al abrir selector de launcher: $e');
    }
  }

  /// Callback para cuando el usuario presiona el botón Home físico o gestual de Android.
  static VoidCallback? onHomePressed;

  /// Inicializa la escucha de eventos provenientes del canal nativo.
  static void inicializarListeners() {
    _canal.setMethodCallHandler((call) async {
      if (call.method == 'onHomeButtonPressed') {
        onHomePressed?.call();
      }
    });
  }

  /// Comprueba si InfocusMind está configurado actualmente como el Launcher predeterminado en Android.
  static Future<bool> esLauncherPredeterminado() async {
    try {
      final res = await _canal.invokeMethod<bool>('isDefaultLauncher');
      return res ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error al verificar launcher predeterminado: $e');
      return false;
    }
  }

  /// Comprueba si la app fue abierta directamente desde el botón HOME del sistema.
  static Future<bool> fueIniciadoDesdeHome() async {
    try {
      final res = await _canal.invokeMethod<bool>('wasLaunchedFromHome');
      return res ?? false;
    } on PlatformException catch (e) {
      debugPrint('Error al verificar origen de inicio: $e');
      return false;
    }
  }
}
