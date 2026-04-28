#!/bin/bash
set -euo pipefail

DEBEZIUM_URL="http://debezium:8083"

echo "🚀 Registrando conectores Debezium para tablas dummy..."

until curl -fsS "${DEBEZIUM_URL}/" > /dev/null 2>&1; do
  echo "⏳ Esperando Debezium..."
  sleep 3
done
echo "✅ Debezium disponible"

upsert_connector () {
  local name="$1"
  local table="$2"
  local slot="$3"

  config=$(cat <<EOF
{
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
EOF
)

  http_status=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT "${DEBEZIUM_URL}/connectors/${name}/config" \
    -H "Content-Type: application/json" \
    --data "${config}")

  if [ "$http_status" -eq 200 ] || [ "$http_status" -eq 201 ]; then
    echo "✅ ${name} → HTTP ${http_status} (creado/actualizado)"
  else
    echo "⚠️  ${name} → HTTP ${http_status} (revisar logs de Debezium)"
  fi
}

upsert_connector "analytics-dim-clientes"     "analytics.dim_clientes"     "analytics_dim_clientes"
upsert_connector "analytics-dim-productos"    "analytics.dim_productos"    "analytics_dim_productos"
upsert_connector "analytics-dim-empleados"    "analytics.dim_empleados"    "analytics_dim_empleados"
upsert_connector "analytics-fact-ventas"      "analytics.fact_ventas"      "analytics_fact_ventas"
upsert_connector "analytics-fact-operaciones" "analytics.fact_operaciones" "analytics_fact_operaciones"
upsert_connector "analytics-fact-presupuesto" "analytics.fact_presupuesto" "analytics_fact_presupuesto"
upsert_connector "analytics-user-region-mapping" "analytics.user_region_mapping" "analytics_user_region_mapping"

echo ""
echo "⏳ Esperando 15 segundos para que los topics se creen..."
sleep 15

echo ""
echo "📋 Estado de conectores:"
curl -fsS "${DEBEZIUM_URL}/connectors"
echo ""
