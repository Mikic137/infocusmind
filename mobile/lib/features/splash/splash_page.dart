import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/destino.dart';
import '../../core/tema.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _escala;
  late final Animation<double> _opacidad;

  int _puntos = 0;
  Timer? _timerPuntos;

  @override
  void initState() {
    super.initState();

    _controlador = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _escala = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controlador, curve: Curves.easeInOut),
    );

    _opacidad = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controlador, curve: Curves.easeInOut),
    );

    // Animación de los puntitos de carga retro
    _timerPuntos = Timer.periodic(const Duration(milliseconds: 400), (t) {
      if (mounted) setState(() => _puntos = (_puntos + 1) % 4);
    });

    _iniciar();
  }

  Future<void> _iniciar() async {
    // Ejecuta la comprobación de sesión y asegura un mínimo de 2.2 segundos para ver la intro
    final resultados = await Future.wait([
      pantallaInicial(),
      Future.delayed(const Duration(milliseconds: 2200)),
    ]);

    final destino = resultados.first as Widget;
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destino,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  void dispose() {
    _timerPuntos?.cancel();
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final puntosTexto = '.' * _puntos;

    return Scaffold(
      backgroundColor: Colores.noche,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animado con pulso y halo neón
            AnimatedBuilder(
              animation: _controlador,
              builder: (context, _) {
                return Transform.scale(
                  scale: _escala.value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colores.nocheClara,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colores.cian, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colores.cian.withValues(alpha: 0.45 * _opacidad.value),
                          offset: const Offset(0, 0),
                          blurRadius: 18,
                        ),
                        const BoxShadow(
                          color: Colores.sombraCarta,
                          offset: Offset(0, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Título estilo Pixel Arcade
            Text(
              'INFOCUSMIND',
              style: hud(18, color: Colores.luna),
            ),

            const SizedBox(height: 10),

            // Subtítulo retro
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colores.nocheClara,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colores.borde, width: 1.5),
              ),
              child: Text(
                'ENFOQUE & PRODUCTIVIDAD',
                style: hud(
                  8,
                  color: Colores.sol,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Texto de carga parpadeante
            SizedBox(
              height: 20,
              child: Text(
                'CARGANDO SISTEMA$puntosTexto',
                style: hud(
                  8,
                  color: Colores.tenue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
