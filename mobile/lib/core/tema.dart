import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Colores {
  // Fondos y superficies
  static const noche = Color(0xFF0D0B1D);          // Fondo principal negro-púrpura
  static const nocheClara = Color(0xFF191538);     // Tarjetas y menús (índigo oscuro)
  static const sombraCarta = Color(0xFF06050D);    // Sombra sólida pixel
  static const borde = Color(0xFF2F295E);          // Borde retro estándar
  static const bordeBrillante = Color(0xFF4C438E); // Borde iluminado

  // Neones principales
  static const violeta = Color(0xFF8B5CF6);
  static const violetaSombra = Color(0xFF5B21B6);
  static const lila = Color(0xFFC4B5FD);

  // Acentos Arcade
  static const sol = Color(0xFFFFD000);            // Oro / amarillo arcade para XP y estrellas
  static const solSombra = Color(0xFFB39200);
  static const menta = Color(0xFF00FFB2);          // Verde-cian neón para éxitos y metas
  static const mentaSombra = Color(0xFF00A875);
  static const coral = Color(0xFFFF2E63);          // Rojo neón / fuego para rachas
  static const coralSombra = Color(0xFFB3143B);
  static const cian = Color(0xFF00F0FF);           // Cian puro arcade
  static const cianSombra = Color(0xFF009CB0);
  static const magenta = Color(0xFFFF007F);        // Fucsia arcade
  static const magentaSombra = Color(0xFFB30059);

  // Textos
  static const luna = Color(0xFFF5F3FF);           // Blanco brillante de alto contraste
  static const tenue = Color(0xFF908BAE);          // Texto secundario legible
}

TextStyle hud(double size, {Color color = Colores.sol}) =>
    GoogleFonts.pressStart2p(fontSize: size, color: color, height: 1.4);

OutlineInputBorder _borde(Color c) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(4),
  borderSide: BorderSide(color: c, width: 2),
);

ThemeData temaJuego() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colores.violeta,
      brightness: Brightness.dark,
    ),
  );
  final texto = base.textTheme.apply(
    bodyColor: Colores.luna,
    displayColor: Colores.luna,
    fontFamily: GoogleFonts.baloo2().fontFamily,
  );
  return base.copyWith(
    scaffoldBackgroundColor: Colores.noche,
    textTheme: texto,
    appBarTheme: AppBarTheme(
      backgroundColor: Colores.noche,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.baloo2(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colores.luna,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colores.nocheClara,
      labelStyle: const TextStyle(color: Colores.tenue),
      hintStyle: const TextStyle(color: Colores.tenue),
      border: _borde(Colores.borde),
      enabledBorder: _borde(Colores.borde),
      focusedBorder: _borde(Colores.cian),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colores.nocheClara,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Colores.cian, width: 2),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colores.nocheClara,
      behavior: SnackBarBehavior.floating,
      contentTextStyle:
          GoogleFonts.baloo2(color: Colores.luna, fontSize: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Colores.sol, width: 2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colores.cian,
        textStyle: GoogleFonts.baloo2(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colores.nocheClara,
      indicatorColor: Colores.violeta.withValues(alpha: 0.45),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.baloo2(fontWeight: FontWeight.w600, color: Colores.luna),
      ),
      iconTheme: WidgetStateProperty.resolveWith((estados) => IconThemeData(
        color: estados.contains(WidgetState.selected)
            ? Colores.cian
            : Colores.tenue,
      )),
    ),
  );
}

/// Botón arcade con bisel y sombra sólida que se hunde al tocarlo.
class BotonJuego extends StatefulWidget {
  final String texto;
  final VoidCallback? onPressed;
  final Color color;
  final Color sombra;
  final Color colorTexto;
  final IconData? icono;
  final bool expandir;
  const BotonJuego({
    super.key,
    required this.texto,
    required this.onPressed,
    this.color = Colores.violeta,
    this.sombra = Colores.violetaSombra,
    this.colorTexto = Colors.white,
    this.icono,
    this.expandir = true,
  });

  @override
  State<BotonJuego> createState() => _BotonJuegoState();
}

class _BotonJuegoState extends State<BotonJuego> {
  bool abajo = false;

  @override
  Widget build(BuildContext context) {
    final activo = widget.onPressed != null;
    final fondo = activo ? widget.color : Colores.borde;
    final sombra = activo ? widget.sombra : Colores.sombraCarta;
    final texto = activo ? widget.colorTexto : Colores.tenue;

    return GestureDetector(
      onTapDown: activo ? (_) => setState(() => abajo = true) : null,
      onTapUp: activo ? (_) => setState(() => abajo = false) : null,
      onTapCancel: activo ? () => setState(() => abajo = false) : null,
      onTap: widget.onPressed,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          transform: Matrix4.translationValues(0, abajo ? 3 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: sombra,
                offset: Offset(0, abajo ? 1 : 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: widget.expandir ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icono != null) ...[
                Icon(widget.icono, color: texto, size: 22),
                const SizedBox(width: 8),
              ],
              Text(
                widget.texto,
                style: GoogleFonts.baloo2(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: texto,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta tipo ventana de diálogo retro con sombra sólida.
class TarjetaJuego extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borde;
  const TarjetaJuego({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borde = Colores.borde,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colores.nocheClara,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borde, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colores.sombraCarta,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Barra retro de XP / Salud estilo arcade con brillo neón y relleno visible garantizado.
class BarraJuego extends StatelessWidget {
  final double valor;
  final Color color;
  final double alto;
  const BarraJuego({
    super.key,
    required this.valor,
    required this.color,
    this.alto = 12,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: valor.clamp(0.0, 1.0).toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Container(
        height: alto,
        decoration: BoxDecoration(
          color: Colores.noche,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colores.borde, width: 1.5),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ancho = (constraints.maxWidth * v).clamp(0.0, constraints.maxWidth);
            return Stack(
              children: [
                Positioned.fill(
                  child: Container(color: Colores.noche),
                ),
                if (ancho > 0)
                  Container(
                    width: ancho,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.65),
                          blurRadius: 5,
                          spreadRadius: 0.5,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// HUD del jugador con Nivel y Barra de XP retro.
class HudNivel extends StatelessWidget {
  final int xp;
  const HudNivel({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    final nivel = xp ~/ 100 + 1;
    final actual = xp % 100;

    return TarjetaJuego(
      borde: Colores.bordeBrillante,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colores.sol,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colores.solSombra,
                  offset: Offset(0, 3),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text('$nivel', style: hud(16, color: Colores.noche)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'LVL $nivel',
                      style: hud(10, color: Colores.luna),
                    ),
                    const Spacer(),
                    Text(
                      '$actual / 100 XP',
                      style: GoogleFonts.baloo2(
                        fontWeight: FontWeight.w700,
                        color: Colores.tenue,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                BarraJuego(valor: actual / 100, color: Colores.sol, alto: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
