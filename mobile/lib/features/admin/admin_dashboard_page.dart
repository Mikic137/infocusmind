import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../../core/tema.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final keyCtrl = TextEditingController();
  final searchCtrl = TextEditingController();

  bool autorizado = false;
  bool cargando = true;
  String? error;
  Map<String, dynamic>? metricas;
  String filtroUsuario = '';

  static const String claveAdmin = 'infocus2026';
  static const String emailAdmin = 'dylsamir2004@gmail.com';

  @override
  void initState() {
    super.initState();
    comprobarAcceso();
  }

  @override
  void dispose() {
    keyCtrl.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> comprobarAcceso() async {
    final correo = await AuthService.obtenerCorreoUsuario();
    if (correo != null && correo.toLowerCase().trim() == emailAdmin.toLowerCase()) {
      setState(() => autorizado = true);
      cargarMetricas(claveAdmin);
    } else {
      setState(() => cargando = false);
    }
  }

  Future<void> cargarMetricas(String clave) async {
    setState(() {
      cargando = true;
      error = null;
    });

    try {
      final r = await dio.get('/admin/metrics?format=json&key=$clave');
      if (r.statusCode == 200 && r.data is Map) {
        if (!mounted) return;
        setState(() {
          autorizado = true;
          metricas = Map<String, dynamic>.from(r.data);
          cargando = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          error = 'Respuesta inesperada del servidor';
          cargando = false;
        });
      }
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response?.statusCode == 401) {
        setState(() {
          error = 'Clave de administrador incorrecta';
          cargando = false;
          autorizado = false;
        });
      } else {
        setState(() {
          error = 'No se pudo conectar con el servidor: ${e.message}';
          cargando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Error: $e';
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colores.noche,
      appBar: AppBar(
        title: Text('PANEL DE CONTROL ADMIN', style: hud(10, color: Colores.sol)),
        centerTitle: true,
        actions: [
          if (autorizado)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colores.cian),
              tooltip: 'Actualizar métricas',
              onPressed: () => cargarMetricas(claveAdmin),
            ),
        ],
      ),
      body: SafeArea(
        child: !autorizado ? _buildLoginAdmin() : _buildContenidoMetricas(),
      ),
    );
  }

  Widget _buildLoginAdmin() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colores.nocheClara,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colores.borde, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colores.sombraCarta,
                  offset: Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colores.sol.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colores.sol, width: 2),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colores.sol, size: 40),
                ),
                const SizedBox(height: 16),
                Text('Acceso de Administrador', style: hud(11, color: Colores.luna)),
                const SizedBox(height: 8),
                const Text(
                  'Este panel está reservado para consultar las métricas del proyecto en vivo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colores.tenue, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: keyCtrl,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Clave de administrador...',
                    prefixIcon: const Icon(Icons.key_rounded, color: Colores.cian),
                    filled: true,
                    fillColor: Colores.noche,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colores.coral, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colores.violeta,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: cargando
                        ? null
                        : () => cargarMetricas(keyCtrl.text.trim()),
                    child: cargando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Entrar al Panel', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContenidoMetricas() {
    if (cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Colores.cian),
      );
    }

    if (metricas == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colores.coral, size: 48),
            const SizedBox(height: 12),
            Text('No se pudieron cargar las métricas', style: hud(10, color: Colores.luna)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => cargarMetricas(claveAdmin),
              child: const Text('Reintentar', style: TextStyle(color: Colores.cian)),
            ),
          ],
        ),
      );
    }

    final totalUsers = metricas!['total_users'] ?? 0;
    final usersToday = metricas!['users_today'] ?? 0;
    final totalTasks = metricas!['total_tasks'] ?? 0;
    final totalSessions = metricas!['total_focus_sessions'] ?? 0;
    final totalHours = metricas!['total_study_hours'] ?? '0.0';
    final totalMins = metricas!['total_study_minutes'] ?? 0;
    final List<dynamic> usersList = metricas!['recent_users'] ?? [];
    final List<dynamic> distractions = metricas!['top_distractions'] ?? [];

    final usuariosFiltrados = usersList.where((u) {
      final mail = (u['email'] ?? '').toString().toLowerCase();
      final id = (u['id'] ?? '').toString();
      return filtroUsuario.isEmpty || mail.contains(filtroUsuario) || id.contains(filtroUsuario);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de estado en vivo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colores.menta.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colores.menta.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colores.menta,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'TELEMETRÍA EN VIVO — POSTGRESQL EN RAILWAY',
                    style: TextStyle(
                      color: Colores.menta,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colores.tenue, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tarjetas de estadísticas de usuarios
          Text('TRÁFICO Y USUARIOS', style: hud(9, color: Colores.tenue)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTarjetaMetrica(
                  titulo: 'TOTAL USUARIOS',
                  valor: '$totalUsers',
                  subtitulo: 'Cuentas registradas',
                  colorAcento: Colores.violeta,
                  icono: Icons.people_alt_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTarjetaMetrica(
                  titulo: 'REGISTRADOS HOY',
                  valor: '$usersToday',
                  subtitulo: 'Nuevos estudiantes',
                  colorAcento: Colores.cian,
                  icono: Icons.person_add_alt_1_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildTarjetaMetrica(
                  titulo: 'MISIONES',
                  valor: '$totalTasks',
                  subtitulo: 'Tareas creadas',
                  colorAcento: Colores.sol,
                  icono: Icons.checklist_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTarjetaMetrica(
                  titulo: 'SESIONES FOCO',
                  valor: '$totalSessions',
                  subtitulo: '${totalHours}h ($totalMins min)',
                  colorAcento: Colores.menta,
                  icono: Icons.timer_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sección de usuarios registrados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('USUARIOS REGISTRADOS (${usersList.length})', style: hud(9, color: Colores.luna)),
              const Text('Hora Ecuador (UTC-5)', style: TextStyle(color: Colores.tenue, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),

          // Buscador de usuario
          TextField(
            controller: searchCtrl,
            onChanged: (v) => setState(() => filtroUsuario = v.trim().toLowerCase()),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Filtrar por correo o #ID...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colores.cian),
              suffixIcon: filtroUsuario.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        searchCtrl.clear();
                        setState(() => filtroUsuario = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colores.nocheClara,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 10),

          // Lista deslizable de usuarios
          Container(
            constraints: const BoxConstraints(maxHeight: 340),
            decoration: BoxDecoration(
              color: Colores.nocheClara,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colores.borde),
            ),
            child: usuariosFiltrados.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Sin usuarios encontrados', style: TextStyle(color: Colores.tenue)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: usuariosFiltrados.length,
                    separatorBuilder: (_, _) => const Divider(color: Colores.borde, height: 1),
                    itemBuilder: (context, i) {
                      final u = usuariosFiltrados[i];
                      final id = u['id'];
                      final email = u['email'] ?? '';
                      final date = u['created_at'] ?? '';
                      final tasks = u['tasks'] ?? 0;
                      final sessions = u['sessions'] ?? 0;

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colores.violeta.withValues(alpha: 0.25),
                          child: Text('#$id', style: const TextStyle(color: Colores.cian, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                          email,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text(
                          date,
                          style: const TextStyle(color: Colores.tenue, fontSize: 11),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colores.cian.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('$tasks mis.', style: const TextStyle(color: Colores.cian, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colores.menta.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('$sessions ses.', style: const TextStyle(color: Colores.menta, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),

          // Top Distracciones
          Text('TOP DISTRACCIONES DETECTADAS', style: hud(9, color: Colores.coral)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colores.nocheClara,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colores.borde),
            ),
            child: distractions.isEmpty
                ? const Text('Aún no se han registrado distracciones.', style: TextStyle(color: Colores.tenue, fontSize: 12))
                : Column(
                    children: [
                      for (final d in distractions)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.block_rounded, color: Colores.coral, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  d['app']?.toString() ?? '',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              Text(
                                '${d['count']} veces (${d['minutes']} min)',
                                style: const TextStyle(color: Colores.tenue, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTarjetaMetrica({
    required String titulo,
    required String valor,
    required String subtitulo,
    required Color colorAcento,
    required IconData icono,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colores.nocheClara,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colores.borde),
        boxShadow: const [
          BoxShadow(
            color: Colores.sombraCarta,
            offset: Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titulo, style: const TextStyle(color: Colores.tenue, fontSize: 10, fontWeight: FontWeight.bold)),
              Icon(icono, color: colorAcento, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Text(valor, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(subtitulo, style: TextStyle(color: colorAcento, fontSize: 11)),
        ],
      ),
    );
  }
}
