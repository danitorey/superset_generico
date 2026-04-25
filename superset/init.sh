#!/bin/sh
set -e

echo "===> Migraciones de base de datos"
superset db upgrade

echo "===> Creando usuario admin"
superset fab create-admin \
  --username "$SUPERSET_ADMIN_USER" \
  --password "$SUPERSET_ADMIN_PASSWORD" \
  --firstname Admin \
  --lastname User \
  --email "$SUPERSET_ADMIN_EMAIL" || true

echo "===> Inicializando Superset"
superset init

echo "===> Creando conexión ClickHouse via API..."
python /app/create_clickhouse_connection.py || true

echo "===> Importando dashboards, alertas y reportes..."
bash /app/import_all_final.sh || true

echo "===> Superset corriendo..."
exec superset run -h 0.0.0.0 -p 8088 --with-threads
