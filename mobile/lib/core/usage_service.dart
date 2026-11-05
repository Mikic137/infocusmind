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
}
