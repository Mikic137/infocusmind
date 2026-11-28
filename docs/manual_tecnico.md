# MANUAL TÉCNICO Y DE ARQUITECTURA
## InfocusMind — Versión 1.1.8 (Build 9)
### Documentación de Ingeniería de Software, Backend y Servicios Nativos Android

---

* **Autor:** Dylan Rosero & Equipo de Desarrollo InfocusMind
* **Institución:** Universidad Politécnica Estatal del Carchi (UPEC)
* **Pila Tecnológica:** Flutter 3.x (Dart), Shelf HTTP Server, PostgreSQL, PayPal Live API, Resend API
* **Fecha:** Noviembre 2026
* **Repositorio Oficial:** [https://github.com/Mikic137/infocusmind](https://github.com/Mikic137/infocusmind)
* **Despliegue Backend Cloud:** [https://infocusmind-production.up.railway.app](https://infocusmind-production.up.railway.app)

---

## 1. VISIÓN GENERAL DE LA ARQUITECTURA

InfocusMind implementa un patrón arquitectónico cliente-servidor desacoplado con arquitectura reactiva basada en capas en el cliente móvil y servicios orientados a dominio en el backend.

```
                      ┌────────────────────────────────────────┐
                      │        CLIENTE MÓVIL (FLUTTER 3.X)     │
                      ├────────────────────────────────────────┤
                      │ - Capa de Presentación (HUD / Widgets) │
                      │ - Gestor de Estado (Riverpod)          │
                      │ - Enrutador Declarativo (GoRouter)     │
                      │ - Canal Nativo Kotlin/Java (Channels)  │
                      │ - Almacenamiento Seguro (KeyStore)     │
                      └───────────────────┬────────────────────┘
                                          │ HTTPS / REST (JWT)
                                          ▼
                      ┌────────────────────────────────────────┐
                      │       SERVIDOR BACKEND (DART SHELF)    │
                      ├────────────────────────────────────────┤
                      │ - Middleware de Versión (vCode >= 9)   │
                      │ - Auth Middleware (JWT Bearer)         │
                      │ - Pipeline IA (DeepSeek / Gemini API)  │
                      │ - PayPal Verification Handler (Live)   │
                      │ - Resend Email Transactional Service   │
                      └───────────────────┬────────────────────┘
                                          │ Driver postgres.dart (Pool)
                                          ▼
                      ┌────────────────────────────────────────┐
                      │     BASE DE DATOS RELACIONAL CLOUD     │
                      │               (POSTGRESQL)             │
                      └────────────────────────────────────────┘
```

---

## 2. PILA TECNOLÓGICA Y DEPENDENCIAS HOMOLOGADAS

### 2.1. Cliente Móvil (Android)
* **Lenguaje y SDK:** Dart v3.3+ / Flutter SDK v3.13+.
* **Gestión de Estado:** `flutter_riverpod: ^3.4.3` para inyección de dependencias y desacoplamiento de la lógica de negocio.
* **Navegación:** `go_router: ^18.1.2` con guardias de autenticación y soporte de deep-linking.
* **Seguridad Local:** `flutter_secure_storage: ^9.0.0` con cifrado mediante Android KeyStore (AES-256 GCM).
* **Audio y Voz:** `speech_to_text: ^6.6.0` para la Interfaz Invisible (Zero UI) y `audioplayers: ^5.2.1` para feedback retro-arcade.

### 2.2. Servidor Backend
* **Servidor HTTP:** `shelf: ^1.4.2` y `shelf_router: ^1.1.4`.
* **Criptografía y Tokens:** `bcrypt: ^1.1.3` (salt rounds = 10) y `dart_jsonwebtoken: ^2.14.0` (algoritmo HMAC-SHA256).
* **Conector de Base de Datos:** `postgres: ^3.1.2` con soporte nativo de pooling asíncrono y consultas preparadas (`Sql.named`).
* **Integración de Pagos:** `http: ^1.2.0` para llamadas a PayPal Orders v2 API con Basic Auth (Live).
* **Envío de Correos:** API REST de Resend (`api.resend.com/emails`).

---

## 3. MODELO DE DATOS RELACIONAL (POSTGRESQL)

El esquema de base de datos fue optimizado para soportar operaciones transaccionales concurrentes y auditoría temporal completa:

```sql
-- Tabla Principal de Cuentas de Usuario
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  is_premium BOOLEAN NOT NULL DEFAULT false,
  ai_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Perfil Académico y Preferencias
CREATE TABLE IF NOT EXISTS profiles (
  user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Misiones y Objetivos Académicos
CREATE TABLE IF NOT EXISTS tasks (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  details TEXT,
  status VARCHAR(50) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Micro-pasos Fragmentados por IA
CREATE TABLE IF NOT EXISTS task_steps (
  id SERIAL PRIMARY KEY,
  task_id INTEGER NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  position INTEGER NOT NULL,
  title VARCHAR(255) NOT NULL,
  est_minutes INTEGER NOT NULL,
  done BOOLEAN NOT NULL DEFAULT false
);

-- Sesiones de Concentración (Pomodoro)
CREATE TABLE IF NOT EXISTS focus_sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  step_id INTEGER REFERENCES task_steps(id) ON DELETE SET NULL,
  step_title VARCHAR(255),
  est_minutes INTEGER NOT NULL,
  actual_seconds INTEGER NOT NULL,
  status VARCHAR(50) DEFAULT 'completed',
  counts_for_learning BOOLEAN DEFAULT true,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ NOT NULL
);

-- Auditoría de Distracciones en Redes y Juegos
CREATE TABLE IF NOT EXISTS distraction_logs (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  app_name VARCHAR(100) NOT NULL,
  package_name VARCHAR(255) NOT NULL,
  seconds INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
```

---

## 4. ESPECIFICACIÓN DE ENDPOINTS DE LA API REST

| Método | Endpoint | Cabeceras Requeridas | Descripción |
| :--- | :--- | :--- | :--- |
| **POST** | `/auth/login` | `Content-Type: application/json` | Valida credenciales con BCrypt y emite JWT. |
| **POST** | `/auth/register` | `Content-Type: application/json` | Registra usuario con cuota inicial Free (10 IA). |
| **POST** | `/auth/recover-request` | `Content-Type: application/json` | Genera OTP y lo envía vía Resend API al correo del estudiante. |
| **POST** | `/auth/reset-password` | `Content-Type: application/json` | Verifica código OTP y actualiza hash de contraseña. |
| **GET** | `/user/subscription` | `Authorization: Bearer <JWT>` | Retorna cuota de IA consumida y estado Premium. |
| **GET** | `/tasks` | `Authorization: Bearer <JWT>` | Retorna misiones y pasos del estudiante. |
| **POST** | `/tasks` | `Authorization: Bearer <JWT>` | Crea una misión manual o programada. |
| **POST** | `/onboarding/chat` | `Authorization: Bearer <JWT>` | Invoca a DeepSeek/Gemini para fragmentar metas. |
| **POST** | `/focus-sessions` | `Authorization: Bearer <JWT>` | Registra sesión de estudio y suma XP. |
| **POST** | `/distractions` | `Authorization: Bearer <JWT>` | Inserta segundos de fuga en `distraction_logs`. |
| **GET** | `/paypal/checkout` | Query: `?token=<JWT>&plan=<P>&amount=<A>` | Renderiza interfaz oficial de PayPal Smart Checkout. |
| **POST** | `/paypal/capture-success` | `Authorization: Bearer <JWT>` | Verificación servidor a servidor de orden PayPal y activación Plus. |
| **GET** | `/admin/metrics` | Query: `?key=infocus2026` | Telemetría en vivo en formato JSON o HTML. |

---

## 5. FLUJO TRANSACCIONAL DE PAGOS (PAYPAL LIVE)

El módulo de monetización implementa la arquitectura oficial recomendada por PayPal para entornos móviles:

```
[ CLIENTE MÓVIL ]                [ BACKEND RAILWAY ]              [ SERVIDOR PAYPAL ]
       │                                  │                                │
       ├─ Solicita URL Checkout ─────────►│                                │
       │◄── Retorna URL firmada ──────────┤                                │
       │                                  │                                │
       ├─ Abre WebView/Browser ───────────────────────────────────────────►│ (Usuario aprueba pago)
       │◄── Captura en JavaScript SDK ─────────────────────────────────────┤ (Devuelve orderID)
       │                                  │                                │
       ├─ POST /paypal/capture-success ──►│                                │
       │  (orderID, plan, amount)         ├─ POST /v1/oauth2/token ───────►│ (Obtiene Access Token)
       │                                  │◄── Bearer Token ───────────────┤
       │                                  │                                │
       │                                  ├─ GET /v2/checkout/orders/{id} ─►│ (Consulta estado real)
       │                                  │◄── Status: 'COMPLETED' ────────┤
       │                                  │                                │
       │                                  ├─ UPDATE users is_premium=true  │ (Persiste en PostgreSQL)
       │                                  ├─ Envia Factura vía Resend API  │ (Despacha a Gmail)
       │◄── HTTP 200 {"is_premium": true}─┤                                │
```

---

## 6. SERVICIOS NATIVOS ANDROID (KOTLIN / MANIFIESTO)

Para garantizar que el bloqueo sea real a nivel de sistema operativo y no una simple máscara de interfaz:

### 6.1. Filtro de Intención para Modo Launcher
En `android/app/src/main/AndroidManifest.xml`:
```xml
<activity
    android:name=".MainActivity"
    android:launchMode="singleTop"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>

    <!-- Habilita a InfocusMind como pantalla de inicio del sistema -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.HOME"/>
        <category android:name="android.intent.category.DEFAULT"/>
    </intent-filter>
</activity>
```

### 6.2. Auditoría Silenciosa con UsageStatsManager
En tiempo de ejecución, la clase nativa consulta el historial de eventos recientes mediante `UsageStatsManager.queryEvents()` filtrando aplicaciones del catálogo distractor (TikTok, Instagram, YouTube, Roblox, Free Fire, etc.) y enviando los deltas de tiempo a través del `MethodChannel('com.infocusmind.mobile/usage')`.
