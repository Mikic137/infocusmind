import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/modelos.dart';
import '../../core/tema.dart';

class AssistantView extends StatefulWidget {
  final VoidCallback? onMisionCreada;
  final VoidCallback? onIrAMisiones;

  const AssistantView({
    super.key,
    this.onMisionCreada,
    this.onIrAMisiones,
  });

  @override
  State<AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<AssistantView> {
  int subModo = 0; // 0 = Dividir con IA, 1 = Conozcámonos / Aprender de ti

  // Estado para Dividir con IA
  final tituloCtrl = TextEditingController();
  final detallesCtrl = TextEditingController();
  DateTime? fechaSeleccionada;
  bool dividiendo = false;
  String? errorDivision;
  String? exitoDivision;

  // Estado para Aprende de Mí (Chat)
  final mensajes = <_MensajeChat>[];
  final chatCtrl = TextEditingController();
  final scrollChat = ScrollController();
  bool esperandoChat = false;
  bool chatIniciado = false;
  String? errorChat;

  @override
  void initState() {
    super.initState();
    fechaSeleccionada = DateTime.now();
  }

  @override
  void dispose() {
    tituloCtrl.dispose();
    detallesCtrl.dispose();
    chatCtrl.dispose();
    scrollChat.dispose();
    super.dispose();
  }

  void aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  // --- MÉTODOS PARA DIVIDIR MISIÓN CON IA ---

  Future<void> seleccionarFecha() async {
    final ahora = DateTime.now();
    final f = await showDatePicker(
      context: context,
      initialDate: fechaSeleccionada ?? ahora,
      firstDate: ahora.subtract(const Duration(days: 30)),
      lastDate: ahora.add(const Duration(days: 365)),
      helpText: 'DÍA PARA REALIZAR LA MISIÓN',
      cancelText: 'CANCELAR',
      confirmText: 'SELECCIONAR',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colores.cian,
              onPrimary: Colores.noche,
              surface: Colores.nocheClara,
              onSurface: Colores.luna,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Colores.nocheClara),
          ),
          child: child!,
        );
      },
    );
    if (f != null) {
      setState(() => fechaSeleccionada = f);
    }
  }

  String formatearFecha(DateTime? d) {
    if (d == null) return 'Sin fecha';
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final comp = DateTime(d.year, d.month, d.day);
    if (comp == hoy) return 'Hoy (${d.day}/${d.month})';
    if (comp == hoy.add(const Duration(days: 1))) return 'Mañana (${d.day}/${d.month})';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> ejecutarDivisionIA() async {
    final t = tituloCtrl.text.trim();
    final d = detallesCtrl.text.trim();
    if (t.isEmpty) {
      setState(() => errorDivision = 'Escribe el nombre o meta de tu misión');
      return;
    }

    setState(() {
      dividiendo = true;
      errorDivision = null;
      exitoDivision = null;
    });

    try {
      final fechaStr = fechaSeleccionada != null
          ? '${fechaSeleccionada!.year}-${fechaSeleccionada!.month.toString().padLeft(2, '0')}-${fechaSeleccionada!.day.toString().padLeft(2, '0')}'
          : null;

      final r = await dio.post('/tasks', data: {
        'title': t,
        'details': d,
        'scheduled_date': fechaStr,
      });

      if (!mounted) return;
      tituloCtrl.clear();
      detallesCtrl.clear();

      setState(() {
        dividiendo = false;
        exitoDivision = '¡Misión dividida exitosamente por la IA!';
      });

      widget.onMisionCreada?.call();

      if (r.data['adjusted'] == true) {
        final pct = ((r.data['factor'] as num) * 100).round();
        aviso('Tiempos calibrados al $pct% según tu rendimiento.');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        dividiendo = false;
        errorDivision = mensajeError(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        dividiendo = false;
        errorDivision = 'Error al generar misión: $e';
      });
    }
  }

  // --- MÉTODOS PARA CHAT APRENDE DE MÍ ---

  void scrollAbajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollChat.hasClients) {
        scrollChat.animateTo(
          scrollChat.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> iniciarChatSiEsNecesario() async {
    if (chatIniciado || esperandoChat) return;
    chatIniciado = true;
    await pedirRespuestaChat();
  }

  Future<void> pedirRespuestaChat() async {
    setState(() {
      esperandoChat = true;
      errorChat = null;
    });
    scrollAbajo();

    try {
      final r = await dio.post('/onboarding/chat', data: {
        'messages': [
          for (final m in mensajes) {'role': m.rol, 'text': m.texto}
        ],
      });
      if (!mounted) return;
      setState(() {
        mensajes.add(_MensajeChat('model', r.data['reply'].toString()));
        esperandoChat = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        errorChat = mensajeError(e);
        esperandoChat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorChat = 'Error en la conexión con la IA';
        esperandoChat = false;
      });
    }
    scrollAbajo();
  }

  void enviarMensajeChat() {
    final texto = chatCtrl.text.trim();
    if (texto.isEmpty || esperandoChat) return;
    chatCtrl.clear();
    setState(() => mensajes.add(_MensajeChat('user', texto)));
    pedirRespuestaChat();
  }

  void reiniciarChat() {
    setState(() {
      mensajes.clear();
      chatIniciado = false;
      errorChat = null;
    });
    iniciarChatSiEsNecesario();
  }

  // --- VISTAS ---

  Widget vistaDividirIA() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner informativo
          TarjetaJuego(
            borde: Colores.violeta,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colores.violeta.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colores.sol, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GENERADOR DE MISIONES IA', style: hud(10, color: Colores.sol)),
                      const SizedBox(height: 6),
                      const Text(
                        'Escribe una meta grande, examen o proyecto. DeepSeek lo fragmentará en micro-pasos con tiempos reales y foco gamificado.',
                        style: TextStyle(color: Colores.tenue, fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Formulario
          TarjetaJuego(
            borde: Colores.borde,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿QUÉ QUIERES LOGRAR?', style: hud(9, color: Colores.cian)),
                const SizedBox(height: 8),
                TextField(
                  controller: tituloCtrl,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Estudiar para el examen final de Cálculo',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                Text('DETALLES ADICIONALES (OPCIONAL)', style: hud(9, color: Colores.tenue)),
                const SizedBox(height: 8),
                TextField(
                  controller: detallesCtrl,
                  maxLines: 2,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Capítulos 4 y 5, teoremas y 10 ejercicios prácticos',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),

                // Selector de calendario
                Text('DÍA PARA REALIZARLO', style: hud(9, color: Colores.luna)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: seleccionarFecha,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colores.noche,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colores.cian.withValues(alpha: 0.8), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Colores.cian, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            formatearFecha(fechaSeleccionada),
                            style: const TextStyle(
                              color: Colores.luna,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colores.cian.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('CAMBIAR', style: hud(8, color: Colores.cian)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (errorDivision != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colores.coral.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colores.coral),
              ),
              child: Text(errorDivision!, style: const TextStyle(color: Colores.coral, fontSize: 13)),
            ),

          if (exitoDivision != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colores.menta.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colores.menta),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colores.menta),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      exitoDivision!,
                      style: const TextStyle(color: Colores.menta, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onIrAMisiones,
                    child: const Text('VER MISIONES', style: TextStyle(color: Colores.cian)),
                  ),
                ],
              ),
            ),

          BotonJuego(
            texto: dividiendo ? 'FRAGMENTANDO CON IA...' : 'DIVIDIR EN MICRO-PASOS',
            icono: Icons.auto_awesome,
            color: Colores.sol,
            sombra: Colores.solSombra,
            colorTexto: Colores.noche,
            onPressed: dividiendo ? null : ejecutarDivisionIA,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget vistaAprendeDeMi() {
    final total = mensajes.length + (esperandoChat ? 1 : 0);

    return Column(
      children: [
        // Cabecera del chat
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colores.nocheClara,
          child: Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Colores.cian, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONOZCAMONOS', style: hud(9, color: Colores.luna)),
                    const Text('La IA aprende tus horarios y ritmo de estudio',
                        style: TextStyle(color: Colores.tenue, fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colores.tenue, size: 20),
                tooltip: 'Reiniciar conversación',
                onPressed: reiniciarChat,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colores.borde),

        // Lista de mensajes
        Expanded(
          child: ListView.builder(
            controller: scrollChat,
            padding: const EdgeInsets.all(16),
            itemCount: total,
            itemBuilder: (_, i) {
              if (i < mensajes.length) {
                final m = mensajes[i];
                final usuario = m.rol == 'user';
                return Align(
                  alignment: usuario ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 290),
                    decoration: BoxDecoration(
                      color: usuario ? Colores.violeta : Colores.nocheClara,
                      border: usuario
                          ? null
                          : Border.all(color: Colores.bordeBrillante, width: 1.5),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(usuario ? 14 : 3),
                        bottomRight: Radius.circular(usuario ? 3 : 14),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colores.sombraCarta,
                          offset: Offset(0, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      m.texto,
                      style: const TextStyle(fontSize: 15, height: 1.25, color: Colores.luna),
                    ),
                  ),
                );
              }
              // Burbuja de pensando
              return Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colores.nocheClara,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colores.borde),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colores.cian),
                      ),
                      const SizedBox(width: 10),
                      Text('Analizando...', style: hud(8, color: Colores.tenue)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        if (errorChat != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(errorChat!, style: const TextStyle(color: Colores.coral, fontSize: 12)),
                ),
                TextButton(
                  onPressed: pedirRespuestaChat,
                  child: const Text('Reintentar', style: TextStyle(color: Colores.cian)),
                ),
              ],
            ),
          ),

        // Barra inferior de envío
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatCtrl,
                    maxLength: 500,
                    onSubmitted: (_) => enviarMensajeChat(),
                    decoration: const InputDecoration(
                      hintText: 'Cuéntame de tu ritmo de estudio...',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colores.violeta,
                    minimumSize: const Size(48, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: esperandoChat ? null : enviarMensajeChat,
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selector de sub-modo Cyberpunk
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colores.nocheClara,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colores.borde, width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => subModo = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: subModo == 0 ? Colores.violeta : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'DIVIDIR CON IA',
                          style: hud(9, color: subModo == 0 ? Colors.white : Colores.tenue),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => subModo = 1);
                      iniciarChatSiEsNecesario();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: subModo == 1 ? Colores.violeta : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'APRENDE DE MÍ',
                          style: hud(9, color: subModo == 1 ? Colors.white : Colores.tenue),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: subModo == 0 ? vistaDividirIA() : vistaAprendeDeMi(),
        ),
      ],
    );
  }
}

class _MensajeChat {
  final String rol;
  final String texto;
  _MensajeChat(this.rol, this.texto);
}
