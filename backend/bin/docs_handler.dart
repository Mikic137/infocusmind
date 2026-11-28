import 'package:shelf/shelf.dart';

Future<Response> handleDocsIndex(Request request) async {
  final html = '''<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Centro de Documentación Oficial — InfocusMind</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #090c13;
      --surface: #111522;
      --card: #151a2b;
      --border: #232a3f;
      --violet: #6c5ce7;
      --cian: #00d2d3;
      --sol: #fed330;
      --menta: #2ecc71;
      --text: #f8f9fa;
      --muted: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: var(--bg); color: var(--text); font-family: 'Plus Jakarta Sans', sans-serif; line-height: 1.6; }
    header { background: rgba(9, 12, 19, 0.9); backdrop-filter: blur(12px); border-bottom: 1.5px solid var(--border); position: sticky; top: 0; z-index: 100; padding: 16px 28px; display: flex; justify-content: space-between; align-items: center; }
    .logo { display: flex; align-items: center; gap: 12px; text-decoration: none; color: #fff; font-weight: 800; font-size: 17px; }
    .logo-box { width: 36px; height: 36px; border-radius: 8px; background: linear-gradient(135deg, var(--violet), var(--cian)); display: flex; align-items: center; justify-content: center; font-family: 'Press Start 2P', monospace; font-size: 11px; color: #fff; }
    .nav-links a { color: var(--muted); text-decoration: none; margin-left: 20px; font-size: 14px; font-weight: 600; transition: color 0.2s; }
    .nav-links a:hover { color: var(--cian); }
    .container { max-width: 1080px; margin: 40px auto; padding: 0 20px; }
    .hero { text-align: center; margin-bottom: 50px; }
    .hero h1 { font-size: 2.4rem; font-weight: 800; margin-bottom: 12px; background: linear-gradient(135deg, #fff 40%, var(--cian)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
    .hero p { color: var(--muted); font-size: 1.1rem; max-width: 650px; margin: 0 auto; }
    .docs-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 24px; margin-top: 30px; }
    .doc-card { background: var(--surface); border: 1.5px solid var(--border); border-radius: 16px; padding: 32px; transition: all 0.25s ease; display: flex; flex-direction: column; justify-content: space-between; position: relative; overflow: hidden; }
    .doc-card:hover { transform: translateY(-4px); border-color: var(--cian); box-shadow: 0 12px 30px rgba(0, 210, 211, 0.12); }
    .doc-badge { align-self: flex-start; padding: 6px 12px; border-radius: 6px; font-size: 11px; font-weight: 700; text-transform: uppercase; margin-bottom: 18px; letter-spacing: 0.5px; }
    .badge-user { background: rgba(108, 92, 231, 0.2); color: #a29bfe; border: 1px solid var(--violet); }
    .badge-tech { background: rgba(0, 210, 211, 0.2); color: var(--cian); border: 1px solid var(--cian); }
    .doc-card h2 { font-size: 1.5rem; margin-bottom: 12px; color: #fff; }
    .doc-card p { color: var(--muted); font-size: 14px; line-height: 1.6; margin-bottom: 24px; }
    .features-list { list-style: none; margin-bottom: 24px; }
    .features-list li { color: #cbd5e1; font-size: 13px; margin-bottom: 8px; display: flex; align-items: center; gap: 8px; }
    .features-list li::before { content: "✔"; color: var(--menta); font-weight: 800; }
    .btn-read { display: inline-flex; align-items: center; justify-content: center; gap: 8px; background: linear-gradient(135deg, var(--violet), #5844e3); color: #fff; padding: 12px 20px; border-radius: 10px; font-weight: 700; text-decoration: none; font-size: 14px; transition: opacity 0.2s; }
    .btn-read:hover { opacity: 0.9; }
    .btn-cyan { background: linear-gradient(135deg, #0984e3, var(--cian)); }
    footer { border-top: 1.5px solid var(--border); padding: 30px; text-align: center; color: var(--muted); font-size: 13px; margin-top: 60px; }
  </style>
</head>
<body>
  <header>
    <a href="/" class="logo">
      <div class="logo-box">IFM</div>
      <span>InfocusMind Docs</span>
    </a>
    <nav class="nav-links">
      <a href="/">Inicio</a>
      <a href="/manual-usuario">Manual de Usuario</a>
      <a href="/manual-tecnico">Manual Técnico</a>
      <a href="/privacy">Privacidad</a>
      <a href="https://github.com/Mikic137/infocusmind" target="_blank">GitHub</a>
    </nav>
  </header>

  <div class="container">
    <div class="hero">
      <h1>Centro de Documentación Oficial</h1>
      <p>Guías exhaustivas, manuales de usuario y especificación técnica de la arquitectura de InfocusMind (v1.1.8 Build 9).</p>
    </div>

    <div class="docs-grid">
      <!-- Tarjeta Manual de Usuario -->
      <div class="doc-card">
        <div>
          <span class="doc-badge badge-user">Para Estudiantes y Usuarios</span>
          <h2>Manual de Usuario</h2>
          <p>Aprende paso a paso cómo instalar la app en Android, utilizar la IA para dividir tareas, activar el Launcher anti-distracciones, ganar experiencia y gestionar tu suscripción InfocusMind Plus.</p>
          <ul class="features-list">
            <li>Instalación y permisos especiales en Android</li>
            <li>Generador de misiones con IA y Zero UI (Voz)</li>
            <li>Modo Launcher Focus: Control total de pantalla</li>
            <li>Gamificación: Niveles, XP, mapas y recompensas</li>
            <li>Monetización y pasarela oficial PayPal</li>
          </ul>
        </div>
        <a href="/manual-usuario" class="btn-read">Leer Manual de Usuario &rarr;</a>
      </div>

      <!-- Tarjeta Manual Técnico -->
      <div class="doc-card">
        <div>
          <span class="doc-badge badge-tech">Para Desarrolladores y Docentes</span>
          <h2>Manual Técnico</h2>
          <p>Especificación de arquitectura de software, modelo de datos relacional en PostgreSQL, endpoints REST, integración de pasarela PayPal Business, servicios de sistema Android y batería de pruebas.</p>
          <ul class="features-list">
            <li>Pila tecnológica: Flutter 3.x, Dart Shelf, PostgreSQL</li>
            <li>Estructura de la base de datos y esquemas SQL</li>
            <li>Seguridad: Cifrado BCrypt y tokens JWT</li>
            <li>APIs nativas: UsageStatsManager y Launcher Home</li>
            <li>Pipeline de pruebas y verificación server-to-server</li>
          </ul>
        </div>
        <a href="/manual-tecnico" class="btn-read btn-cyan">Leer Manual Técnico &rarr;</a>
      </div>
    </div>
  </div>

  <footer>
    <p>InfocusMind &bull; Universidad Politécnica Estatal del Carchi (UPEC) &bull; Dylan Rosero &bull; 2026</p>
  </footer>
</body>
</html>''';

  return Response(200, body: html, headers: {'content-type': 'text/html; charset=utf-8'});
}

Future<Response> handleUserManual(Request request) async {
  final html = '''<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Manual de Usuario — InfocusMind v1.1.8</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #090c13;
      --surface: #111522;
      --card: #151a2b;
      --border: #232a3f;
      --violet: #6c5ce7;
      --cian: #00d2d3;
      --sol: #fed330;
      --menta: #2ecc71;
      --coral: #ff7675;
      --text: #f8f9fa;
      --muted: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: var(--bg); color: var(--text); font-family: 'Plus Jakarta Sans', sans-serif; line-height: 1.6; }
    header { background: rgba(9, 12, 19, 0.9); backdrop-filter: blur(12px); border-bottom: 1.5px solid var(--border); position: sticky; top: 0; z-index: 100; padding: 14px 28px; display: flex; justify-content: space-between; align-items: center; }
    .logo { display: flex; align-items: center; gap: 10px; text-decoration: none; color: #fff; font-weight: 800; font-size: 16px; }
    .logo-box { width: 32px; height: 32px; border-radius: 6px; background: linear-gradient(135deg, var(--violet), var(--cian)); display: flex; align-items: center; justify-content: center; font-family: 'Press Start 2P', monospace; font-size: 10px; color: #fff; }
    .btn-back { color: var(--cian); text-decoration: none; font-size: 13px; font-weight: 700; }
    .layout { display: flex; max-width: 1200px; margin: 0 auto; }
    .sidebar { width: 280px; position: sticky; top: 65px; height: calc(100vh - 65px); overflow-y: auto; padding: 30px 20px; border-right: 1px solid var(--border); }
    .sidebar h3 { font-size: 12px; text-transform: uppercase; letter-spacing: 1px; color: var(--muted); margin-bottom: 12px; }
    .sidebar a { display: block; color: #cbd5e1; text-decoration: none; font-size: 13.5px; padding: 6px 10px; border-radius: 6px; margin-bottom: 4px; transition: all 0.2s; }
    .sidebar a:hover { background: rgba(108, 92, 231, 0.15); color: var(--cian); }
    .content { flex: 1; padding: 40px 50px; max-width: 880px; }
    h1 { font-size: 2.2rem; font-weight: 800; color: #fff; margin-bottom: 8px; }
    .subtitle { color: var(--muted); font-size: 15px; margin-bottom: 30px; border-bottom: 1px solid var(--border); padding-bottom: 16px; }
    h2 { font-size: 1.5rem; font-weight: 700; color: #fff; margin: 40px 0 16px 0; border-left: 4px solid var(--cian); padding-left: 12px; }
    h3 { font-size: 1.2rem; font-weight: 600; color: var(--cian); margin: 24px 0 10px 0; }
    p, li { color: #cbd5e1; font-size: 14.5px; line-height: 1.7; margin-bottom: 14px; }
    ul, ol { padding-left: 24px; margin-bottom: 18px; }
    .step-box { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 20px; margin-bottom: 16px; }
    .step-num { display: inline-block; background: var(--violet); color: #fff; font-weight: 800; width: 24px; height: 24px; border-radius: 50%; text-align: center; line-height: 24px; font-size: 12px; margin-right: 8px; }
    .callout { background: rgba(0, 210, 211, 0.08); border-left: 4px solid var(--cian); border-radius: 0 10px 10px 0; padding: 16px; margin: 20px 0; }
    .callout-warning { background: rgba(255, 118, 117, 0.08); border-left-color: var(--coral); }
    .badge { display: inline-block; padding: 3px 8px; border-radius: 4px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
    .badge-gold { background: rgba(254, 211, 48, 0.2); color: var(--sol); border: 1px solid var(--sol); }
    code { font-family: 'JetBrains Mono', monospace; background: #1a1f30; color: #fed330; padding: 2px 6px; border-radius: 4px; font-size: 13px; }
    @media (max-width: 850px) { .layout { flex-direction: column; } .sidebar { display: none; } .content { padding: 24px; } }
  </style>
</head>
<body>
  <header>
    <a href="/docs" class="logo">
      <div class="logo-box">IFM</div>
      <span>InfocusMind Manual de Usuario</span>
    </a>
    <a href="/docs" class="btn-back">&larr; Volver al Centro de Docs</a>
  </header>

  <div class="layout">
    <nav class="sidebar">
      <h3>Contenido</h3>
      <a href="#intro">1. Introducción</a>
      <a href="#instalacion">2. Instalación en Android</a>
      <a href="#permisos">3. Configuración de Permisos</a>
      <a href="#registro">4. Registro e Inicio de Sesión</a>
      <a href="#misiones">5. Gestión de Misiones</a>
      <a href="#asistente-ia">6. Asistente con IA (DeepSeek)</a>
      <a href="#zero-ui">7. Interfaz Invisible (Voz)</a>
      <a href="#launcher">8. Modo Launcher Focus</a>
      <a href="#gamificacion">9. Gamificación (XP y Niveles)</a>
      <a href="#temas">10. Personalización de Temas</a>
      <a href="#plus">11. InfocusMind Plus (PayPal)</a>
      <a href="#faq">12. Preguntas Frecuentes</a>
    </nav>

    <main class="content">
      <h1>Manual de Usuario Oficial</h1>
      <div class="subtitle">Guía de usuario paso a paso para la versión 1.1.8 (Build 9) de InfocusMind.</div>

      <section id="intro">
        <h2>1. Introducción a InfocusMind</h2>
        <p><strong>InfocusMind</strong> es una plataforma de productividad y estudio diseñada especialmente para estudiantes universitarios y de secundaria. Su objetivo fundamental es combatir la procrastinación mediante la integración de <strong>Inteligencia Artificial generativa</strong>, <strong>gamificación tipo RPG</strong> y un <strong>Modo Launcher nativo</strong> que transforma la pantalla de tu celular en un entorno libre de distracciones.</p>
      </section>

      <section id="instalacion">
        <h2>2. Instalación en Dispositivos Android</h2>
        <div class="step-box">
          <p><span class="step-num">1</span> <strong>Descargar el APK Oficial:</strong> Descarga el archivo de instalación <code>InfocusMind_v1.1.8.apk</code> desde la página oficial o desde tu panel de distribución.</p>
        </div>
        <div class="step-box">
          <p><span class="step-num">2</span> <strong>Permitir Fuentes Desconocidas:</strong> Si es la primera vez que instalas una app fuera de Google Play, Android te solicitará activar <em>"Permitir la instalación de apps de esta fuente"</em> en Chrome o en tu explorador de archivos.</p>
        </div>
        <div class="step-box">
          <p><span class="step-num">3</span> <strong>Completar la Instalación:</strong> Toca el archivo descargado y presiona <strong>Instalar</strong>. El instalador verificará el paquete sin errores y dejará el icono de InfocusMind listo en tu dispositivo.</p>
        </div>
      </section>

      <section id="permisos">
        <h2>3. Configuración de Permisos Especiales</h2>
        <p>Para que InfocusMind pueda bloquear distracciones y monitorear hábitos de estudio, requiere dos permisos seguros de Android:</p>
        <ul>
          <li><strong>Acceso a Datos de Uso (UsageStats):</strong> Permite a la app detectar silenciosamente si sales a abrir TikTok, Instagram, YouTube o videojuegos mientras estás en una sesión de estudio. InfocusMind <strong>NUNCA</strong> accede a fotos, chats, contraseñas ni datos bancarios.</li>
          <li><strong>Permiso de Pantalla de Inicio (Launcher Home):</strong> Permite sustituir temporalmente la pantalla principal de tu teléfono por la interfaz limpia de estudio de InfocusMind.</li>
        </ul>
      </section>

      <section id="registro">
        <h2>4. Registro e Inicio de Sesión</h2>
        <p>Al abrir la aplicación por primera vez podrás:</p>
        <ul>
          <li><strong>Crear Cuenta:</strong> Ingresa tu correo universitario o personal y una contraseña segura.</li>
          <li><strong>Continuar con Google:</strong> Acceso rápido con un toque mediante tu cuenta de Google.</li>
          <li><strong>Recuperar Contraseña:</strong> Si olvidaste tu clave, pulsa <em>"¿Olvidaste tu contraseña?"</em>. El bot de seguridad te enviará un código de verificación de 6 dígitos a tu correo de Gmail para crear una nueva contraseña en segundos.</li>
        </ul>
      </section>

      <section id="asistente-ia">
        <h2>5. Asistente de Estudio con IA (DeepSeek / Gemini)</h2>
        <p>Si tienes una meta académica pesada (ej: <em>"Estudiar para el examen final de Estructuras de Datos"</em>) que te causa bloqueo mental:</p>
        <ol>
          <li>Entra a la pestaña <strong>Ayudante</strong>.</li>
          <li>Escribe la meta o pulsa el botón del micrófono para dictarla.</li>
          <li>Presiona <strong>"Dividir con IA"</strong>.</li>
          <li>El asistente descompondrá tu objetivo en 3 a 5 micro-pasos alcanzables con tiempos estimados (ej: 25 min lectura, 40 min ejercicios, 15 min resumen).</li>
        </ol>
      </section>

      <section id="launcher">
        <h2>6. Modo Launcher Focus (Anti-Distracciones)</h2>
        <p>Cuando necesites concentración absoluta para exámenes o entregas:</p>
        <div class="callout">
          <strong>¿Cómo funciona?</strong> Ve a la pestaña <strong>Bloqueo</strong> y presiona <em>"Activar como Launcher"</em>. En los ajustes de Android, selecciona InfocusMind como tu aplicación de inicio por defecto. A partir de ese momento, al presionar el botón Home de tu teléfono, solo verás tus herramientas de estudio, eliminando el impulso de abrir redes sociales.
        </div>
      </section>

      <section id="gamificacion">
        <h2>7. Gamificación: Niveles, XP y Recompensas</h2>
        <p>InfocusMind convierte cada sesión de estudio en una partida de videojuego:</p>
        <ul>
          <li><strong>Ganancia de XP:</strong> Ganas <strong>2 puntos de experiencia (XP)</strong> por cada minuto de concentración real en tus sesiones Pomodoro.</li>
          <li><strong>Subida de Nivel:</strong> Al acumular XP, la barra de tu HUD se llena y desbloqueas nuevos niveles (Lvl 1, Lvl 2, Lvl 3...).</li>
          <li><strong>Penalización por Distracción:</strong> Si durante tu sesión abres aplicaciones distractoras como TikTok o Instagram, el sistema audita los segundos perdidos y reduce proporcionalmente el bono de XP al finalizar.</li>
        </ul>
      </section>

      <section id="plus">
        <h2>8. Suscripción InfocusMind Plus con PayPal</h2>
        <p>Los usuarios gratuitos tienen acceso a 10 acciones con IA y 5 mapas de misiones. Para acceder a potencia ilimitada:</p>
        <ul>
          <li>Pulsa el botón dorado <strong>PLUS</strong> en el HUD.</li>
          <li>Elige entre el <strong>Plan Mensual (\$3.99)</strong> o el <strong>Plan Semestral Estudiante (\$14.99)</strong>.</li>
          <li>Presiona <strong>PayPal Empresarial (InfocusMind)</strong>.</li>
          <li>Se abrirá la pasarela oficial segura de PayPal donde puedes pagar con saldo de PayPal o tarjeta de débito/crédito.</li>
          <li>Al confirmar el pago, tu cuenta se activa automáticamente en el servidor y recibirás tu <strong>factura digital formal en tu correo electrónico</strong>.</li>
        </ul>
      </section>

      <section id="faq">
        <h2>9. Preguntas Frecuentes (FAQ)</h2>
        <div class="callout">
          <strong>¿InfocusMind consume mucha batería?</strong><br>
          No. La aplicación está construida sobre Flutter 3 optimizado en código nativo AOT y los servicios de fondo solo se activan cuando tú inicias explícitamente una sesión de estudio.
        </div>
        <div class="callout">
          <strong>¿Cómo desactivo el Modo Launcher cuando termino de estudiar?</strong><br>
          Simplemente ve a la pestaña Bloqueo y pulsa <em>"Desactivar Launcher"</em> o ve a los Ajustes de tu teléfono > Aplicaciones por defecto > Pantalla de inicio y vuelve a seleccionar el launcher original de tu celular.
        </div>
      </section>
    </main>
  </div>
</body>
</html>''';

  return Response(200, body: html, headers: {'content-type': 'text/html; charset=utf-8'});
}

Future<Response> handleTechnicalManual(Request request) async {
  final html = '''<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Manual Técnico de Arquitectura — InfocusMind v1.1.8</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #090c13;
      --surface: #111522;
      --card: #151a2b;
      --border: #232a3f;
      --violet: #6c5ce7;
      --cian: #00d2d3;
      --sol: #fed330;
      --menta: #2ecc71;
      --text: #f8f9fa;
      --muted: #94a3b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background: var(--bg); color: var(--text); font-family: 'Plus Jakarta Sans', sans-serif; line-height: 1.6; }
    header { background: rgba(9, 12, 19, 0.9); backdrop-filter: blur(12px); border-bottom: 1.5px solid var(--border); position: sticky; top: 0; z-index: 100; padding: 14px 28px; display: flex; justify-content: space-between; align-items: center; }
    .logo { display: flex; align-items: center; gap: 10px; text-decoration: none; color: #fff; font-weight: 800; font-size: 16px; }
    .logo-box { width: 32px; height: 32px; border-radius: 6px; background: linear-gradient(135deg, var(--violet), var(--cian)); display: flex; align-items: center; justify-content: center; font-family: 'Press Start 2P', monospace; font-size: 10px; color: #fff; }
    .btn-back { color: var(--cian); text-decoration: none; font-size: 13px; font-weight: 700; }
    .layout { display: flex; max-width: 1240px; margin: 0 auto; }
    .sidebar { width: 290px; position: sticky; top: 65px; height: calc(100vh - 65px); overflow-y: auto; padding: 30px 20px; border-right: 1px solid var(--border); }
    .sidebar h3 { font-size: 12px; text-transform: uppercase; letter-spacing: 1px; color: var(--muted); margin-bottom: 12px; }
    .sidebar a { display: block; color: #cbd5e1; text-decoration: none; font-size: 13.5px; padding: 6px 10px; border-radius: 6px; margin-bottom: 4px; transition: all 0.2s; }
    .sidebar a:hover { background: rgba(0, 210, 211, 0.15); color: var(--cian); }
    .content { flex: 1; padding: 40px 50px; max-width: 920px; }
    h1 { font-size: 2.2rem; font-weight: 800; color: #fff; margin-bottom: 8px; }
    .subtitle { color: var(--muted); font-size: 15px; margin-bottom: 30px; border-bottom: 1px solid var(--border); padding-bottom: 16px; }
    h2 { font-size: 1.5rem; font-weight: 700; color: #fff; margin: 40px 0 16px 0; border-left: 4px solid var(--violet); padding-left: 12px; }
    h3 { font-size: 1.2rem; font-weight: 600; color: var(--cian); margin: 24px 0 10px 0; }
    p, li { color: #cbd5e1; font-size: 14.5px; line-height: 1.7; margin-bottom: 14px; }
    ul, ol { padding-left: 24px; margin-bottom: 18px; }
    pre { background: #0c0f17; border: 1px solid var(--border); border-radius: 10px; padding: 18px; overflow-x: auto; font-family: 'JetBrains Mono', monospace; font-size: 13px; color: #e2e8f0; margin: 16px 0; line-height: 1.5; }
    code { font-family: 'JetBrains Mono', monospace; color: var(--cian); background: #1a1f30; padding: 2px 6px; border-radius: 4px; font-size: 13px; }
    .table-tech { width: 100%; border-collapse: collapse; margin: 20px 0; font-size: 13.5px; }
    .table-tech th { background: var(--surface); color: var(--cian); text-align: left; padding: 12px; border: 1px solid var(--border); }
    .table-tech td { padding: 10px 12px; border: 1px solid var(--border); color: #cbd5e1; }
    .badge { display: inline-block; padding: 3px 8px; border-radius: 4px; font-size: 11px; font-weight: 700; text-transform: uppercase; }
    .badge-post { background: rgba(46, 204, 113, 0.2); color: var(--menta); }
    .badge-get { background: rgba(0, 210, 211, 0.2); color: var(--cian); }
    @media (max-width: 850px) { .layout { flex-direction: column; } .sidebar { display: none; } .content { padding: 24px; } }
  </style>
</head>
<body>
  <header>
    <a href="/docs" class="logo">
      <div class="logo-box">IFM</div>
      <span>InfocusMind Manual Técnico</span>
    </a>
    <a href="/docs" class="btn-back">&larr; Volver al Centro de Docs</a>
  </header>

  <div class="layout">
    <nav class="sidebar">
      <h3>Arquitectura</h3>
      <a href="#arquitectura">1. Arquitectura General</a>
      <a href="#stack">2. Pila Tecnológica</a>
      <a href="#database">3. Modelo de Datos (PostgreSQL)</a>
      <a href="#seguridad">4. Seguridad y Autenticación</a>
      <a href="#api">5. Especificación de la API REST</a>
      <a href="#paypal-flow">6. Pasarela PayPal Smart Checkout</a>
      <a href="#android-native">7. Integración Nativa Android</a>
      <a href="#updater">8. Actualizador In-App Dinámico</a>
      <a href="#email-service">9. Servicio Transaccional Resend</a>
    </nav>

    <main class="content">
      <h1>Manual Técnico y de Arquitectura</h1>
      <div class="subtitle">Documentación técnica formal del ecosistema móvil y backend de InfocusMind (v1.1.8 Build 9).</div>

      <section id="arquitectura">
        <h2>1. Arquitectura General del Sistema</h2>
        <p>InfocusMind está estructurado bajo una arquitectura cliente-servidor desacoplada basada en micro-servicios REST y comunicación segura bajo TLS/HTTPS:</p>
        <pre>
┌────────────────────────────────────────────────────────┐
│                   CLIENTE MÓVIL (FLUTTER 3.x)          │
│  - Presentation Layer: Riverpod + GoRouter             │
│  - Platform Channels: UsageStats & Launcher Intent      │
│  - Secure Storage: AES/KeyStore Encrypted Storage      │
└───────────────────────────┬────────────────────────────┘
                            │ HTTPS / REST API (JWT)
                            ▼
┌────────────────────────────────────────────────────────┐
│                BACKEND SERVER (DART SHELF)             │
│  - Middleware: Auth JWT + Version Validator (vCode>=9) │
│  - Handlers: Tasks, AI DeepSeek, PayPal, Metrics, Resend│
└───────────────────────────┬────────────────────────────┘
                            │ Pool de Conexiones ACID
                            ▼
┌────────────────────────────────────────────────────────┐
│             BASE DE DATOS RELACIONAL (POSTGRESQL)       │
│  - users, tasks, task_steps, focus_sessions, profiles   │
│  - distraction_logs, subscriptions                      │
└────────────────────────────────────────────────────────┘
        </pre>
      </section>

      <section id="stack">
        <h2>2. Pila Tecnológica Homologada</h2>
        <table class="table-tech">
          <thead>
            <tr><th>Componente</th><th>Tecnología</th><th>Versión / Detalle</th></tr>
          </thead>
          <tbody>
            <tr><td>Framework Cliente</td><td>Flutter / Dart SDK</td><td>Flutter v3.13+ / Dart v3.3+ (Engine Impeller)</td></tr>
            <tr><td>Gestión de Estado</td><td>Riverpod</td><td><code>flutter_riverpod: ^3.4.3</code> (StateNotifier/ChangeNotifier)</td></tr>
            <tr><td>Enrutamiento</td><td>GoRouter</td><td><code>go_router: ^18.1.2</code> con redirección declarativa</td></tr>
            <tr><td>Backend Engine</td><td>Dart Shelf HTTP Server</td><td><code>shelf: ^1.4.2</code> + <code>shelf_router: ^1.1.4</code></td></tr>
            <tr><td>Base de Datos</td><td>PostgreSQL</td><td>v15+ administrada en la nube (Railway)</td></tr>
            <tr><td>Motor de Inteligencia Artificial</td><td>DeepSeek V3 / Gemini</td><td>Pipeline de fragmentación de lenguaje natural</td></tr>
            <tr><td>Pasarela de Pagos</td><td>PayPal Smart Checkout Live</td><td>Orders v2 API + Server-to-Server Verification</td></tr>
            <tr><td>Envío de Correos y Facturación</td><td>Resend API</td><td>REST API HTTP + Cifrado TLS con adjuntos digitales</td></tr>
          </tbody>
        </table>
      </section>

      <section id="database">
        <h2>3. Modelo de Base de Datos Relacional</h2>
        <p>El esquema de base de datos relacional garantiza integridad referencial con borrado en cascada (ON DELETE CASCADE) y campos de auditoría temporal (TIMESTAMPTZ):</p>
        <pre>
-- Tabla de Usuarios
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  is_premium BOOLEAN NOT NULL DEFAULT false,
  ai_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Misiones Académicas
CREATE TABLE tasks (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  details TEXT,
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de Pasos de Misión
CREATE TABLE task_steps (
  id SERIAL PRIMARY KEY,
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  position INTEGER NOT NULL,
  title VARCHAR(255) NOT NULL,
  est_minutes INTEGER NOT NULL,
  done BOOLEAN NOT NULL DEFAULT false
);

-- Sesiones de Enfoque Pomodoro
CREATE TABLE focus_sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  step_id INTEGER REFERENCES task_steps(id) ON DELETE SET NULL,
  actual_seconds INTEGER NOT NULL,
  status VARCHAR(50) DEFAULT 'completed',
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ NOT NULL
);

-- Telemetría de Distracciones (TikTok, Instagram, Juegos)
CREATE TABLE distraction_logs (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  app_name VARCHAR(100) NOT NULL,
  package_name VARCHAR(255) NOT NULL,
  seconds INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
        </pre>
      </section>

      <section id="api">
        <h2>4. Especificación de Endpoints de la API REST</h2>
        <table class="table-tech">
          <thead>
            <tr><th>Método</th><th>Ruta / Endpoint</th><th>Descripción</th><th>Autenticación</th></tr>
          </thead>
          <tbody>
            <tr><td><span class="badge badge-post">POST</span></td><td><code>/auth/login</code></td><td>Autentica credenciales y emite token JWT con expiración a 30 días.</td><td>Pública</td></tr>
            <tr><td><span class="badge badge-post">POST</span></td><td><code>/auth/register</code></td><td>Registra nuevo usuario con hash BCrypt (salt factor 10).</td><td>Pública</td></tr>
            <tr><td><span class="badge badge-post">POST</span></td><td><code>/auth/recover-request</code></td><td>Genera OTP de 6 dígitos y despacha correo vía Resend API.</td><td>Pública</td></tr>
            <tr><td><span class="badge badge-post">POST</span></td><td><code>/auth/reset-password</code></td><td>Valida OTP y actualiza la contraseña del usuario.</td><td>Pública</td></tr>
            <tr><td><span class="badge badge-get">GET</span></td><td><code>/tasks</code></td><td>Retorna las misiones y micro-pasos del usuario autenticado.</td><td>Bearer JWT</td></tr>
            <tr><td><span class="badge badge-post">POST</span></td><td><code>/onboarding/chat</code></td><td>Procesa prompt de estudio y genera tareas con IA.</td><td>Bearer JWT</td></tr>
            <tr><td><span class="badge badge-get">GET</span></td><td><code>/paypal/checkout</code></td><td>Renderiza página con PayPal Smart Buttons oficiales Live.</td><td>Pública (Token url)</td></tr>
            <tr><td><span class="badge badge-post">POST</span></td><td><code>/paypal/capture-success</code></td><td>Verifica orden en <code>api-m.paypal.com</code> y activa cuenta Plus.</td><td>Bearer JWT</td></tr>
            <tr><td><span class="badge badge-get">GET</span></td><td><code>/admin/metrics</code></td><td>Consolida telemetría de usuarios, sesiones y distracciones.</td><td>Admin Key</td></tr>
          </tbody>
        </table>
      </section>

      <section id="paypal-flow">
        <h2>5. Pasarela PayPal: Flujo de Verificación Servidor a Servidor</h2>
        <p>A diferencia de sistemas vulnerables que confían ciegamente en la respuesta del cliente móvil, InfocusMind implementa una <strong>doble verificación bancaria</strong> estricta:</p>
        <ol>
          <li>El usuario aprueba la transacción en la interfaz oficial de PayPal.</li>
          <li>El frontend envía el <code>orderID</code> al backend en <code>/paypal/capture-success</code>.</li>
          <li>El servidor en Dart Shelf realiza una llamada autenticada directa hacia la API de PayPal (<code>https://api-m.paypal.com/v2/checkout/orders/\$orderId</code>) usando Basic Auth con el Client ID y Client Secret empresarial.</li>
          <li>Solo si PayPal confirma que el estado es <code>COMPLETED</code> o <code>APPROVED</code>, el backend ejecuta la transacción SQL para activar <code>is_premium = true</code>.</li>
          <li>El servidor genera el comprobante digital y lo despacha al correo del comprador vía <strong>Resend API</strong>.</li>
        </ol>
      </section>

      <section id="android-native">
        <h2>6. Integración Nativa con el Sistema Operativo Android</h2>
        <p>InfocusMind utiliza dos componentes nativos en el manifiesto de Android (<code>AndroidManifest.xml</code>):</p>
        <pre>
&lt;!-- Permiso para auditar tiempo de uso de apps distractoras --&gt;
&lt;uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions"/&gt;

&lt;!-- Filtro de intención para operar como Launcher por defecto --&gt;
&lt;intent-filter&gt;
    &lt;action android:name="android.intent.action.MAIN"/&gt;
    &lt;category android:name="android.intent.category.HOME"/&gt;
    &lt;category android:name="android.intent.category.DEFAULT"/&gt;
&lt;/intent-filter&gt;
        </pre>
      </section>
    </main>
  </div>
</body>
</html>''';

  return Response(200, body: html, headers: {'content-type': 'text/html; charset=utf-8'});
}
