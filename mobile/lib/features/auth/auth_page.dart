import 'package:flutter/material.dart';
import '../../core/auth_service.dart';
import '../../core/destino.dart';
import '../../core/tema.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool esRegistro = false;
  bool cargando = false;
  String? error;

  Future<void> enviar() async {
    setState(() {
      cargando = true;
      error = null;
    });
    final ruta = esRegistro ? '/register' : '/login';
    final fallo =
        await AuthService.enviar(ruta, email.text.trim(), password.text);
    if (!mounted) return;
    if (fallo == null) {
      final destino = await pantallaInicial();
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => destino));
    } else {
      setState(() {
        error = fallo;
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.noche,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo nuevo de InfocusMind con estilo retro
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colores.nocheClara,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colores.cian, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colores.sombraCarta,
                          offset: Offset(0, 5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.psychology,
                                size: 54, color: Colores.cian),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('InfocusMind', style: hud(20, color: Colores.luna)),
                  const SizedBox(height: 10),
                  const Text('Estudia por misiones y gana XP.',
                      style: TextStyle(color: Colores.tenue, fontSize: 16)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Contraseña (mínimo 8 caracteres)'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colores.coral)),
                  ],
                  const SizedBox(height: 24),
                  BotonJuego(
                    texto: cargando
                        ? 'Un momento...'
                        : (esRegistro ? 'Crear cuenta' : 'Entrar'),
                    onPressed: cargando ? null : enviar,
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => setState(() => esRegistro = !esRegistro),
                    child: Text(esRegistro
                        ? 'Ya tengo cuenta'
                        : 'No tengo cuenta, quiero registrarme'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comprobando conexión...')),
                      );
                      final diag = await AuthService.diagnosticarConexion();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(diag),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.wifi_find_rounded,
                        size: 14, color: Colores.tenue),
                    label: const Text('Comprobar conexión con servidor',
                        style: TextStyle(color: Colores.tenue, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
