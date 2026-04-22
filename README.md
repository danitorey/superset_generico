# 🏗️ Data Platform — CASmart

## 🎯 Objetivo

Diseñar e implementar una plataforma de datos moderna, escalable y de bajo costo operativo
que permita a cualquier organización (pública o privada) centralizar sus fuentes de información,
procesarlas en tiempo real mediante Change Data Capture (CDC), almacenarlas en un motor analítico
de alto rendimiento, y visualizarlas en dashboards ejecutivos interactivos.

La plataforma está pensada para crecer: desde un stack local con Docker hasta una solución
productiva con consultas federadas entre múltiples bases, alertas automáticas, monitoreo
continuo del pipeline y, en su etapa más avanzada, asistencia inteligente basada en IA
para análisis y generación de insights.

---

## 📊 Los 7 Dashboards

| Dashboard | Propósito ejecutivo |
|---|---|
| **Resumen Ejecutivo** | Vista global del negocio: ventas, operaciones y presupuesto en una sola pantalla |
| **Ventas y Comercial** | Quién vende más, qué productos jalan y qué clientes compran más |
| **Operaciones** | Carga de trabajo, tiempos de resolución y cuellos de botella operativos |
| **Presupuesto** | Control del gasto: asignado vs ejercido, alertas de sobreejercicio |
| **Calidad de datos** | Detecta datos incompletos o inválidos antes de que afecten decisiones |
| **Recursos Humanos** | Plantilla, distribución por área, nivel y desempeño comercial |
| **Tendencias y Proyecciones** | Evolución histórica, comparativas y proyección de ventas y operaciones |

---

## 🗺️ Arquitectura por capas

```
╔══════════════════════════════════════════════════════════════════════╗
║                        CAPA DE FUENTES                              ║
║                                                                      ║
║   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐            ║
║   │  PostgreSQL │    │  SQL Server │    │  Otras BD   │  ← futuro  ║
║   │  (fuente    │    │  (futuro)   │    │  (futuro)   │            ║
║   │   actual)   │    └─────────────┘    └─────────────┘            ║
║   └──────┬──────┘                                                   ║
╚══════════╪═══════════════════════════════════════════════════════════╝
           │ WAL / CDC
╔══════════╪═══════════════════════════════════════════════════════════╗
║          ▼         CAPA DE INGESTA (CDC)                            ║
║   ┌─────────────┐                                                   ║
║   │  Debezium   │  Captura cambios en tiempo real (INSERT/UPDATE/   ║
║   │  (CDC)      │  DELETE) sin modificar la base fuente             ║
║   └──────┬──────┘                                                   ║
╚══════════╪═══════════════════════════════════════════════════════════╝
           │ Eventos
╔══════════╪═══════════════════════════════════════════════════════════╗
║          ▼         CAPA DE MENSAJERÍA                               ║
║   ┌─────────────┐                                                   ║
║   │   Redpanda  │  Bus de eventos Kafka-compatible. Desacopla       ║
║   │   (Kafka)   │  productores de consumidores                      ║
║   └──────┬──────┘                                                   ║
╚══════════╪═══════════════════════════════════════════════════════════╝
           │ Kafka Engine
╔══════════╪═══════════════════════════════════════════════════════════╗
║          ▼         CAPA DE ALMACENAMIENTO ANALÍTICO                 ║
║   ┌─────────────────────────────────────────────────┐              ║
║   │                  ClickHouse                      │              ║
║   │                                                  │              ║
║   │  ┌─────────────┐   MV    ┌──────────────────┐  │              ║
║   │  │ Kafka Tables│ ──────► │ ReplacingMerge   │  │              ║
║   │  │ (entrada)   │         │ Tree (físicas)   │  │              ║
║   │  └─────────────┘         └────────┬─────────┘  │              ║
║   │                                   │ Views       │              ║
║   │                          ┌────────▼─────────┐  │              ║
║   │                          │   vw_* (vistas   │  │              ║
║   │                          │   limpias)       │  │              ║
║   │                          └──────────────────┘  │              ║
║   └─────────────────────────────────────────────────┘              ║
╚══════════════════════════════════════════════════════════════════════╝
           │
╔══════════╪═══════════════════════════════════════════════════════════╗
║          ▼         CAPA DE CONSULTA FEDERADA (Fase 6)               ║
║   ┌─────────────┐                                                   ║
║   │    Trino    │  Permite hacer JOINs entre PostgreSQL y           ║
║   │  (federado) │  ClickHouse en una sola consulta SQL              ║
║   └──────┬──────┘                                                   ║
╚══════════╪═══════════════════════════════════════════════════════════╝
           │
╔══════════╪═══════════════════════════════════════════════════════════╗
║          ▼         CAPA DE VISUALIZACIÓN Y ALERTAS                  ║
║   ┌─────────────────────────────────────────────────┐              ║
║   │                  Apache Superset                 │              ║
║   │                                                  │              ║
║   │  7 Dashboards ejecutivos                         │              ║
║   │  Alertas y reportes programados (Fase 5)         │              ║
║   │  IA y lenguaje natural (Fase 9)                  │              ║
║   └──────────────────────┬──────────────────────────┘              ║
║                          │ Caché / Broker                           ║
║                   ┌──────▼──────┐                                  ║
║                   │    Redis    │                                   ║
║                   └─────────────┘                                  ║
╚══════════════════════════════════════════════════════════════════════╝
           │
╔══════════╪═══════════════════════════════════════════════════════════╗
║          ▼         CAPA DE MONITOREO                                ║
║   ┌─────────────────────────────────────────────────┐              ║
║   │  Cron Jobs + monitor_pipeline.sh                 │              ║
║   │  Verifica: Debezium, Redpanda, ClickHouse        │              ║
║   │  Logs en /var/log/pipeline_monitor.log           │              ║
║   └─────────────────────────────────────────────────┘              ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

## 🚀 Fases del proyecto

### ✅ Fase 1 — Infraestructura base
- Docker Compose con PostgreSQL, Redpanda, Debezium, ClickHouse, Redis y Superset
- Healthchecks, límites de memoria en ClickHouse (`limits.xml`)
- Variables de entorno centralizadas en `.env`
- Volúmenes persistentes para datos y configuración

### ✅ Fase 2 — Modelo de datos
- Tablas en PostgreSQL: `dim_clientes`, `dim_productos`, `dim_empleados`, `fact_ventas`, `fact_operaciones`, `fact_presupuesto`
- Tablas en ClickHouse con motor `ReplacingMergeTree`
- Tablas Kafka Engine (colas de entrada por tabla)
- Materialized Views para mover datos de Kafka a tablas físicas
- Vistas limpias `vw_*` para consumo desde Superset
- Vista de calidad de datos `vw_calidad_datos`

### ✅ Fase 3 — Pipeline CDC
- Conector Debezium apuntando a PostgreSQL
- Tópicos en Redpanda por tabla (`analytics.analytics.*`)
- Flujo activo: PostgreSQL → Debezium → Redpanda → ClickHouse

### ✅ Fase 4 — Dashboards ejecutivos
- 7 dashboards en Apache Superset
- Importación automática al levantar el stack vía `init.sh`
- Filtros interactivos por fecha, área, estatus y más
- Datasets registrados desde vistas de ClickHouse

### 🔄 Fase 5 — Automatización avanzada *(en curso)*
- Alertas nativas de Superset con condiciones sobre métricas
- Reportes programados enviados por email (SMTP + Celery + Redis)
- Script `monitor_pipeline.sh` para verificar estado del pipeline
- Cron jobs para monitoreo continuo cada hora

### 🔜 Fase 6 — Consultas federadas con Trino
- Trino como motor SQL federado entre PostgreSQL y ClickHouse
- Catálogos configurados: `postgres.properties` y `clickhouse.properties`
- Conexión de Superset a Trino para dashboards con datos cruzados
- Caso de uso: cruzar datos transaccionales (PG) con analíticos (CH) en una sola consulta

### 🔜 Fase 7 — Calidad de datos avanzada
- Validaciones estrictas en `vw_calidad_datos`: nulos, duplicados, rangos inválidos
- Alertas automáticas al degradarse la calidad por debajo de umbral
- Historial de calidad por dominio y fecha

### 🔜 Fase 8 — Seguridad y multitenancy
- Roles y permisos por usuario en Superset
- Row Level Security: cada área ve solo sus datos
- Cifrado de conexiones entre servicios (TLS)
- Gestión de secretos con variables de entorno seguras

### 🔜 Fase 9 — IA en Superset
- Integración de modelos LLM para consultas en lenguaje natural sobre los dashboards
- Exploración de datos asistida por IA ("¿Cuál fue el mejor mes de ventas?")
- Generación automática de resúmenes e insights desde Superset

---

## 🗂️ Estructura del repositorio

```
data-platform/
│
├── docker-compose.yml              # Orquestación completa del stack
├── .env                            # Variables de entorno (no subir a Git)
├── Dockerfile.superset             # Imagen personalizada de Superset
├── Dockerfile.init                 # Contenedor de inicialización
│
├── postgres/
│   └── init/                       # Scripts SQL de inicialización de PostgreSQL
│
├── clickhouse/
│   └── config.d/
│       └── limits.xml              # Límites de memoria de ClickHouse
│
├── sql/
│   ├── 01_postgres_dummy.sql       # Tablas y datos dummy en PostgreSQL
│   └── 02_clickhouse_dummy.sql     # Tablas, MVs y vistas en ClickHouse
│
├── sh/
│   ├── 03_debezium_connectors.sh   # Registro de conectores Debezium
│   └── monitor_pipeline.sh         # Monitoreo del pipeline (Fase 5)
│
├── superset/
│   ├── superset_config.py          # Configuración de Superset (Celery, SMTP, flags)
│   ├── init.sh                     # Script de inicialización y carga de dashboards
│   └── exports/                    # ZIPs de dashboards exportados
│       ├── reporte_ejecutivo.zip
│       ├── Ventas_comercial.zip
│       ├── operaciones.zip
│       ├── presupuesto.zip
│       ├── calidad_datos.zip
│       ├── recursos_humanos.zip
│       └── tendencias_proyecciones.zip
│
└── trino/                          # Fase 6 — Consultas federadas
    └── catalog/
        ├── postgres.properties
        └── clickhouse.properties
```

---

## 🛠️ Stack tecnológico

| Componente | Tecnología | Versión | Fase |
|---|---|---|---|
| Base de datos fuente | PostgreSQL | 16 | ✅ Activo |
| Mensajería / Streaming | Redpanda (Kafka) | v23.3.10 | ✅ Activo |
| Change Data Capture | Debezium | 2.5 | ✅ Activo |
| Almacén analítico | ClickHouse | 26.3.9.8 | ✅ Activo |
| Caché y broker | Redis | 7 | ✅ Activo |
| Visualización BI | Apache Superset | 6.0.0 | ✅ Activo |
| Consultas federadas | Trino | latest | 🔜 Fase 6 |
| Orquestación | Docker Compose | — | ✅ Activo |

---

## ⚡ Cómo levantar el stack

```bash
git clone <repo>
cd data-platform
docker compose up -d --build
docker logs -f platform_init
```

| Servicio | URL |
|---|---|
| Superset | http://localhost:8088 |
| ClickHouse | http://localhost:18123 |
| Debezium | http://localhost:8083 |
| Redpanda | localhost:9092 |
| Trino (Fase 6) | http://localhost:8080 |
