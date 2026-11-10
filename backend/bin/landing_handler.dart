import 'dart:io';
import 'package:shelf/shelf.dart';

Future<Response> handleLanding(Request request) async {
  final env = Platform.environment;
  final customDownloadUrl = env['APK_DOWNLOAD_URL'];
  final downloadHref = (customDownloadUrl != null && customDownloadUrl.trim().isNotEmpty)
      ? customDownloadUrl.trim()
      : '/download/InfocusMind.apk';

  final html = '''<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>InfocusMind — Convierte tu estudio en una misión épica</title>
  <meta name="description" content="InfocusMind es la app gamificada que fragmenta tus tareas con Inteligencia Artificial, bloquea distracciones con su Modo Launcher y cuenta con Interfaz Invisible por voz.">
  <meta name="theme-color" content="#0a0d14">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&family=Inter:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #090c13;
      --surface: #111522;
      --surface-card: #161b2c;
      --border: #232a3f;
      --border-glow: #384363;
      --violet: #6c5ce7;
      --violet-glow: rgba(108, 92, 231, 0.35);
      --cian: #00d2d3;
      --cian-glow: rgba(0, 210, 211, 0.25);
      --menta: #2ecc71;
      --sol: #fed330;
      --coral: #ff6b6b;
      --text: #f8f9fa;
      --muted: #9aa5b8;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    html { scroll-behavior: smooth; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'Inter', -apple-system, sans-serif;
      overflow-x: hidden;
      line-height: 1.6;
    }

    /* Ambient background glows */
    .glow-orb {
      position: absolute;
      width: 500px;
      height: 500px;
      border-radius: 50%;
      filter: blur(140px);
      pointer-events: none;
      z-index: 0;
    }
    .orb-1 { top: -100px; left: -100px; background: rgba(108, 92, 231, 0.18); }
    .orb-2 { top: 200px; right: -150px; background: rgba(0, 210, 211, 0.15); }
    .orb-3 { bottom: 100px; left: 20%; background: rgba(254, 211, 48, 0.08); }

    .nav {
      position: sticky;
      top: 0;
      z-index: 100;
      backdrop-filter: blur(16px);
      background: rgba(9, 12, 19, 0.85);
      border-bottom: 1px solid var(--border);
    }
    .nav-inner {
      max-width: 1140px;
      margin: 0 auto;
      padding: 14px 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .logo {
      display: flex;
      align-items: center;
      gap: 12px;
      text-decoration: none;
      color: var(--text);
    }
    .logo-box {
      width: 38px;
      height: 38px;
      background: linear-gradient(135deg, var(--violet), var(--cian));
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: 'Press Start 2P', monospace;
      font-size: 13px;
      color: #fff;
      box-shadow: 0 4px 14px var(--violet-glow);
    }
    .logo-text {
      font-family: 'Press Start 2P', monospace;
      font-size: 13px;
      letter-spacing: -0.5px;
      background: linear-gradient(90deg, #fff, var(--cian));
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .nav-links {
      display: flex;
      gap: 20px;
      align-items: center;
    }
    .nav-link {
      color: var(--muted);
      text-decoration: none;
      font-size: 14px;
      font-weight: 600;
      transition: color 0.2s;
    }
    .nav-link:hover { color: var(--cian); }

    .btn-nav {
      background: linear-gradient(135deg, var(--violet), #5b46e0);
      color: #fff;
      padding: 9px 18px;
      border-radius: 8px;
      text-decoration: none;
      font-size: 13px;
      font-weight: 700;
      border: 1px solid rgba(255,255,255,0.15);
      box-shadow: 0 4px 12px var(--violet-glow);
      transition: transform 0.15s, box-shadow 0.15s;
    }
    .btn-nav:hover {
      transform: translateY(-2px);
      box-shadow: 0 6px 18px var(--violet-glow);
    }

    /* Hero Section */
    .hero {
      position: relative;
      max-width: 1140px;
      margin: 0 auto;
      padding: 80px 20px 60px;
      text-align: center;
      z-index: 1;
    }
    .badge-hero {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      background: rgba(0, 210, 211, 0.1);
      border: 1px solid var(--cian);
      color: var(--cian);
      padding: 6px 14px;
      border-radius: 30px;
      font-size: 12px;
      font-weight: 700;
      letter-spacing: 0.5px;
      margin-bottom: 24px;
      text-transform: uppercase;
    }
    .badge-hero span { font-size: 14px; }

    .hero-title {
      font-size: clamp(34px, 5.5vw, 62px);
      font-weight: 900;
      line-height: 1.12;
      letter-spacing: -1.5px;
      max-width: 900px;
      margin: 0 auto 20px;
    }
    .hero-title .gradient-text {
      background: linear-gradient(120deg, #fff 20%, var(--cian) 60%, var(--violet) 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
    }

    .hero-subtitle {
      font-size: clamp(16px, 2vw, 20px);
      color: var(--muted);
      max-width: 680px;
      margin: 0 auto 36px;
      font-weight: 400;
    }

    .cta-group {
      display: flex;
      flex-wrap: wrap;
      justify-content: center;
      align-items: center;
      gap: 16px;
      margin-bottom: 30px;
    }
    .btn-download {
      background: linear-gradient(135deg, var(--sol), #f39c12);
      color: #0c0f17;
      padding: 16px 32px;
      border-radius: 10px;
      text-decoration: none;
      font-weight: 800;
      font-size: 16px;
      display: inline-flex;
      align-items: center;
      gap: 12px;
      box-shadow: 0 6px 20px rgba(254, 211, 48, 0.35), inset 0 2px 0 rgba(255,255,255,0.4);
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      border: none;
      cursor: pointer;
    }
    .btn-download:hover {
      transform: translateY(-3px) scale(1.02);
      box-shadow: 0 10px 28px rgba(254, 211, 48, 0.45);
    }
    .btn-download svg { width: 22px; height: 22px; fill: currentColor; }

    .btn-secondary {
      background: var(--surface);
      border: 1.5px solid var(--border-glow);
      color: var(--text);
      padding: 15px 28px;
      border-radius: 10px;
      text-decoration: none;
      font-weight: 700;
      font-size: 15px;
      display: inline-flex;
      align-items: center;
      gap: 10px;
      transition: all 0.2s;
    }
    .btn-secondary:hover {
      background: var(--surface-card);
      border-color: var(--cian);
      color: var(--cian);
    }

    .specs-line {
      display: flex;
      justify-content: center;
      gap: 20px;
      font-size: 13px;
      color: var(--muted);
      flex-wrap: wrap;
    }
    .spec-item {
      display: flex;
      align-items: center;
      gap: 6px;
    }
    .spec-dot { width: 6px; height: 6px; background: var(--menta); border-radius: 50%; }

    /* Phone Mockup Showcase */
    .showcase {
      max-width: 900px;
      margin: 40px auto 70px;
      position: relative;
    }
    .mockup-card {
      background: var(--surface);
      border: 2px solid var(--border);
      border-radius: 20px;
      padding: 24px;
      box-shadow: 0 25px 60px rgba(0, 0, 0, 0.6), 0 0 40px var(--violet-glow);
      position: relative;
      overflow: hidden;
    }
    .mockup-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-bottom: 16px;
      border-bottom: 1px solid var(--border);
      margin-bottom: 20px;
    }
    .mockup-dots { display: flex; gap: 6px; }
    .mockup-dot { width: 10px; height: 10px; border-radius: 50%; background: var(--border-glow); }
    .mockup-title { font-family: 'Press Start 2P', monospace; font-size: 10px; color: var(--sol); }

    .preview-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 16px;
      text-align: left;
    }
    .preview-box {
      background: var(--surface-card);
      border: 1.5px solid var(--border);
      border-radius: 12px;
      padding: 16px;
      position: relative;
    }
    .preview-tag {
      font-family: 'Press Start 2P', monospace;
      font-size: 8px;
      padding: 4px 8px;
      border-radius: 4px;
      display: inline-block;
      margin-bottom: 10px;
    }
    .tag-violet { background: rgba(108,92,231,0.2); color: var(--violet); border: 1px solid var(--violet); }
    .tag-cian { background: rgba(0,210,211,0.2); color: var(--cian); border: 1px solid var(--cian); }
    .tag-sol { background: rgba(254,211,48,0.2); color: var(--sol); border: 1px solid var(--sol); }

    .preview-box h4 { font-size: 15px; margin-bottom: 6px; color: #fff; }
    .preview-box p { font-size: 12px; color: var(--muted); }

    /* Features Grid */
    .section {
      max-width: 1140px;
      margin: 0 auto;
      padding: 70px 20px;
      position: relative;
      z-index: 1;
    }
    .section-header {
      text-align: center;
      margin-bottom: 50px;
    }
    .section-eyebrow {
      font-family: 'Press Start 2P', monospace;
      font-size: 11px;
      color: var(--cian);
      margin-bottom: 12px;
      display: block;
    }
    .section-heading {
      font-size: clamp(28px, 4vw, 42px);
      font-weight: 800;
      letter-spacing: -1px;
    }

    .features-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(310px, 1fr));
      gap: 22px;
    }
    .feature-card {
      background: var(--surface);
      border: 1.5px solid var(--border);
      border-radius: 16px;
      padding: 28px;
      transition: all 0.25s ease;
      position: relative;
      overflow: hidden;
    }
    .feature-card:hover {
      border-color: var(--cian);
      transform: translateY(-5px);
      box-shadow: 0 16px 36px rgba(0, 210, 211, 0.12);
    }
    .feature-icon {
      width: 52px;
      height: 52px;
      border-radius: 12px;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 24px;
      margin-bottom: 18px;
    }
    .icon-violet { background: rgba(108, 92, 231, 0.18); border: 1.5px solid var(--violet); color: var(--violet); }
    .icon-cian { background: rgba(0, 210, 211, 0.18); border: 1.5px solid var(--cian); color: var(--cian); }
    .icon-sol { background: rgba(254, 211, 48, 0.18); border: 1.5px solid var(--sol); color: var(--sol); }
    .icon-menta { background: rgba(46, 204, 113, 0.18); border: 1.5px solid var(--menta); color: var(--menta); }
    .icon-coral { background: rgba(255, 107, 107, 0.18); border: 1.5px solid var(--coral); color: var(--coral); }

    .feature-card h3 {
      font-size: 19px;
      font-weight: 700;
      margin-bottom: 10px;
    }
    .feature-card p {
      font-size: 14px;
      color: var(--muted);
      line-height: 1.6;
    }

    /* Installation Steps */
    .install-box {
      background: linear-gradient(145deg, var(--surface), #0f131f);
      border: 2px solid var(--border-glow);
      border-radius: 20px;
      padding: 40px 30px;
      box-shadow: 0 20px 45px rgba(0,0,0,0.5);
    }
    .steps-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 24px;
      margin-top: 36px;
    }
    .step-item {
      text-align: left;
      position: relative;
    }
    .step-number {
      font-family: 'Press Start 2P', monospace;
      font-size: 14px;
      width: 40px;
      height: 40px;
      border-radius: 10px;
      background: var(--surface-card);
      border: 2px solid var(--cian);
      color: var(--cian);
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: 14px;
    }
    .step-item h4 {
      font-size: 16px;
      margin-bottom: 8px;
    }
    .step-item p {
      font-size: 13px;
      color: var(--muted);
    }

    /* CTA Bottom */
    .cta-banner {
      background: linear-gradient(135deg, rgba(108, 92, 231, 0.25), rgba(0, 210, 211, 0.15));
      border: 2px solid var(--violet);
      border-radius: 24px;
      padding: 60px 30px;
      text-align: center;
      margin-top: 40px;
      box-shadow: 0 20px 50px var(--violet-glow);
    }
    .cta-banner h2 {
      font-size: clamp(26px, 3.5vw, 40px);
      font-weight: 900;
      margin-bottom: 14px;
    }
    .cta-banner p {
      color: var(--muted);
      max-width: 600px;
      margin: 0 auto 30px;
      font-size: 16px;
    }

    /* Footer */
    .footer {
      border-top: 1px solid var(--border);
      padding: 40px 20px;
      text-align: center;
      font-size: 13px;
      color: var(--muted);
      margin-top: 40px;
    }
    .footer-links {
      display: flex;
      justify-content: center;
      gap: 20px;
      margin-bottom: 16px;
      flex-wrap: wrap;
    }
    .footer-links a {
      color: var(--text);
      text-decoration: none;
      font-weight: 600;
    }
    .footer-links a:hover { color: var(--cian); }

    @media (max-width: 768px) {
      .hero { padding: 50px 16px 40px; }
      .cta-group { flex-direction: column; width: 100%; }
      .btn-download, .btn-secondary { width: 100%; justify-content: center; }
      .nav-links { display: none; }
    }
  </style>
</head>
<body>
  <div class="glow-orb orb-1"></div>
  <div class="glow-orb orb-2"></div>
  <div class="glow-orb orb-3"></div>

  <!-- Navigation -->
  <header class="nav">
    <div class="nav-inner">
      <a href="#" class="logo">
        <div class="logo-box">IFM</div>
        <span class="logo-text">InfocusMind</span>
      </a>
      <nav class="nav-links">
        <a href="#caracteristicas" class="nav-link">Características</a>
        <a href="#launcher" class="nav-link">Modo Launcher</a>
        <a href="#instalacion" class="nav-link">Instalación</a>
        <a href="/admin/metrics?key=infocus2026" class="nav-link">Métricas</a>
        <a href="$downloadHref" class="btn-nav">Descargar APK</a>
      </nav>
    </div>
  </header>

  <!-- Hero Section -->
  <main class="hero">
    <div class="badge-hero">
      <span>🚀</span> Proyecto de Enfoque y Productividad Gamificada
    </div>
    <h1 class="hero-title">
      Convierte tu estudio en un videojuego y <span class="gradient-text">derrota las distracciones</span>
    </h1>
    <p class="hero-subtitle">
      InfocusMind fragmenta tus tareas con Inteligencia Artificial, bloquea redes sociales adictivas con su Modo Launcher y te permite dictar tus misiones por voz con Interfaz Invisible.
    </p>

    <div class="cta-group">
      <a href="$downloadHref" class="btn-download" download>
        <svg viewBox="0 0 24 24"><path d="M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM17 13l-5 5-5-5h3V9h4v4h3z"/></svg>
        Descargar APK Gratis
      </a>
      <a href="#instalacion" class="btn-secondary">
        ¿Cómo instalar en Android?
      </a>
    </div>

    <div class="specs-line">
      <div class="spec-item"><div class="spec-dot"></div> Versión 1.0 Estable</div>
      <div class="spec-item"><div class="spec-dot"></div> Compatible con Android 8.0+</div>
      <div class="spec-item"><div class="spec-dot"></div> 100% Gratuito y Sin Anuncios</div>
    </div>

    <!-- Phone Preview Showcase -->
    <div class="showcase">
      <div class="mockup-card">
        <div class="mockup-header">
          <div class="mockup-dots">
            <div class="mockup-dot"></div>
            <div class="mockup-dot"></div>
            <div class="mockup-dot"></div>
          </div>
          <div class="mockup-title">INFOCUSMIND OS &bull; INTERFAZ HUD GAMIFICADA</div>
          <div style="font-size:11px; color:var(--menta); font-weight:700;">EN VIVO</div>
        </div>

        <div class="preview-grid">
          <div class="preview-box">
            <span class="preview-tag tag-violet">IA PLANNER</span>
            <h4>Fragmentación Automática</h4>
            <p>La IA divide exámenes y metas complejas en bloques de 5 a 25 min para evitar la procrastinación.</p>
          </div>
          <div class="preview-box">
            <span class="preview-tag tag-cian">MODO LAUNCHER</span>
            <h4>Anti-Distracciones Real</h4>
            <p>Al pulsar el botón Home solo ves tus herramientas de estudio permitidas (Calculadora, Libros, etc.).</p>
          </div>
          <div class="preview-box">
            <span class="preview-tag tag-sol">ZERO UI</span>
            <h4>Interfaz Invisible por Voz</h4>
            <p>Toca el micrófono y dicta tus tareas sin tocar el teclado. La app las procesa automáticamente.</p>
          </div>
        </div>
      </div>
    </div>
  </main>

  <!-- Features Section -->
  <section id="caracteristicas" class="section">
    <div class="section-header">
      <span class="section-eyebrow">TECNOLOGÍA Y FUNCIONES</span>
      <h2 class="section-heading">Todo lo que necesitas para concentrarte</h2>
    </div>

    <div class="features-grid">
      <div class="feature-card">
        <div class="feature-icon icon-violet">🤖</div>
        <h3>Planificador Asistente con IA</h3>
        <p>Impulsado por modelos avanzados de lenguaje. Solo escribe o dicta tu meta de estudio y el bot la dividirá paso a paso con tiempos estimados y verbos de acción.</p>
      </div>

      <div class="feature-card">
        <div class="feature-icon icon-cian">🛡️</div>
        <h3>Modo Launcher Focus</h3>
        <p>Convierte la pantalla de inicio de tu teléfono en un entorno minimalista. Bloquea el acceso involuntario a TikTok, Instagram o juegos mientras estudias.</p>
      </div>

      <div class="feature-card">
        <div class="feature-icon icon-sol">🎙️</div>
        <h3>Interfaz Invisible (Zero UI)</h3>
        <p>Integración nativa con reconocimiento de voz. Habla de manera natural al micrófono para crear misiones o chatear con el asistente sin fricción.</p>
      </div>

      <div class="feature-card">
        <div class="feature-icon icon-menta">🎮</div>
        <h3>Gamificación con XP y Niveles</h3>
        <p>Gana puntos de experiencia (XP) por cada minuto de enfoque real completado. Sube de nivel, desbloquea logros y sigue tu racha diaria en el mapa.</p>
      </div>

      <div class="feature-card">
        <div class="feature-icon icon-coral">📊</div>
        <h3>Auditoría de Distracciones</h3>
        <p>La app registra silenciosamente el tiempo que abriste aplicaciones distractoras durante tu sesión para mostrarte estadísticas precisas de tus hábitos.</p>
      </div>

      <div class="feature-card">
        <div class="feature-icon icon-cian">📅</div>
        <h3>Calendario y Gestión Manual</h3>
        <p>Planifica tus sesiones con fechas específicas, edita misiones existentes en cualquier momento y reorganiza tus pasos según tus necesidades del día.</p>
      </div>
    </div>
  </section>

  <!-- Launcher Section -->
  <section id="launcher" class="section">
    <div class="mockup-card" style="border-color:var(--cian); text-align:center; padding: 50px 30px;">
      <span class="preview-tag tag-cian" style="margin-bottom:16px;">TECNOLOGÍA NATIVA ANDROID</span>
      <h2 style="font-size:clamp(24px, 3.5vw, 36px); font-weight:800; margin-bottom:16px;">
        ¿Cómo funciona el Launcher de InfocusMind?
      </h2>
      <p style="color:var(--muted); max-width:720px; margin:0 auto 30px; font-size:15px;">
        A diferencia de otras apps que solo ponen ventanas emergentes que puedes cerrar fácilmente, InfocusMind se integra como un <strong>Launcher del sistema Android</strong>.
      </p>
      <div class="preview-grid" style="text-align:left;">
        <div class="preview-box">
          <h4 style="color:var(--cian);">1. Activar Launcher</h4>
          <p>Un toque en Ajustes fija InfocusMind como pantalla principal para tus horas de estudio intensivo.</p>
        </div>
        <div class="preview-box">
          <h4 style="color:var(--sol);">2. Solo Apps Permitidas</h4>
          <p>El botón de inicio de tu celular solo te llevará al launcher con tus herramientas útiles seleccionadas.</p>
        </div>
        <div class="preview-box">
          <h4 style="color:var(--coral);">3. Desactivar en 1 Toque</h4>
          <p>Al terminar de estudiar, tocas "Desactivar" y tu teléfono vuelve a su pantalla normal inmediatamente.</p>
        </div>
      </div>
    </div>
  </section>

  <!-- Installation Steps -->
  <section id="instalacion" class="section">
    <div class="install-box">
      <div style="text-align:center;">
        <span class="section-eyebrow">GUÍA RÁPIDA</span>
        <h2 class="section-heading">Cómo instalar InfocusMind en tu celular</h2>
        <p style="color:var(--muted); max-width:600px; margin:10px auto 0;">Sigue estos 3 sencillos pasos para instalar el archivo APK directamente en cualquier dispositivo Android:</p>
      </div>

      <div class="steps-grid">
        <div class="step-item">
          <div class="step-number">01</div>
          <h4>Descarga el APK</h4>
          <p>Pulsa el botón amarillo de descarga desde tu celular para bajar el archivo <code>InfocusMind.apk</code>.</p>
        </div>
        <div class="step-item">
          <div class="step-number">02</div>
          <h4>Permitir instalación</h4>
          <p>Si Android te pide confirmación por ser una descarga fuera de Play Store, pulsa <strong>"Descargar de todos modos"</strong> y luego <strong>"Instalar"</strong>.</p>
        </div>
        <div class="step-item">
          <div class="step-number">03</div>
          <h4>Crea tu cuenta y enfócate</h4>
          <p>Abre la app, regístrate con tu correo y comienza tu primera misión de estudio gamificada.</p>
        </div>
      </div>

      <div style="text-align:center; margin-top:36px;">
        <a href="$downloadHref" class="btn-download" download>
          <svg viewBox="0 0 24 24"><path d="M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM17 13l-5 5-5-5h3V9h4v4h3z"/></svg>
          Descargar InfocusMind APK
        </a>
      </div>
    </div>
  </section>

  <!-- Final CTA -->
  <section class="section" style="padding-top:0;">
    <div class="cta-banner">
      <h2>¿Listo para subir de nivel tus notas?</h2>
      <p>Deja de procrastinar y transforma tus sesiones de estudio en logros reales hoy mismo.</p>
      <a href="$downloadHref" class="btn-download" download>
        Descargar APK para Android
      </a>
    </div>
  </section>

  <!-- Footer -->
  <footer class="footer">
    <div class="footer-links">
      <a href="#">Inicio</a>
      <a href="#caracteristicas">Características</a>
      <a href="#instalacion">Instalación</a>
      <a href="/admin/metrics?key=infocus2026">Panel de Métricas</a>
      <a href="https://github.com/Mikic137/infocusmind" target="_blank" rel="noopener">GitHub</a>
    </div>
    <p>InfocusMind &bull; Proyecto de Productividad Gamificada para Estudiantes &bull; 2026</p>
  </footer>
</body>
</html>''';

  return Response(200,
      body: html, headers: {'content-type': 'text/html; charset=utf-8'});
}

Future<Response> handlePrivacy(Request request) async {
  final html = '''<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Política de Privacidad — InfocusMind</title>
  <style>
    body {
      background: #090c13;
      color: #e2e8f0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      line-height: 1.6;
      padding: 40px 20px;
      max-width: 800px;
      margin: 0 auto;
    }
    h1 { color: #6c5ce7; font-size: 2rem; margin-bottom: 8px; }
    h2 { color: #00d2d3; font-size: 1.3rem; margin-top: 32px; margin-bottom: 12px; }
    p, li { color: #94a3b8; font-size: 1rem; margin-bottom: 12px; }
    ul { padding-left: 24px; margin-bottom: 16px; }
    a { color: #6c5ce7; text-decoration: none; }
    a:hover { text-decoration: underline; }
    .card {
      background: #111522;
      border: 1px solid #232a3f;
      border-radius: 12px;
      padding: 32px;
      margin-top: 24px;
    }
    .back { display: inline-block; margin-bottom: 20px; font-weight: 600; }
  </style>
</head>
<body>
  <a href="/" class="back">&larr; Volver a InfocusMind</a>
  <div class="card">
    <h1>Política de Privacidad</h1>
    <p><strong>Última actualización:</strong> Noviembre 2026</p>
    
    <h2>1. Información que recopilamos</h2>
    <p>InfocusMind recopila la información mínima necesaria para brindar el servicio:</p>
    <ul>
      <li><strong>Cuenta de usuario:</strong> Dirección de correo electrónico y contraseña encriptada (con hash bcrypt) para autenticación segura.</li>
      <li><strong>Datos de estudio y productividad:</strong> Misiones, tareas, sesiones de enfoque completadas, tiempos de estudio y nivel de experiencia (XP) para el funcionamiento de las funciones de gamificación.</li>
      <li><strong>Dictado por voz:</strong> Las grabaciones de voz se procesan temporalmente de manera local o mediante el proveedor de IA únicamente para transcribir el texto de las tareas, sin almacenarse en audio permanente.</li>
    </ul>

    <h2>2. Uso de la Información</h2>
    <p>Los datos recopilados se utilizan exclusivamente para:</p>
    <ul>
      <li>Permitir el acceso y sincronización de tareas entre tus dispositivos.</li>
      <li>Calibrar las estimaciones de tiempo y personalización del asistente de estudio.</li>
      <li>Calcular estadísticas globales de uso anónimas para la mejora continua del servicio.</li>
    </ul>

    <h2>3. Almacenamiento y Seguridad</h2>
    <p>Toda la comunicación entre la aplicación móvil y nuestros servidores se realiza mediante cifrado TLS/HTTPS. Las contraseñas se almacenan con algoritmos de hashing unidireccional (bcrypt).</p>

    <h2>4. Permisos en el Dispositivo</h2>
    <ul>
      <li><strong>Micrófono:</strong> Utilizado únicamente cuando el usuario presiona el botón de dictado de tareas por voz (Zero UI).</li>
      <li><strong>Modo Launcher:</strong> Utilizado voluntariamente para reemplazar la pantalla de inicio durante las sesiones de estudio y evitar distracciones.</li>
    </ul>

    <h2>5. Contacto</h2>
    <p>Si tienes preguntas sobre esta política o deseas solicitar la eliminación de tu cuenta y datos, puedes contactarnos a través de nuestra web oficial o repositorio en GitHub:</p>
    <p><a href="https://github.com/Mikic137/infocusmind">https://github.com/Mikic137/infocusmind</a></p>
  </div>
</body>
</html>''';

  return Response(200, body: html, headers: {'content-type': 'text/html; charset=utf-8'});
}
