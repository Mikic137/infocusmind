import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _almacen = FlutterSecureStorage();

final dio = Dio(BaseOptions(
  baseUrl: 'https://infocusmind-production.up.railway.app',
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 90),
  sendTimeout: const Duration(seconds: 30),
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
