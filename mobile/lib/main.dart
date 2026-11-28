import 'package:flutter/material.dart';
import 'core/tema.dart';
import 'core/usage_service.dart';
import 'features/splash/splash_page.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GestorTema.instancia.cargarTemaGuardado();
  UsageService.inicializarListeners();
  runApp(ListenableBuilder(
    listenable: GestorTema.instancia,
    builder: (context, _) => MaterialApp(
      navigatorKey: globalNavigatorKey,
      title: 'InfocusMind',
      debugShowCheckedModeBanner: false,
      theme: GestorTema.instancia.temaActual(),
      home: const SplashPage(),
    ),
  ));
}
