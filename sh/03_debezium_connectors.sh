#!/bin/bash
DEBEZIUM_URL="http://localhost:8083/connectors"

echo "🚀 Registrando conectores Debezium para tablas dummy..."

# ---- 1. dim_clientes ----
curl -s -X POST $DEBEZIUM_URL \
  -H "Content-Type: application/json" \
  -d '{
    "name": "analytics-dim-clientes",
    "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "database.hostname": "postgres",
      "database.port": "5432",
      "database.user": "postgres",
      "database.password": "postgres123",
      "database.dbname": "postgres",
      "database.server.name": "analytics",
      "topic.prefix": "analytics",
      "schema.include.list": "analytics",
      "table.include.list": "analytics.dim_clientes",
      "plugin.name": "pgoutput",
      "slot.name": "analytics_dim_clientes",
      "snapshot.mode": "always",
      "decimal.handling.mode": "string",
      "key.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "key.converter.schemas.enable": "false",
      "value.converter.schemas.enable": "false",
      "transforms": "unwrap",
      "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
      "transforms.unwrap.drop.tombstones": "false",
      "transforms.unwrap.delete.handling.mode": "rewrite"
    }
  }'
echo ""
echo "✅ analytics-dim-clientes registrado"

# ---- 2. dim_productos ----
curl -s -X POST $DEBEZIUM_URL \
  -H "Content-Type: application/json" \
  -d '{
    "name": "analytics-dim-productos",
    "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "database.hostname": "postgres",
      "database.port": "5432",
      "database.user": "postgres",
      "database.password": "postgres123",
      "database.dbname": "postgres",
      "database.server.name": "analytics",
      "topic.prefix": "analytics",
      "schema.include.list": "analytics",
      "table.include.list": "analytics.dim_productos",
      "plugin.name": "pgoutput",
      "slot.name": "analytics_dim_productos",
      "snapshot.mode": "always",
      "decimal.handling.mode": "string",
      "key.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "key.converter.schemas.enable": "false",
      "value.converter.schemas.enable": "false",
      "transforms": "unwrap",
      "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
      "transforms.unwrap.drop.tombstones": "false",
      "transforms.unwrap.delete.handling.mode": "rewrite"
    }
  }'
echo ""
echo "✅ analytics-dim-productos registrado"

# ---- 3. dim_empleados ----
curl -s -X POST $DEBEZIUM_URL \
  -H "Content-Type: application/json" \
  -d '{
    "name": "analytics-dim-empleados",
    "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "database.hostname": "postgres",
      "database.port": "5432",
      "database.user": "postgres",
      "database.password": "postgres123",
      "database.dbname": "postgres",
      "database.server.name": "analytics",
      "topic.prefix": "analytics",
      "schema.include.list": "analytics",
      "table.include.list": "analytics.dim_empleados",
      "plugin.name": "pgoutput",
      "slot.name": "analytics_dim_empleados",
      "snapshot.mode": "always",
      "decimal.handling.mode": "string",
      "key.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "key.converter.schemas.enable": "false",
      "value.converter.schemas.enable": "false",
      "transforms": "unwrap",
      "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
      "transforms.unwrap.drop.tombstones": "false",
      "transforms.unwrap.delete.handling.mode": "rewrite"
    }
  }'
echo ""
echo "✅ analytics-dim-empleados registrado"

# ---- 4. fact_ventas ----
curl -s -X POST $DEBEZIUM_URL \
  -H "Content-Type: application/json" \
  -d '{
    "name": "analytics-fact-ventas",
    "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "database.hostname": "postgres",
      "database.port": "5432",
      "database.user": "postgres",
      "database.password": "postgres123",
      "database.dbname": "postgres",
      "database.server.name": "analytics",
      "topic.prefix": "analytics",
      "schema.include.list": "analytics",
      "table.include.list": "analytics.fact_ventas",
      "plugin.name": "pgoutput",
      "slot.name": "analytics_fact_ventas",
      "snapshot.mode": "always",
      "decimal.handling.mode": "string",
      "key.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "key.converter.schemas.enable": "false",
      "value.converter.schemas.enable": "false",
      "transforms": "unwrap",
      "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
      "transforms.unwrap.drop.tombstones": "false",
      "transforms.unwrap.delete.handling.mode": "rewrite"
    }
  }'
echo ""
echo "✅ analytics-fact-ventas registrado"

# ---- 5. fact_operaciones ----
curl -s -X POST $DEBEZIUM_URL \
  -H "Content-Type: application/json" \
  -d '{
    "name": "analytics-fact-operaciones",
    "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "database.hostname": "postgres",
      "database.port": "5432",
      "database.user": "postgres",
      "database.password": "postgres123",
      "database.dbname": "postgres",
      "database.server.name": "analytics",
      "topic.prefix": "analytics",
      "schema.include.list": "analytics",
      "table.include.list": "analytics.fact_operaciones",
      "plugin.name": "pgoutput",
      "slot.name": "analytics_fact_operaciones",
      "snapshot.mode": "always",
      "decimal.handling.mode": "string",
      "key.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "key.converter.schemas.enable": "false",
      "value.converter.schemas.enable": "false",
      "transforms": "unwrap",
      "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
      "transforms.unwrap.drop.tombstones": "false",
      "transforms.unwrap.delete.handling.mode": "rewrite"
    }
  }'
echo ""
echo "✅ analytics-fact-operaciones registrado"

# ---- 6. fact_presupuesto ----
curl -s -X POST $DEBEZIUM_URL \
  -H "Content-Type: application/json" \
  -d '{
    "name": "analytics-fact-presupuesto",
    "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "database.hostname": "postgres",
      "database.port": "5432",
      "database.user": "postgres",
      "database.password": "postgres123",
      "database.dbname": "postgres",
      "database.server.name": "analytics",
      "topic.prefix": "analytics",
      "schema.include.list": "analytics",
      "table.include.list": "analytics.fact_presupuesto",
      "plugin.name": "pgoutput",
      "slot.name": "analytics_fact_presupuesto",
      "snapshot.mode": "always",
      "decimal.handling.mode": "string",
      "key.converter": "org.apache.kafka.connect.json.JsonConverter",
      "value.converter": "org.apache.kafka.connect.json.JsonConverter",
      "key.converter.schemas.enable": "false",
      "value.converter.schemas.enable": "false",
      "transforms": "unwrap",
      "transforms.unwrap.type": "io.debezium.transforms.ExtractNewRecordState",
      "transforms.unwrap.drop.tombstones": "false",
      "transforms.unwrap.delete.handling.mode": "rewrite"
    }
  }'
echo ""
echo "✅ analytics-fact-presupuesto registrado"

echo ""
echo "⏳ Esperando 15 segundos para que los topics se creen..."
sleep 15

echo ""
echo "📋 Topics creados en Redpanda:"
docker exec redpanda rpk topic list | grep analytics

echo ""
echo "📋 Estado de conectores:"
curl -s http://localhost:8083/connectors | python3 -m json.tool
