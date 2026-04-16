# Data Platform OLTP → CDC → OLAP → BI

## Objetivo
Implementar una plataforma de datos moderna que permita:
- Replicar datos desde PostgreSQL (OLTP) en tiempo casi real
- Acelerar analítica con ClickHouse (OLAP)
- Visualizar información con Superset
- Evitar impacto en sistemas transaccionales

## Arquitectura

PostgreSQL → Debezium → Redpanda (Kafka) → ClickHouse → Superset

### Capas
1. **Origen (OLTP)**: PostgreSQL 16
2. **Transporte (CDC)**: Debezium Connect
3. **Streaming**: Redpanda (Kafka compatible)
4. **Analítica (OLAP)**: ClickHouse
5. **Visualización (BI)**: Superset 6.0 + Redis

## Diagrama

Postgres
   |
   | CDC
   v
Debezium
   |
   v
Redpanda (Kafka)
   |
   v
ClickHouse
   |
   v
Superset

## Tecnologías
- Docker / Docker Compose
- PostgreSQL 16
- Debezium 2.5
- Redpanda
- ClickHouse
- Apache Superset 6.0
- Redis

## Instalación

```bash
git clone <repo>
cd data-platform
docker compose up -d
```

## URLs
- Superset: http://localhost:8088
- Debezium: http://localhost:8083
- ClickHouse: http://localhost:18123

## Principios
- Append-only
- CDC real
- Cache controlado
- Arquitectura desacoplada
