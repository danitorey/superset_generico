# 🏗️ Plataforma de Datos OLTP → CDC → OLAP → BI

> **Stack:** PostgreSQL 16 · Debezium 2.5 · Redpanda (Kafka-compatible) · ClickHouse · Apache Superset 6.0 · Redis · Docker Compose

---

## 1. Objetivo

Diseñar e implementar una plataforma de datos moderna que permita:

- Replicar datos desde PostgreSQL (OLTP) en tiempo casi real mediante CDC
- Desacoplar completamente la carga analítica del sistema transaccional
- Acelerar consultas analíticas con ClickHouse (OLAP columnar)
- Visualizar información con Apache Superset de forma segura y cacheada con Redis
- Garantizar reproducibilidad y portabilidad completa mediante Docker Compose

---

## 2. Arquitectura General

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PLATAFORMA DE DATOS                                 │
│                                                                             │
│   Usuarios / Apps                                                           │
│         │                                                                   │
│         ▼                                                                   │
│  ┌─────────────┐    logical replication    ┌──────────────┐                │
│  │ PostgreSQL  │ ─────────────────────────▶│   Debezium   │                │
│  │  (OLTP 16)  │                           │  Connect 2.5 │                │
│  └─────────────┘                           └──────┬───────┘                │
│    6 tablas CDC:                                   │ eventos JSON           │
│    • dim_clientes                                  ▼                        │
│    • dim_productos                        ┌──────────────┐                 │
│    • dim_empleados                        │   Redpanda   │                 │
│    • fact_ventas                          │  (Kafka API) │                 │
│    • fact_operaciones                     └──────┬───────┘                 │
│    • fact_presupuesto                            │ topics por tabla        │
│                                                  ▼                         │
│                                         ┌──────────────┐                  │
│                                         │  ClickHouse  │                  │
│                                         │  (OLAP col.) │                  │
│                                         └──────┬───────┘                  │
│                                                │ consultas OLAP            │
│                              ┌─────────────────┤                           │
│                              │                 │                           │
│                              ▼                 ▼                           │
│                        ┌──────────┐    ┌──────────────┐                   │
│                        │  Redis   │◀───│   Superset   │                   │
│                        │ (cache)  │    │    BI 6.0    │                   │
│                        └──────────┘    └──────┬───────┘                   │
│                                               │ :8088                      │
│                                               ▼                            │
│                                         Dashboards BI                      │
│                                    ┌────────────────────┐                  │
│                                    │ • Ventas           │                  │
│                                    │ • Operaciones      │                  │
│                                    │ • Clientes         │                  │
│                                    │ • Productos        │                  │
│                                    │ • Empleados        │                  │
│                                    │ • Presupuesto      │                  │
│                                    │ • Analytics Gen.   │                  │
│                                    └────────────────────┘                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Tabla de Fases del Proyecto

| # | Fase | Descripción | Estado |
|---|------|-------------|--------|
| 1 | **Infraestructura base** | Docker Compose con PostgreSQL, Redpanda, Debezium, ClickHouse, Redis, Superset | ✅ Completado |
| 2 | **CDC con Debezium** | Replicación lógica de 6 tablas del schema `analytics` hacia topics Redpanda | ✅ Completado |
| 3 | **Datos dummy** | Tablas y datos de prueba en PostgreSQL y ClickHouse para validación end-to-end | ✅ Completado |
| 4 | **Conexión ClickHouse → Superset** | Script automático `create_clickhouse_connection.py` via API REST | ✅ Completado |
| 5 | **Dashboards BI** | 7 dashboards importados automáticamente desde ZIPs en `superset/exports/` | ✅ Completado |
| 6 | **Init automatizado** | `init.sh` orquesta migraciones, admin, init, conexión CH y carga de dashboards | ✅ Completado |
| 7 | **Alertas y correos** | Configurar Superset Alerts & Reports con SMTP para notificaciones automáticas | 🔲 Siguiente |
| 8 | **Dashboard de monitoreo** | Dashboard interno de salud de la plataforma (lag CDC, estado conectores, métricas) | 🔲 Pendiente |
| 9 | **Authentik (SSO/IdP)** | Autenticación centralizada con Authentik como proveedor OIDC/SAML para Superset | 🔲 Pendiente |
| 10 | **API Gateway** | Traefik o Nginx como reverse proxy con rutas, TLS y rate limiting | 🔲 Pendiente |
| 11 | **Hardening producción** | Secrets management, usuarios no-root, variables de entorno seguras, backups | 🔲 Pendiente |
| 12 | **Observabilidad** | Prometheus + Grafana para métricas de contenedores y pipelines | 🔲 Futuro |

---

## 4. Servicios del Stack

| Servicio | Imagen | Puerto | Rol |
|----------|--------|--------|-----|
| `postgres` | `postgres:16` | `5432` | Fuente OLTP, WAL lógico |
| `redpanda` | `redpandadata/redpanda:v23.3.10` | `9092` | Broker Kafka-compatible |
| `debezium` | `debezium/connect:2.5` | `8083` | CDC connector (6 tablas) |
| `clickhouse` | `clickhouse/clickhouse-server:latest` | `8123 / 9000` | OLAP columnar |
| `redis` | `redis:7` | `6379` | Cache de queries Superset |
| `superset` | `apache/superset:6.0.0` + custom | `8088` | BI / Dashboards |
| `platform_init` | custom (postgres:16 base) | — | Orquestador de inicialización |

---

## 5. Conectores Debezium activos

```
analytics-dim-clientes      → topic: analytics.analytics.dim_clientes
analytics-dim-productos     → topic: analytics.analytics.dim_productos
analytics-dim-empleados     → topic: analytics.analytics.dim_empleados
analytics-fact-ventas       → topic: analytics.analytics.fact_ventas
analytics-fact-operaciones  → topic: analytics.analytics.fact_operaciones
analytics-fact-presupuesto  → topic: analytics.analytics.fact_presupuesto
```

---

## 6. Dashboards importados en Superset

| Dashboard | Archivo ZIP |
|-----------|-------------|
| Ventas | `dashboard_ventas.zip` |
| Operaciones | `dashboard_operaciones.zip` |
| Clientes | `dashboard_clientes.zip` |
| Productos | `dashboard_productos.zip` |
| Empleados | `dashboard_empleados.zip` |
| Presupuesto | `dashboard_presupuesto.zip` |
| Analytics General | `dashboard_analytics_general.zip` |

---

## 7. Estructura de Directorios

```
data-platform/
├── docker-compose.yml
├── .env
├── Dockerfile.superset
├── Dockerfile.init
├── README.md
│
├── postgres/
│   └── docker-entrypoint-initdb.d/
│
├── sql/
│   ├── 01_postgres_dummy.sql
│   └── 02_clickhouse_dummy.sql
│
├── sh/
│   └── 03_debezium_connectors.sh
│
├── superset/
│   ├── superset_config.py
│   ├── init.sh                        ← orquestador principal
│   ├── create_clickhouse_connection.py
│   └── exports/
│       ├── dashboard_ventas.zip
│       ├── dashboard_operaciones.zip
│       ├── dashboard_clientes.zip
│       ├── dashboard_productos.zip
│       ├── dashboard_empleados.zip
│       ├── dashboard_presupuesto.zip
│       └── dashboard_analytics_general.zip
```

---

## 8. Comandos de operación

### 🔄 Ciclo completo (bajar → limpiar → levantar)

```bash
# 1. Bajar todo (volúmenes incluidos)
docker compose down -v --remove-orphans

# 2. Verificar ZIPs en su lugar
ls -lh superset/exports/

# 3. Construir y levantar
docker compose up -d --build

# 4. Monitorear init
docker logs -f platform_init

# 5. Monitorear Superset (en otra terminal)
docker logs -f superset
```

### 📋 Verificación rápida

```bash
# Estado de todos los contenedores
docker compose ps

# Salud de conectores Debezium
curl -s http://localhost:8083/connectors | python3 -m json.tool

# Estado individual de un conector
curl -s http://localhost:8083/connectors/analytics-fact-ventas/status | python3 -m json.tool

# Ping ClickHouse
curl -s http://localhost:8123/ping

# Ver topics Redpanda
docker exec redpanda rpk topic list
```

### 🧹 Limpieza selectiva (sin bajar todo)

```bash
# Solo reiniciar el init (para re-importar dashboards)
docker compose restart platform_init

# Solo reiniciar Superset
docker compose restart superset
```

---

## 9. Qué sigue — Fase 7: Alertas, Correos y Dashboard de Monitoreo

### Paso 1 — Habilitar celery beat en Superset

Superset necesita un worker y scheduler para ejecutar alertas/reportes.
Agregar en `docker-compose.yml`:

```yaml
superset-worker:
  build:
    context: .
    dockerfile: Dockerfile.superset
  container_name: superset_worker
  command: celery --app=superset.tasks.celery_app:app worker --loglevel=INFO
  env_file: .env
  depends_on:
    - redis
    - postgres
  networks:
    - dataplatformnetwork
  restart: unless-stopped

superset-beat:
  build:
    context: .
    dockerfile: Dockerfile.superset
  container_name: superset_beat
  command: celery --app=superset.tasks.celery_app:app beat --loglevel=INFO
  env_file: .env
  depends_on:
    - redis
    - postgres
  networks:
    - dataplatformnetwork
  restart: unless-stopped
```

### Paso 2 — Configurar SMTP en `superset_config.py`

```python
# Alertas y correos
ENABLE_SCHEDULED_EMAIL_REPORTS = True
ENABLE_ALERTS = True

EMAIL_NOTIFICATIONS = True
SMTP_HOST = "smtp.gmail.com"           # o tu servidor SMTP
SMTP_STARTTLS = True
SMTP_SSL = False
SMTP_PORT = 587
SMTP_USER = "tu-correo@gmail.com"
SMTP_PASSWORD = "tu-app-password"
SMTP_MAIL_FROM = "tu-correo@gmail.com"

# Celery broker (Redis)
from celery.schedules import crontab
CELERY_CONFIG = {
    "broker_url": "redis://redis:6379/0",
    "result_backend": "redis://redis:6379/0",
    "worker_prefetch_multiplier": 1,
    "task_acks_late": False,
    "beat_schedule": {
        "reports.scheduler": {
            "task": "reports.scheduler",
            "schedule": crontab(minute="*", hour="*"),
        },
    },
}

# URL base para links en correos
WEBDRIVER_BASEURL = "http://superset:8088/"
WEBDRIVER_BASEURL_USER_FRIENDLY = "http://localhost:8088/"
```

### Paso 3 — Crear una alerta en Superset UI

1. Ir a **Alerts & Reports** → `+ Alert`
2. Configurar:
   - **Nombre:** `Ventas diarias bajas`
   - **Alert type:** `SQL-based alert`
   - **Database:** ClickHouse Analytics
   - **SQL:** `SELECT count(*) FROM fact_ventas WHERE toDate(fecha) = today()`
   - **Condición:** `< 10`
   - **Schedule:** cron `0 9 * * *` (9 AM diario)
   - **Notificación:** Email → destinatarios

### Paso 4 — Dashboard de Monitoreo de la plataforma

Crear un dashboard en Superset con estas métricas clave:

```sql
-- 1. Lag aproximado de CDC (última inserción vs ahora)
SELECT
    table,
    max(updated_at) AS ultima_replicacion,
    now() - max(updated_at) AS lag
FROM analytics.dim_clientes
UNION ALL
SELECT 'fact_ventas', max(fecha), now() - max(fecha)
FROM analytics.fact_ventas;

-- 2. Conteo de registros por tabla
SELECT 'dim_clientes' AS tabla, count(*) AS registros FROM analytics.dim_clientes
UNION ALL SELECT 'fact_ventas', count(*) FROM analytics.fact_ventas
UNION ALL SELECT 'fact_operaciones', count(*) FROM analytics.fact_operaciones;

-- 3. Volumen de eventos por hora (últimas 24h)
SELECT
    toStartOfHour(fecha) AS hora,
    count(*) AS eventos
FROM analytics.fact_ventas
WHERE fecha >= now() - INTERVAL 1 DAY
GROUP BY hora
ORDER BY hora;
```

---

## 10. Variables de entorno (.env)

```env
# PostgreSQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres123
POSTGRES_DB=postgres

# ClickHouse
CLICKHOUSE_DB=analytics
CLICKHOUSE_USER=default
CLICKHOUSE_PASSWORD=clickhouse123

# Superset
SUPERSET_SECRET_KEY=tu-clave-secreta-muy-larga
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin
ADMIN_EMAIL=admin@example.com
ADMIN_FIRST_NAME=Admin
ADMIN_LAST_NAME=User
```

---

## 11. Requisitos de infraestructura

| Entorno | CPU | RAM | Disco |
|---------|-----|-----|-------|
| Dev / pruebas | 4 cores | 8 GB | 50 GB SSD |
| QA / pre-prod | 8 cores | 16 GB | 100 GB SSD |
| Producción inicial | 16 cores | 32 GB | 300 GB SSD (IOPS altos) |

---

## 12. Troubleshooting rápido

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| `platform_init` termina con error | Superset no listo aún | Aumentar `sleep` en el `until` del `init.sh` |
| Dashboards no importan | ZIPs no encontrados o mal nombrados | `ls superset/exports/` y verificar nombres exactos |
| ClickHouse `409` en conexión | Conexión ya existe | Normal, ignorar |
| Debezium `404` al registrar | Debezium aún arrancando | El script reintenta automáticamente |
| Superset sin charts | UUID del dashboard no coincide con datasource | Re-exportar desde Superset con datos correctos |
| Celery worker no procesa alertas | Redis no conectado o celery no arranca | `docker logs superset_worker` |

---

*Última actualización: Abril 2026 — Ricardo Daniel Reyes Arellano*
