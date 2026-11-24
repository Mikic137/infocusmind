import 'package:shelf/shelf.dart';

const String kPaypalClientId =
    'AW9NLHA61XG9XPEyjWNaEVS4oUVQWVN8x5onXitERX2BPLe2gXkEwtjeiNVwq5qedwAokhQKPDnaIGNw';

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
  <title>InfocusMind Plus - Pago Seguro con PayPal Sandbox</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">
  <!-- PayPal JavaScript SDK en Sandbox con el Client ID de Dylan -->
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
      padding: 20px;
    }
    .container {
      background: var(--card);
      border: 1.5px solid var(--border);
      border-radius: 16px;
      max-width: 440px;
      width: 100%;
      padding: 24px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
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
      margin-bottom: 20px;
      line-height: 1.4;
    }
    .plan-box {
      background: #0b0f19;
      border: 1px dashed var(--cian);
      border-radius: 12px;
      padding: 14px;
      margin-bottom: 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .plan-info .title {
      font-weight: 700;
      font-size: 14px;
      color: #fff;
    }
    .plan-info .user {
      font-size: 11px;
      color: var(--muted);
      margin-top: 2px;
    }
    .plan-price {
      text-align: right;
    }
    .plan-price .amount {
      font-family: 'Press Start 2P', monospace;
      font-size: 14px;
      color: var(--menta);
    }
    .plan-price .cur {
      font-size: 10px;
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
    <h1>Checkout Seguro PayPal</h1>
    <p class="sub">Completa tu pago a través de PayPal para desbloquear IA ilimitada y mapas de guías.</p>

    <div class="plan-box">
      <div class="plan-info">
        <div class="title">$plan</div>
        <div class="user">Cuenta: $userEmail</div>
      </div>
      <div class="plan-price">
        <div class="amount">\$$amount</div>
        <div class="cur">USD</div>
      </div>
    </div>

    <div id="paypal-button-container"></div>

    <div id="success-box" class="status-box">
      <h2>🎉 ¡PAGO CAPTURADO CON ÉXITO!</h2>
      <p>Tu orden ha sido validada y registrada en el servidor.<br><br>
      <strong>Tu cuenta ya es InfocusMind Plus.</strong><br>
      Vuelve a la aplicación y presiona <em>"COMPROBAR ACTIVACIÓN"</em> para disfrutar de todas tus ventajas.</p>
    </div>

    <div class="footer-note">
      🔒 Transacción cifrada vía PayPal Sandbox API | InfocusMind 2026
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
          // Confirmar con el backend de InfocusMind
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
            alert('Pago capturado en PayPal, actualizando cuenta...');
            document.getElementById('paypal-button-container').style.display = 'none';
            document.getElementById('success-box').style.display = 'block';
          });
        });
      },
      onError: function(err) {
        console.error('Error en PayPal Sandbox:', err);
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
