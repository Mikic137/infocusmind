import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_client.dart';
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
  bool hayNuevaVersion = false;
  String urlDescarga = 'https://infocusmind-production.up.railway.app/descargar';

  @override
  void initState() {
    super.initState();
    _verificarSiRequiereActualizacion();
  }

  Future<void> _verificarSiRequiereActualizacion() async {
    try {
      final r = await dio.get('/app/version');
      if (r.statusCode == 200 && r.data is Map) {
        final data = r.data as Map;
        final latestCode = (data['latest_version_code'] as num?)?.toInt() ?? 1;
        final force = data['force_update'] == true;
        // Solo mostramos opciones de actualización si la versión instalada es MENOR que la del servidor
        if (UpdateService.codigoVersionActual < latestCode && force) {
          if (mounted) {
            setState(() {
              hayNuevaVersion = true;
              urlDescarga = data['download_url']?.toString() ?? urlDescarga;
            });
            UpdateService.comprobarActualizacion(context);
          }
        }
      }
    } catch (_) {}
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

  void _abrirDialogoRecuperarCuenta() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoRecuperarCuenta(
        correoInicial: emailController.text.trim(),
        onPasswordRestablecida: (correo, nuevaPass) {
          setState(() {
            emailController.text = correo;
            passwordController.text = nuevaPass;
            esRegistro = false;
            error = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colores.menta,
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colores.noche),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Contraseña actualizada exitosamente! Inicia sesión con tus nuevas credenciales.',
                      style: TextStyle(color: Colores.noche, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              duration: Duration(seconds: 4),
            ),
          );
        },
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

                  // Solo se muestra si el servidor indica que hay una versión más nueva que la instalada
                  if (hayNuevaVersion) ...[
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
                                  'Nueva Versión Disponible',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Descarga la actualización obligatoria',
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
                            onPressed: () => UsageService.abrirUrl(urlDescarga),
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
                  ],

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

                  // Enlace para recuperar cuenta si es modo login
                  if (!esRegistro) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: _abrirDialogoRecuperarCuenta,
                        icon: const Icon(Icons.lock_reset_rounded, size: 15, color: Colores.cian),
                        label: const Text(
                          '¿Olvidaste tu contraseña? Recuperar',
                          style: TextStyle(
                            color: Colores.cian,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],

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

                  // Solo se muestra si el servidor indica que hay una versión más nueva que la instalada
                  if (hayNuevaVersion) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colores.sol,
                          side: const BorderSide(color: Colores.sol, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => UsageService.abrirUrl(urlDescarga),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text(
                          'Descargar Actualización Obligatoria (APK)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  // Texto poco visto y discreto con la versión oficial
                  Text(
                    'v${UpdateService.nombreVersionActual} • Build ${UpdateService.codigoVersionActual}',
                    style: TextStyle(
                      color: Colores.tenue.withValues(alpha: 0.35),
                      fontSize: 11,
                      letterSpacing: 0.5,
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
                _BeneficioItem(texto: 'Selector de 4 estilos (Maduro, Juvenil, Cálido, B&W)'),
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

/// Diálogo profesional con Bot Asistente de Seguridad para recuperar cuenta y verificar existencia de correo
class _DialogoRecuperarCuenta extends StatefulWidget {
  final String correoInicial;
  final void Function(String correo, String nuevaPassword) onPasswordRestablecida;

  const _DialogoRecuperarCuenta({
    required this.correoInicial,
    required this.onPasswordRestablecida,
  });

  @override
  State<_DialogoRecuperarCuenta> createState() => _DialogoRecuperarCuentaState();
}

class _DialogoRecuperarCuentaState extends State<_DialogoRecuperarCuenta> {
  int _paso = 1; // 1: Email, 2: OTP, 3: Nueva Password, 4: Éxito
  late final TextEditingController _correoCtrl;
  final _codigoCtrl = TextEditingController();
  final _nuevaPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _cargando = false;
  String? _error;
  String _codigoGenerado = '';
  bool _verNuevaPass = false;
  bool _verConfirmPass = false;

  @override
  void initState() {
    super.initState();
    _correoCtrl = TextEditingController(text: widget.correoInicial);
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _codigoCtrl.dispose();
    _nuevaPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  // Criterios de seguridad
  bool get _tieneMinimo8 => _nuevaPassCtrl.text.length >= 8;
  bool get _tieneMayuscula => _nuevaPassCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _tieneNumero => _nuevaPassCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _noEsComun {
    final t = _nuevaPassCtrl.text.toLowerCase();
    const faciles = ['12345678', 'password', 'contraseña', 'qwerty123', 'admin123', '123456789'];
    return !faciles.any((f) => t.contains(f));
  }

  double get _fortalezaScore {
    int p = 0;
    if (_tieneMinimo8) p++;
    if (_tieneMayuscula) p++;
    if (_tieneNumero) p++;
    if (_noEsComun && _nuevaPassCtrl.text.isNotEmpty) p++;
    return p / 4.0;
  }

  Color get _fortalezaColor {
    final s = _fortalezaScore;
    if (s <= 0.25) return Colores.coral;
    if (s <= 0.5) return const Color(0xFFFF9800);
    if (s <= 0.75) return Colores.sol;
    return Colores.menta;
  }

  Future<void> _solicitarCodigo() async {
    final email = _correoCtrl.text.trim();
    if (!email.contains('@') || !email.contains('.') || email.length < 5) {
      setState(() => _error = 'Por favor ingresa un correo electrónico válido.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    final res = await AuthService.solicitarRecuperacion(email);
    if (!mounted) return;

    if (res['success'] == true) {
      setState(() {
        _codigoGenerado = res['code']?.toString() ?? '';
        _cargando = false;
        _error = null;
        _paso = 2;
      });
    } else {
      setState(() {
        _cargando = false;
        _error = res['error']?.toString() ?? 'Error al verificar la cuenta.';
      });
    }
  }

  void _validarCodigo() {
    final ing = _codigoCtrl.text.trim();
    if (ing.isEmpty) {
      setState(() => _error = 'Ingresa el código OTP de 6 dígitos que te proporcionó el Bot.');
      return;
    }
    if (ing != _codigoGenerado) {
      setState(() => _error = 'El código ingresado es incorrecto. Verifica que coincida exactamente.');
      return;
    }
    setState(() {
      _error = null;
      _paso = 3;
    });
  }

  Future<void> _restablecerPassword() async {
    final p1 = _nuevaPassCtrl.text;
    final p2 = _confirmPassCtrl.text;

    if (p1.isEmpty) {
      setState(() => _error = 'Ingresa tu nueva contraseña.');
      return;
    }
    if (p1 != p2) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    if (!_tieneMinimo8 || !_tieneMayuscula || !_tieneNumero || !_noEsComun) {
      setState(() => _error = 'La contraseña no cumple los requisitos mínimos de seguridad.');
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    final fallo = await AuthService.cambiarPasswordConCodigo(
      email: _correoCtrl.text.trim(),
      code: _codigoCtrl.text.trim(),
      newPassword: p1,
    );
    if (!mounted) return;

    if (fallo == null) {
      setState(() {
        _cargando = false;
        _error = null;
        _paso = 4;
      });
    } else {
      setState(() {
        _cargando = false;
        _error = fallo;
      });
    }
  }

  Widget _buildStepPill(int pasoNumero, String etiqueta) {
    final activo = _paso == pasoNumero;
    final completado = _paso > pasoNumero;

    return Expanded(
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: completado
                  ? Colores.menta
                  : activo
                      ? Colores.cian
                      : Colores.borde,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: activo ? FontWeight.bold : FontWeight.normal,
              color: completado
                  ? Colores.menta
                  : activo
                      ? Colores.cian
                      : Colores.tenue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheck(String titulo, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: ok ? Colores.menta : Colores.tenue.withValues(alpha: 0.5),
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 11,
              color: ok ? Colors.white : Colores.tenue,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colores.nocheClara,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colores.borde, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado con Bot
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colores.cian.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colores.cian, width: 1.5),
                    ),
                    child: const Icon(Icons.smart_toy_rounded, color: Colores.cian, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bot de Seguridad InfocusMind',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Recuperación Segura de Cuenta',
                          style: TextStyle(color: Colores.tenue, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colores.tenue),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Barra de Pasos
              Row(
                children: [
                  _buildStepPill(1, '1. Correo'),
                  const SizedBox(width: 6),
                  _buildStepPill(2, '2. Bot OTP'),
                  const SizedBox(width: 6),
                  _buildStepPill(3, '3. Clave'),
                  const SizedBox(width: 6),
                  _buildStepPill(4, '4. Listo'),
                ],
              ),
              const SizedBox(height: 16),

              // Banner de Error si existe
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colores.coral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colores.coral.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colores.coral, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFFFB3B3), fontSize: 12, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // CUERPO SEGÚN EL PASO
              if (_paso == 1) ...[
                // Tarjeta Bot Paso 1
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colores.noche,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colores.borde),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.support_agent_rounded, color: Colores.cian, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hola, soy el asistente de seguridad. Escribe tu correo registrado para verificar en tiempo real si tu cuenta existe en la base de datos.',
                          style: TextStyle(color: Colores.luna.withValues(alpha: 0.9), fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _correoCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico Registrado',
                    prefixIcon: const Icon(Icons.email_outlined, color: Colores.cian),
                    filled: true,
                    fillColor: Colores.noche,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colores.borde),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.cian,
                      foregroundColor: Colores.noche,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _cargando ? null : _solicitarCodigo,
                    icon: _cargando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colores.noche),
                          )
                        : const Icon(Icons.verified_user_rounded, size: 20),
                    label: Text(
                      _cargando ? 'Verificando con la base de datos...' : 'Verificar y Enviar Código',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ] else if (_paso == 2) ...[
                // Paso 2: Código OTP generado por el Bot
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colores.noche,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colores.menta.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colores.menta, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '¡Cuenta verificada! (${_correoCtrl.text.trim()})',
                              style: const TextStyle(color: Colores.menta, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '🤖 El Bot de Seguridad ha generado tu código de verificación OTP (válido por 15 minutos):',
                        style: TextStyle(color: Colores.luna, fontSize: 12, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colores.nocheClara,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colores.sol, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _codigoGenerado,
                                style: const TextStyle(
                                  color: Colores.sol,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 6,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, color: Colores.sol, size: 20),
                                tooltip: 'Copiar código',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _codigoGenerado));
                                  _codigoCtrl.text = _codigoGenerado;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('¡Código copiado al portapapeles y pegado!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _codigoCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Ingresa el código OTP de 6 dígitos',
                    hintText: '000000',
                    prefixIcon: const Icon(Icons.pin_rounded, color: Colores.cian),
                    suffixIcon: TextButton(
                      onPressed: () {
                        _codigoCtrl.text = _codigoGenerado;
                      },
                      child: const Text('Autocompletar', style: TextStyle(color: Colores.cian, fontSize: 11)),
                    ),
                    filled: true,
                    fillColor: Colores.noche,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colores.borde),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _paso = 1),
                      child: const Text('Atrás', style: TextStyle(color: Colores.tenue)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colores.cian,
                            foregroundColor: Colores.noche,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _validarCodigo,
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: const Text(
                            'Confirmar Código',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_paso == 3) ...[
                // Paso 3: Nueva Contraseña
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colores.noche,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colores.borde),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: Colores.menta, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Código validado. Ahora define tu nueva contraseña segura:',
                          style: TextStyle(color: Colores.luna, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _nuevaPassCtrl,
                  obscureText: !_verNuevaPass,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline, color: Colores.cian),
                    suffixIcon: IconButton(
                      icon: Icon(_verNuevaPass ? Icons.visibility_off : Icons.visibility, color: Colores.tenue),
                      onPressed: () => setState(() => _verNuevaPass = !_verNuevaPass),
                    ),
                    filled: true,
                    fillColor: Colores.noche,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colores.borde),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Medidor
                if (_nuevaPassCtrl.text.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _fortalezaScore,
                      backgroundColor: Colores.borde,
                      valueColor: AlwaysStoppedAnimation<Color>(_fortalezaColor),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colores.noche,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colores.borde),
                    ),
                    child: Column(
                      children: [
                        _buildCheck('Mínimo 8 caracteres', _tieneMinimo8),
                        _buildCheck('Al menos una mayúscula (A-Z)', _tieneMayuscula),
                        _buildCheck('Al menos un número (0-9)', _tieneNumero),
                        _buildCheck('Sin palabras o secuencias obvias', _noEsComun),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                TextField(
                  controller: _confirmPassCtrl,
                  obscureText: !_verConfirmPass,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Confirmar Nueva Contraseña',
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: Colores.menta),
                    suffixIcon: IconButton(
                      icon: Icon(_verConfirmPass ? Icons.visibility_off : Icons.visibility, color: Colores.tenue),
                      onPressed: () => setState(() => _verConfirmPass = !_verConfirmPass),
                    ),
                    filled: true,
                    fillColor: Colores.noche,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colores.borde),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.menta,
                      foregroundColor: Colores.noche,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _cargando ? null : _restablecerPassword,
                    icon: _cargando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colores.noche),
                          )
                        : const Icon(Icons.save_rounded, size: 20),
                    label: Text(
                      _cargando ? 'Actualizando contraseña...' : 'Guardar y Restablecer',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ] else if (_paso == 4) ...[
                // Paso 4: Éxito total
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colores.noche,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colores.menta, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colores.menta.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.task_alt_rounded, color: Colores.menta, size: 48),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '¡Restablecimiento Exitoso!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'El Bot de Seguridad ha actualizado tu contraseña en los servidores encriptados de InfocusMind.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colores.luna.withValues(alpha: 0.9), fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colores.sol,
                            foregroundColor: Colores.noche,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onPasswordRestablecida(_correoCtrl.text.trim(), _nuevaPassCtrl.text);
                          },
                          icon: const Icon(Icons.login_rounded, size: 20),
                          label: const Text(
                            'Iniciar Sesión con Nuevas Credenciales',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
