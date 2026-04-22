#!/bin/bash

echo "🚀 Iniciando Data Platform..."

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado"
    exit 1
fi

# Construir y levantar contenedores
docker compose build --no-cache
docker compose up -d

echo "⏳ Esperando que los servicios estén listos..."
sleep 30

# ============================================================
# PostgreSQL — Crear tablas dummy
# ============================================================
echo "📦 Creando tablas dummy en PostgreSQL..."
docker exec -i postgres psql -U postgres -d postgres < sql/01_postgres_dummy.sql
echo "✅ PostgreSQL listo"

# ============================================================
# ClickHouse — Crear estructuras
# ============================================================
echo "🏗️  Creando estructuras en ClickHouse..."
docker exec -i clickhouse clickhouse-client --multiquery < sql/02_clickhouse_dummy.sql
echo "✅ ClickHouse listo"

# ============================================================
# Debezium — Registrar conectores
# ============================================================
echo "🔌 Registrando conectores Debezium..."
sleep 10
bash sh/03_debezium_connectors.sh
echo "✅ Debezium listo"

echo ""
echo "✅ Plataforma iniciada correctamente!"
echo ""
echo "📊 Accesos:"
echo "  - Superset:   http://localhost:8088 (admin/admin)"
echo "  - ClickHouse: http://localhost:18123"
echo "  - PostgreSQL: localhost:5432"
echo "  - Debezium:   http://localhost:8083"
echo ""
echo "🔌 Cadena de conexión ClickHouse en Superset:"
echo "   clickhouse://superset_user:superset_pass@clickhouse:8123/analytics"
