import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../features/auth/auth_page.dart';
import '../features/home/home_page.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Elige la primera pantalla según la sesión del usuario.
/// Va directo a HomePage; la configuración y aprendizaje con IA está en la pestaña de Ayudante.
Future<Widget> pantallaInicial() async {
  if (!await AuthService.haySesion()) return const AuthPage();
  try {
    await dio.get('/profile');
    return const HomePage();
  } on DioException catch (e) {
    final codigo = e.response?.statusCode;
    if (codigo == 401) {
      await AuthService.cerrarSesion(); // token vencido o inválido
      return const AuthPage();
    }
    return const HomePage();
  }
}