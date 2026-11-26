import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'tema.dart';
import 'usage_service.dart';

class EstadoSuscripcion {
  final bool isPremium;
  final int aiCount;
  final int aiLimit;
  final int tasksCount;
  final int tasksLimit;
  final bool canUseAi;
  final bool canCreateTask;

  const EstadoSuscripcion({
    required this.isPremium,
    required this.aiCount,
    required this.aiLimit,
    required this.tasksCount,
    required this.tasksLimit,
    required this.canUseAi,
    required this.canCreateTask,
  });

  factory EstadoSuscripcion.fromJson(Map<String, dynamic> json) {
    final isPremium = json['is_premium'] == true;
    final aiCount = (json['ai_count'] as num?)?.toInt() ?? 0;
    final aiLimit = (json['ai_limit'] as num?)?.toInt() ?? 10;
    final tasksCount = (json['tasks_count'] as num?)?.toInt() ?? 0;
    final tasksLimit = (json['tasks_limit'] as num?)?.toInt() ?? 5;
    return EstadoSuscripcion(
      isPremium: isPremium,
      aiCount: aiCount,
      aiLimit: aiLimit,
      tasksCount: tasksCount,
      tasksLimit: tasksLimit,
      canUseAi: json['can_use_ai'] == true,
      canCreateTask: json['can_create_task'] == true,
    );
  }

  int get aiRestantes => (aiLimit - aiCount).clamp(0, aiLimit);
  int get tasksRestantes => (tasksLimit - tasksCount).clamp(0, tasksLimit);
}

class SubscriptionService {
  static EstadoSuscripcion? ultimoEstado;

  static Future<EstadoSuscripcion?> obtenerEstado() async {
    try {
      final r = await dio.get('/user/subscription');
      if (r.statusCode == 200 && r.data is Map) {
        final estado = EstadoSuscripcion.fromJson(Map<String, dynamic>.from(r.data));
        ultimoEstado = estado;
        return estado;
      }
    } catch (e) {
      debugPrint('Error obteniendo suscripción: $e');
    }
    return ultimoEstado;
  }

  static Future<bool> procesarPagoPlus({
    required String metodoPago,
    required String plan,
  }) async {
    try {
      final r = await dio.post('/user/upgrade-plus', data: {
        'payment_method': metodoPago,
        'plan': plan,
      });
      if (r.statusCode == 200) {
        await obtenerEstado();
        return true;
      }
    } catch (e) {
      debugPrint('Error procesando pago Plus: $e');
    }
    return false;
  }

  /// Muestra el modal con botones de pago para InfocusMind Plus
  static Future<bool?> mostrarModalPlus(
    BuildContext context, {
    String? motivo,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ModalPlusDialog(motivo: motivo),
    );
  }
}

class _ModalPlusDialog extends StatefulWidget {
  final String? motivo;
  const _ModalPlusDialog({this.motivo});

  @override
  State<_ModalPlusDialog> createState() => _ModalPlusDialogState();
}

class _ModalPlusDialogState extends State<_ModalPlusDialog> {
  int _planSeleccionado = 0; // 0: Mensual ($3.99), 1: Semestral ($14.99)
  bool _procesando = false;
  String? _metodoSeleccionado;
  bool _exito = false;
  bool _esperandoVerificacionPayPal = false;

  final List<Map<String, dynamic>> planes = [
    {
      'titulo': 'Plan Mensual',
      'precio': '\$3.99',
      'periodo': 'al mes',
      'badge': 'FLEXIBLE',
      'color': Colores.cian,
    },
    {
      'titulo': 'Plan Semestral Estudiante',
      'precio': '\$14.99',
      'periodo': 'por 6 meses (\$2.49/mes)',
      'badge': 'MÁS POPULAR · AHORRA 38%',
      'color': Colores.sol,
    },
  ];

  Future<void> _iniciarPagoPaypalOficial() async {
    final plan = planes[_planSeleccionado]['titulo'] as String;
    final monto = _planSeleccionado == 0 ? '3.99' : '14.99';

    setState(() {
      _procesando = true;
      _metodoSeleccionado = 'PayPal Oficial';
    });

    try {
      const almacen = FlutterSecureStorage();
      final token = await almacen.read(key: 'token') ?? '';
      final url =
          'https://infocusmind-production.up.railway.app/paypal/checkout?token=$token&plan=${Uri.encodeComponent(plan)}&amount=$monto';

      await UsageService.abrirUrl(url);

      if (mounted) {
        setState(() {
          _procesando = false;
          _esperandoVerificacionPayPal = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _procesando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colores.coral,
            content: Text('Error abriendo PayPal: $e'),
          ),
        );
      }
    }
  }

  Future<void> _verificarActivacionReal() async {
    setState(() {
      _procesando = true;
      _metodoSeleccionado = 'Verificando';
    });

    final estado = await SubscriptionService.obtenerEstado();

    if (!mounted) return;

    if (estado != null && estado.isPremium) {
      setState(() {
        _procesando = false;
        _esperandoVerificacionPayPal = false;
        _exito = true;
      });
    } else {
      setState(() {
        _procesando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colores.coral,
          content: Text(
            'El pago aún no ha sido confirmado por PayPal. Termina de aprobarlo en el navegador y vuelve a presionar comprobar.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_exito) {
      return Dialog(
        backgroundColor: Colores.nocheClara,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colores.menta, width: 2),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colores.menta.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Colores.sol, size: 54),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡BIENVENIDO A INFOCUSMIND PLUS!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tu suscripción ha sido activada con éxito.\nYa tienes acceso ilimitado a la Inteligencia Artificial y a la creación infinita de mapas de guías.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colores.luna, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colores.menta,
                    foregroundColor: Colores.noche,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.bolt_rounded, size: 22),
                  label: const Text(
                    'COMENZAR AHORA ILIMITADO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colores.nocheClara,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colores.bordeBrillante, width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colores.sol.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colores.sol, width: 1.5),
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colores.sol, size: 26),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'InfocusMind Plus 💎',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Acceso Completo e Ilimitado',
                          style: TextStyle(color: Colores.tenue, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded, color: Colores.tenue),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Motivo si fue activado por alcanzar límite
              if (widget.motivo != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colores.sol.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colores.sol.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colores.sol, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.motivo!,
                          style: const TextStyle(color: Colores.sol, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Beneficios
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colores.noche,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colores.borde),
                ),
                child: const Column(
                  children: [
                    _BeneficioItem(
                      icono: Icons.smart_toy_rounded,
                      titulo: 'Inteligencia Artificial Ilimitada',
                      subtitulo: 'Sin tope de 10 acciones; divide y consulta todo lo que necesites.',
                    ),
                    _BeneficioItem(
                      icono: Icons.map_rounded,
                      titulo: 'Mapas de Guías y Subtareas Infinitos',
                      subtitulo: 'Supera el límite de 5 misiones estructuradas del plan gratis.',
                    ),
                    _BeneficioItem(
                      icono: Icons.psychology_rounded,
                      titulo: 'Asistente "Aprende de Mí" Continuo',
                      subtitulo: 'Perfilado dinámico y adaptación a tus horas de mayor enfoque.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Selector de Planes
              const Text(
                'SELECCIONA TU PLAN:',
                style: TextStyle(color: Colores.tenue, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < planes.length; i++) ...[
                _buildCardPlan(i),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 12),
              const Text(
                'MÉTODOS DE PAGO DISPONIBLES:',
                style: TextStyle(color: Colores.tenue, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Único Botón Oficial: PayPal Empresarial Live
              _BotonPago(
                icono: Icons.verified_user_rounded,
                texto: 'PayPal Oficial (Smart Checkout)',
                subtexto: 'Verificación bancaria automática en 1 toque',
                colorFondo: const Color(0xFF003087),
                colorBorde: Colores.sol,
                cargando: _procesando && _metodoSeleccionado == 'PayPal Oficial' && !_esperandoVerificacionPayPal,
                deshabilitado: _procesando,
                onTap: _iniciarPagoPaypalOficial,
              ),

              // Tarjeta: Verificación oficial para PayPal
              if (_esperandoVerificacionPayPal) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B192C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colores.sol, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.open_in_new_rounded, color: Colores.sol, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Checkout abierto en PayPal Oficial (${_planSeleccionado == 0 ? '\$3.99' : '\$14.99'} USD)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '1. Completa el pago en la ventana segura de PayPal con tu cuenta o tarjeta.\n'
                        '2. Al terminar, toca el botón de abajo para verificar la activación oficial con el servidor:',
                        style: TextStyle(color: Colores.luna, fontSize: 11, height: 1.3),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colores.sol,
                            foregroundColor: Colores.noche,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _procesando ? null : _verificarActivacionReal,
                          icon: _procesando
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colores.noche))
                              : const Icon(Icons.sync_rounded, size: 20),
                          label: Text(
                            _procesando ? 'VERIFICANDO EN SERVIDOR...' : 'COMPROBAR ACTIVACIÓN OFICIAL',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _esperandoVerificacionPayPal = false),
                          child: const Text('Cerrar y volver a elegir', style: TextStyle(color: Colores.tenue, fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Center(
                child: Text(
                  '🔒 Pagos procesados de forma segura con cifrado SSL.',
                  style: TextStyle(color: Colores.tenue, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardPlan(int index) {
    final p = planes[index];
    final seleccionado = _planSeleccionado == index;

    return InkWell(
      onTap: _procesando ? null : () => setState(() => _planSeleccionado = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? (p['color'] as Color).withValues(alpha: 0.12) : Colores.noche,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: seleccionado ? (p['color'] as Color) : Colores.borde,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              seleccionado ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: seleccionado ? (p['color'] as Color) : Colores.tenue,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        p['titulo'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (p['color'] as Color).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p['badge'] as String,
                          style: TextStyle(
                            color: p['color'] as Color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p['periodo'] as String,
                    style: const TextStyle(color: Colores.tenue, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              p['precio'] as String,
              style: TextStyle(
                color: p['color'] as Color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeneficioItem extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;

  const _BeneficioItem({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: Colores.menta, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitulo,
                  style: const TextStyle(color: Colores.tenue, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonPago extends StatelessWidget {
  final IconData icono;
  final String texto;
  final String subtexto;
  final Color colorFondo;
  final Color colorBorde;
  final bool cargando;
  final bool deshabilitado;
  final VoidCallback onTap;

  const _BotonPago({
    required this.icono,
    required this.texto,
    required this.subtexto,
    required this.colorFondo,
    required this.colorBorde,
    required this.cargando,
    required this.deshabilitado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: deshabilitado ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorBorde.withValues(alpha: 0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            if (cargando) ...[
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            ] else ...[
              Icon(icono, color: Colors.white, size: 24),
            ],
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtexto,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }
}
