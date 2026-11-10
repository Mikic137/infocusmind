import 'package:flutter/material.dart';
import '../../core/tema.dart';

class TutorialGuidePage extends StatefulWidget {
  final bool desdeRegistro;
  const TutorialGuidePage({super.key, this.desdeRegistro = false});

  @override
  State<TutorialGuidePage> createState() => _TutorialGuidePageState();
}

class _TutorialGuidePageState extends State<TutorialGuidePage> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;

  final List<Map<String, dynamic>> _pasos = [
    {
      'titulo': 'Desglose con Inteligencia Artificial',
      'subtitulo': 'Convierte lo abrumador en alcanzable',
      'icono': Icons.auto_awesome,
      'color': Colores.violeta,
      'descripcion':
          '¿Tienes un examen difícil o un proyecto universitario largo? No te paralices. InfocusMind analiza tu tarea y la fragmenta automáticamente en micro-pasos de 15 a 45 minutos con tiempos realistas.',
      'tip': '💡 Consejo: Puedes editar o cambiar cualquier paso si prefieres otro orden.',
    },
    {
      'titulo': 'Interfaz Invisible (Zero UI)',
      'subtitulo': 'Dicta tus misiones hablando',
      'icono': Icons.mic_rounded,
      'color': Colores.cian,
      'descripcion':
          'Olvídate de teclear en pantallas pequeñas. Toca el micrófono en el asistente o en la creación de tareas y habla con naturalidad. El sistema transcribe y estructura tu misión al instante.',
      'tip': '🎙️ Consejo: Prueba decir "Estudiar cálculo integral capítulo 2 mañana a las 3pm".',
    },
    {
      'titulo': 'Modo Launcher Anti-Distracciones',
      'subtitulo': 'Blinda tu celular contra redes sociales',
      'icono': Icons.security_rounded,
      'color': Colores.menta,
      'descripcion':
          'Activa el Modo Launcher cuando inicies tu sesión de estudio. Reemplazará tu pantalla de inicio habitual por una interfaz minimalista y enfocada, ocultando apps adictivas como TikTok, Instagram o juegos.',
      'tip': '🛡️ Consejo: Al terminar tu sesión de estudio, el launcher se desactiva con un solo toque.',
    },
    {
      'titulo': 'Bloqueador de Sitios Web y Dominios',
      'subtitulo': 'Cero tentaciones en el navegador',
      'icono': Icons.public_off_rounded,
      'color': Colores.coral,
      'descripcion':
          'Evita saltarte el bloqueo abriendo el navegador. InfocusMind vigila que no ingreses a sitios de juegos o entretenimiento (como YouTube, Poki, Roblox o redes web) mientras estás en modo concentración.',
      'tip': '🚫 Consejo: Puedes personalizar tu lista negra de dominios en Ajustes de Distracciones.',
    },
    {
      'titulo': 'Gamificación RPG y Experiencia (XP)',
      'subtitulo': 'Cada minuto de estudio te hace subir de nivel',
      'icono': Icons.military_tech_rounded,
      'color': Colores.sol,
      'descripcion':
          'Transforma el esfuerzo en una aventura. Cada micro-paso completado te otorga XP equivalente al tiempo invertido. Sube de rango, mantén tu racha de días consecutivos y celebra tus logros académicos.',
      'tip': '🏆 Consejo: Mantener tu racha diaria desbloquea multiplicadores y prestigio en tu perfil.',
    },
    {
      'titulo': 'Temporizador Pomodoro Calibrado',
      'subtitulo': 'Enfoque profundo a tu propio ritmo',
      'icono': Icons.timer_rounded,
      'color': Colores.cian,
      'descripcion':
          'Entra en la zona de concentración con el temporizador integrado. Detecta tus pausas y calcula tu ritmo real para recomendarte descansos exactos y evitar el agotamiento mental.',
      'tip': '⏱️ Consejo: Un bloque de 25-45 minutos seguido de 5 minutos de descanso es la fórmula ideal.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_paginaActual];
    final Color pasoColor = paso['color'] as Color;

    return Scaffold(
      backgroundColor: Colores.noche,
      appBar: AppBar(
        backgroundColor: Colores.noche,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colores.luna),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Cómo funciona InfocusMind',
          style: hud(14, color: Colores.luna),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Saltar', style: TextStyle(color: Colores.tenue)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indicador de pasos superior
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: List.generate(_pasos.length, (index) {
                  final activo = index == _paginaActual;
                  final pasado = index < _paginaActual;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: activo
                            ? pasoColor
                            : (pasado ? Colores.luna.withValues(alpha: 0.6) : Colores.borde),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Contenido con PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _paginaActual = i),
                itemCount: _pasos.length,
                itemBuilder: (context, index) {
                  final item = _pasos[index];
                  final Color c = item['color'] as Color;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        // Icono circular grande animado
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: c, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: c.withValues(alpha: 0.3),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(item['icono'] as IconData, size: 54, color: c),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          item['titulo'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['subtitulo'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 22),

                        // Descripción clara
                        Container(
                          padding: const EdgeInsets.all(18),
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
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        // Tip o truco pro
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item['tip'] as String,
                                  style: TextStyle(
                                    color: Colores.luna.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Controles inferiores
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_paginaActual > 0)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colores.borde),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      if (_paginaActual < _pasos.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _paginaActual < _pasos.length - 1 ? 'Siguiente' : '¡Entendido, a Estudiar!',
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
    );
  }
}
