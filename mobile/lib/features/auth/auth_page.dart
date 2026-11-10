import 'package:flutter/material.dart';
import '../../core/auth_service.dart';
import '../../core/destino.dart';
import '../../core/tema.dart';
import '../../core/update_service.dart';
import '../../core/usage_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final googleEmailController = TextEditingController();

  bool esRegistro = false;
  bool cargando = false;
  bool verPassword = false;
  bool verConfirmPassword = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.comprobarActualizacion(context);
    });
  }

  // Evaluación de fortaleza de contraseña
  bool get tieneMinimo8 => passwordController.text.length >= 8;
  bool get tieneMayuscula => passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get tieneNumero => passwordController.text.contains(RegExp(r'[0-9]'));
  bool get esComun {
    final t = passwordController.text.toLowerCase().trim();
    const debiles = {
      '12345678', '123456789', '1234567890', 'password', 'contraseña',
      'qwertyuiop', '11111111', '87654321', 'abcdefgh', 'infocusmind'
    };
    return debiles.contains(t);
  }

  double get fortalezaScore {
    if (passwordController.text.isEmpty) return 0.0;
    double score = 0.0;
    if (tieneMinimo8) score += 0.35;
    if (tieneMayuscula) score += 0.35;
    if (tieneNumero) score += 0.30;
    if (esComun) score = 0.15;
    return score.clamp(0.0, 1.0);
  }

  Color get fortalezaColor {
    final s = fortalezaScore;
    if (s < 0.4) return Colores.coral;
    if (s < 0.75) return Colores.sol;
    return Colores.menta;
  }

  String get fortalezaTexto {
    final s = fortalezaScore;
    if (passwordController.text.isEmpty) return '';
    if (esComun) return 'Demasiado fácil (no permitida)';
    if (s < 0.4) return 'Contraseña débil';
    if (s < 0.75) return 'Contraseña aceptable';
    return '¡Contraseña fuerte y segura!';
  }

  Future<void> enviar() async {
    final mail = emailController.text.trim();
    final pass = passwordController.text;

    if (mail.isEmpty || !mail.contains('@')) {
      setState(() => error = 'Por favor ingresa un correo electrónico válido');
      return;
    }

    if (esRegistro) {
      if (!tieneMinimo8) {
        setState(() => error = 'La contraseña debe tener al menos 8 caracteres');
        return;
      }
      if (esComun) {
        setState(() => error = 'La contraseña es muy común. Elige una más segura');
        return;
      }
      if (!tieneMayuscula || !tieneNumero) {
        setState(() => error = 'La contraseña debe incluir al menos una mayúscula y un número');
        return;
      }
      if (pass != confirmPasswordController.text) {
        setState(() => error = 'Las contraseñas no coinciden');
        return;
      }
    } else {
      if (pass.isEmpty) {
        setState(() => error = 'Por favor ingresa tu contraseña');
        return;
      }
    }

    setState(() {
      cargando = true;
      error = null;
    });

    final ruta = esRegistro ? '/register' : '/login';
    final fallo = await AuthService.enviar(ruta, mail, pass);

    if (!mounted) return;
    if (fallo == null) {
      final destino = await pantallaInicial();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destino));
    } else {
      setState(() {
        error = fallo;
        cargando = false;
      });
    }
  }

  Future<void> mostrarDialogoGoogle() async {
    googleEmailController.clear();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colores.nocheClara,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colores.borde, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Acceder con Google',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu cuenta de Google / Gmail para entrar sin necesidad de recordar contraseña:',
              style: TextStyle(color: Colores.tenue, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: googleEmailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'tu.correo@gmail.com',
                hintStyle: TextStyle(color: Colores.tenue.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.mail_outline, color: Colores.cian),
                filled: true,
                fillColor: Colores.noche,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colores.borde),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colores.tenue)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colores.cian,
              foregroundColor: Colores.noche,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final gMail = googleEmailController.text.trim();
              if (!gMail.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa un correo de Gmail válido')),
                );
                return;
              }
              Navigator.of(ctx).pop();
              setState(() {
                cargando = true;
                error = null;
              });
              final fallo = await AuthService.autenticarConGoogle(gMail);
              if (!mounted) return;
              if (fallo == null) {
                final destino = await pantallaInicial();
                if (!mounted) return;
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destino));
              } else {
                setState(() {
                  error = fallo;
                  cargando = false;
                });
              }
            },
            child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.noche,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo de InfocusMind
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colores.nocheClara,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: esRegistro ? Colores.menta : Colores.cian,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (esRegistro ? Colores.menta : Colores.cian).withValues(alpha: 0.2),
                          offset: const Offset(0, 6),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.psychology, size: 48, color: esRegistro ? Colores.menta : Colores.cian),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('InfocusMind', style: hud(22, color: Colores.luna)),
                  const SizedBox(height: 10),

                  // Banner elegante para descargar la versión más reciente
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colores.sol.withValues(alpha: 0.16),
                          Colores.nocheClara,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colores.sol.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.download_for_offline_rounded, color: Colores.sol, size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Versión v1.1.0 Disponible',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Descarga la app oficial actualizada',
                                style: TextStyle(
                                  color: Colores.tenue,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colores.sol,
                            foregroundColor: Colores.noche,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => UsageService.abrirUrl(
                            'https://infocusmind-production.up.railway.app/descargar',
                          ),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text(
                            'Descargar',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Selector diferenciado tipo Tabs
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colores.nocheClara,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colores.borde),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() {
                              esRegistro = false;
                              error = null;
                            }),
                            borderRadius: BorderRadius.circular(9),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !esRegistro ? Colores.violeta : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                'Iniciar Sesión',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !esRegistro ? Colors.white : Colores.tenue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() {
                              esRegistro = true;
                              error = null;
                            }),
                            borderRadius: BorderRadius.circular(9),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: esRegistro ? Colores.menta : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                'Crear Cuenta',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: esRegistro ? Colores.noche : Colores.tenue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Subtítulo contextual
                  Text(
                    esRegistro
                        ? '🌱 Únete hoy y comienza a subir de nivel con IA'
                        : '⚡ Bienvenido de nuevo. Mantén tu racha de estudio activa',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colores.tenue, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Botón Acceder con Google (Destacado)
                  InkWell(
                    onTap: cargando ? null : mostrarDialogoGoogle,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            offset: const Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 28),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            esRegistro ? 'Registrarme con Google' : 'Continuar con Google',
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colores.borde)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('o con tu correo', style: TextStyle(color: Colores.tenue.withValues(alpha: 0.7), fontSize: 12)),
                      ),
                      const Expanded(child: Divider(color: Colores.borde)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Campo Correo
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Correo Electrónico',
                      prefixIcon: const Icon(Icons.email_outlined, color: Colores.cian),
                      filled: true,
                      fillColor: Colores.nocheClara,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colores.borde),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Campo Contraseña
                  TextField(
                    controller: passwordController,
                    obscureText: !verPassword,
                    onChanged: esRegistro ? (_) => setState(() {}) : null,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: esRegistro ? 'Crea una contraseña segura' : 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline, color: Colores.cian),
                      suffixIcon: IconButton(
                        icon: Icon(verPassword ? Icons.visibility_off : Icons.visibility, color: Colores.tenue),
                        onPressed: () => setState(() => verPassword = !verPassword),
                      ),
                      filled: true,
                      fillColor: Colores.nocheClara,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colores.borde),
                      ),
                    ),
                  ),

                  // Medidor de fortaleza de contraseña si es registro
                  if (esRegistro && passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fortalezaScore,
                        backgroundColor: Colores.borde,
                        valueColor: AlwaysStoppedAnimation<Color>(fortalezaColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(fortalezaTexto, style: TextStyle(color: fortalezaColor, fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('${(fortalezaScore * 100).toInt()}%', style: TextStyle(color: fortalezaColor, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colores.nocheClara,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colores.borde),
                      ),
                      child: Column(
                        children: [
                          _buildCheckItem('Mínimo 8 caracteres', tieneMinimo8),
                          _buildCheckItem('Al menos una mayúscula (A-Z)', tieneMayuscula),
                          _buildCheckItem('Al menos un número (0-9)', tieneNumero),
                          _buildCheckItem('No usar contraseñas fáciles como 12345678', !esComun),
                        ],
                      ),
                    ),
                  ],

                  // Confirmar contraseña (solo registro)
                  if (esRegistro) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: !verConfirmPassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        prefixIcon: const Icon(Icons.lock_reset_rounded, color: Colores.menta),
                        suffixIcon: IconButton(
                          icon: Icon(verConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colores.tenue),
                          onPressed: () => setState(() => verConfirmPassword = !verConfirmPassword),
                        ),
                        filled: true,
                        fillColor: Colores.nocheClara,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colores.borde),
                        ),
                      ),
                    ),
                  ],

                  if (error != null) ...[
                    const SizedBox(height: 14),
                    if (error!.toLowerCase().contains('actualiz') ||
                        error!.contains('1.1.0') ||
                        error!.contains('426') ||
                        error!.contains('download')) ...[
                      _TarjetaActualizacionElegante(
                        mensaje: error!,
                        onDescargar: () => UsageService.abrirUrl(
                          'https://infocusmind-production.up.railway.app/descargar',
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colores.coral.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colores.coral.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colores.coral, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error!,
                                style: const TextStyle(color: Colores.coral, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 22),

                  // Botón principal
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: esRegistro ? Colores.menta : Colores.violeta,
                        foregroundColor: esRegistro ? Colores.noche : Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: cargando ? null : enviar,
                      child: cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              esRegistro ? 'Crear mi Cuenta de Estudiante' : 'Entrar a InfocusMind',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Comprobando conexión con servidor...')),
                      );
                      final diag = await AuthService.diagnosticarConexion();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(diag), duration: const Duration(seconds: 4)),
                        );
                      }
                    },
                    icon: const Icon(Icons.wifi_find_rounded, size: 15, color: Colores.tenue),
                    label: const Text('Comprobar conexión con servidor', style: TextStyle(color: Colores.tenue, fontSize: 12)),
                  ),
                  const SizedBox(height: 8),

                  // Botón directo para descargar actualización
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colores.sol,
                        side: const BorderSide(color: Colores.sol, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => UsageService.abrirUrl(
                        'https://infocusmind-production.up.railway.app/descargar',
                      ),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text(
                        'Descargar InfocusMind v1.1.0 (APK)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String texto, bool cumple) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            cumple ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: cumple ? Colores.menta : Colores.tenue.withValues(alpha: 0.5),
            size: 15,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: cumple ? Colores.luna : Colores.tenue,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaActualizacionElegante extends StatelessWidget {
  final String mensaje;
  final VoidCallback onDescargar;

  const _TarjetaActualizacionElegante({
    required this.mensaje,
    required this.onDescargar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colores.sol.withValues(alpha: 0.18),
            Colores.violeta.withValues(alpha: 0.22),
            Colores.nocheClara,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colores.sol, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colores.sol.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colores.sol, Color(0xFFFFA502)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colores.sol.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.system_update_rounded,
                  color: Color(0xFF11111B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colores.sol.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colores.sol.withValues(alpha: 0.6)),
                      ),
                      child: const Text(
                        '⚡ ACTUALIZACIÓN REQUERIDA',
                        style: TextStyle(
                          color: Colores.sol,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'InfocusMind v1.1.0 Disponible',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Hemos lanzado una versión con acceso Google, mayor seguridad en contraseñas, tutorial interactivo, bloqueo de dominios web y selector de temas.',
            style: TextStyle(color: Colores.luna, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BeneficioItem(texto: 'Acceso directo con cuenta Google / Gmail'),
                _BeneficioItem(texto: 'Bloqueo de sitios web (YouTube, TikTok, Juegos)'),
                _BeneficioItem(texto: 'Selector de estilos (Maduro, Juvenil, Cálido)'),
                _BeneficioItem(texto: 'Guía tutorial interactiva paso a paso'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colores.sol,
                foregroundColor: const Color(0xFF11111B),
                elevation: 6,
                shadowColor: Colores.sol.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onDescargar,
              icon: const Icon(Icons.download_rounded, size: 22),
              label: const Text(
                'DESCARGAR E INSTALAR AHORA',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Descarga directa oficial sin esperas',
              style: TextStyle(color: Colores.tenue, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _BeneficioItem extends StatelessWidget {
  final String texto;
  const _BeneficioItem({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colores.menta, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: Colores.luna, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
