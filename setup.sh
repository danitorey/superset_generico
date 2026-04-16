#!/bin/bash

echo "🚀 Iniciando Data Platform..."

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker no está instalado"
    exit 1
fi

# Construir y levantar
docker compose build --no-cache
docker compose up -d

echo "✅ Platforma iniciada!"
echo ""
echo "📊 Accesos:"
echo "  - Superset: http://localhost:8088 (admin/admin)"
echo "  - ClickHouse HTTP: http://localhost:18123"
echo "  - PostgreSQL: localhost:5432"
echo ""
echo "🔌 Para conectar ClickHouse en Superset:"
echo "   clickhouse://clickhouse:8123/default"
