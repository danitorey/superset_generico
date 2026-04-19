# Plataforma de Datos OLTP → CDC → OLAP → BI

## 1. Objetivo
Diseñar e implementar una plataforma de datos moderna que permita:
- Replicar datos desde PostgreSQL (OLTP) en tiempo casi real
- Desacoplar completamente la carga analítica del sistema transaccional
- Acelerar consultas con ClickHouse (OLAP)
- Visualizar información con Superset de forma segura y cacheada
- Garantizar reproducibilidad mediante Docker

---

## 2. Arquitectura General

PostgreSQL → Debezium → Redpanda (Kafka) → ClickHouse → Superset

### Capas
1. **Origen (OLTP)**: PostgreSQL 16
2. **CDC / Transporte**: Debezium Connect
3. **Streaming**: Redpanda (Kafka-compatible)
4. **Analítica (OLAP)**: ClickHouse
5. **Visualización (BI)**: Superset 6.0 + Redis

---

## 3. Diagrama de Arquitectura

Usuarios / Apps
|
v
PostgreSQL (OLTP)
|
| CDC (logical replication)
v
Debezium
|
v
Redpanda (Kafka)
|
v
ClickHouse (OLAP)
|
v
Superset (BI)

---

## 4. Requisitos de Infraestructura

### Mínimos (dev / pruebas)
- CPU: 4 cores
- RAM: 8 GB
- Disco: 50 GB SSD

### Recomendados (QA / pre-prod)
- CPU: 8 cores
- RAM: 16 GB
- Disco: 100 GB SSD

### Producción inicial
- CPU: 16 cores
- RAM: 32 GB
- Disco: 300 GB SSD (IOPS altos)

---

## 5. Estructura de Directorios

data-platform/
│
├── docker-compose.yml
├── Dockerfile.superset
├── .env
├── setup.sh
├── README.md
│
├── postgres/
│ └── init/
│ └── 01_init.sql
│
├── clickhouse/
│ └── init/
│ └── 01_tables.sql
│
├── superset/
│ ├── superset_config.py
│ └── init.sh
│
└── debezium/
└── (conectores se crean vía API)

---

## 6. Instalación

```bash
git clone <repo>
cd data-platform
chmod +x setup.sh
./setup.sh