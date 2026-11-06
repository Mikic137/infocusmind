import 'package:dio/dio.dart';
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
      await _storage.write(key: 'token', value: r.data['token']);
      return null;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final map = e.response!.data as Map;
        return map['error']?.toString() ??
            map['message']?.toString() ??
            'Error del servidor (${e.response?.statusCode})';
      }
      if (e.type == DioExceptionType.connectionTimeout) {
        return 'Tiempo de conexión agotado (servidor ocupado o despertando). Reintenta en unos segundos.';
      }
      return 'No se pudo conectar con el servidor (${e.message ?? e.type.name})';
    } catch (e) {
      return 'Error de conexión: $e';
    }
  }

  static Future<bool> haySesion() async =>
      (await _storage.read(key: 'token')) != null;

  static Future<void> cerrarSesion() => _storage.delete(key: 'token');
}
