#!/bin/bash
set -euo pipefail

DEBEZIUM_URL="http://debezium:8083"
CONNECTORS_URL="${DEBEZIUM_URL}/connectors"

echo "🚀 Registrando conectores Debezium para tablas dummy..."

until curl -fsS "${DEBEZIUM_URL}/"; do
  echo "⏳ Esperando Debezium..."
  sleep 3
done

create_connector () {
  local name="$1"
  local table="$2"
  local slot="$3"

  payload=$(cat <<EOF
{
  "name": "${name}",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "postgres",
    "database.port": "5432",
    "database.user": "postgres",
    "database.password": "postgres123",
    "database.dbname": "postgres",
    "topic.prefix": "analytics",
    "schema.include.list": "analytics",
    "table.include.list": "${table}",
    "plugin.name": "pgoutput",
    "slot.name": "${slot}",
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
}
EOF
)

  curl -fsS -X POST "${CONNECTORS_URL}" \
    -H "Content-Type: application/json" \
    --data "${payload}"

  echo ""
  echo "✅ ${name} registrado"
}

create_connector "analytics-dim-clientes" "analytics.dim_clientes" "analytics_dim_clientes"
create_connector "analytics-dim-productos" "analytics.dim_productos" "analytics_dim_productos"
create_connector "analytics-dim-empleados" "analytics.dim_empleados" "analytics_dim_empleados"
create_connector "analytics-fact-ventas" "analytics.fact_ventas" "analytics_fact_ventas"
create_connector "analytics-fact-operaciones" "analytics.fact_operaciones" "analytics_fact_operaciones"
create_connector "analytics-fact-presupuesto" "analytics.fact_presupuesto" "analytics_fact_presupuesto"

echo ""
echo "⏳ Esperando 15 segundos para que los topics se creen..."
sleep 15

echo ""
echo "📋 Estado de conectores:"
curl -fsS "${CONNECTORS_URL}"
