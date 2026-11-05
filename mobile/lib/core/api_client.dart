import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _almacen = FlutterSecureStorage();

// 10.0.2.2 es la dirección con la que el emulador ve tu PC
final dio = Dio(BaseOptions(
  baseUrl: 'http://10.0.2.2:8080',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 90),
))
  ..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _almacen.read(key: 'token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));