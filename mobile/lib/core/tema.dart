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

enum EstiloVisual {
  arcade, // Juvenil Arcade HUD / Pixel Art
  maduro, // Minimalista Maduro / Ejecutivo
  calido, // Biblioteca Cálida & Café
  monocromo, // Blanco y Negro / Neutral Minimalista
}

class GestorTema extends ChangeNotifier {
  static final GestorTema instancia = GestorTema._();
  GestorTema._();

  EstiloVisual _estilo = EstiloVisual.arcade;
  EstiloVisual get estilo => _estilo;

  bool get esArcade => _estilo == EstiloVisual.arcade;
  bool get esMaduro => _estilo == EstiloVisual.maduro;
  bool get esCalido => _estilo == EstiloVisual.calido;
  bool get esMonocromo => _estilo == EstiloVisual.monocromo;

  Color get colorFondo {
    switch (_estilo) {
      case EstiloVisual.maduro:
        return const Color(0xFF0F172A);
      case EstiloVisual.calido:
        return const Color(0xFF1C1917);
      case EstiloVisual.monocromo:
        return const Color(0xFF101010);
      case EstiloVisual.arcade:
        return Colores.noche;
    }
  }

  Color get colorSuperficie {
    switch (_estilo) {
      case EstiloVisual.maduro:
        return const Color(0xFF1E293B);
      case EstiloVisual.calido:
        return const Color(0xFF292524);
      case EstiloVisual.monocromo:
        return const Color(0xFF1B1B1B);
      case EstiloVisual.arcade:
        return Colores.nocheClara;
    }
  }

  Color get colorBorde {
    switch (_estilo) {
      case EstiloVisual.maduro:
        return const Color(0xFF334155);
      case EstiloVisual.calido:
        return const Color(0xFF443831);
      case EstiloVisual.monocromo:
        return const Color(0xFF383838);
      case EstiloVisual.arcade:
        return Colores.borde;
    }
  }

  Color get colorAcento {
    switch (_estilo) {
      case EstiloVisual.maduro:
        return const Color(0xFF38BDF8); // Cian cielo profesional
      case EstiloVisual.calido:
        return const Color(0xFFF59E0B); // Ámbar miel cálido
      case EstiloVisual.monocromo:
        return Colors.white; // Blanco puro minimalista
      case EstiloVisual.arcade:
        return Colores.cian;
    }
  }

  Color get colorSecundario {
    switch (_estilo) {
      case EstiloVisual.maduro:
        return const Color(0xFF6366F1); // Indigo moderno
      case EstiloVisual.calido:
        return const Color(0xFFD97706); // Miel tostada
      case EstiloVisual.monocromo:
        return const Color(0xFFE5E5E5); // Blanco plata neutro
      case EstiloVisual.arcade:
        return Colores.violeta;
    }
  }

  void cambiarEstilo(EstiloVisual nuevo) {
    if (_estilo == nuevo) return;
    _estilo = nuevo;
    notifyListeners();
  }

  ThemeData temaActual() {
    switch (_estilo) {
      case EstiloVisual.maduro:
        return temaMaduro();
      case EstiloVisual.calido:
        return temaCalido();
      case EstiloVisual.monocromo:
        return temaMonocromo();
      case EstiloVisual.arcade:
        return temaJuego();
    }
  }
}

TextStyle hud(double size, {Color? color, FontWeight? weight}) {
  if (GestorTema.instancia.esMaduro) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size * 1.35,
      color: color ?? Colors.white,
      fontWeight: weight ?? FontWeight.w800,
      letterSpacing: -0.2,
    );
  }
  if (GestorTema.instancia.esCalido) {
    return GoogleFonts.outfit(
      fontSize: size * 1.35,
      color: color ?? const Color(0xFFFEF3C7),
      fontWeight: weight ?? FontWeight.w700,
      letterSpacing: 0.1,
    );
  }
  if (GestorTema.instancia.esMonocromo) {
    return GoogleFonts.inter(
      fontSize: size * 1.35,
      color: color ?? Colors.white,
      fontWeight: weight ?? FontWeight.w800,
      letterSpacing: -0.2,
    );
  }
  return GoogleFonts.pressStart2p(
    fontSize: size,
    color: color ?? Colores.sol,
    height: 1.4,
  );
}

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

/// Botón con diseño adaptable según el estilo seleccionado.
class BotonJuego extends StatefulWidget {
  final String texto;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? sombra;
  final Color colorTexto;
  final IconData? icono;
  final bool expandir;
  const BotonJuego({
    super.key,
    required this.texto,
    required this.onPressed,
    this.color,
    this.sombra,
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
    final gestor = GestorTema.instancia;
    final activo = widget.onPressed != null;
    final fondo = activo ? (widget.color ?? gestor.colorSecundario) : gestor.colorBorde;
    final sombra = widget.sombra ?? (widget.color ?? gestor.colorSecundario);
    final texto = activo ? widget.colorTexto : Colores.tenue;

    if (gestor.esMaduro) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          width: widget.expandir ? double.infinity : null,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: fondo,
              foregroundColor: texto,
              elevation: activo ? 4 : 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: widget.onPressed,
            icon: widget.icono != null ? Icon(widget.icono, size: 20) : const SizedBox.shrink(),
            label: Text(
              widget.texto,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    if (gestor.esCalido) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          width: widget.expandir ? double.infinity : null,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: fondo,
              foregroundColor: texto,
              elevation: activo ? 3 : 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: widget.onPressed,
            icon: widget.icono != null ? Icon(widget.icono, size: 20) : const SizedBox.shrink(),
            label: Text(
              widget.texto,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    if (gestor.esMonocromo) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          width: widget.expandir ? double.infinity : null,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: activo ? (widget.color ?? Colors.white) : const Color(0xFF262626),
              foregroundColor: activo ? (widget.color != null ? widget.colorTexto : Colors.black) : const Color(0xFF737373),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: activo ? (widget.color ?? Colors.white) : const Color(0xFF404040),
                  width: 1.2,
                ),
              ),
            ),
            onPressed: widget.onPressed,
            icon: widget.icono != null ? Icon(widget.icono, size: 20) : const SizedBox.shrink(),
            label: Text(
              widget.texto,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      );
    }

    // Arcade (Retro Pixel con sombra sólida)
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

/// Tarjeta adaptable según el tema (Retro pixel, Minimalista moderna o Cálida).
class TarjetaJuego extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borde;
  const TarjetaJuego({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borde,
  });

  @override
  Widget build(BuildContext context) {
    final gestor = GestorTema.instancia;
    final bordeColor = borde ?? gestor.colorBorde;

    if (gestor.esMaduro) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: gestor.colorSuperficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bordeColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
          ],
        ),
        child: child,
      );
    }

    if (gestor.esCalido) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: gestor.colorSuperficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: bordeColor, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              offset: const Offset(0, 3),
              blurRadius: 12,
            ),
          ],
        ),
        child: child,
      );
    }

    if (gestor.esMonocromo) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: gestor.colorSuperficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bordeColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              offset: const Offset(0, 3),
              blurRadius: 10,
            ),
          ],
        ),
        child: child,
      );
    }

    // Arcade (Retro Pixel con sombra sólida de 0 desenfoque)
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colores.nocheClara,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bordeColor, width: 2),
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

/// Barra de XP adaptable (Neón arcade, moderna difuminada o ámbar cálida).
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
    final gestor = GestorTema.instancia;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: valor.clamp(0.0, 1.0).toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        if (gestor.esMaduro || gestor.esCalido || gestor.esMonocromo) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(alto / 2),
            child: LinearProgressIndicator(
              value: v,
              minHeight: alto,
              backgroundColor: gestor.colorBorde,
              valueColor: AlwaysStoppedAnimation(gestor.esMonocromo ? Colors.white : color),
            ),
          );
        }

        return Container(
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
        );
      },
    );
  }
}

/// Nivel y Barra de Progreso totalmente transformable según el tema.
class HudNivel extends StatelessWidget {
  final int xp;
  const HudNivel({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    final gestor = GestorTema.instancia;
    final nivel = xp ~/ 100 + 1;
    final actual = xp % 100;

    if (gestor.esMaduro) {
      return TarjetaJuego(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '$nivel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Nivel $nivel • Concentración',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$actual / 100 XP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BarraJuego(valor: actual / 100, color: const Color(0xFF38BDF8), alto: 8),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (gestor.esCalido) {
      return TarjetaJuego(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '$nivel',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Nivel de Estudio $nivel',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFFEF3C7),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$actual / 100 XP',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFA8A29E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BarraJuego(valor: actual / 100, color: const Color(0xFFF59E0B), alto: 8),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (gestor.esMonocromo) {
      return TarjetaJuego(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$nivel',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Nivel $nivel • Enfoque Neutral',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$actual / 100 XP',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA3A3A3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BarraJuego(valor: actual / 100, color: Colors.white, alto: 8),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Arcade (Retro Pixel)
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

ThemeData temaMaduro() {
  const bg = Color(0xFF0F172A); // Slate 900
  const surface = Color(0xFF1E293B); // Slate 800
  const border = Color(0xFF334155);
  const accent = Color(0xFF38BDF8); // Sky blue
  const primary = Color(0xFF6366F1); // Indigo

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: bg,
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      bodyColor: const Color(0xFFF8FAFC),
      displayColor: const Color(0xFFF8FAFC),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border, width: 1.2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border, width: 1.2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: primary.withValues(alpha: 0.35),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 12),
      ),
      iconTheme: WidgetStateProperty.resolveWith((estados) => IconThemeData(
        color: estados.contains(WidgetState.selected) ? accent : const Color(0xFF94A3B8),
      )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent, width: 2)),
    ),
  );
}

ThemeData temaCalido() {
  const bg = Color(0xFF1C1917); // Stone 900 cálido
  const surface = Color(0xFF292524);
  const border = Color(0xFF44403C);
  const accent = Color(0xFFF59E0B); // Ámbar cálido
  const primary = Color(0xFFD97706); // Miel tostada

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: surface,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: bg,
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.outfit().fontFamily,
      bodyColor: const Color(0xFFFAFAF9),
      displayColor: const Color(0xFFFAFAF9),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFFEF3C7),
      ),
    ),
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: border, width: 1.2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: border, width: 1.2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: primary.withValues(alpha: 0.35),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.outfit(fontWeight: FontWeight.w600, color: const Color(0xFFFEF3C7), fontSize: 12),
      ),
      iconTheme: WidgetStateProperty.resolveWith((estados) => IconThemeData(
        color: estados.contains(WidgetState.selected) ? accent : const Color(0xFFA8A29E),
      )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent, width: 2)),
    ),
  );
}

ThemeData temaMonocromo() {
  const bg = Color(0xFF0F0F0F); // Negro neutro profundo
  const surface = Color(0xFF1B1B1B); // Gris oscuro neutro
  const border = Color(0xFF333333); // Gris medio sobrio
  const accent = Color(0xFFFFFFFF); // Blanco puro alto contraste
  const primary = Color(0xFFE5E5E5); // Blanco plata neutro
  const textMuted = Color(0xFFA3A3A3); // Gris legible

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: accent,
      secondary: primary,
      outline: border,
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: bg,
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.inter().fontFamily,
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border, width: 1.2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: border, width: 1.2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: Colors.white.withValues(alpha: 0.15),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 12),
      ),
      iconTheme: WidgetStateProperty.resolveWith((estados) => IconThemeData(
        color: estados.contains(WidgetState.selected) ? Colors.white : textMuted,
      )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      labelStyle: const TextStyle(color: textMuted),
      hintStyle: const TextStyle(color: textMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white, width: 1.8)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface,
      behavior: SnackBarBehavior.floating,
      contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: border, width: 1),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
  );
}

void mostrarSelectorTema(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: GestorTema.instancia.colorSuperficie,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_rounded, color: GestorTema.instancia.colorAcento, size: 24),
                  const SizedBox(width: 10),
                  Text('Personalizar Estilo Visual', style: hud(11, color: Colores.luna)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Elige la apariencia que mejor se adapte a tu forma de estudiar:',
                style: TextStyle(color: Colores.tenue, fontSize: 13),
              ),
              const SizedBox(height: 18),
              _buildOpcionTema(
                ctx,
                estilo: EstiloVisual.arcade,
                titulo: 'Juvenil / Cyberpunk HUD',
                subtitulo: 'Estilo arcade retro con fuente pixel art y colores neón',
                icono: Icons.sports_esports_rounded,
                color: Colores.violeta,
              ),
              const SizedBox(height: 10),
              _buildOpcionTema(
                ctx,
                estilo: EstiloVisual.maduro,
                titulo: 'Maduro / Minimalista Ejecutivo',
                subtitulo: 'Tipografía moderna limpia, tonos sobrios y sin exceso de IA',
                icono: Icons.workspace_premium_rounded,
                color: Colores.cian,
              ),
              const SizedBox(height: 10),
              _buildOpcionTema(
                ctx,
                estilo: EstiloVisual.calido,
                titulo: 'Biblioteca Cálida & Café',
                subtitulo: 'Ambiente sereno, tonos ámbar y lectura relajante',
                icono: Icons.menu_book_rounded,
                color: Colores.sol,
              ),
              const SizedBox(height: 10),
              _buildOpcionTema(
                ctx,
                estilo: EstiloVisual.monocromo,
                titulo: 'Blanco y Negro / Neutral',
                subtitulo: 'Minimalista puro, sobrio y sin distracciones de color',
                icono: Icons.contrast_rounded,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _buildOpcionTema(
  BuildContext context, {
  required EstiloVisual estilo,
  required String titulo,
  required String subtitulo,
  required IconData icono,
  required Color color,
}) {
  final seleccionado = GestorTema.instancia.estilo == estilo;
  return InkWell(
    onTap: () {
      GestorTema.instancia.cambiarEstilo(estilo);
      Navigator.of(context).pop();
    },
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: seleccionado ? color.withValues(alpha: 0.15) : GestorTema.instancia.colorFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: seleccionado ? color : GestorTema.instancia.colorBorde,
          width: seleccionado ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: const TextStyle(color: Colores.tenue, fontSize: 11),
                ),
              ],
            ),
          ),
          if (seleccionado)
            Icon(Icons.check_circle_rounded, color: color, size: 20),
        ],
      ),
    ),
  );
}
