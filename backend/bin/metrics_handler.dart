import 'dart:convert';
import 'dart:io';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

Future<Response> handleMetrics(
    Request request, Future<Connection> Function() abrirConexion) async {
  final env = Platform.environment;
  final queryKey = request.url.queryParameters['key'];
  final headerKey = request.headers['x-admin-key'];
  final expectedKey = env['ADMIN_KEY'] ?? 'infocus2026';

  if (queryKey != expectedKey && headerKey != expectedKey) {
    return Response(401,
        body: '''<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>InfocusMind — Acceso al Panel</title>
  <style>
    body { background: #0c0f17; color: #f1f2f6; font-family: -apple-system, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
    .box { background: #151926; padding: 36px; border-radius: 12px; border: 1.5px solid #242b3d; text-align: center; max-width: 380px; width: 90%; }
    h2 { margin: 0 0 10px; font-size: 20px; }
    p { font-size: 13px; color: #a4b0be; margin-bottom: 20px; }
    input { width: 100%; box-sizing: border-box; padding: 12px; border-radius: 8px; border: 1px solid #333; background: #0c0f17; color: #fff; margin-bottom: 14px; font-size: 14px; }
    button { width: 100%; padding: 12px; border-radius: 8px; background: #6c5ce7; color: #fff; border: none; font-weight: 700; cursor: pointer; font-size: 14px; }
    button:hover { background: #5a4bcf; }
  </style>
</head>
<body>
  <div class="box">
    <h2>🔒 InfocusMind Analytics</h2>
    <p>Ingresa la clave de administrador para consultar las métricas del proyecto:</p>
    <form method="GET">
      <input type="password" name="key" placeholder="Clave de administrador..." autofocus required>
      <button type="submit">Ver Métricas</button>
    </form>
  </div>
</body>
</html>''',
        headers: {'content-type': 'text/html; charset=utf-8'});
  }

  try {
    final conn = await abrirConexion();
    try {
      final rUsers = await conn.execute('SELECT COUNT(*) FROM users');
      final totalUsers = rUsers.first[0] as int;

      final rUsersToday = await conn.execute(
          'SELECT COUNT(*) FROM users WHERE created_at >= CURRENT_DATE');
      final usersToday = rUsersToday.first[0] as int;

      final rUsers7d = await conn.execute(
          "SELECT COUNT(*) FROM users WHERE created_at >= NOW() - INTERVAL '7 days'");
      final users7d = rUsers7d.first[0] as int;

      final rActiveUsers = await conn.execute(
          "SELECT COUNT(DISTINCT user_id) FROM focus_sessions WHERE started_at >= NOW() - INTERVAL '7 days'");
      final activeUsers7d = rActiveUsers.first[0] as int;

      final rTasks = await conn.execute('SELECT COUNT(*) FROM tasks');
      final totalTasks = rTasks.first[0] as int;

      final rTasksDone = await conn.execute(
          "SELECT COUNT(*) FROM tasks WHERE status = 'completed'");
      final completedTasks = rTasksDone.first[0] as int;

      final rSessions = await conn.execute('SELECT COUNT(*) FROM focus_sessions');
      final totalSessions = rSessions.first[0] as int;

      final rFocusTime = await conn.execute(
          'SELECT COALESCE(SUM(actual_seconds), 0) FROM focus_sessions');
      final totalSeconds = (rFocusTime.first[0] as num).toInt();
      final totalMinutes = (totalSeconds / 60).round();
      final totalHours = (totalMinutes / 60.0).toStringAsFixed(1);

      final rRecentUsers = await conn.execute('''
        SELECT 
          u.id, 
          u.email, 
          u.created_at,
          (SELECT COUNT(*) FROM tasks t WHERE t.user_id = u.id) as tareas,
          (SELECT COUNT(*) FROM focus_sessions f WHERE f.user_id = u.id) as sesiones
        FROM users u 
        ORDER BY u.created_at DESC 
        LIMIT 250
      ''');
      final recentUsers = rRecentUsers.map((row) {
        final email = row[1] as String;
        final rawDt = row[2] as DateTime;
        final ecuadorDt = rawDt.toUtc().subtract(const Duration(hours: 5));
        return {
          'id': row[0],
          'email': email,
          'created_at': ecuadorDt.toString().substring(0, 19),
          'tasks': (row[3] as num).toInt(),
          'sessions': (row[4] as num).toInt(),
        };
      }).toList();

      final rDistractions = await conn.execute('''
        SELECT app_name, COALESCE(SUM(seconds), 0) as total_seg, COUNT(*) as veces
        FROM distraction_logs
        GROUP BY app_name
        ORDER BY total_seg DESC, veces DESC
        LIMIT 50
      ''');
      final topDistractions = rDistractions.map((row) {
        final seg = (row[1] as num).toInt();
        final displayTime = seg < 60 ? '$seg seg' : '${(seg / 60).round()} min';
        return {
          'app': row[0].toString(),
          'seconds': seg,
          'minutes': (seg / 60).round(),
          'display_time': displayTime,
          'count': (row[2] as num).toInt(),
        };
      }).toList();

      final rRecentLogs = await conn.execute('''
        SELECT d.id, u.email, d.app_name, d.seconds, d.created_at
        FROM distraction_logs d
        JOIN users u ON u.id = d.user_id
        ORDER BY d.created_at DESC
        LIMIT 25
      ''');
      final recentLogs = rRecentLogs.map((row) {
        final seg = (row[3] as num).toInt();
        final displayTime = seg < 60 ? '$seg seg' : '${(seg / 60).round()} min';
        final rawDt = row[4] as DateTime;
        final ecuadorDt = rawDt.toUtc().subtract(const Duration(hours: 5));
        return {
          'id': row[0],
          'email': row[1].toString(),
          'app': row[2].toString(),
          'display_time': displayTime,
          'created_at': ecuadorDt.toString().substring(0, 19),
        };
      }).toList();

      final wantsJson =
          request.headers['accept']?.contains('application/json') == true ||
              request.url.queryParameters['format'] == 'json';
      if (wantsJson) {
        return Response(200,
            body: jsonEncode({
              'total_users': totalUsers,
              'users_today': usersToday,
              'users_last_7_days': users7d,
              'active_users_7_days': activeUsers7d,
              'total_tasks': totalTasks,
              'completed_tasks': completedTasks,
              'total_focus_sessions': totalSessions,
              'total_study_minutes': totalMinutes,
              'total_study_hours': totalHours,
              'recent_users': recentUsers,
              'top_distractions': topDistractions,
              'recent_distraction_logs': recentLogs,
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            }),
            headers: {'content-type': 'application/json'});
      }

      final html = '''<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>InfocusMind — Panel de Métricas</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #0c0f17;
      --card: #151926;
      --card-border: #242b3d;
      --accent: #6c5ce7;
      --accent-glow: rgba(108, 92, 231, 0.25);
      --cian: #00d2d3;
      --menta: #2ecc71;
      --sol: #fed330;
      --coral: #ff6b6b;
      --text: #f1f2f6;
      --muted: #a4b0be;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'Inter', -apple-system, sans-serif;
      padding: 24px;
      line-height: 1.5;
    }
    .header {
      max-width: 1100px;
      margin: 0 auto 28px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      flex-wrap: wrap;
      gap: 16px;
      border-bottom: 2px solid var(--card-border);
      padding-bottom: 16px;
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .logo-badge {
      background: linear-gradient(135deg, var(--accent), var(--cian));
      padding: 10px 14px;
      border-radius: 10px;
      font-family: 'Press Start 2P', monospace;
      font-size: 14px;
      color: #fff;
      box-shadow: 0 4px 15px var(--accent-glow);
    }
    .title h1 {
      font-size: 22px;
      font-weight: 800;
      letter-spacing: -0.5px;
    }
    .title p {
      font-size: 13px;
      color: var(--muted);
    }
    .live-badge {
      background: rgba(46, 204, 113, 0.15);
      border: 1px solid var(--menta);
      color: var(--menta);
      padding: 6px 12px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 700;
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }
    .dot {
      width: 8px;
      height: 8px;
      background: var(--menta);
      border-radius: 50%;
      animation: pulse 1.8s infinite;
    }
    @keyframes pulse {
      0% { opacity: 0.4; transform: scale(0.9); }
      50% { opacity: 1; transform: scale(1.1); }
      100% { opacity: 0.4; transform: scale(0.9); }
    }
    .container {
      max-width: 1100px;
      margin: 0 auto;
    }
    .section-title {
      font-size: 13px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: var(--cian);
      margin: 24px 0 12px;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 16px;
      margin-bottom: 24px;
    }
    .card {
      background: var(--card);
      border: 1.5px solid var(--card-border);
      border-radius: 12px;
      padding: 18px 20px;
      position: relative;
      overflow: hidden;
    }
    .card::before {
      content: '';
      position: absolute;
      top: 0; left: 0; right: 0; height: 3px;
      background: var(--accent);
    }
    .card.cian::before { background: var(--cian); }
    .card.menta::before { background: var(--menta); }
    .card.sol::before { background: var(--sol); }
    .card.coral::before { background: var(--coral); }
    .card-label {
      font-size: 11px;
      font-weight: 700;
      color: var(--muted);
      margin-bottom: 8px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .card-value {
      font-size: 32px;
      font-weight: 800;
      color: #fff;
      letter-spacing: -1px;
    }
    .card-sub {
      font-size: 12px;
      color: var(--muted);
      margin-top: 4px;
    }
    .tables-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(360px, 1fr));
      gap: 20px;
      margin-top: 10px;
    }
    .table-card {
      background: var(--card);
      border: 1.5px solid var(--card-border);
      border-radius: 12px;
      padding: 18px;
    }
    .table-card h3 {
      font-size: 15px;
      font-weight: 700;
      margin-bottom: 14px;
      color: var(--text);
    }
    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }
    th {
      text-align: left;
      color: var(--muted);
      font-weight: 600;
      padding: 8px 6px;
      border-bottom: 1px solid var(--card-border);
    }
    td {
      padding: 9px 6px;
      border-bottom: 1px solid rgba(255,255,255,0.04);
      color: var(--text);
    }
    .badge {
      display: inline-block;
      padding: 3px 8px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: 700;
      background: rgba(108, 92, 231, 0.2);
      color: var(--accent);
    }
    .footer {
      text-align: center;
      margin-top: 36px;
      color: var(--muted);
      font-size: 12px;
    }
    .refresh-btn {
      background: var(--card-border);
      color: var(--text);
      border: none;
      padding: 6px 14px;
      border-radius: 6px;
      cursor: pointer;
      font-size: 12px;
      font-weight: 600;
    }
    .refresh-btn:hover { background: var(--accent); }
  </style>
</head>
<body>
  <div class="header">
    <div class="brand">
      <div class="logo-badge">IFM</div>
      <div class="title">
        <h1>InfocusMind — Métricas del Proyecto</h1>
        <p>Estadísticas del lanzamiento en tiempo real</p>
      </div>
    </div>
    <div style="display:flex; gap:10px; align-items:center;">
      <div class="live-badge"><span class="dot"></span> EN VIVO</div>
      <button class="refresh-btn" onclick="location.reload()">↻ Actualizar</button>
    </div>
  </div>

  <div class="container">
    <div class="section-title">👥 Tráfico y Usuarios</div>
    <div class="grid">
      <div class="card">
        <div class="card-label">TOTAL USUARIOS REGISTRADOS</div>
        <div class="card-value">$totalUsers</div>
        <div class="card-sub">Cuentas creadas en la app</div>
      </div>
      <div class="card cian">
        <div class="card-label">REGISTRADOS HOY</div>
        <div class="card-value">$usersToday</div>
        <div class="card-sub">Nuevos hoy</div>
      </div>
      <div class="card sol">
        <div class="card-label">ÚLTIMOS 7 DÍAS</div>
        <div class="card-value">$users7d</div>
        <div class="card-sub">Crecimiento semanal</div>
      </div>
      <div class="card menta">
        <div class="card-label">USUARIOS ACTIVOS (7 DÍAS)</div>
        <div class="card-value">$activeUsers7d</div>
        <div class="card-sub">Con sesiones de estudio</div>
      </div>
    </div>

    <div class="section-title">⚡ Uso y Productividad</div>
    <div class="grid">
      <div class="card sol">
        <div class="card-label">MISIONES CREADAS</div>
        <div class="card-value">$totalTasks</div>
        <div class="card-sub">$completedTasks completadas</div>
      </div>
      <div class="card menta">
        <div class="card-label">SESIONES DE ENFOQUE</div>
        <div class="card-value">$totalSessions</div>
        <div class="card-sub">Temporizadores ejecutados</div>
      </div>
      <div class="card cian">
        <div class="card-label">TIEMPO TOTAL DE ESTUDIO</div>
        <div class="card-value">${totalHours}h</div>
        <div class="card-sub">$totalMinutes minutos concentrados</div>
      </div>
    </div>

    <div class="tables-grid">
      <div class="table-card">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
          <h3 style="margin-bottom:0;">Usuarios Registrados ($totalUsers en total)</h3>
          <span style="font-size:11px; color:var(--muted)">Hora Ecuador (UTC-5)</span>
        </div>
        <div style="max-height: 480px; overflow-y: auto;">
          <table>
            <thead>
              <tr>
                <th>ID</th>
                <th>Correo</th>
                <th>Fecha (Ecuador)</th>
                <th>Misiones</th>
                <th>Sesiones</th>
              </tr>
            </thead>
            <tbody>
              ${recentUsers.isEmpty ? '<tr><td colspan="5" style="text-align:center; color:var(--muted)">Sin registros aún</td></tr>' : recentUsers.map((u) => '''
                <tr>
                  <td><span class="badge">#${u['id']}</span></td>
                  <td><strong>${u['email']}</strong></td>
                  <td style="color:var(--muted); font-size:12px;">${u['created_at']}</td>
                  <td><span class="badge" style="background:rgba(0,210,211,0.15); color:var(--cian);">${u['tasks']}</span></td>
                  <td><span class="badge" style="background:rgba(46,204,113,0.15); color:var(--menta);">${u['sessions']}</span></td>
                </tr>
              ''').join('')}
            </tbody>
          </table>
        </div>
      </div>

      <div class="table-card">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
          <h3 style="margin-bottom:0;">Aplicaciones Distractoras (${topDistractions.length} detectadas)</h3>
          <span style="font-size:11px; color:var(--muted)">Historial consolidado</span>
        </div>
        <div style="max-height: 480px; overflow-y: auto;">
          <table>
            <thead>
              <tr>
                <th>Aplicación</th>
                <th>Veces detectada</th>
                <th>Tiempo total</th>
              </tr>
            </thead>
            <tbody>
              ${topDistractions.isEmpty ? '<tr><td colspan="3" style="text-align:center; color:var(--muted)">Aún no se han registrado distracciones</td></tr>' : topDistractions.map((d) => '''
                <tr>
                  <td><strong>${d['app']}</strong></td>
                  <td>${d['count']} veces</td>
                  <td><span class="badge" style="background:rgba(255,107,107,0.18); color:var(--coral)">${d['display_time']}</span></td>
                </tr>
              ''').join('')}
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="table-card" style="margin-top:20px;">
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
        <h3 style="margin-bottom:0;">Últimos Eventos de Distracción en Vivo (${recentLogs.length} recientes)</h3>
        <span style="font-size:11px; color:var(--muted)">Hora Ecuador (UTC-5)</span>
      </div>
      <div style="max-height: 380px; overflow-y: auto;">
        <table>
          <thead>
            <tr>
              <th>ID</th>
              <th>Usuario</th>
              <th>Aplicación</th>
              <th>Tiempo Distraído</th>
              <th>Fecha y Hora</th>
            </tr>
          </thead>
          <tbody>
            ${recentLogs.isEmpty ? '<tr><td colspan="5" style="text-align:center; color:var(--muted)">No hay registros recientes</td></tr>' : recentLogs.map((l) => '''
              <tr>
                <td><span class="badge">#${l['id']}</span></td>
                <td><strong>${l['email']}</strong></td>
                <td><span class="badge" style="background:rgba(254,211,48,0.18); color:var(--sol)">${l['app']}</span></td>
                <td><span class="badge" style="background:rgba(255,107,107,0.18); color:var(--coral)">${l['display_time']}</span></td>
                <td style="color:var(--muted); font-size:12px;">${l['created_at']}</td>
              </tr>
            ''').join('')}
          </tbody>
        </table>
      </div>
    </div>

    <div class="footer">
      InfocusMind en Railway &bull; PostgreSQL &bull; Actualizado: ${DateTime.now().toLocal().toString().substring(0, 19)}
    </div>
  </div>
</body>
</html>''';

      return Response(200,
          body: html, headers: {'content-type': 'text/html; charset=utf-8'});
    } finally {
      await conn.close();
    }
  } catch (e) {
    print('Error al obtener metricas: $e');
    return Response(500,
        body: jsonEncode({'error': 'Error obteniendo metricas: $e'}),
        headers: {'content-type': 'application/json'});
  }
}
