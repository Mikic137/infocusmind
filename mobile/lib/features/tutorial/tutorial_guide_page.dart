import 'package:flutter/material.dart';
import '../../core/auth_service.dart';
import '../../core/tema.dart';

class TutorialGuidePage extends StatefulWidget {
  final bool desdeRegistro;
  final bool bloqueante;
  final VoidCallback? onCompletado;

  const TutorialGuidePage({
    super.key,
    this.desdeRegistro = false,
    this.bloqueante = false,
    this.onCompletado,
  });

  @override
  State<TutorialGuidePage> createState() => _TutorialGuidePageState();
}

class _TutorialGuidePageState extends State<TutorialGuidePage> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;

  final List<Map<String, dynamic>> _pasos = [
    {
      'paso': 1,
      'etiqueta': 'Misiones',
      'titulo': '1. Crea y Conquista tus Misiones',
      'subtitulo': 'Convierte grandes tareas en metas diarias',
      'icono': Icons.checklist_rounded,
      'color': Colores.cian,
      'descripcion':
          'En la pestaña principal «Misiones» organizas todo lo que debes estudiar. Cada tarea tiene una barra de progreso que se llena a medida que completas sus pasos.',
      'tip': '💡 Consejo: Pulsa el botón «+ Nueva misión» para empezar.',
    },
    {
      'paso': 2,
      'etiqueta': 'Ayudante IA',
      'titulo': '2. Desglose con Inteligencia Artificial',
      'subtitulo': 'Di adiós a la procrastinación',
      'icono': Icons.smart_toy_rounded,
      'color': Colores.violeta,
      'descripcion':
          '¿Tienes un examen difícil o un proyecto largo? En la pestaña «Ayudante», pídele a la IA que divida tu tema en micropasos alcanzables de 15 a 45 minutos.',
      'tip': '🎙️ Consejo: Puedes hablarle usando tu voz con el botón del micrófono.',
    },
    {
      'paso': 3,
      'etiqueta': 'Launcher',
      'titulo': '3. Modo Launcher Anti-Distracciones',
      'subtitulo': 'Blindaje total contra redes sociales',
      'icono': Icons.security_rounded,
      'color': Colores.menta,
      'descripcion':
          'Al estudiar, activa el Modo Launcher para ocultar juegos y apps adictivas como TikTok o Instagram. Tu pantalla se convertirá en un entorno 100% de enfoque.',
      'tip': '🛡️ Consejo: Al terminar tu sesión de estudio, se desactiva con un toque.',
    },
    {
      'paso': 4,
      'etiqueta': 'Webs',
      'titulo': '4. Bloqueador de Sitios Web y Juegos',
      'subtitulo': 'Cero tentaciones en Chrome o navegadores',
      'icono': Icons.public_off_rounded,
      'color': Colores.coral,
      'descripcion':
          'InfocusMind vigila que nadie abra sitios de juegos web (como YouTube, Poki o Roblox) mientras estudias, evitando que te distraigas por internet.',
      'tip': '🚫 Consejo: Puedes añadir tus propios dominios en la pestaña «Bloqueo».',
    },
    {
      'paso': 5,
      'etiqueta': 'XP & Nivel',
      'titulo': '5. Gamificación RPG y Experiencia',
      'subtitulo': 'Sube de nivel cada día de estudio',
      'icono': Icons.military_tech_rounded,
      'color': Colores.sol,
      'descripcion':
          'Cada misión y minuto de estudio te otorga XP. Revisa en «Logros» y «Mapa» tu nivel, tu racha de días consecutivos y los trofeos desbloqueados.',
      'tip': '🏆 Consejo: Si mantienes tu racha activa, obtendrás multiplicadores de XP.',
    },
    {
      'paso': 6,
      'etiqueta': 'Estilos',
      'titulo': '6. Personaliza tu Estilo de Estudio',
      'subtitulo': 'Juvenil Arcade, Maduro Minimalista o Cálido',
      'icono': Icons.palette_rounded,
      'color': Colores.lila,
      'descripcion':
          'Toca el icono de la paleta en la barra superior en cualquier momento para cambiar entre el tema Arcade (pixel gamer), Maduro (sin píxeles, ejecutivo) o Biblioteca Cálida.',
      'tip': '🎨 Consejo: El tema Maduro transforma la app con tipografía limpia y profesional.',
    },
  ];

  Future<void> _finalizarTutorial() async {
    await AuthService.guardarTutorialCompletado();
    widget.onCompletado?.call();
    if (mounted) Navigator.of(context).pop();
  }

  void _confirmarSalto() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colores.nocheClara,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colores.sol, width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colores.sol, size: 24),
            const SizedBox(width: 10),
            Text('¿Saltar el tutorial?', style: hud(11, color: Colors.white)),
          ],
        ),
        content: const Text(
          'Podrás volver a consultar esta guía en cualquier momento pulsando el icono (?) de ayuda en la parte superior.',
          style: TextStyle(color: Colores.luna, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuar viendo', style: TextStyle(color: Colores.tenue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colores.sol,
              foregroundColor: Colores.noche,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _finalizarTutorial();
            },
            child: const Text('Saltar y Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_paginaActual];
    final Color pasoColor = paso['color'] as Color;

    return PopScope(
      canPop: !widget.bloqueante,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && widget.bloqueante) {
          _confirmarSalto();
        }
      },
      child: Scaffold(
        backgroundColor: Colores.noche,
        appBar: AppBar(
          backgroundColor: Colores.noche,
          elevation: 0,
          automaticallyImplyLeading: !widget.bloqueante,
          title: Text(
            'Guía Paso a Paso',
            style: hud(12, color: Colores.luna),
          ),
          actions: [
            // Botón de Saltar tutorial visible y accesible
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _confirmarSalto,
                icon: const Icon(Icons.fast_forward_rounded, size: 16, color: Colores.sol),
                label: const Text(
                  'Saltar tutorial',
                  style: TextStyle(
                    color: Colores.sol,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),

              // Diagrama de Roadmap con 6 pasos circulares conectados por flechas
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colores.nocheClara,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colores.borde),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_pasos.length * 2 - 1, (i) {
                      if (i.isOdd) {
                        // Flecha conectora entre pasos
                        final prevIndex = i ~/ 2;
                        final activa = prevIndex < _paginaActual;
                        return Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: activa ? pasoColor : Colores.tenue.withValues(alpha: 0.3),
                        );
                      }

                      // Círculo numerado de paso
                      final index = i ~/ 2;
                      final esActual = index == _paginaActual;
                      final esCompletado = index < _paginaActual;
                      final colorPaso = _pasos[index]['color'] as Color;

                      return GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: esActual ? 36 : 28,
                          height: esActual ? 36 : 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: esActual
                                ? colorPaso
                                : (esCompletado
                                    ? colorPaso.withValues(alpha: 0.25)
                                    : Colores.noche),
                            border: Border.all(
                              color: esActual
                                  ? Colors.white
                                  : (esCompletado ? colorPaso : Colores.borde),
                              width: esActual ? 2.2 : 1.2,
                            ),
                            boxShadow: esActual
                                ? [
                                    BoxShadow(
                                      color: colorPaso.withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: esActual
                                    ? (colorPaso == Colores.sol || colorPaso == Colores.menta
                                        ? Colores.noche
                                        : Colors.white)
                                    : (esCompletado ? colorPaso : Colores.tenue),
                                fontWeight: FontWeight.bold,
                                fontSize: esActual ? 14 : 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Text(
                'Paso ${_paginaActual + 1} de ${_pasos.length}: ${paso['etiqueta']}',
                style: TextStyle(
                  color: pasoColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),

              // Contenido interactivo con PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _paginaActual = i),
                  itemCount: _pasos.length,
                  itemBuilder: (context, index) {
                    final item = _pasos[index];
                    final Color c = item['color'] as Color;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),

                          // Icono circular destacado con resplandor
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: c, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.35),
                                  blurRadius: 22,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(item['icono'] as IconData, size: 48, color: c),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            item['titulo'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['subtitulo'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),

                          // Tarjeta de descripción
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colores.nocheClara,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colores.borde),
                            ),
                            child: Text(
                              item['descripcion'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colores.luna,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Consejo pro
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: c.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: c.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              item['tip'] as String,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colores.luna.withValues(alpha: 0.95),
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Controles de navegación inferior
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    if (_paginaActual > 0)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colores.borde),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Anterior', style: TextStyle(color: Colores.tenue)),
                      ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pasoColor,
                        foregroundColor: pasoColor == Colores.menta || pasoColor == Colores.sol
                            ? Colores.noche
                            : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        elevation: 4,
                      ),
                      onPressed: () {
                        if (_paginaActual < _pasos.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _finalizarTutorial();
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _paginaActual < _pasos.length - 1
                                ? 'Siguiente paso'
                                : '¡Comenzar ahora!',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _paginaActual < _pasos.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.check_circle_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
