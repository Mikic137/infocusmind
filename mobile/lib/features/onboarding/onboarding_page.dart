import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/modelos.dart';
import '../../core/tema.dart';
import '../home/home_page.dart';
import '../tutorial/tutorial_guide_page.dart';

class Mensaje {
  final String rol; // 'user' o 'model'
  final String texto;
  Mensaje(this.rol, this.texto);
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final mensajes = <Mensaje>[];
  final controlador = TextEditingController();
  final scroll = ScrollController();
  bool esperando = false;
  bool terminado = false;
  String? error;

  @override
  void initState() {
    super.initState();
    pedirRespuesta(); // la IA saluda primero
  }

  @override
  void dispose() {
    controlador.dispose();
    scroll.dispose();
    super.dispose();
  }

  void bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> pedirRespuesta() async {
    setState(() {
      esperando = true;
      error = null;
    });
    bajar();
    try {
      final r = await dio.post('/onboarding/chat', data: {
        'messages': [
          for (final m in mensajes) {'role': m.rol, 'text': m.texto}
        ],
      });
      if (!mounted) return;
      setState(() {
        mensajes.add(Mensaje('model', r.data['reply'].toString()));
        terminado = r.data['done'] == true;
        esperando = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        error = mensajeError(e);
        esperando = false;
      });
    }
    bajar();
  }

  void enviar() {
    final texto = controlador.text.trim();
    if (texto.isEmpty || esperando || terminado) return;
    controlador.clear();
    setState(() => mensajes.add(Mensaje('user', texto)));
    pedirRespuesta();
  }

  Widget burbuja(Mensaje m) {
    final usuario = m.rol == 'user';
    return Align(
      alignment: usuario ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),
        decoration: BoxDecoration(
          color: usuario ? Colores.violeta : Colores.nocheClara,
          border: usuario ? null : Border.all(color: Colores.borde, width: 2),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(usuario ? 20 : 4),
            bottomRight: Radius.circular(usuario ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Text(
          m.texto,
          style: const TextStyle(
            fontSize: 18,
            height: 1.45,
            fontWeight: FontWeight.w400,
            color: Colores.luna,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = mensajes.length + (esperando ? 1 : 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conozcámonos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colores.cian),
            tooltip: 'Ver Tutorial',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TutorialGuidePage()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                itemCount: total,
                itemBuilder: (_, i) => i < mensajes.length
                    ? burbuja(mensajes[i])
                    : burbuja(Mensaje('model', 'Pensando...')),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(error!,
                            style: const TextStyle(color: Colores.coral))),
                    TextButton(
                        onPressed: pedirRespuesta,
                        child: const Text('Reintentar')),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: terminado
                  ? BotonJuego(
                texto: 'Empezar mi aventura',
                color: Colores.menta,
                sombra: Colores.mentaSombra,
                colorTexto: Colores.noche,
                onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomePage())),
              )
                  : Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controlador,
                      maxLength: 500,
                      onSubmitted: (_) => enviar(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu respuesta...',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                        backgroundColor: Colores.violeta,
                        minimumSize: const Size(52, 52)),
                    onPressed: esperando ? null : enviar,
                    icon: const Icon(Icons.send_rounded),
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