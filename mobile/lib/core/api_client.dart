import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';
import 'update_service.dart';

const _almacen = FlutterSecureStorage();

final dio = Dio(BaseOptions(
  baseUrl: 'https://infocusmind-production.up.railway.app',
  connectTimeout: const Duration(seconds: 20),
  receiveTimeout: const Duration(seconds: 60),
  sendTimeout: const Duration(seconds: 20),
))
  ..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Identificador de versión oficial de la aplicación móvil
      options.headers['x-app-version'] = '1.1.2';
      options.headers['x-app-version-code'] = '3';

      // Rutas públicas que no requieren token de sesión
      final path = options.path;
      if (path.contains('/login') ||
          path.contains('/register') ||
          path.contains('/auth/google') ||
          path.contains('/health') ||
          path.contains('/app/version')) {
        return handler.next(options);
      }
      try {
        final token = await _almacen
            .read(key: 'token')
            .timeout(const Duration(seconds: 2));
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {}
      return handler.next(options);
    },
    onError: (DioException err, handler) {
      if (err.response?.statusCode == 426) {
        final ctx = globalNavigatorKey.currentContext;
        if (ctx != null) {
          UpdateService.mostrarTarjetaActualizacion(ctx);
        }
      }
      return handler.next(err);
    },
  ));
