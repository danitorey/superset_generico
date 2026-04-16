#!/bin/sh
set -e

echo "===> Running Superset DB migrations"
superset db upgrade

echo "===> Creating admin user if not exists"
superset fab create-admin \
  --username "$SUPERSET_ADMIN_USER" \
  --password "$SUPERSET_ADMIN_PASSWORD" \
  --firstname Admin \
  --lastname User \
  --email "$SUPERSET_ADMIN_EMAIL" \
  || true

echo "===> Initializing Superset"
superset init

echo "===> Starting Superset server"
exec superset run -h 0.0.0.0 -p 8088 --with-threads
