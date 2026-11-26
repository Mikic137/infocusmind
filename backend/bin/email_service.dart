import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class EmailService {
  static final String _apiKey = Platform.environment['RESEND_API_KEY'] ??
      utf8.decode(base64Decode('cmVfaVVadjhUV1FfQ1d6TmIxM1l2UVlRZTNjcEZjbjhiY1lD'));

  /// Envía el código de recuperación de contraseña de 6 dígitos al correo del estudiante
  static Future<bool> enviarRecuperacionPassword({
    required String correoDestino,
    required String codigoOTP,
  }) async {
    try {
      final payload = {
        'from': 'InfocusMind <onboarding@resend.dev>',
        'to': [correoDestino],
        'subject': '🔑 [$codigoOTP] Código de Recuperación - InfocusMind',
        'html': '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <style>
    body { background-color: #090c13; color: #f8f9fa; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; margin: 0; padding: 24px; }
    .container { max-width: 480px; margin: 0 auto; background: #111522; border: 1.5px solid #232a3f; border-radius: 16px; padding: 28px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
    .badge { display: inline-block; background: rgba(0, 210, 211, 0.15); color: #00d2d3; font-weight: 700; font-size: 11px; text-transform: uppercase; padding: 4px 10px; border-radius: 6px; margin-bottom: 12px; }
    h1 { font-size: 20px; color: #ffffff; margin: 0 0 12px 0; font-weight: 800; }
    p { font-size: 14px; color: #9aa5b8; line-height: 1.6; margin: 0 0 16px 0; }
    .otp-box { background: #0b0e17; border: 2px dashed #6c5ce7; border-radius: 12px; padding: 18px; text-align: center; margin: 20px 0; }
    .otp-code { font-family: monospace; font-size: 32px; font-weight: 900; color: #fed330; letter-spacing: 6px; }
    .footer { font-size: 11px; color: #636e72; text-align: center; margin-top: 24px; border-top: 1px solid #1a1f30; padding-top: 14px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="badge">InfocusMind Security Bot</div>
    <h1>Recuperación de Contraseña</h1>
    <p>Has solicitado restablecer la contraseña de tu cuenta de estudiante. Ingresa este código temporal de verificación en la aplicación móvil:</p>
    
    <div class="otp-box">
      <div class="otp-code">$codigoOTP</div>
    </div>

    <p>⏳ <strong>Este código es válido por 15 minutos.</strong> Por tu seguridad, nunca lo compartas con nadie.</p>
    <p>Si no realizaste esta solicitud, puedes ignorar este correo; tu cuenta permanece completamente protegida.</p>

    <div class="footer">
      InfocusMind 2026 • Asistente de Enfoque y Estudio Gamificado con IA<br>
      Soporte: infocusmind84@gmail.com
    </div>
  </div>
</body>
</html>
''',
      };

      final res = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'User-Agent': 'InfocusMind-Backend/1.0',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        print('📧 [Resend] Código de recuperación enviado exitosamente a $correoDestino');
        return true;
      } else {
        print('⚠️ [Resend Error] Fallo al enviar recuperación a $correoDestino: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('❌ [Resend Exception] Error enviando correo de recuperación: $e');
      return false;
    }
  }

  /// Envía la factura digital formal de suscripción Plus con todos los datos fiscales y de PayPal
  static Future<bool> enviarFacturaPago({
    required String correoDestino,
    required String nombreEstudiante,
    required String plan,
    required String monto,
    required String orderId,
  }) async {
    try {
      final fechaHoy = DateTime.now().toUtc().subtract(const Duration(hours: 5));
      final fechaTexto = '${fechaHoy.day.toString().padLeft(2, '0')}/${fechaHoy.month.toString().padLeft(2, '0')}/${fechaHoy.year} ${fechaHoy.hour.toString().padLeft(2, '0')}:${fechaHoy.minute.toString().padLeft(2, '0')}';

      final payload = {
        'from': 'InfocusMind <onboarding@resend.dev>',
        'to': [correoDestino],
        'subject': '📄 Factura de Suscripción: InfocusMind Plus ($plan)',
        'html': '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <style>
    body { background-color: #090c13; color: #f8f9fa; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; margin: 0; padding: 24px; }
    .container { max-width: 520px; margin: 0 auto; background: #111522; border: 1.5px solid #232a3f; border-radius: 18px; padding: 32px; box-shadow: 0 12px 35px rgba(0,0,0,0.6); }
    .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1.5px solid #232a3f; padding-bottom: 18px; margin-bottom: 20px; }
    .title { font-size: 20px; font-weight: 900; color: #fff; }
    .status-badge { background: rgba(46, 204, 113, 0.15); color: #2ecc71; border: 1px solid #2ecc71; font-size: 11px; font-weight: 800; padding: 4px 10px; border-radius: 6px; text-transform: uppercase; }
    .company-box { background: rgba(0, 210, 211, 0.08); border: 1px solid #00d2d3; border-radius: 10px; padding: 12px 14px; margin-bottom: 20px; font-size: 12px; line-height: 1.5; color: #dfe6e9; }
    .table-receipt { width: 100%; border-collapse: collapse; margin-bottom: 24px; }
    .table-receipt td { padding: 10px 0; border-bottom: 1px solid #1a1f30; font-size: 13px; }
    .label { color: #9aa5b8; }
    .val { color: #ffffff; font-weight: 600; text-align: right; }
    .total-row td { font-size: 16px; font-weight: 800; color: #fed330; border-bottom: none; padding-top: 14px; }
    .features-list { background: #0b0e17; border-radius: 12px; padding: 14px 16px; margin-bottom: 20px; }
    .features-list h4 { margin: 0 0 8px 0; font-size: 12px; color: #00d2d3; text-transform: uppercase; }
    .features-list ul { margin: 0; padding-left: 18px; font-size: 12px; color: #9aa5b8; line-height: 1.6; }
    .footer { font-size: 11px; color: #636e72; text-align: center; margin-top: 20px; border-top: 1px solid #1a1f30; padding-top: 14px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="title">COMPROBANTE DE PAGO</div>
      <div class="status-badge">✔ PAGADO</div>
    </div>

    <!-- Datos del Comercio Receptor Oficial -->
    <div class="company-box">
      <strong>Comercio Receptor:</strong> InfocusMind Business (Patrick Riofrio)<br>
      <strong>Pasarela:</strong> PayPal Smart Checkout (Oficial)<br>
      <strong>Soporte:</strong> infocusmind84@gmail.com
    </div>

    <table class="table-receipt">
      <tr>
        <td class="label">Estudiante Comprador:</td>
        <td class="val">$nombreEstudiante ($correoDestino)</td>
      </tr>
      <tr>
        <td class="label">Plan Contratado:</td>
        <td class="val">$plan</td>
      </tr>
      <tr>
        <td class="label">ID de Transacción PayPal:</td>
        <td class="val"><code style="color:#00d2d3;">$orderId</code></td>
      </tr>
      <tr>
        <td class="label">Fecha y Hora (Ecuador):</td>
        <td class="val">$fechaTexto</td>
      </tr>
      <tr class="total-row">
        <td>Total Abonado:</td>
        <td class="val">\$$monto USD</td>
      </tr>
    </table>

    <div class="features-list">
      <h4>Beneficios Activos en tu Cuenta:</h4>
      <ul>
        <li>Inteligencia Artificial ilimitada para fragmentación de misiones.</li>
        <li>Mapas y submisiones infinitas sin restricciones de plan gratuito.</li>
        <li>Asistente continuo para optimización de horarios de concentración.</li>
      </ul>
    </div>

    <p style="font-size: 13px; color: #b2bec3; text-align: center;">
      ¡Tu cuenta ya está activa! Abre la aplicación móvil InfocusMind para disfrutar de todas tus herramientas sin límites.
    </p>

    <div class="footer">
      Este comprobante digital certifica la compra de licencia de software para InfocusMind Plus.<br>
      Desarrollado para estudiantes universitarios • 2026
    </div>
  </div>
</body>
</html>
''',
      };

      final res = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'User-Agent': 'InfocusMind-Backend/1.0',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        print('🧾 [Resend] Factura de pago enviada exitosamente a $correoDestino (Order $orderId)');
        return true;
      } else {
        print('⚠️ [Resend Error] Fallo al enviar factura a $correoDestino: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('❌ [Resend Exception] Error enviando correo de factura: $e');
      return false;
    }
  }
}
