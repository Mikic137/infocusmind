import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

const _storage = FlutterSecureStorage();

class AuthService {
  /// Devuelve null si todo salió bien, o el mensaje de error.
  static Future<String?> enviar(
      String ruta, String email, String password) async {
    try {
      final r = await dio.post(ruta, data: {
        'email': email,
        'password': password,
      });
      final token = r.data['token']?.toString();
      if (token != null) {
        try {
          await _storage
              .write(key: 'token', value: token)
              .timeout(const Duration(seconds: 3));
          await _storage
              .write(key: 'user_email', value: email)
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('Error guardando token: $e');
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final map = e.response!.data as Map;
        return map['error']?.toString() ??
            map['message']?.toString() ??
            'Error del servidor (${e.response?.statusCode})';
      }
      if (e.type == DioExceptionType.connectionTimeout) {
        return 'Tiempo de conexión agotado. Revisa tu conexión a internet o datos móviles.';
      }
      return 'No se pudo conectar con el servidor: ${e.message ?? e.type.name}';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  /// Comprueba la salud del servidor y la conectividad
  static Future<String> diagnosticarConexion() async {
    try {
      final r = await dio.get('/health');
      if (r.statusCode == 200) {
        return 'Servidor conectado correctamente (200 OK)';
      }
      return 'Respuesta del servidor: ${r.statusCode}';
    } on DioException catch (e) {
      return 'Fallo de conexión: ${e.message ?? e.type.name}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  static Future<bool> haySesion() async {
    try {
      final t = await _storage
          .read(key: 'token')
          .timeout(const Duration(seconds: 2));
      return t != null;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> autenticarConGoogle(String email) async {
    try {
      final r = await dio.post('/auth/google', data: {'email': email});
      final token = r.data['token']?.toString();
      if (token != null) {
        try {
          await _storage
              .write(key: 'token', value: token)
              .timeout(const Duration(seconds: 3));
          await _storage
              .write(key: 'user_email', value: email)
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('Error guardando token: $e');
        }
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final map = e.response!.data as Map;
        return map['error']?.toString() ?? 'Error al autenticar con Google';
      }
      return 'No se pudo conectar con el servidor Google Auth';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }

  static Future<String?> obtenerCorreoUsuario() async {
    try {
      return await _storage.read(key: 'user_email');
    } catch (_) {
      return null;
    }
  }

  static Future<void> cerrarSesion() async {
    try {
      await _storage
          .delete(key: 'token')
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  static Future<bool> esTutorialCompletado() async {
    try {
      final v = await _storage.read(key: 'tutorial_completado_v112');
      return v == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> guardarTutorialCompletado() async {
    try {
      await _storage.write(key: 'tutorial_completado_v112', value: 'true');
    } catch (_) {}
  }
}
