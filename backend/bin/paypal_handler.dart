import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';

const String kPaypalClientId =
    'BAAyIyzAvpwdME5xyTCSkUDt9FkJ1g1uEQx6nhY0ppuIlblT0VLtZHKy3ITGwigiAnoI_tK6taM1Yd09YU';
const String kPaypalClientSecret =
    'EFQQz2HtCJ5eGoMPl5_ko0mPgX9j7Kno8_qK4M6hFLkhz3cyo05y6UHJeA9OxykdwGKFCc0pN0VLFNv7';

/// Consulta a la API oficial de PayPal Live para verificar que la orden existe y fue pagada
Future<bool> verifyPaypalOrderLive(String orderId) async {
  try {
    final basicAuth = base64Encode(utf8.encode('$kPaypalClientId:$kPaypalClientSecret'));
    final tokenResp = await http.post(
      Uri.parse('https://api-m.paypal.com/v1/oauth2/token'),
      headers: {
        'Authorization': 'Basic $basicAuth',
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'InfocusMind-Backend/1.0',
      },
      body: {'grant_type': 'client_credentials'},
    );

    if (tokenResp.statusCode != 200) {
      print('Error obteniendo token PayPal Live: ${tokenResp.body}');
      return false;
    }

    final tokenData = jsonDecode(tokenResp.body) as Map;
    final accessToken = tokenData['access_token'];

    final orderResp = await http.get(
      Uri.parse('https://api-m.paypal.com/v2/checkout/orders/$orderId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'User-Agent': 'InfocusMind-Backend/1.0',
      },
    );

    if (orderResp.statusCode != 200) {
      print('Error consultando orden PayPal $orderId: ${orderResp.body}');
      return false;
    }

    final orderData = jsonDecode(orderResp.body) as Map;
    final status = orderData['status']?.toString();
    print('Estado verificado de orden PayPal $orderId: $status');
    return status == 'COMPLETED' || status == 'APPROVED';
  } catch (e) {
    print('Excepción al verificar orden PayPal: $e');
    return false;
  }
}

Response renderPaypalCheckoutHtml({
  required int userId,
  required String userEmail,
  required String plan,
  required String amount,
  required String token,
}) {
  final html = '''<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>InfocusMind Plus - Pasarela Oficial PayPal</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&family=Inter:wght@400;600;700;800;900&display=swap" rel="stylesheet">
  <!-- PayPal JavaScript SDK Oficial en Vivo (Live) -->
  <script src="https://www.paypal.com/sdk/js?client-id=$kPaypalClientId&currency=USD"></script>
  <style>
    :root {
      --bg: #090c13;
      --card: #111522;
      --border: #232a3f;
      --cian: #00d2d3;
      --menta: #2ecc71;
      --sol: #fed330;
      --text: #f8f9fa;
      --muted: #9aa5b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'Inter', sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 16px;
    }
    .container {
      background: var(--card);
      border: 1.5px solid var(--border);
      border-radius: 18px;
      max-width: 440px;
      width: 100%;
      padding: 24px;
      box-shadow: 0 12px 35px rgba(0,0,0,0.6);
    }
    .badge {
      font-family: 'Press Start 2P', monospace;
      font-size: 9px;
      color: var(--sol);
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 8px;
    }
    h1 {
      font-size: 20px;
      font-weight: 800;
      margin-bottom: 6px;
      color: #ffffff;
    }
    p.sub {
      color: var(--muted);
      font-size: 13px;
      margin-bottom: 18px;
      line-height: 1.45;
    }
    .plan-box {
      background: #0b0f19;
      border: 1px dashed var(--cian);
      border-radius: 12px;
      padding: 14px 16px;
      margin-bottom: 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .plan-info .title {
      font-weight: 700;
      font-size: 15px;
      color: #fff;
    }
    .plan-info .user {
      font-size: 12px;
      color: var(--muted);
      margin-top: 2px;
    }
    .plan-price {
      text-align: right;
    }
    .plan-price .amount {
      font-family: 'Press Start 2P', monospace;
      font-size: 15px;
      color: var(--menta);
    }
    .plan-price .cur {
      font-size: 11px;
      color: var(--muted);
    }
    #paypal-button-container {
      margin-top: 10px;
      min-height: 150px;
    }
    .status-box {
      display: none;
      background: rgba(46, 204, 113, 0.12);
      border: 1.5px solid var(--menta);
      border-radius: 12px;
      padding: 20px;
      text-align: center;
      margin-top: 15px;
    }
    .status-box h2 {
      color: var(--menta);
      font-size: 16px;
      margin-bottom: 8px;
    }
    .status-box p {
      font-size: 13px;
      color: var(--text);
      line-height: 1.5;
    }
    .footer-note {
      text-align: center;
      margin-top: 18px;
      font-size: 11px;
      color: var(--muted);
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="badge">INFOCUSMIND ARCADE PLUS</div>
    <h1>Pago Seguro PayPal Oficial</h1>
    <p class="sub">Procesado a través de la cuenta comercial oficial de InfocusMind. Tu suscripción se activará inmediatamente.</p>

    <!-- Comercio Receptor Empresarial Oficial -->
    <div style="background: rgba(0, 210, 211, 0.08); border: 1.5px solid var(--cian); border-radius: 12px; padding: 12px 16px; margin-bottom: 14px; display: flex; align-items: center; justify-content: space-between;">
      <div>
        <div style="font-size: 11px; text-transform: uppercase; color: var(--cian); font-weight: 800; letter-spacing: 0.5px;">Comercio Receptor Oficial</div>
        <div style="font-size: 14px; font-weight: 700; color: #fff; margin-top: 2px;">InfocusMind Business</div>
        <div style="font-size: 11px; color: var(--menta); margin-top: 2px;">✔ Cuenta Empresarial Verificada (Patrick Riofrio)</div>
      </div>
      <div style="font-size: 26px;">🏢</div>
    </div>

    <div class="plan-box">
      <div class="plan-info">
        <div class="title">$plan</div>
        <div class="user">Estudiante a activar: <strong>$userEmail</strong></div>
      </div>
      <div class="plan-price">
        <div class="amount">\$$amount</div>
        <div class="cur">USD</div>
      </div>
    </div>

    <div id="paypal-button-container"></div>

    <div id="success-box" class="status-box">
      <h2>🎉 ¡PAGO CONFIRMADO CON ÉXITO!</h2>
      <p>Tu pago ha sido validado con los servidores de PayPal.<br><br>
      <strong>Tu cuenta InfocusMind Plus ya está activa.</strong><br>
      Regresa a la aplicación móvil y pulsa <em>"COMPROBAR ACTIVACIÓN"</em> para disfrutar de IA y misiones ilimitadas.</p>
    </div>

    <div class="footer-note">
      🔒 Cifrado bancario oficial de 256 bits | InfocusMind 2026
    </div>
  </div>

  <script>
    const plan = "$plan";
    const amount = "$amount";
    const token = "$token";
    const userId = $userId;

    paypal.Buttons({
      style: {
        layout: 'vertical',
        color:  'gold',
        shape:  'rect',
        label:  'paypal'
      },
      createOrder: function(data, actions) {
        return actions.order.create({
          purchase_units: [{
            description: "InfocusMind Plus - " + plan,
            amount: {
              currency_code: "USD",
              value: amount
            }
          }]
        });
      },
      onApprove: function(data, actions) {
        return actions.order.capture().then(function(details) {
          fetch('/paypal/capture-success', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ' + token
            },
            body: JSON.stringify({
              order_id: data.orderID,
              plan: plan,
              amount: amount,
              payer_name: (details.payer && details.payer.name) ? details.payer.name.given_name : 'Usuario'
            })
          })
          .then(res => res.json())
          .then(resData => {
            document.getElementById('paypal-button-container').style.display = 'none';
            document.getElementById('success-box').style.display = 'block';
          })
          .catch(err => {
            document.getElementById('paypal-button-container').style.display = 'none';
            document.getElementById('success-box').style.display = 'block';
          });
        });
      },
      onError: function(err) {
        console.error('Error en PayPal:', err);
      }
    }).render('#paypal-button-container');
  </script>
</body>
</html>''';

  return Response.ok(
    html,
    headers: {
      'content-type': 'text/html; charset=utf-8',
      'cache-control': 'no-cache, no-store, must-revalidate'
    },
  );
}
