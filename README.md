# 🏗️ Data Platform: OLTP → CDC → OLAP → BI

> Plataforma de datos moderna y reproducible que replica cambios desde PostgreSQL en tiempo real hacia ClickHouse para análisis de alta velocidad, visualizados en Apache Superset — todo orquestado con Docker Compose.

---

## 📐 Arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA PLATFORM                               │
│                                                                     │
│  ┌──────────────┐    WAL /     ┌─────────────┐   Kafka    ┌──────────────┐
│  │  PostgreSQL  │─────CDC─────▶│  Debezium   │──Topics───▶│  Redpanda    │
│  │   (OLTP)     │   Logical    │  Connect    │            │  (Kafka API) │
│  │  port: 5432  │  Replication │  port: 8083 │            │  port: 9092  │
│  └──────────────┘              └─────────────┘            └──────┬───────┘
│         ▲                                                         │        
│   INSERT/                                                    JSON Events    
│  UPDATE/DELETE                                                    │        
│         │                                                         ▼        
│  ┌──────────────┐              ┌─────────────────────────────────────────┐
│  │  Apps /      │              │           ClickHouse (OLAP)             │
│  │  Usuarios    │              │   ReplacingMergeTree / analytics DB     │
│  └──────────────┘              │              port: 18123 / 19000        │
│                                └──────────────────┬──────────────────────┘
│                                                   │                       
│                                              SQL Queries                  
│                                                   │                       
│                                ┌──────────────────▼──────────────────────┐
│                                │            Apache Superset               │
│                                │   Dashboards + Redis Cache (5 min)      │
│                                │              port: 8088                  │
│                                └─────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────────┘
```

### Capas del sistema

| Capa | Tecnología | Rol | Puerto |
|------|-----------|-----|--------|
| OLTP / Origen | PostgreSQL 16 | Base de datos transaccional con WAL lógico activo | 5432 |
| CDC | Debezium Connect 2.5 | Captura cambios del WAL y los publica como eventos JSON | 8083 |
| Streaming | Redpanda (Kafka-compatible) | Bus de mensajería; desacopla origen del destino | 9092 |
| OLAP / Destino | ClickHouse | Almacén analítico columnar de alta velocidad | 18123, 19000 |
| Caché | Redis 7 | Caché de queries para Superset | 6379 |
| BI | Apache Superset 6.0 | Dashboards y exploración de datos | 8088 |

---

## ⚙️ Requisitos Previos

- Docker >= 24.x
- Docker Compose >= 2.x
- 8 GB RAM mínimo (16 GB recomendado)
- 50 GB disco libre

---

## 🚀 Instalación y Ejecución

### 1. Clonar el repositorio

```bash
git clone <url-del-repo>
cd data-platform
```

### 2. Configurar variables de entorno

Crea un archivo `.env` en la raíz del proyecto:

```env
# PostgreSQL
POSTGRES_DB=app_db
POSTGRES_USER=app_user
POSTGRES_PASSWORD=app_password

# Superset
SUPERSET_ADMIN_USER=admin
SUPERSET_ADMIN_PASSWORD=admin
SUPERSET_ADMIN_EMAIL=admin@example.com
SECRET_KEY=mysecretkey123
```

### 3. Levantar la plataforma

```bash
chmod +x setup.sh
./setup.sh
```

El script valida que Docker esté disponible, construye la imagen personalizada de Superset (con drivers de ClickHouse y PostgreSQL), y levanta todos los servicios en segundo plano.

### 4. Verificar que todos los servicios están corriendo

```bash
docker compose ps
```

Todos los contenedores deben mostrar status `Up`.

---

## 🗂️ Estructura del Proyecto

```
data-platform/
│
├── docker-compose.yml          # Orquestación de todos los servicios
├── Dockerfile.superset         # Imagen Superset con drivers clickhouse-connect + psycopg2
├── .env                        # Variables de entorno (no subir a Git)
├── setup.sh                    # Script de arranque rápido
├── README.md
│
├── postgres/
│   └── init/
│       └── 01_init.sql         # Inicialización de PostgreSQL
│
├── clickhouse/
│   └── init/
│       └── 01_tables.sql       # Tablas OLAP con ReplacingMergeTree
│
├── superset/
│   ├── superset_config.py      # Config Redis cache + feature flags
│   └── init.sh                 # Migraciones DB, creación admin, arranque
│
└── debezium/
    └── application.properties  # Conector PostgreSQL → ClickHouse via JDBC sink
```

---

## 📋 Ejemplo Completo: Replicar una Tabla Nueva

Supongamos que quieres replicar la tabla `alumnos` desde PostgreSQL hacia ClickHouse.

### Paso 1 — Crear la tabla en PostgreSQL (OLTP)

Conéctate a PostgreSQL y ejecuta:

```sql
-- En PostgreSQL (app_db)
CREATE TABLE alumnos (
    id       BIGSERIAL PRIMARY KEY,
    nombre   VARCHAR(100) NOT NULL,
    activo   BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Habilitar replica identity para CDC completo
ALTER TABLE alumnos REPLICA IDENTITY FULL;
```

### Paso 2 — Crear la tabla espejo en ClickHouse (OLAP)

```sql
-- En ClickHouse (analytics)
CREATE DATABASE IF NOT EXISTS analytics;

CREATE TABLE analytics.alumnos (
    id         UInt64,
    nombre     String,
    activo     UInt8,
    updated_at DateTime
) ENGINE = ReplacingMergeTree(updated_at)
ORDER BY id;
```

El motor `ReplacingMergeTree` deduplica registros por `id`, manteniendo siempre la versión más reciente según `updated_at`.

### Paso 3 — Registrar el conector Debezium via API REST

```bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "postgres-connector",
    "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "database.hostname": "postgres",
      "database.port": "5432",
      "database.user": "app_user",
      "database.password": "app_password",
      "database.dbname": "app_db",
      "database.server.name": "pgserver",
      "plugin.name": "pgoutput",
      "table.include.list": "public.alumnos",
      "publication.name": "debezium_pub",
      "slot.name": "debezium_slot"
    }
  }'
```

### Paso 4 — Insertar datos de prueba en PostgreSQL

```sql
INSERT INTO alumnos (nombre, activo) VALUES
  ('Ana García', true),
  ('Carlos López', true),
  ('María Torres', false);
```

En segundos, los registros aparecerán replicados en ClickHouse via Redpanda.

### Paso 5 — Verificar datos en ClickHouse

```bash
curl "http://localhost:18123/?query=SELECT%20*%20FROM%20analytics.alumnos"
```

---

## 📊 Conexión con Apache Superset

### Acceso

Abre el navegador en: **http://localhost:8088**  
Credenciales por defecto: `admin / admin`

### Agregar ClickHouse como fuente de datos

1. Ve a **Settings → Database Connections → + Database**
2. Selecciona **ClickHouse Connect**
3. Ingresa la cadena de conexión:

```
clickhouse://default:@clickhouse:8123/analytics
```

4. Haz clic en **Test Connection** → **Connect**

### Crear un Dataset y Dashboard

1. Ve a **Datasets → + Dataset**
2. Selecciona la base `analytics` y la tabla `alumnos`
3. Guarda y ve a **Charts → + Chart** para crear visualizaciones
4. Agrega los charts a un **Dashboard**

> 💡 Superset usa Redis como caché con timeout de 300 segundos. Los dashboards muestran datos casi en tiempo real con baja carga sobre ClickHouse.

---

## 🔌 URLs de Acceso

| Servicio | URL | Credenciales |
|---------|-----|-------------|
| Superset (BI) | http://localhost:8088 | admin / admin |
| ClickHouse HTTP | http://localhost:18123 | default / (sin password) |
| Debezium REST API | http://localhost:8083 | — |
| PostgreSQL | localhost:5432 | app_user / app_password |
| Redpanda (Kafka) | localhost:9092 | — |

---

## 🛑 Detener la Plataforma

```bash
docker compose down
```

Para eliminar también los volúmenes de datos:

```bash
docker compose down -v
```

---

## 🔍 Flujo de Datos Resumido

```
INSERT/UPDATE/DELETE en PostgreSQL
        │
        ▼ (WAL logical replication via pgoutput)
    Debezium captura el cambio como evento JSON
        │
        ▼ (publica en topic Redpanda)
    redpanda topic: pgserver.public.alumnos
        │
        ▼ (JDBC Sink a ClickHouse)
    ClickHouse analytics.alumnos (ReplacingMergeTree)
        │
        ▼ (SQL query con caché Redis 5 min)
    Apache Superset → Dashboard actualizado
```

---

## 🧰 Troubleshooting

**Superset no inicia:**
```bash
docker compose logs superset
```

**Debezium no conecta con PostgreSQL:**
```bash
# Verificar que WAL lógico esté activo
docker exec postgres psql -U app_user -d app_db -c "SHOW wal_level;"
# Debe retornar: logical
```

**Datos no llegan a ClickHouse:**
```bash
# Revisar estado del conector
curl http://localhost:8083/connectors/postgres-connector/status
```

**Limpiar y reiniciar todo:**
```bash
docker compose down -v
./setup.sh
```
