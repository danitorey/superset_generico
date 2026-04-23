# 🏗️ Data Platform — CASmart

## 🎯 Objetivo

Diseñar e implementar una plataforma de datos moderna, escalable y de bajo costo operativo que permita centralizar información, capturar cambios en tiempo real, almacenar datos analíticos y mostrarlos en dashboards ejecutivos útiles para la toma de decisiones.

La meta es que la solución sirva tanto para un proyecto como SIQROO como para cualquier organización que necesite control operativo, seguimiento de KPIs, calidad de datos, reportes automáticos y crecimiento futuro hacia consultas federadas e inteligencia asistida por IA.

---

## 📊 ¿Para qué sirven los 7 dashboards?

| Dashboard | Uso principal |
|---|---|
| **Resumen Ejecutivo** | Ver en una sola pantalla cómo va el negocio hoy. |
| **Ventas y Comercial** | Saber qué se vende, quién vende más y a qué clientes. |
| **Operaciones** | Monitorear solicitudes, tiempos de atención y cuellos de botella. |
| **Presupuesto** | Comparar lo asignado contra lo ejercido y detectar desvíos. |
| **Calidad de datos** | Identificar registros incompletos o inválidos. |
| **Recursos Humanos** | Entender plantilla, áreas, niveles y antigüedad. |
| **Tendencias y Proyecciones** | Ver evolución histórica y anticipar comportamientos futuros. |

---

## 🗺️ Diagrama de flujo

```text
┌──────────────────────┐
│  Fuentes de datos    │
│  PostgreSQL          │
│  (y futuras fuentes) │
└──────────┬───────────┘
           │ CDC / Cambios
           ▼
┌──────────────────────┐
│      Debezium        │
│  Captura cambios     │
│  en tiempo real      │
└──────────┬───────────┘
           │ Eventos
           ▼
┌──────────────────────┐
│      Redpanda        │
│   Bus tipo Kafka     │
└──────────┬───────────┘
           │ Kafka Engine
           ▼
┌────────────────────────────────────────────┐
│               ClickHouse                    │
│  ┌───────────────┐                          │
│  │ Kafka tables  │  Entrada de eventos      │
│  └──────┬────────┘                          │
│         │ Materialized Views                │
│  ┌──────▼────────┐                          │
│  │ Tablas físicas │  Datos ya procesados    │
│  └──────┬────────┘                          │
│         │ Vistas limpias                    │
│  ┌──────▼────────┐                          │
│  │   vw_*        │  Consumo para Superset  │
│  └────────────────┘                          │
└──────────┬───────────────────────────────────┘
           │
           ▼
┌──────────────────────┐
│     Apache Superset  │
│  Dashboards y filtros│
│  Reportes y alertas  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│     Monitoreo        │
│  logs, cron jobs,    │
│  pipeline health     │
└──────────────────────┘
```

---

## 🧩 Arquitectura por capas

### 1. Capa de fuentes
Origen de los datos: PostgreSQL hoy, y otras bases o sistemas después.

### 2. Capa de ingestión
Debezium captura los cambios sin afectar el sistema fuente.

### 3. Capa de mensajería
Redpanda transporta eventos de forma ordenada y desacoplada.

### 4. Capa analítica
ClickHouse guarda, procesa y sirve la información lista para consulta rápida.

### 5. Capa de consumo
Superset presenta los dashboards, filtros, reportes y visualizaciones.

### 6. Capa de monitoreo
Scripts y logs verifican que el pipeline siga funcionando.

---

## 🚀 Fases del proyecto

| Fase | Estado | Descripción |
|---|---|---|
| **1. Infraestructura base** | ✅ | Docker Compose, servicios, límites y persistencia. |
| **2. Modelo de datos** | ✅ | Tablas, vistas y estructuras en PostgreSQL y ClickHouse. |
| **3. Pipeline CDC** | ✅ | Flujo PostgreSQL → Debezium → Redpanda → ClickHouse. |
| **4. Dashboards** | ✅ | 7 dashboards ejecutivos en Superset. |
| **5. Automatización avanzada** | 🔄 | Alertas, reportes programados y monitoreo del pipeline. |
| **6. Consultas federadas con Trino** | 🔜 | Unir datos de PostgreSQL y ClickHouse en una sola consulta. |
| **7. Calidad de datos avanzada** | 🔜 | Validaciones más estrictas y alertas por degradación. |
| **8. Seguridad y multitenencia** | 🔜 | Roles, permisos y aislamiento por área. |
| **9. IA en Superset** | 🔜 | Preguntas en lenguaje natural e insights automáticos. |

---

## 🧱 Estructura del repositorio

```text
data-platform/
├── docker-compose.yml
├── .env
├── Dockerfile.superset
├── Dockerfile.init
├── README.md
│
├── postgres/
│   └── init/
│
├── clickhouse/
│   └── config.d/
│       └── limits.xml
│
├── sql/
│   ├── 01_postgres_dummy.sql
│   └── 02_clickhouse_dummy.sql
│
├── sh/
│   ├── 03_debezium_connectors.sh
│   └── monitor_pipeline.sh
│
├── superset/
│   ├── superset_config.py
│   ├── init.sh
│   └── exports/
│       ├── reporte_ejecutivo.zip
│       ├── Ventas_comercial.zip
│       ├── operaciones.zip
│       ├── presupuesto.zip
│       ├── calidad_datos.zip
│       ├── recursos_humanos.zip
│       └── tendencias_proyecciones.zip
│
└── trino/
    └── catalog/
        ├── postgres.properties
        └── clickhouse.properties
```

---

## ⚙️ Cómo se levanta

```bash
docker compose down -v --remove-orphans
docker compose up -d --build
docker logs -f platform_init
```

Servicios principales:
- Superset: http://localhost:8088
- ClickHouse: http://localhost:18123
- Debezium: http://localhost:8083

---

## 📥 Importación automática de dashboards

El archivo `superset/init.sh` debe importar uno por uno los 7 ZIPs:

```bash
echo "📊 Importando dashboards..."
superset import-dashboards -p /app/exports/reporte_ejecutivo.zip --username admin
superset import-dashboards -p /app/exports/Ventas_comercial.zip --username admin
superset import-dashboards -p /app/exports/operaciones.zip --username admin
superset import-dashboards -p /app/exports/presupuesto.zip --username admin
superset import-dashboards -p /app/exports/calidad_datos.zip --username admin
superset import-dashboards -p /app/exports/recursos_humanos.zip --username admin
superset import-dashboards -p /app/exports/tendencias_proyecciones.zip --username admin
echo "✅ Dashboards importados"
```

Y en `docker-compose.yml` se monta la carpeta completa:

```yaml
volumes:
  - ./superset/superset_config.py:/app/pythonpath/superset_config.py
  - ./superset/init.sh:/app/init.sh
  - ./superset/exports:/app/exports:ro
```

---

## 🔮 Evolución futura

- **Trino**: para consultar PostgreSQL y ClickHouse juntos.
- **Alertas y reportes**: notificaciones automáticas por cambios de KPI.
- **Monitoreo del pipeline**: validar que la cadena de datos siga viva.
- **IA en Superset**: consultas y resúmenes en lenguaje natural.

---

## 📝 Nota

Esta plataforma está pensada para crecer por etapas. Primero se consolida la base operativa y analítica, luego se agrega automatización, después consultas federadas y finalmente capacidades de inteligencia asistida.
