import 'package:flutter/material.dart';
import 'core/tema.dart';
import 'core/usage_service.dart';
import 'features/splash/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  UsageService.inicializarListeners();
  runApp(MaterialApp(
    title: 'InfocusMind',
    debugShowCheckedModeBanner: false,
    theme: temaJuego(),
    home: const SplashPage(),
  ));
}
