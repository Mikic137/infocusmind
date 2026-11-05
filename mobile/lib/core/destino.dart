import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../features/auth/auth_page.dart';
import '../features/home/home_page.dart';
import '../features/onboarding/onboarding_page.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Elige la primera pantalla según la sesión y el perfil del usuario.
Future<Widget> pantallaInicial() async {
  if (!await AuthService.haySesion()) return const AuthPage();
  try {
    await dio.get('/profile');
    return const HomePage();
  } on DioException catch (e) {
    final codigo = e.response?.statusCode;
    if (codigo == 404) return const OnboardingPage(); // aún sin perfil
    if (codigo == 401) {
      await AuthService.cerrarSesion(); // token vencido o inválido
      return const AuthPage();
    }
    return const HomePage(); // sin conexión: no bloqueamos la app
  }
}