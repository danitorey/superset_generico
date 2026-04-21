#!/bin/bash

DEBEZIUM_URL="http://localhost:8083/connectors"

echo "🔌 Registrando conectores Debezium para tablas dummy..."

for TABLA in dim_clientes dim_productos dim_empleados fact_ventas fact_operaciones fact_presupuesto; do
  NOMBRE="analytics-${TABLA//_/-}"

  # Elimina si ya existe para evitar conflictos al reiniciar
  curl -s -X DELETE $DEBEZIUM_URL/$NOMBRE > /dev/null 2>&1
  sleep 2

  curl -s -X POST $DEBEZIUM_URL \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"$NOMBRE\",
      \"config\": {
        \"connector.class\": \"io.debezium.connector.postgresql.PostgresConnector\",
        \"database.hostname\": \"postgres\",
        \"database.port\": \"5432\",
        \"database.user\": \"postgres\",
        \"database.password\": \"postgres123\",
        \"database.dbname\": \"postgres\",
        \"database.server.name\": \"analytics\",
        \"topic.prefix\": \"analytics\",
        \"schema.include.list\": \"analytics\",
        \"table.include.list\": \"analytics.$TABLA\",
        \"plugin.name\": \"pgoutput\",
        \"snapshot.mode\": \"always\",
        \"key.converter\": \"org.apache.kafka.connect.json.JsonConverter\",
        \"value.converter\": \"org.apache.kafka.connect.json.JsonConverter\",
        \"key.converter.schemas.enable\": \"false\",
        \"value.converter.schemas.enable\": \"false\",
        \"transforms\": \"unwrap\",
        \"transforms.unwrap.type\": \"io.debezium.transforms.ExtractNewRecordState\",
        \"transforms.unwrap.drop.tombstones\": \"false\",
        \"transforms.unwrap.delete.handling.mode\": \"rewrite\"
      }
    }" > /dev/null
  echo "  ✅ $NOMBRE registrado"
done

echo ""
echo "⏳ Esperando 15 segundos para verificar topics..."
sleep 15

echo ""
echo "📋 Topics en Redpanda:"
docker exec -it redpanda rpk topic list | grep analytics

echo ""
echo "📋 Estado de conectores:"
curl -s http://localhost:8083/connectors | python3 -m json.tool