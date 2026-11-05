import 'package:flutter/material.dart';
import 'core/tema.dart';
import 'features/splash/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'InfocusMind',
    debugShowCheckedModeBanner: false,
    theme: temaJuego(),
    home: const SplashPage(),
  ));
}
