# 🃏 GoldenAce — Sistema de Apuestas

Plataforma web de apuestas virtuales entre usuarios desarrollada como proyecto de ingeniería de software. Permite a los usuarios crear eventos, apostar monedas virtuales, proponer resultados y competir en un ranking semanal, todo bajo la supervisión de un administrador.

---

## 🚀 Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Frontend | Vue 3 + Vuetify + Pinia + TypeScript |
| Backend | Node.js + Express + TypeScript |
| Base de datos | PostgreSQL 16 |
| Tiempo real | Socket.io |
| Autenticación | JWT + bcrypt |
| Validación | Zod |
| Servidor web | NGINX |
| Contenedores | Docker + Docker Compose |

---

## 📁 Estructura del Proyecto

```
casino/
├── backend/
│   ├── src/
│   │   ├── config/          # DB, env, socket, multer
│   │   ├── middlewares/     # auth, role, validate, error
│   │   └── modules/         # auth, apuestas, participaciones,
│   │                        # resultados, saldos, retiros,
│   │                        # documentos, usuarios, categorias, ranking
│   ├── Dockerfile
│   └── tsconfig.json
├── frontend/
│   ├── src/
│   │   ├── config/          # api.ts (apiFetch centralizado)
│   │   ├── stores/          # auth, apuestas (Pinia)
│   │   ├── views/           # Login, Registro, Apuestas, Crear,
│   │   │                    # Perfil, Historial, Wallet, Admin, Ranking
│   │   └── components/      # Navbar
│   ├── nginx.conf
│   └── Dockerfile
├── docker-compose.yml
└── README.md
```

---

## ⚙️ Requisitos Previos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) con WSL2 habilitado
- Git

---

## 🐳 Levantar con Docker (Recomendado)

```bash
# 1. Clonar el repositorio
git clone https://github.com/LudoSoft2026/casino.git
cd casino

# 2. Construir y levantar los contenedores
docker compose up --build

# 3. Cargar la base de datos (primera vez)
docker exec -i casino_db psql -U postgres -d apuestas_db < apuestas_db.sql
```

La aplicación estará disponible en:
- **Frontend**: http://localhost
- **Backend**: http://localhost:3000

---

## 💻 Levantar en Desarrollo Local

### Backend

```bash
cd backend
pnpm install
pnpm dev
```

### Frontend

```bash
cd frontend
pnpm install
pnpm dev
```

### Variables de entorno

Crea `backend/.env`:

```env
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=apuestas_db
DB_USER=postgres
DB_PASSWORD=123
JWT_SECRET=una_clave_secreta_muy_larga_y_segura_aqui
JWT_EXPIRES_IN=7d
```

Crea `frontend/.env`:

```env
VITE_API_URL=http://localhost:3000
VITE_SOCKET_URL=http://localhost:3000
```

---

## 🔑 Roles de Usuario

| Rol | Permisos |
|---|---|
| **Usuario** | Registro, login, crear apuestas, apostar, proponer resultado, ver historial, wallet, ranking |
| **Administrador** | Todo lo anterior + gestión de usuarios, documentos, saldos, categorías y declarar ganadores |

---

## 📋 Requisitos Funcionales Implementados

| Requisito | Descripción | Estado |
|---|---|---|
| RF-USU-01 | Registro de usuarios con validación de mayoría de edad | ✅ |
| RF-USU-02 | Autenticación con JWT y verificación de identidad | ✅ |
| RF-USU-06 | Saldo en tiempo real via WebSocket | ✅ |
| RF-USU-09 | Propuesta de resultado por el creador con evidencia | ✅ |
| RF-APU-03 | Catálogo de apuestas activas con contador regresivo | ✅ |
| RF-APU-04 | Realizar apuesta con validación de saldo | ✅ |
| RF-APU-07 | Crear apuesta con opciones y probabilidades | ✅ |
| RF-ADM-05 | Historial de participaciones por usuario | ✅ |
| RF-ADM-07 | Asignación manual de saldo (abono) | ✅ |
| RF-ADM-08 | Deducción manual de saldo | ✅ |
| RF-ADM-10 | Declarar ganador con distribución de premios | ✅ |
| RF-ADM-11 | Gestión de usuarios (activar/suspender/bloquear) | ✅ |
| RF-ADM-13 | Validación de documentos de identidad | ✅ |
| RF-ADM-14 | Gestión de categorías de apuestas | ✅ |
| RF-RAN-14 | Ranking semanal de usuarios ganadores | ✅ |

---

## 🔒 Requisitos No Funcionales Implementados

| Requisito | Descripción | Estado |
|---|---|---|
| RNF-SIS-01 | Tiempo real con WebSockets | ✅ |
| RNF-SIS-02 | Bloqueo de 30s entre apuestas | ✅ |
| RNF-SIS-04 | Seguridad con Helmet, JWT, bcrypt | ✅ |
| RNF-SIS-05 | Autenticación, sesiones y control de acceso | ✅ |
| RNF-SIS-07 | Tiempo de respuesta < 3s en catálogo | ✅ |
| RNF-SIS-08 | Integridad financiera (no saldos negativos) | ✅ |
| RNF-SIS-09 | Atomicidad en pagos y reembolsos | ✅ |
| RNF-SIS-10 | Diseño de interfaz adaptativa (web) | ✅ |
| RNF-SIS-11 | Separación de responsabilidades arquitectónicas | ✅ |

---

## 🗄️ Arquitectura de Base de Datos

### Tablas principales
`usuarios`, `apuestas`, `opciones_apuesta`, `participaciones`, `resultados_apuesta`, `saldos`, `transacciones`, `documentos_identidad`, `categorias`, `retiros`, `logs_admin`

### Stored Procedures principales
- `sp_registrar_usuario` — Registro con validaciones
- `sp_gestionar_login` — Login con bloqueo de intentos
- `sp_crear_apuesta` — Creación de apuesta con opciones
- `sp_participar_apuesta` — Apostar con validación de saldo
- `sp_proponer_resultado` — Proponer resultado con evidencia
- `sp_confirmar_resultado` — Confirmar y distribuir premios
- `sp_cancelar_apuesta` — Cancelar con reembolso automático
- `sp_abonar_saldo_admin` — Abonar saldo (admin)
- `sp_deducir_saldo_admin` — Deducir saldo (admin)
- `sp_cerrar_apuestas_expiradas` — Cierre automático cada 30s

### Vistas
- `v_apuestas_activas` — Apuestas disponibles para apostar
- `v_ranking_semanal` — Ranking de ganadores de la semana
- `v_historial_participaciones` — Historial por usuario
- `v_documentos_pendientes` — Documentos por revisar

---

## 🌐 Endpoints Principales

### Autenticación
```
POST /api/auth/registro
POST /api/auth/login
```

### Apuestas
```
GET  /api/apuestas
POST /api/apuestas
GET  /api/apuestas/mis-apuestas
GET  /api/apuestas/:id/opciones
DELETE /api/apuestas/:id
```

### Participaciones
```
POST /api/participaciones
GET  /api/participaciones/historial
```

### Resultados
```
POST /api/resultados/proponer
POST /api/resultados/confirmar
GET  /api/resultados/pendientes
```

### Saldos
```
GET  /api/saldos
GET  /api/saldos/historial
POST /api/saldos/admin/abonar
POST /api/saldos/admin/deducir
```

### Categorías
```
GET    /api/categorias
POST   /api/categorias
PUT    /api/categorias/:id
DELETE /api/categorias/:id
```

### Ranking
```
GET /api/ranking
```

---

## 🔌 WebSocket Events

| Evento | Descripción |
|---|---|
| `join:usuario` | Unirse a sala personal para recibir actualizaciones de saldo |
| `join:apuesta` | Unirse a sala de apuesta para ver participantes en tiempo real |
| `saldo:actualizado` | Notificación de cambio de saldo |
| `apuesta:actualizada` | Notificación de nueva participación en apuesta |

---

## 🐳 Comandos Docker Útiles

```bash
# Levantar contenedores
docker compose up

# Levantar y reconstruir
docker compose up --build

# Detener contenedores
docker compose down

# Ver logs del backend
docker compose logs backend --tail=50

# Ver logs en tiempo real
docker compose logs -f

# Cargar base de datos
docker exec -i casino_db psql -U postgres -d apuestas_db < apuestas_db.sql
```

---

## 👥 Equipo

Proyecto desarrollado como parte del curso de Ingeniería de Software

---

## 📄 Licencia

Uso académico exclusivo.