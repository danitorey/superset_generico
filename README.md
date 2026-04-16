# Data Platform – OLTP → CDC → OLAP → BI

Plataforma de datos end-to-end lista para usar que habilita ingestión en tiempo real, analítica de alto rendimiento y visualización self-service, desplegable con un solo comando.

Arquitectura completa:
PostgreSQL (OLTP) → Debezium (CDC) → Redpanda (Kafka) → ClickHouse (OLAP) → Superset (BI)

---

## 🚀 Características Clave

- CDC en tiempo real (no batch)
- Arquitectura event-driven
- ClickHouse append-only para máximo performance
- BI self-service con Superset
- Cache distribuido con Redis
- Infraestructura como código (Docker)
- Reproducible y portable

---

## 🏗️ Arquitectura

PostgreSQL (OLTP)
→ Debezium (CDC)
→ Redpanda (Kafka)
→ ClickHouse (OLAP)
→ Superset (BI)

---

## 📋 Requisitos

- Docker 20.10+
- Docker Compose 2.0+
- 8 GB RAM mínimo (16 GB recomendado)

---

## ⚡ Instalación Rápida

```bash
git clone <tu-repositorio>
cd data-platform
docker compose up -d
```

Superset: http://localhost:8088  
Usuario: admin / admin

---

## ✅ Validación

```bash
docker exec -it superset python -c "import clickhouse_connect; print('ClickHouse OK')"
docker exec -it superset python -c "import psycopg2; print('PostgreSQL OK')"
```

---

✅ Plataforma lista para desarrollo, demo o pruebas de concepto.
