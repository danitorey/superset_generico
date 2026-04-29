# 🏗️ Plataforma de Datos OLTP → CDC → OLAP → BI

> **Stack:** PostgreSQL 16 · Debezium 2.5 · Redpanda (Kafka-compatible) · ClickHouse · Cube · Trino · Apache Superset 6.0 · Redis · Docker Compose

---

## 1. Objetivo

Diseñar e implementar una plataforma de datos moderna que permita:

- Replicar datos desde PostgreSQL (OLTP) en tiempo casi real mediante CDC
- Desacoplar completamente la carga analítica del sistema transaccional
- Acelerar consultas analíticas con ClickHouse (OLAP columnar)
- Visualizar información con Apache Superset de forma segura y cacheada con Redis
- Garantizar reproducibilidad y portabilidad completa mediante Docker Compose

---

## 2. Diagrama de Arquitectura (Mermaid)

flowchart TB
    subgraph ORIGEN["📦 Origen de Datos (OLTP)"]
        PG[("PostgreSQL 16
        6 tablas analíticas")]
    end

    subgraph CDC["🔄 Captura de Cambios (CDC)"]
        DEB[Debezium Connect 2.5
        Conectores por tabla]
    end

    subgraph STREAMING["📨 Streaming / Mensajería"]
        RP[Redpanda
        Kafka-compatible
        Topics por tabla]
    end

    subgraph OLAP["⚡ Almacén Analítico (OLAP)"]
        CH[("ClickHouse
        Columnar
        Base analítica")]
    end

    subgraph FEDERATION["🔗 Federación de Datos"]
        TR[("Trino
        Consultas multi-fuente")]
    end

    subgraph SEMANTIC["🧠 Capa Semántica"]
        CB[Cube
        Métricas centralizadas
        RLS dinámico]
    end

    subgraph CACHE["💨 Capa de Caché"]
        RD[("Redis
        Cache de queries")]
    end

    subgraph BI["📊 Capa de Visualización (BI)"]
        SUP[Apache Superset
        Dashboards BI]
    end

    subgraph USERS["👥 Usuarios Finales"]
        USER[("Analistas / Gerencia")]
    end

    PG -->|WAL| DEB
    DEB -->|Eventos JSON CDC| RP
    RP -->|Consumo por tabla| CH
    
    CH -->|Datos analíticos| TR
    TR -->|Unificar datos| CB
    
    CB -->|Métricas + RLS| SUP
    RD -->|Cache de resultados| SUP
    SUP -->|Dashboards / Reportes| USER

## 3. Diagrama de Flujo de Datos (Secuencia completa)

```mermaid
flowchart LR
    START([Inicio: App escribe en PostgreSQL]) --> TRIGGER[PostgreSQL WAL genera cambios]
    TRIGGER --> DEBEZIUM[Debezium captura CDC
por cada tabla]
    DEBEZIUM --> TOPIC{¿Qué tabla?}
    
    TOPIC -->|dim_clientes| T1[Topic: dim_clientes]
    TOPIC -->|dim_productos| T2[Topic: dim_productos]
    TOPIC -->|dim_empleados| T3[Topic: dim_empleados]
    TOPIC -->|fact_ventas| T4[Topic: fact_ventas]
    TOPIC -->|fact_operaciones| T5[Topic: fact_operaciones]
    TOPIC -->|fact_presupuesto| T6[Topic: fact_presupuesto]
    
    T1 --> CH
    T2 --> CH
    T3 --> CH
    T4 --> CH
    T5 --> CH
    T6 --> CH
    
    CH --> QUERY[Usuario ejecuta consulta
en Superset]
    QUERY --> CACHE{¿En Redis?}
    CACHE -->|Sí| FAST[Retorna desde caché]
    CACHE -->|No| SLOW[Consulta ClickHouse
Guarda en caché]
    SLOW --> FAST
    FAST --> DASH[Dashboard visualiza]
    DASH --> END([Fin: Insights para negocio])
```

## 4. Diagrama de Flujo de Inicialización (Docker Compose)

```mermaid
flowchart TD
    A[docker compose up -d] --> B[PostgreSQL inicia
+ datos dummy]
    A --> C[Redpanda inicia]
    A --> D[ClickHouse inicia]
    A --> E[Redis inicia]
    A --> F[Debezium inicia]
    A --> G[Superset inicia]

    B --> H[platform_init espera]
    C --> H
    D --> H
    E --> H
    F --> H
    G --> H

    H --> I{¿Servicios OK?}
    I -->|No| H
    I -->|Sí| J[Inicialización completada]
```

## 5. Diagrama de Flujo de Datos (Vista por tabla)

```mermaid
flowchart TB
    subgraph PG[PostgreSQL - Schema analytics]
        P1[(dim_clientes)]
        P2[(dim_productos)]
        P3[(dim_empleados)]
        P4[(fact_ventas)]
        P5[(fact_operaciones)]
        P6[(fact_presupuesto)]
    end

    subgraph DEB[Debezium Connectors]
        C1[connector-clientes]
        C2[connector-productos]
        C3[connector-empleados]
        C4[connector-ventas]
        C5[connector-operaciones]
        C6[connector-presupuesto]
    end

    subgraph RP[Redpanda Topics]
        R1[topic: dim_clientes]
        R2[topic: dim_productos]
        R3[topic: dim_empleados]
        R4[topic: fact_ventas]
        R5[topic: fact_operaciones]
        R6[topic: fact_presupuesto]
    end

    subgraph CH[ClickHouse Tables]
        H1[dim_clientes]
        H2[dim_productos]
        H3[dim_empleados]
        H4[fact_ventas]
        H5[fact_operaciones]
        H6[fact_presupuesto]
    end

    P1 --> C1 --> R1 --> H1
    P2 --> C2 --> R2 --> H2
    P3 --> C3 --> R3 --> H3
    P4 --> C4 --> R4 --> H4
    P5 --> C5 --> R5 --> H5
    P6 --> C6 --> R6 --> H6
```

## 6. Tabla de Fases del Proyecto

| # | Fase | Descripción | Estado |
|---|------|-------------|--------|
| 1 | Infraestructura base | Docker Compose con PostgreSQL, Redpanda, Debezium, ClickHouse, Redis, Superset | ✅ Completado |
| 2 | CDC con Debezium | Replicación lógica de 6 tablas del schema analytics | ✅ Completado |
| 3 | Datos dummy | Tablas y datos de prueba end-to-end | ✅ Completado |
| 4 | Conexión ClickHouse → Superset | Script automático vía API REST | ✅ Completado |
| 5 | Dashboards BI | 7 dashboards importados automáticamente | ✅ Completado |
| 6 | Init automatizado | Orquestación completa | ✅ Completado |
| 7 | Alertas y correos | Superset Alerts & Reports con SMTP | ✅ Completado |
| 8 | Semantic Layer con Cube | Métricas centralizadas, RLS dinámico sin multiplicar conexiones | ⬜ Pendiente |
| 9 | Federación con Trino | Consultas multi-fuente (ClickHouse + otras bases) | ⬜ Pendiente |
|10 | Dashboard de monitoreo | Salud de la plataforma | ⬜ Pendiente |
|11 | Authentik (SSO/IdP) | OIDC / SAML para Superset | ⬜ Pendiente |
|12 | API Gateway | Traefik o Nginx | ⬜ Pendiente |
|13 | Hardening producción | Seguridad y backups | ⬜ Pendiente |
|14 | Observabilidad | Prometheus + Grafana | ⬜ Futuro |

## 7. Servicios del Stack

| Servicio | Imagen | Puerto | Rol |
|--------|--------|--------|-----|
| postgres | postgres:16 | 5432 | Fuente OLTP, WAL lógico |
| redpanda | redpandadata/redpanda:v23.3.10 | 9092 | Broker Kafka-compatible |
| debezium | debezium/connect:2.5 | 8083 | CDC connector |
| clickhouse | clickhouse/clickhouse-server | 8123 / 9000 | OLAP columnar |
| cube | cubejs/cube:latest | 4000 / 3000 | Semantic layer (métricas + RLS) |
| trino | trinodb/trino:latest | 8080 | Federación multi-fuente |
| redis | redis:7 | 6379 | Cache Superset |
| superset | apache/superset:6.0.0 | 8088 | BI |
| platform_init | custom | — | Orquestador |

## 8. Conectores Debezium activos
```text
analytics-dim-clientes      → topic: analytics.analytics.dim_clientes
analytics-dim-productos     → topic: analytics.analytics.dim_productos
analytics-dim-empleados     → topic: analytics.analytics.dim_empleados
analytics-fact-ventas       → topic: analytics.analytics.fact_ventas
analytics-fact-operaciones  → topic: analytics.analytics.fact_operaciones
analytics-fact-presupuesto  → topic: analytics.analytics.fact_presupuesto
```

## 9. Dashboards importados en Superset

| Dashboard | Archivo ZIP |
|----------|-------------|
| Ventas | dashboard_ventas.zip |
| Operaciones | dashboard_operaciones.zip |
| Clientes | dashboard_clientes.zip |
| Productos | dashboard_productos.zip |
| Empleados | dashboard_empleados.zip |
| Presupuesto | dashboard_presupuesto.zip |
| Analytics General | dashboard_analytics_general.zip |

## 10. Estructura de Directorios
```text
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

## 11. Comandos de operación

🔄 Ciclo completo (bajar → limpiar → levantar)
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

📋 Verificación rápida
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

🧹 Limpieza selectiva (sin bajar todo)
```bash
# Solo reiniciar el init (para re-importar dashboards)
docker compose restart platform_init

# Solo reiniciar Superset
docker compose restart superset
```

## 12. Diagrama de Flujo de Alertas (Fase 7)

```mermaid
flowchart TD
    A[Usuario configura Alerta
en UI de Superset] --> B[Alerta guardada
en PostgreSQL]
    B --> C[Celery Beat
cada minuto revisa schedule]
    C --> D{¿Condición
de alerta?}
    
    D -->|No se cumple| C
    D -->|Se cumple| E[Celery Worker
ejecuta SQL]
    
    E --> F{¿Resultado
supera umbral?}
    F -->|No| C
    F -->|Sí| G[Superset genera
alerta/reporte]
    
    G --> H[SMTP envía correo
a destinatarios]
    H --> I[Email con:
• Gráfico embedido
• Enlace al dashboard
• Resumen ejecutivo]
    
    I --> J[📧 Usuario recibe
alerta en su correo]
    J --> C
```

## 13. Variables de entorno (.env)

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

## 14. Requisitos de infraestructura

| Entorno              | CPU      | RAM   | Disco                     |
|----------------------|----------|-------|---------------------------|
| Dev / pruebas        | 4 cores  | 8 GB  | 50 GB SSD                |
| QA / pre-prod        | 8 cores  | 16 GB | 100 GB SSD               |
| Producción inicial   | 16 cores | 32 GB | 300 GB SSD (IOPS altos)  |

## 15. Troubleshooting rápido

| Síntoma                              | Causa probable                                      | Solución                                                         |
|-------------------------------------|----------------------------------------------------|------------------------------------------------------------------|
| platform_init termina con error     | Superset no listo aún                               | Aumentar `sleep` en el `until` del `init.sh`                    |
| Dashboards no importan              | ZIPs no encontrados o mal nombrados                | `ls superset/exports/` y verificar nombres exactos              |
| ClickHouse 409 en conexión          | Conexión ya existe                                 | Normal, ignorar                                                 |
| Debezium 404 al registrar           | Debezium aún arrancando                            | El script reintenta automáticamente                             |
| Superset sin charts                 | UUID del dashboard no coincide con datasource      | Re-exportar desde Superset con datos correctos                  |
| Celery worker no procesa alertas    | Redis no conectado o celery no arranca             | `docker logs superset_worker`                                   |


## 16. Evolución de la Plataforma

### 🔐 El desafío del RLS (Row Level Security)

En la arquitectura actual, ClickHouse aplica el RLS según el **usuario de conexión** a la base de datos. Para que diferentes usuarios de Superset vean diferentes regiones (NORTE, SUR, ESTE, OESTE), se requeriría:

- Crear un usuario en ClickHouse por cada rol (ej. `analista_norte`, `analista_sur`)
- Crear una conexión independiente en Superset por cada usuario
- Esto **no escala**: 5 roles hoy, 50 mañana → 50 conexiones

### ✅ Solución propuesta: Cube como Semantic Layer

[Cube](https://cube.dev) se posiciona entre ClickHouse y Superset como una **capa semántica** que:

- **Centraliza métricas**: Definimos "Ventas totales" una sola vez, se usa en todos los dashboards
- **Aplica RLS dinámico**: Filtra por usuario SIN multiplicar conexiones ni usuarios en DB
- **Cache inteligente**: Consultas repetitivas se sirven desde cache, reduciendo carga en ClickHouse
- **Consistencia**: El mismo cálculo en todos los dashboards

### 🌐 Federación con Trino

[Trino](https://trino.io) permite consultar **múltiples fuentes de datos** con una sola consulta SQL:

- ClickHouse (datos analíticos rápidos)
- PostgreSQL (datos transaccionales)
- Otras bases (MySQL, MongoDB, etc.)

Ideal para:
- Dashboards que cruzan datos de ventas (ClickHouse) con inventario (PostgreSQL)
- Reportes ejecutivos que necesitan información consolidada de diferentes sistemas

### 🎯 Nueva Arquitectura

ClickHouse (rápido) ─┐
├─→ Trino (federación) → Cube (métricas + RLS) → Superset
PostgreSQL (transaccional) ─┘

**Beneficios:**
- Una sola conexión de Superset a Cube
- RLS dinámico sin multiplicar usuarios
- Consultas multi-fuente con Trino
- Métricas centralizadas y consistentes

## 17. Diagrama de Flujo con Semantic Layer (Cube + Trino)

```mermaid
flowchart LR
    CH[("ClickHouse
    Datos analíticos")]
    
    PG[("PostgreSQL
    Datos transaccionales")]
    
    TRINO[("Trino
    Federación multi-fuente")]
    
    CUBE[("Cube
    Métricas + RLS")]

    SUP[("Superset
    Dashboards")]

    USER[("👤 Usuario
    analista_norte")]

    CH -->|consulta| TRINO
    PG -->|consulta| TRINO
    TRINO -->|datos unificados| CUBE
    
    USER -->|login: norte@empresa.com| SUP
    SUP -->|solicita dashboard| CUBE
    CUBE -->|aplica filtro region='NORTE'| TRINO
    CUBE -->|devuelve datos filtrados| SUP
    SUP -->|visualiza| USER

## ## Flujo completo resumido (visión 30 segundos)

```mermaid
flowchart LR
    START((🗄️ PostgreSQL\n6 tablas\nCDC activado))
    START -->|WAL| CDC((🔄 Debezium\n2.5 Connect))
    CDC -->|eventos| KAFKA((📨 Redpanda\ntopics por tabla))
    KAFKA -->|consumo| CH((⚡ ClickHouse\nOLAP columnar))
    CH -->|SQL| BI((📊 Superset\nDashboards + cache))
    BI -->|email| ALERT((📧 Alertas\nnotificaciones))
    BI -->|visualización| USER((👤 Usuarios\ninsights de negocio))

📌 Notas importantes

Todos los dashboards se importan automáticamente al primer inicio

El platform_init ejecuta la lógica solo una vez y luego se detiene (exit code 0)

Redis acelera las consultas repetitivas de Superset

ClickHouse ofrece compresión y velocidad para agregaciones complejas

El CDC es asíncrono → no afecta rendimiento del OLTP

🚀 Quick start (una vez clonado)

```bash
# 1. Clonar
git clone <tu-repo>
cd data-platform

# 2. Configurar .env (copiar ejemplo)
cp .env.example .env

# 3. Levantar todo
docker compose up -d --build

# 4. Ver logs del init
docker logs -f platform_init

# 5. Abrir Superset
http://localhost:8088
# Usuario: admin / Contraseña: admin
```

```markdown
## 🔄 Próximos pasos

### 🔐 RLS Dinámico con Cube
- **Problema actual:** ClickHouse requiere un usuario por rol para aplicar RLS
- **Solución:** Cube como capa intermedia que filtra por usuario sin multiplicar conexiones
- **Beneficio:** Una sola conexión, escalable a cientos de usuarios

### 🌐 Federación con Trino
- **Caso de uso:** Dashboards que necesitan datos de ClickHouse + PostgreSQL + otras fuentes
- **Ventaja:** Una sola consulta SQL unifica datos de múltiples sistemas



