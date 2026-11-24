import 'dart:convert';
import 'dart:io';
import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

Future<Response> handleSeedStudents(
    Request request, Future<Connection> Function() abrirConexion) async {
  final env = Platform.environment;
  final queryKey = request.url.queryParameters['key'];
  final headerKey = request.headers['x-admin-key'];
  final expectedKey = env['ADMIN_KEY'] ?? 'infocus2026';

  if (queryKey != expectedKey && headerKey != expectedKey) {
    return Response(401,
        body: jsonEncode({'error': 'No autorizado. Se requiere admin key válida'}),
        headers: {'content-type': 'application/json'});
  }

  // Lista de 18 estudiantes reales con cuentas @gmail.com
  // Fechas programadas: desde el martes 10 de nov en la tarde hasta el miércoles 11 de nov antes de las 10 PM (Ecuador UTC-5)
  // Nota: En base de datos TIMESTAMPTZ UTC = Ecuador + 5 horas
  final estudiantes = [
    // --- Martes 10 de Noviembre (Tarde y Noche) ---
    {
      'email': 'mateo.andrade05@gmail.com',
      'nombre': 'Mateo Andrade',
      'carrera': 'Ingeniería en Software',
      'ecuador_time': '2026-11-10 15:18:22',
      'utc_time': DateTime.utc(2026, 11, 10, 20, 18, 22),
      'task': 'Informe de Laboratorio de Redes',
      'task_done': true,
      'session_min': 30,
      'distractions': ['TikTok', 'Instagram'],
    },
    {
      'email': 'camila.paredes2004@gmail.com',
      'nombre': 'Camila Paredes',
      'carrera': 'Medicina',
      'ecuador_time': '2026-11-10 16:35:10',
      'utc_time': DateTime.utc(2026, 11, 10, 21, 35, 10),
      'task': 'Repaso Anatomía Humana: Sistema Óseo',
      'task_done': true,
      'session_min': 45,
      'distractions': ['TikTok', 'WhatsApp', 'Instagram'],
    },
    {
      'email': 'sebastian.mora.ec@gmail.com',
      'nombre': 'Sebastián Mora',
      'carrera': 'Administración de Empresas',
      'ecuador_time': '2026-11-10 17:12:45',
      'utc_time': DateTime.utc(2026, 11, 10, 22, 12, 45),
      'task': 'Caso de Estudio Microeconomía',
      'task_done': false,
      'session_min': 25,
      'distractions': ['TikTok', 'YouTube'],
    },
    {
      'email': 'valeria.castillo99@gmail.com',
      'nombre': 'Valeria Castillo',
      'carrera': 'Diseño Gráfico',
      'ecuador_time': '2026-11-10 18:44:03',
      'utc_time': DateTime.utc(2026, 11, 10, 23, 44, 3),
      'task': 'Bocetos y Prototipo UI en Figma',
      'task_done': true,
      'session_min': 40,
      'distractions': ['Instagram', 'TikTok', 'Pinterest'],
    },
    {
      'email': 'diego.morales2204@gmail.com',
      'nombre': 'Diego Morales',
      'carrera': 'Ingeniería Civil',
      'ecuador_time': '2026-11-10 19:28:15',
      'utc_time': DateTime.utc(2026, 11, 11, 0, 28, 15),
      'task': 'Ejercicios de Resistencia de Materiales',
      'task_done': false,
      'session_min': 25,
      'distractions': ['TikTok', 'Facebook'],
    },
    {
      'email': 'domenicamendoza2005@gmail.com',
      'nombre': 'Doménica Mendoza',
      'carrera': 'Psicología',
      'ecuador_time': '2026-11-10 20:50:30',
      'utc_time': DateTime.utc(2026, 11, 11, 1, 50, 30),
      'task': 'Lectura Neurobiología del Aprendizaje',
      'task_done': true,
      'session_min': 35,
      'distractions': ['TikTok', 'Instagram', 'WhatsApp'],
    },
    {
      'email': 'kevin.cueva77@gmail.com',
      'nombre': 'Kevin Cueva',
      'carrera': 'Ingeniería en Sistemas',
      'ecuador_time': '2026-11-10 21:35:18',
      'utc_time': DateTime.utc(2026, 11, 11, 2, 35, 18),
      'task': 'Práctica de Consultas SQL y Normalización',
      'task_done': true,
      'session_min': 30,
      'distractions': ['TikTok', 'Discord', 'YouTube'],
    },

    // --- Miércoles 11 de Noviembre (Mañana, Tarde y Noche antes de las 10 PM) ---
    {
      'email': 'paula.guerrero.u@gmail.com',
      'nombre': 'Paula Guerrero',
      'carrera': 'Derecho',
      'ecuador_time': '2026-11-11 09:20:14',
      'utc_time': DateTime.utc(2026, 11, 11, 14, 20, 14),
      'task': 'Análisis Sentencia Constitucional',
      'task_done': false,
      'session_min': 25,
      'distractions': ['TikTok', 'Instagram'],
    },
    {
      'email': 'bryan.vargas2004@gmail.com',
      'nombre': 'Bryan Vargas',
      'carrera': 'Ingeniería Mecánica',
      'ecuador_time': '2026-11-11 10:45:32',
      'utc_time': DateTime.utc(2026, 11, 11, 15, 45, 32),
      'task': 'Modelado 3D en SolidWorks',
      'task_done': true,
      'session_min': 40,
      'distractions': ['TikTok', 'YouTube Shorts'],
    },
    {
      'email': 'melany.reyes04@gmail.com',
      'nombre': 'Melany Reyes',
      'carrera': 'Enfermería',
      'ecuador_time': '2026-11-11 11:30:19',
      'utc_time': DateTime.utc(2026, 11, 11, 16, 30, 19),
      'task': 'Fichas Farmacológicas de Antibióticos',
      'task_done': false,
      'session_min': 20,
      'distractions': ['TikTok', 'WhatsApp', 'Instagram'],
    },
    {
      'email': 'alejandro.salazar987@gmail.com',
      'nombre': 'Alejandro Salazar',
      'carrera': 'Economía',
      'ecuador_time': '2026-11-11 12:40:55',
      'utc_time': DateTime.utc(2026, 11, 11, 17, 40, 55),
      'task': 'Resolución Taller de Estadística Inferencial',
      'task_done': true,
      'session_min': 30,
      'distractions': ['TikTok', 'Twitter'],
    },
    {
      'email': 'daniela.guzman2005@gmail.com',
      'nombre': 'Daniela Guzmán',
      'carrera': 'Comunicación Social',
      'ecuador_time': '2026-11-11 13:55:40',
      'utc_time': DateTime.utc(2026, 11, 11, 18, 55, 40),
      'task': 'Guion Podcast Universitario',
      'task_done': false,
      'session_min': 25,
      'distractions': ['TikTok', 'Instagram', 'Spotify'],
    },
    {
      'email': 'esteban.rivera.ec@gmail.com',
      'nombre': 'Esteban Rivera',
      'carrera': 'Ingeniería en Telecomunicaciones',
      'ecuador_time': '2026-11-11 15:22:18',
      'utc_time': DateTime.utc(2026, 11, 11, 20, 22, 18),
      'task': 'Simulación de Enlace de Fibra Óptica',
      'task_done': true,
      'session_min': 35,
      'distractions': ['TikTok', 'Instagram'],
    },
    {
      'email': 'carolina.velez2004@gmail.com',
      'nombre': 'Carolina Vélez',
      'carrera': 'Arquitectura',
      'ecuador_time': '2026-11-11 16:40:05',
      'utc_time': DateTime.utc(2026, 11, 11, 21, 40, 5),
      'task': 'Planos de Distribución y Cortes',
      'task_done': false,
      'session_min': 40,
      'distractions': ['TikTok', 'Pinterest', 'Instagram'],
    },
    {
      'email': 'nicolas.ortiz.dev@gmail.com',
      'nombre': 'Nicolás Ortiz',
      'carrera': 'Desarrollo de Software',
      'ecuador_time': '2026-11-11 17:35:48',
      'utc_time': DateTime.utc(2026, 11, 11, 22, 35, 48),
      'task': 'Backend API REST con Dart & Shelf',
      'task_done': true,
      'session_min': 45,
      'distractions': ['TikTok', 'YouTube', 'Discord'],
    },
    {
      'email': 'josselyn.alvarez05@gmail.com',
      'nombre': 'Josselyn Álvarez',
      'carrera': 'Bioquímica y Farmacia',
      'ecuador_time': '2026-11-11 18:20:12',
      'utc_time': DateTime.utc(2026, 11, 11, 23, 20, 12),
      'task': 'Informe Práctica de Titulación Ácido-Base',
      'task_done': true,
      'session_min': 25,
      'distractions': ['TikTok', 'WhatsApp', 'Instagram'],
    },
    {
      'email': 'gabriel.montes2004@gmail.com',
      'nombre': 'Gabriel Montes',
      'carrera': 'Ingeniería Industrial',
      'ecuador_time': '2026-11-11 19:15:30',
      'utc_time': DateTime.utc(2026, 11, 12, 0, 15, 30),
      'task': 'Diagrama de Flujo de Operaciones',
      'task_done': false,
      'session_min': 20,
      'distractions': ['TikTok', 'Instagram'],
    },
    {
      'email': 'stephanie.cabrera9@gmail.com',
      'nombre': 'Stephanie Cabrera',
      'carrera': 'Marketing Digital',
      'ecuador_time': '2026-11-11 20:08:44',
      'utc_time': DateTime.utc(2026, 11, 12, 1, 8, 44),
      'task': 'Plan de Campaña y Métricas de Conversión',
      'task_done': true,
      'session_min': 30,
      'distractions': ['TikTok', 'Instagram', 'Canva'],
    },

    // =========================================================================
    // --- SEMANA ANTERIOR: Lunes 16 de Noviembre a Domingo 22 de Noviembre ---
    // (Registros distribuidos de forma natural; CERO registros ayer ni hoy)
    // =========================================================================

    // --- Lunes 16 de Noviembre ---
    {
      'email': 'andrea.maldonado05@gmail.com',
      'nombre': 'Andrea Maldonado',
      'carrera': 'Medicina Humana',
      'ecuador_time': '2026-11-16 08:42:15',
      'utc_time': DateTime.utc(2026, 11, 16, 13, 42, 15),
      'task': 'Caso Clínico: Farmacología Cardíaca',
      'task_done': true,
      'session_min': 40,
      'distractions': ['Instagram', 'TikTok'],
    },
    {
      'email': 'david.paredes.dev@gmail.com',
      'nombre': 'David Paredes',
      'carrera': 'Ingeniería en Software',
      'ecuador_time': '2026-11-16 11:15:30',
      'utc_time': DateTime.utc(2026, 11, 16, 16, 15, 30),
      'task': 'Implementación de Patrones de Diseño',
      'task_done': true,
      'session_min': 45,
      'distractions': ['YouTube', 'Discord'],
    },
    {
      'email': 'valeria.guerrero99@gmail.com',
      'nombre': 'Valeria Guerrero',
      'carrera': 'Derecho Procesal',
      'ecuador_time': '2026-11-16 14:28:44',
      'utc_time': DateTime.utc(2026, 11, 16, 19, 28, 44),
      'task': 'Alegato Final y Jurisprudencia Penal',
      'task_done': false,
      'session_min': 30,
      'distractions': ['TikTok', 'WhatsApp'],
    },
    {
      'email': 'bryan.espinoza.ec@gmail.com',
      'nombre': 'Bryan Espinoza',
      'carrera': 'Ingeniería Mecatrónica',
      'ecuador_time': '2026-11-16 17:50:12',
      'utc_time': DateTime.utc(2026, 11, 16, 22, 50, 12),
      'task': 'Programación PLC y Control PID',
      'task_done': true,
      'session_min': 35,
      'distractions': ['Brawl Stars', 'YouTube'],
    },
    {
      'email': 'domenica.castro2005@gmail.com',
      'nombre': 'Doménica Castro',
      'carrera': 'Psicología Clínica',
      'ecuador_time': '2026-11-16 21:14:03',
      'utc_time': DateTime.utc(2026, 11, 17, 2, 14, 3),
      'task': 'Informe de Evaluación Psicométrica',
      'task_done': true,
      'session_min': 25,
      'distractions': ['TikTok', 'Instagram'],
    },

    // --- Martes 17 de Noviembre ---
    {
      'email': 'kevin.zambrano.dev@gmail.com',
      'nombre': 'Kevin Zambrano',
      'carrera': 'Tecnologías de la Información',
      'ecuador_time': '2026-11-17 09:18:25',
      'utc_time': DateTime.utc(2026, 11, 17, 14, 18, 25),
      'task': 'Configuración de VLANs y Enrutamiento',
      'task_done': true,
      'session_min': 30,
      'distractions': ['Discord', 'YouTube'],
    },
    {
      'email': 'camila.lozano2004@gmail.com',
      'nombre': 'Camila Lozano',
      'carrera': 'Enfermería',
      'ecuador_time': '2026-11-17 11:45:10',
      'utc_time': DateTime.utc(2026, 11, 17, 16, 45, 10),
      'task': 'Plan de Cuidados en Paciente Crítico',
      'task_done': false,
      'session_min': 25,
      'distractions': ['TikTok', 'Instagram', 'WhatsApp'],
    },
    {
      'email': 'mateo.herrera.ec@gmail.com',
      'nombre': 'Mateo Herrera',
      'carrera': 'Administración de Empresas',
      'ecuador_time': '2026-11-17 13:30:42',
      'utc_time': DateTime.utc(2026, 11, 17, 18, 30, 42),
      'task': 'Evaluación Financiera VAN y TIR',
      'task_done': true,
      'session_min': 40,
      'distractions': ['Clash Royale', 'TikTok'],
    },
    {
      'email': 'nathaly.ponce05@gmail.com',
      'nombre': 'Nathaly Ponce',
      'carrera': 'Arquitectura y Urbanismo',
      'ecuador_time': '2026-11-17 16:12:18',
      'utc_time': DateTime.utc(2026, 11, 17, 21, 12, 18),
      'task': 'Renderizado de Fachada y Paisajismo',
      'task_done': true,
      'session_min': 50,
      'distractions': ['Pinterest', 'TikTok'],
    },
    {
      'email': 'gabriel.torres99@gmail.com',
      'nombre': 'Gabriel Torres',
      'carrera': 'Ingeniería Civil',
      'ecuador_time': '2026-11-17 18:40:55',
      'utc_time': DateTime.utc(2026, 11, 17, 23, 40, 55),
      'task': 'Diseño Estructural de Vigas en Hormigón',
      'task_done': false,
      'session_min': 35,
      'distractions': ['Brawl Stars', 'Facebook'],
    },
    {
      'email': 'josselyn.reyes2005@gmail.com',
      'nombre': 'Josselyn Reyes',
      'carrera': 'Bioquímica y Farmacia',
      'ecuador_time': '2026-11-17 21:25:30',
      'utc_time': DateTime.utc(2026, 11, 18, 2, 25, 30),
      'task': 'Determinación Espectrofotométrica',
      'task_done': true,
      'session_min': 30,
      'distractions': ['TikTok', 'Instagram'],
    },

    // --- Miércoles 18 de Noviembre ---
    {
      'email': 'sebastian.alarcon.ec@gmail.com',
      'nombre': 'Sebastián Alarcón',
      'carrera': 'Economía Aplicada',
      'ecuador_time': '2026-11-18 08:35:14',
      'utc_time': DateTime.utc(2026, 11, 18, 13, 35, 14),
      'task': 'Modelo Econométrico con R Studio',
      'task_done': true,
      'session_min': 45,
      'distractions': ['Twitter', 'YouTube'],
    },
    {
      'email': 'melanie.cardenas04@gmail.com',
      'nombre': 'Melanie Cárdenas',
      'carrera': 'Odontología',
      'ecuador_time': '2026-11-18 10:50:22',
      'utc_time': DateTime.utc(2026, 11, 18, 15, 50, 22),
      'task': 'Protocolos de Endodoncia Unirradicular',
      'task_done': false,
      'session_min': 20,
      'distractions': ['Instagram', 'TikTok'],
    },
    {
      'email': 'leonardo.mena.ec@gmail.com',
      'nombre': 'Leonardo Mena',
      'carrera': 'Ingeniería en Sistemas',
      'ecuador_time': '2026-11-18 13:15:48',
      'utc_time': DateTime.utc(2026, 11, 18, 18, 15, 48),
      'task': 'Consultas Avanzadas PostgreSQL y Triggers',
      'task_done': true,
      'session_min': 40,
      'distractions': ['Free Fire', 'Discord'],
    },
    {
      'email': 'samantha.vega2005@gmail.com',
      'nombre': 'Samantha Vega',
      'carrera': 'Diseño Gráfico Publicitario',
      'ecuador_time': '2026-11-18 15:42:05',
      'utc_time': DateTime.utc(2026, 11, 18, 20, 42, 5),
      'task': 'Manual de Identidad de Marca Corporativa',
      'task_done': true,
      'session_min': 35,
      'distractions': ['Pinterest', 'Instagram'],
    },
    {
      'email': 'paulina.benitez.u@gmail.com',
      'nombre': 'Paulina Benítez',
      'carrera': 'Comunicación y Medios',
      'ecuador_time': '2026-11-18 18:20:33',
      'utc_time': DateTime.utc(2026, 11, 18, 23, 20, 33),
      'task': 'Reportaje Multimedia sobre Educación Rural',
      'task_done': false,
      'session_min': 25,
      'distractions': ['TikTok', 'TikTok', 'WhatsApp'],
    },
    {
      'email': 'christian.salgado99@gmail.com',
      'nombre': 'Christian Salgado',
      'carrera': 'Marketing Digital',
      'ecuador_time': '2026-11-18 20:55:10',
      'utc_time': DateTime.utc(2026, 11, 19, 1, 55, 10),
      'task': 'Estrategia SEO y Creación de Contenido',
      'task_done': true,
      'session_min': 30,
      'distractions': ['TikTok', 'Roblox'],
    },

    // --- Jueves 19 de Noviembre ---
    {
      'email': 'daniela.osorio2004@gmail.com',
      'nombre': 'Daniela Osorio',
      'carrera': 'Medicina Veterinaria y Zootecnia',
      'ecuador_time': '2026-11-19 09:10:45',
      'utc_time': DateTime.utc(2026, 11, 19, 14, 10, 45),
      'task': 'Diagnóstico Clínico en Pequeñas Especies',
      'task_done': true,
      'session_min': 35,
      'distractions': ['Instagram', 'TikTok'],
    },
    {
      'email': 'erick.villacis.ec@gmail.com',
      'nombre': 'Erick Villacís',
      'carrera': 'Ingeniería Industrial',
      'ecuador_time': '2026-11-19 11:24:18',
      'utc_time': DateTime.utc(2026, 11, 19, 16, 24, 18),
      'task': 'Optimización de Procesos de Manufactura',
      'task_done': true,
      'session_min': 40,
      'distractions': ['Call of Duty Mobile', 'YouTube'],
    },
    {
      'email': 'genesis.barahona05@gmail.com',
      'nombre': 'Génesis Barahona',
      'carrera': 'Fisioterapia y Rehabilitación',
      'ecuador_time': '2026-11-19 14:05:30',
      'utc_time': DateTime.utc(2026, 11, 19, 19, 5, 30),
      'task': 'Guía Terapéutica para Lesión Meniscal',
      'task_done': false,
      'session_min': 20,
      'distractions': ['TikTok', 'Instagram'],
    },
    {
      'email': 'juancarlos.poma@gmail.com',
      'nombre': 'Juan Carlos Poma',
      'carrera': 'Ingeniería en Telecomunicaciones',
      'ecuador_time': '2026-11-19 16:38:12',
      'utc_time': DateTime.utc(2026, 11, 19, 21, 38, 12),
      'task': 'Cálculo de Propagación de Ondas Electromagnéticas',
      'task_done': true,
      'session_min': 45,
      'distractions': ['Brawl Stars', 'Discord'],
    },
    {
      'email': 'jennifer.rosero2005@gmail.com',
      'nombre': 'Jennifer Rosero',
      'carrera': 'Nutrición y Dietética',
      'ecuador_time': '2026-11-19 19:14:50',
      'utc_time': DateTime.utc(2026, 11, 20, 0, 14, 50),
      'task': 'Cálculo Calórico y Plan Alimenticio Personalizado',
      'task_done': true,
      'session_min': 30,
      'distractions': ['TikTok', 'Instagram'],
    },
    {
      'email': 'adrian.villacres99@gmail.com',
      'nombre': 'Adrián Villacrés',
      'carrera': 'Gestión del Turismo',
      'ecuador_time': '2026-11-19 21:40:22',
      'utc_time': DateTime.utc(2026, 11, 20, 2, 40, 22),
      'task': 'Rutas Ecoturísticas en la Zona Norte',
      'task_done': false,
      'session_min': 25,
      'distractions': ['TikTok', 'Facebook'],
    },

    // --- Viernes 20 de Noviembre ---
    {
      'email': 'romina.calderon04@gmail.com',
      'nombre': 'Romina Calderón',
      'carrera': 'Finanzas y Auditoría',
      'ecuador_time': '2026-11-20 08:52:10',
      'utc_time': DateTime.utc(2026, 11, 20, 13, 52, 10),
      'task': 'Auditoría Tributaria de Estados Financieros',
      'task_done': true,
      'session_min': 40,
      'distractions': ['Instagram', 'TikTok'],
    },
    {
      'email': 'isaac.montalvo.ec@gmail.com',
      'nombre': 'Isaac Montalvo',
      'carrera': 'Ingeniería Automotriz',
      'ecuador_time': '2026-11-20 11:34:40',
      'utc_time': DateTime.utc(2026, 11, 20, 16, 34, 40),
      'task': 'Diagnóstico Electrónico OBD-II y Sensores',
      'task_done': true,
      'session_min': 35,
      'distractions': ['Free Fire', 'YouTube'],
    },
    {
      'email': 'evelyn.tapia2005@gmail.com',
      'nombre': 'Evelyn Tapia',
      'carrera': 'Pedagogía de los Idiomas',
      'ecuador_time': '2026-11-20 14:18:15',
      'utc_time': DateTime.utc(2026, 11, 20, 19, 18, 15),
      'task': 'Plan de Lección: Estrategias de Fonética en Inglés',
      'task_done': false,
      'session_min': 25,
      'distractions': ['TikTok', 'Instagram'],
    },
    {
      'email': 'andres.villavicencio.ec@gmail.com',
      'nombre': 'Andrés Villavicencio',
      'carrera': 'Ingeniería Ambiental',
      'ecuador_time': '2026-11-20 16:45:30',
      'utc_time': DateTime.utc(2026, 11, 20, 21, 45, 30),
      'task': 'Estudio de Impacto Ambiental en Cuencas Hídricas',
      'task_done': true,
      'session_min': 45,
      'distractions': ['Clash Royale', 'TikTok'],
    },
    {
      'email': 'diana.sotomayor99@gmail.com',
      'nombre': 'Diana Sotomayor',
      'carrera': 'Trabajo Social',
      'ecuador_time': '2026-11-20 18:50:22',
      'utc_time': DateTime.utc(2026, 11, 20, 23, 50, 22),
      'task': 'Fichas Socioeconómicas de Familias Vulnerables',
      'task_done': true,
      'session_min': 30,
      'distractions': ['TikTok', 'WhatsApp'],
    },
    {
      'email': 'jorge.carrion.dev@gmail.com',
      'nombre': 'Jorge Carrión',
      'carrera': 'Desarrollo de Software y Ciberseguridad',
      'ecuador_time': '2026-11-20 22:05:14',
      'utc_time': DateTime.utc(2026, 11, 21, 3, 5, 14),
      'task': 'Pruebas de Penetración y Cifrado Asimétrico',
      'task_done': true,
      'session_min': 50,
      'distractions': ['Discord', 'YouTube'],
    },

    // --- Sábado 21 de Noviembre ---
    {
      'email': 'karla.quezada2004@gmail.com',
      'nombre': 'Karla Quezada',
      'carrera': 'Contabilidad y Finanzas',
      'ecuador_time': '2026-11-21 10:15:33',
      'utc_time': DateTime.utc(2026, 11, 21, 15, 15, 33),
      'task': 'Conciliación Bancaria y Flujo de Caja',
      'task_done': true,
      'session_min': 35,
      'distractions': ['TikTok', 'Instagram'],
    },
    {
      'email': 'anthony.salazar.ec@gmail.com',
      'nombre': 'Anthony Salazar',
      'carrera': 'Ingeniería Electrónica',
      'ecuador_time': '2026-11-21 13:22:50',
      'utc_time': DateTime.utc(2026, 11, 21, 18, 22, 50),
      'task': 'Circuito de Filtro Activo de Segundo Orden',
      'task_done': true,
      'session_min': 40,
      'distractions': ['Brawl Stars', 'TikTok'],
    },
    {
      'email': 'nicole.viteri05@gmail.com',
      'nombre': 'Nicole Viteri',
      'carrera': 'Diseño de Modas y Textil',
      'ecuador_time': '2026-11-21 16:08:14',
      'utc_time': DateTime.utc(2026, 11, 21, 21, 8, 14),
      'task': 'Patronaje Digital y Selección de Textiles',
      'task_done': false,
      'session_min': 30,
      'distractions': ['Pinterest', 'Instagram', 'TikTok'],
    },
    {
      'email': 'felipe.grijalva99@gmail.com',
      'nombre': 'Felipe Grijalva',
      'carrera': 'Gestión y Políticas Públicas',
      'ecuador_time': '2026-11-21 18:35:40',
      'utc_time': DateTime.utc(2026, 11, 21, 23, 35, 40),
      'task': 'Evaluación del Plan de Desarrollo Cantonal',
      'task_done': true,
      'session_min': 35,
      'distractions': ['TikTok', 'Twitter'],
    },
    {
      'email': 'angie.cobena2005@gmail.com',
      'nombre': 'Angie Cobeña',
      'carrera': 'Marketing Estratégico',
      'ecuador_time': '2026-11-21 21:12:05',
      'utc_time': DateTime.utc(2026, 11, 22, 2, 12, 5),
      'task': 'Benchmarking de Competidores en Redes',
      'task_done': true,
      'session_min': 25,
      'distractions': ['TikTok', 'Instagram'],
    },

    // --- Domingo 22 de Noviembre ---
    {
      'email': 'christopher.loor.ec@gmail.com',
      'nombre': 'Christopher Loor',
      'carrera': 'Biotecnología',
      'ecuador_time': '2026-11-22 09:40:18',
      'utc_time': DateTime.utc(2026, 11, 22, 14, 40, 18),
      'task': 'Extracción de ADN y Electroforesis en Gel',
      'task_done': true,
      'session_min': 45,
      'distractions': ['DB LEGENDS', 'YouTube'],
    },
    {
      'email': 'abigail.solorzano04@gmail.com',
      'nombre': 'Abigail Solórzano',
      'carrera': 'Comercio Exterior y Aduanas',
      'ecuador_time': '2026-11-22 11:15:22',
      'utc_time': DateTime.utc(2026, 11, 22, 16, 15, 22),
      'task': 'Clasificación Arancelaria y Logística de Importación',
      'task_done': false,
      'session_min': 25,
      'distractions': ['TikTok', 'Instagram'],
    },
    {
      'email': 'jonathan.macias.ec@gmail.com',
      'nombre': 'Jonathan Macías',
      'carrera': 'Ingeniería Agronómica',
      'ecuador_time': '2026-11-22 13:30:45',
      'utc_time': DateTime.utc(2026, 11, 22, 18, 30, 45),
      'task': 'Diseño de Riego por Goteo y Manejo de Suelos',
      'task_done': true,
      'session_min': 40,
      'distractions': ['TikTok', 'WhatsApp', 'Facebook'],
    },
    {
      'email': 'shirley.guaman2005@gmail.com',
      'nombre': 'Shirley Guamán',
      'carrera': 'Gestión del Talento Humano',
      'ecuador_time': '2026-11-22 15:10:30',
      'utc_time': DateTime.utc(2026, 11, 22, 20, 10, 30),
      'task': 'Diseño del Plan de Clima Laboral y Desempeño',
      'task_done': true,
      'session_min': 30,
      'distractions': ['TikTok', 'Instagram'],
    },
    {
      'email': 'marlon.chango.ec@gmail.com',
      'nombre': 'Marlon Chango',
      'carrera': 'Inteligencia de Negocios y Big Data',
      'ecuador_time': '2026-11-22 17:45:15',
      'utc_time': DateTime.utc(2026, 11, 22, 22, 45, 15),
      'task': 'Dashboard en PowerBI con Métricas de Rendimiento',
      'task_done': true,
      'session_min': 45,
      'distractions': ['Roblox', 'Discord'],
    },
  ];

  try {
    final conn = await abrirConexion();
    try {
      var agregados = 0;
      var omitidos = 0;

      for (final est in estudiantes) {
        final email = est['email'] as String;
        final nombre = est['nombre'] as String;
        final carrera = est['carrera'] as String;
        final utcCreatedAt = est['utc_time'] as DateTime;
        final taskTitle = est['task'] as String;
        final taskDone = est['task_done'] as bool;
        final sessionMin = est['session_min'] as int;
        final distractions = est['distractions'] as List<String>;

        // 1. Verificar si ya existe este correo para NUNCA tocarlo ni duplicarlo
        final rCheck = await conn.execute(
          Sql.named('SELECT id FROM users WHERE email = @e'),
          parameters: {'e': email},
        );
        if (rCheck.isNotEmpty) {
          omitidos++;
          continue;
        }

        // 2. Insertar usuario con su fecha exacta correspondiente
        final dummyHash = BCrypt.hashpw(
          'StudentPass_${email.split('@').first}_2026',
          BCrypt.gensalt(),
        );

        final rUser = await conn.execute(
          Sql.named('''
            INSERT INTO users (email, password_hash, created_at)
            VALUES (@email, @hash, @created_at)
            RETURNING id
          '''),
          parameters: {
            'email': email,
            'hash': dummyHash,
            'created_at': utcCreatedAt,
          },
        );
        final userId = rUser.first[0] as int;

        // 3. Crear perfil del estudiante con distracciones registradas
        final profileData = jsonEncode({
          'nombre': nombre,
          'estudios': carrera,
          'gustos': ['Música', 'Estudio', 'Series'],
          'mejor_horario': 'Tarde y Noche',
          'distracciones': distractions,
          'minutos_concentracion': 25,
        });

        await conn.execute(
          Sql.named('''
            INSERT INTO profiles (user_id, data, updated_at)
            VALUES (@u, @data, @updated_at)
            ON CONFLICT (user_id) DO NOTHING
          '''),
          parameters: {
            'u': userId,
            'data': profileData,
            'updated_at': utcCreatedAt.add(const Duration(minutes: 5)),
          },
        );

        // 4. Crear tarea académica
        final rTask = await conn.execute(
          Sql.named('''
            INSERT INTO tasks (user_id, title, details, status, created_at)
            VALUES (@u, @title, @details, @status, @created_at)
            RETURNING id
          '''),
          parameters: {
            'u': userId,
            'title': taskTitle,
            'details': 'Misión asignada en sesión de concentración',
            'status': taskDone ? 'completed' : 'pending',
            'created_at': utcCreatedAt.add(const Duration(minutes: 7)),
          },
        );
        final taskId = rTask.first[0] as int;

        // 5. Crear pasos de la tarea
        final rStep1 = await conn.execute(
          Sql.named('''
            INSERT INTO task_steps (task_id, position, title, est_minutes, done)
            VALUES (@t, 0, 'Revisar material y bibliografía', @m, @done)
            RETURNING id
          '''),
          parameters: {
            't': taskId,
            'm': 15,
            'done': taskDone,
          },
        );
        final stepId = rStep1.first[0] as int;

        await conn.execute(
          Sql.named('''
            INSERT INTO task_steps (task_id, position, title, est_minutes, done)
            VALUES (@t, 1, 'Desarrollar contenido principal', @m, @done)
          '''),
          parameters: {
            't': taskId,
            'm': sessionMin,
            'done': taskDone,
          },
        );

        // 6. Registrar sesión de enfoque (Pomodoro) completada
        final sessionStarted = utcCreatedAt.add(const Duration(minutes: 10));
        final sessionSeconds = sessionMin * 60;
        final rSession = await conn.execute(
          Sql.named('''
            INSERT INTO focus_sessions (
              user_id, step_id, step_title, est_minutes, 
              started_at, ended_at, actual_seconds, status, counts_for_learning
            )
            VALUES (
              @u, @step_id, @step_title, @est_m, 
              @started, @ended, @actual_s, 'completed', true
            )
            RETURNING id
          '''),
          parameters: {
            'u': userId,
            'step_id': stepId,
            'step_title': 'Desarrollar contenido principal',
            'est_m': sessionMin,
            'started': sessionStarted,
            'ended': sessionStarted.add(Duration(seconds: sessionSeconds)),
            'actual_s': sessionSeconds,
          },
        );
        final sessionId = rSession.first[0] as int;

        // 7. Registrar logs de distracciones en distraction_logs (TikTok, Instagram, juegos, etc.)
        for (final dist in distractions) {
          String pkg = 'com.facebook.katana';
          int seg = 210 + ((agregados * 11) % 130);
          final dLower = dist.toLowerCase();

          if (dLower.contains('tiktok')) {
            pkg = 'com.zhiliaoapp.musically';
            seg = 320 + ((agregados * 17) % 220);
          } else if (dLower.contains('instagram')) {
            pkg = 'com.instagram.android';
            seg = 280 + ((agregados * 13) % 190);
          } else if (dLower.contains('whatsapp')) {
            pkg = 'com.whatsapp';
            seg = 180 + ((agregados * 11) % 140);
          } else if (dLower.contains('youtube')) {
            pkg = 'com.google.android.youtube';
            seg = 350 + ((agregados * 19) % 210);
          } else if (dLower.contains('brawl')) {
            pkg = 'com.supercell.brawlstars';
            seg = 260 + ((agregados * 15) % 180);
          } else if (dLower.contains('clash')) {
            pkg = 'com.supercell.clashroyale';
            seg = 240 + ((agregados * 14) % 160);
          } else if (dLower.contains('free fire')) {
            pkg = 'com.dts.freefireth';
            seg = 310 + ((agregados * 18) % 190);
          } else if (dLower.contains('roblox')) {
            pkg = 'com.roblox.client';
            seg = 270 + ((agregados * 12) % 170);
          } else if (dLower.contains('call of duty')) {
            pkg = 'com.activision.callofduty.shooter';
            seg = 320 + ((agregados * 16) % 180);
          } else if (dLower.contains('legends')) {
            pkg = 'com.bandainamcoent.dblegends_app';
            seg = 250 + ((agregados * 15) % 160);
          } else if (dLower.contains('discord')) {
            pkg = 'com.discord';
            seg = 220 + ((agregados * 10) % 140);
          } else if (dLower.contains('pinterest')) {
            pkg = 'com.pinterest';
            seg = 200 + ((agregados * 9) % 130);
          } else if (dLower.contains('twitter')) {
            pkg = 'com.twitter.android';
            seg = 210 + ((agregados * 12) % 140);
          }

          await conn.execute(
            Sql.named('''
              INSERT INTO distraction_logs (user_id, session_id, package_name, app_name, seconds, created_at)
              VALUES (@u, @s, @pkg, @app, @seg, @created_at)
            '''),
            parameters: {
              'u': userId,
              's': sessionId,
              'pkg': pkg,
              'app': dist,
              'seg': seg,
              'created_at': sessionStarted.add(const Duration(minutes: 12)),
            },
          );
        }

        agregados++;
      }

      // Obtener el nuevo conteo total
      final rTotal = await conn.execute('SELECT COUNT(*) FROM users');
      final totalActualizado = rTotal.first[0] as int;

      return Response(200,
          body: jsonEncode({
            'success': true,
            'nuevos_usuarios_insertados': agregados,
            'usuarios_omitidos_existentes': omitidos,
            'total_usuarios_actual': totalActualizado,
            'mensaje': 'Estudiantes registrados exitosamente con distracciones y sesiones.',
          }),
          headers: {'content-type': 'application/json'});
    } finally {
      await conn.close();
    }
  } catch (e, st) {
    print('Error en handleSeedStudents: $e\n$st');
    return Response(500,
        body: jsonEncode({'error': 'Fallo al sembrar usuarios: $e'}),
        headers: {'content-type': 'application/json'});
  }
}

Future<Response> handleAdjustDistractions(
    Request request, Future<Connection> Function() abrirConexion) async {
  final env = Platform.environment;
  final queryKey = request.url.queryParameters['key'];
  final headerKey = request.headers['x-admin-key'];
  final expectedKey = env['ADMIN_KEY'] ?? 'infocus2026';

  if (queryKey != expectedKey && headerKey != expectedKey) {
    return Response(401,
        body: jsonEncode({'error': 'No autorizado. Se requiere admin key válida'}),
        headers: {'content-type': 'application/json'});
  }

  try {
    final conn = await abrirConexion();
    try {
      // 1. Obtener lista de usuarios para asignarles los eventos
      final rUsers = await conn.execute(
        "SELECT id, email, created_at FROM users WHERE email LIKE '%@gmail.com' ORDER BY id"
      );
      if (rUsers.isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'No hay usuarios estudiantiles registrados'}),
            headers: {'content-type': 'application/json'});
      }
      final userList = rUsers.map((r) => {
        'id': r[0] as int,
        'email': r[1].toString(),
        'created_at': (r[2] as DateTime),
      }).toList();

      // 2. Limpiar registros automáticos previos para evitar duplicados residuales
      await conn.execute('''
        DELETE FROM distraction_logs 
        WHERE app_name IN (
          'Brawl Stars', 'Clash Royale', 'Free Fire', 'Roblox', 'Call of Duty Mobile',
          'DB LEGENDS', 'TikTok', 'Instagram', 'YouTube', 'WhatsApp', 'Discord', 'Facebook', 'Pinterest', 'Spotify'
        )
      ''');

      // 3. Definir la lista de distracciones escaladas ("un poco menos del doble", ratio ~1.65x - 1.75x)
      // Incluyendo Brawl Stars y otros juegos móviles populares
      final itemsDistraccion = <Map<String, dynamic>>[
        // --- BRAWL STARS (Solicitado por el usuario) ---
        // 7 eventos, ~31 minutos en total
        {'app': 'Brawl Stars', 'pkg': 'com.supercell.brawlstars', 'sec': 260, 'min_offset': 15},
        {'app': 'Brawl Stars', 'pkg': 'com.supercell.brawlstars', 'sec': 310, 'min_offset': 28},
        {'app': 'Brawl Stars', 'pkg': 'com.supercell.brawlstars', 'sec': 240, 'min_offset': 45},
        {'app': 'Brawl Stars', 'pkg': 'com.supercell.brawlstars', 'sec': 280, 'min_offset': 72},
        {'app': 'Brawl Stars', 'pkg': 'com.supercell.brawlstars', 'sec': 230, 'min_offset': 110},
        {'app': 'Brawl Stars', 'pkg': 'com.supercell.brawlstars', 'sec': 290, 'min_offset': 150},
        {'app': 'Brawl Stars', 'pkg': 'com.supercell.brawlstars', 'sec': 270, 'min_offset': 190},

        // --- CLASH ROYALE (Juego) ---
        // 5 eventos, ~20 minutos en total
        {'app': 'Clash Royale', 'pkg': 'com.supercell.clashroyale', 'sec': 230, 'min_offset': 20},
        {'app': 'Clash Royale', 'pkg': 'com.supercell.clashroyale', 'sec': 280, 'min_offset': 55},
        {'app': 'Clash Royale', 'pkg': 'com.supercell.clashroyale', 'sec': 210, 'min_offset': 90},
        {'app': 'Clash Royale', 'pkg': 'com.supercell.clashroyale', 'sec': 260, 'min_offset': 135},
        {'app': 'Clash Royale', 'pkg': 'com.supercell.clashroyale', 'sec': 240, 'min_offset': 180},

        // --- FREE FIRE (Juego) ---
        // 4 eventos, ~23 minutos en total
        {'app': 'Free Fire', 'pkg': 'com.dts.freefireth', 'sec': 330, 'min_offset': 30},
        {'app': 'Free Fire', 'pkg': 'com.dts.freefireth', 'sec': 380, 'min_offset': 75},
        {'app': 'Free Fire', 'pkg': 'com.dts.freefireth', 'sec': 310, 'min_offset': 120},
        {'app': 'Free Fire', 'pkg': 'com.dts.freefireth', 'sec': 360, 'min_offset': 160},

        // --- ROBLOX (Juego) ---
        // 4 eventos, ~19 minutos en total
        {'app': 'Roblox', 'pkg': 'com.roblox.client', 'sec': 280, 'min_offset': 25},
        {'app': 'Roblox', 'pkg': 'com.roblox.client', 'sec': 320, 'min_offset': 65},
        {'app': 'Roblox', 'pkg': 'com.roblox.client', 'sec': 260, 'min_offset': 105},
        {'app': 'Roblox', 'pkg': 'com.roblox.client', 'sec': 290, 'min_offset': 145},

        // --- CALL OF DUTY MOBILE (Juego) ---
        // 3 eventos, ~17 minutos en total
        {'app': 'Call of Duty Mobile', 'pkg': 'com.activision.callofduty.shooter', 'sec': 340, 'min_offset': 40},
        {'app': 'Call of Duty Mobile', 'pkg': 'com.activision.callofduty.shooter', 'sec': 360, 'min_offset': 95},
        {'app': 'Call of Duty Mobile', 'pkg': 'com.activision.callofduty.shooter', 'sec': 310, 'min_offset': 170},

        // --- DB LEGENDS (Juego aumentado a tiempo de partida real) ---
        // 5 eventos, ~19.5 minutos en total
        {'app': 'DB LEGENDS', 'pkg': 'com.bandainamcoent.dblegends_app', 'sec': 240, 'min_offset': 18},
        {'app': 'DB LEGENDS', 'pkg': 'com.bandainamcoent.dblegends_app', 'sec': 260, 'min_offset': 48},
        {'app': 'DB LEGENDS', 'pkg': 'com.bandainamcoent.dblegends_app', 'sec': 210, 'min_offset': 82},
        {'app': 'DB LEGENDS', 'pkg': 'com.bandainamcoent.dblegends_app', 'sec': 230, 'min_offset': 125},
        {'app': 'DB LEGENDS', 'pkg': 'com.bandainamcoent.dblegends_app', 'sec': 230, 'min_offset': 165},

        // --- TIKTOK (Escalado de 8 a 14 eventos: ~58 minutos en total, ~1.8x) ---
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 240, 'min_offset': 12},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 280, 'min_offset': 26},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 220, 'min_offset': 38},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 260, 'min_offset': 52},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 270, 'min_offset': 68},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 230, 'min_offset': 85},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 280, 'min_offset': 100},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 250, 'min_offset': 115},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 240, 'min_offset': 130},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 270, 'min_offset': 148},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 250, 'min_offset': 165},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 230, 'min_offset': 185},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 260, 'min_offset': 205},
        {'app': 'TikTok', 'pkg': 'com.zhiliaoapp.musically', 'sec': 240, 'min_offset': 225},

        // --- INSTAGRAM (Escalado de 6 a 10 eventos: ~38 minutos en total, ~1.8x) ---
        {'app': 'Instagram', 'pkg': 'com.instagram.android', 'sec': 230, 'min_offset': 15},
        {'app': 'Instagram', 'pkg': 'com.instagram.android', 'sec': 260, 'min_offset': 35},
        {'app': 'Instagram', 'pkg': 'com.instagram.android', 'sec': 210, 'min_offset': 58},
        {'app': 'Instagram', 'pkg': 'com.instagram.android', 'sec': 250, 'min_offset': 78},
        {'app': 'Instagram', 'pkg': 'com.instagram.android', 'sec': 220, 'min_offset': 98},
        {'app': 'Instagram', 'pkg': 'com.instagram.android', 'sec': 240, 'min_offset': 122},
        {'app': 'Instagram', 'pkg': 'com.instagram.android', 'sec': 230, 'min_offset': 142},
        {'app': 'Instagram', 'pkg': 'com.instagram.android', 'sec': 250, 'min_offset': 168},
        {'app': 'Instagram', 'pkg': 'com.instagram.android', 'sec': 220, 'min_offset': 195},
        {'app': 'Instagram', 'pkg': 'com.instagram.android', 'sec': 210, 'min_offset': 218},

        // --- YOUTUBE (Escalado de 5 a 8 eventos: ~36 minutos en total, ~1.8x) ---
        {'app': 'YouTube', 'pkg': 'com.google.android.youtube', 'sec': 270, 'min_offset': 22},
        {'app': 'YouTube', 'pkg': 'com.google.android.youtube', 'sec': 310, 'min_offset': 46},
        {'app': 'YouTube', 'pkg': 'com.google.android.youtube', 'sec': 250, 'min_offset': 70},
        {'app': 'YouTube', 'pkg': 'com.google.android.youtube', 'sec': 280, 'min_offset': 96},
        {'app': 'YouTube', 'pkg': 'com.google.android.youtube', 'sec': 260, 'min_offset': 128},
        {'app': 'YouTube', 'pkg': 'com.google.android.youtube', 'sec': 290, 'min_offset': 155},
        {'app': 'YouTube', 'pkg': 'com.google.android.youtube', 'sec': 250, 'min_offset': 182},
        {'app': 'YouTube', 'pkg': 'com.google.android.youtube', 'sec': 270, 'min_offset': 210},

        // --- WHATSAPP (Escalado de 4 a 6 eventos: ~17 minutos en total) ---
        {'app': 'WhatsApp', 'pkg': 'com.whatsapp', 'sec': 160, 'min_offset': 14},
        {'app': 'WhatsApp', 'pkg': 'com.whatsapp', 'sec': 180, 'min_offset': 42},
        {'app': 'WhatsApp', 'pkg': 'com.whatsapp', 'sec': 150, 'min_offset': 84},
        {'app': 'WhatsApp', 'pkg': 'com.whatsapp', 'sec': 170, 'min_offset': 118},
        {'app': 'WhatsApp', 'pkg': 'com.whatsapp', 'sec': 160, 'min_offset': 162},
        {'app': 'WhatsApp', 'pkg': 'com.whatsapp', 'sec': 190, 'min_offset': 202},

        // --- DISCORD (Escalado a 4 eventos: ~18 minutos) ---
        {'app': 'Discord', 'pkg': 'com.discord', 'sec': 260, 'min_offset': 32},
        {'app': 'Discord', 'pkg': 'com.discord', 'sec': 290, 'min_offset': 88},
        {'app': 'Discord', 'pkg': 'com.discord', 'sec': 270, 'min_offset': 138},
        {'app': 'Discord', 'pkg': 'com.discord', 'sec': 280, 'min_offset': 192},

        // --- PINTEREST (3 eventos: ~15 minutos) ---
        {'app': 'Pinterest', 'pkg': 'com.pinterest', 'sec': 290, 'min_offset': 44},
        {'app': 'Pinterest', 'pkg': 'com.pinterest', 'sec': 310, 'min_offset': 108},
        {'app': 'Pinterest', 'pkg': 'com.pinterest', 'sec': 280, 'min_offset': 176},

        // --- SPOTIFY (3 eventos: ~12 minutos) ---
        {'app': 'Spotify', 'pkg': 'com.spotify.music', 'sec': 240, 'min_offset': 36},
        {'app': 'Spotify', 'pkg': 'com.spotify.music', 'sec': 260, 'min_offset': 92},
        {'app': 'Spotify', 'pkg': 'com.spotify.music', 'sec': 250, 'min_offset': 154},

        // --- FACEBOOK (2 eventos: ~8 minutos) ---
        {'app': 'Facebook', 'pkg': 'com.facebook.katana', 'sec': 240, 'min_offset': 50},
        {'app': 'Facebook', 'pkg': 'com.facebook.katana', 'sec': 260, 'min_offset': 130},
      ];

      // 4. Insertar las distracciones asociadas a usuarios en orden rotativo
      var insertadas = 0;
      for (var i = 0; i < itemsDistraccion.length; i++) {
        final item = itemsDistraccion[i];
        final usuario = userList[i % userList.length];
        final uId = usuario['id'] as int;
        final baseDate = usuario['created_at'] as DateTime;
        final offset = item['min_offset'] as int;
        final fechaDist = baseDate.add(Duration(minutes: offset));

        await conn.execute(
          Sql.named('''
            INSERT INTO distraction_logs (user_id, package_name, app_name, seconds, created_at)
            VALUES (@u, @pkg, @app, @sec, @dt)
          '''),
          parameters: {
            'u': uId,
            'pkg': item['pkg'],
            'app': item['app'],
            'sec': item['sec'],
            'dt': fechaDist,
          },
        );
        insertadas++;
      }

      // 5. Escalar las sesiones de estudio (duplica pero un poco menos: ~34 horas totales)
      // Comprobar sesiones actuales
      final rSesiones = await conn.execute("SELECT COUNT(*) FROM focus_sessions");
      final sesionesActuales = (rSesiones.first[0] as num).toInt();

      var sesionesNuevas = 0;
      if (sesionesActuales < 85) {
        // Insertar sesiones complementarias de 25 a 45 minutos para los estudiantes
        for (var i = 0; i < userList.length; i++) {
          final usuario = userList[i];
          final uId = usuario['id'] as int;
          final baseDate = usuario['created_at'] as DateTime;
          final estM = 25 + ((i * 7) % 20); // 25 a 45 minutos
          final sec = estM * 60;
          final inicio = baseDate.add(Duration(minutes: 30 + (i * 12)));

          await conn.execute(
            Sql.named('''
              INSERT INTO focus_sessions (
                user_id, step_title, est_minutes, started_at, ended_at, actual_seconds, status, counts_for_learning
              )
              VALUES (
                @u, @title, @est_m, @started, @ended, @actual_s, 'completed', true
              )
            '''),
            parameters: {
              'u': uId,
              'title': 'Sesión de concentración intensiva',
              'est_m': estM,
              'started': inicio,
              'ended': inicio.add(Duration(seconds: sec)),
              'actual_s': sec,
            },
          );
          sesionesNuevas++;
          if (sesionesActuales + sesionesNuevas >= 92) break;
        }
      }

      // 6. Consultar métricas finales consolidadas
      final rTotalDist = await conn.execute("SELECT COUNT(*), SUM(seconds) FROM distraction_logs");
      final totalDistCount = rTotalDist.first[0];
      final totalDistSec = rTotalDist.first[1];
      final rTotalSes = await conn.execute("SELECT COUNT(*), SUM(actual_seconds) FROM focus_sessions");
      final totalSesCount = rTotalSes.first[0];
      final totalSesSec = rTotalSes.first[1];

      return Response(200,
          body: jsonEncode({
            'success': true,
            'mensaje': 'Estadísticas calibradas y escaladas exitosamente con Brawl Stars y juegos móviles.',
            'distracciones_insertadas': insertadas,
            'total_distracciones_registradas': totalDistCount,
            'minutos_totales_distraccion': ((totalDistSec as num).toInt() / 60).round(),
            'sesiones_de_estudio_agregadas': sesionesNuevas,
            'total_sesiones_estudio': totalSesCount,
            'horas_totales_estudio': (((totalSesSec as num).toInt() / 3600)).toStringAsFixed(1),
          }),
          headers: {'content-type': 'application/json'});
    } finally {
      await conn.close();
    }
  } catch (e, st) {
    print('Error en handleAdjustDistractions: $e\n$st');
    return Response(500,
        body: jsonEncode({'error': 'Error ajustando distracciones: $e'}),
        headers: {'content-type': 'application/json'});
  }
}
