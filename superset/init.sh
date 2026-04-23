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

echo "===> Levantando Superset en segundo plano..."
superset run -h 0.0.0.0 -p 8088 --with-threads &
SUPERSET_PID=$!

echo "===> Esperando que Superset esté listo..."
until curl -sf http://localhost:8088/health | grep -q "OK"; do
  echo "⏳ Esperando Superset..."
  sleep 3
done
echo "✅ Superset listo"

echo "===> Creando conexión ClickHouse via API..."
python /app/create_clickhouse_connection.py || true
echo "✅ Conexión ClickHouse lista"

echo "📦 Parcheando ZIPs con password de ClickHouse..."
mkdir -p /tmp/exports_patched

python3 - <<'PYEOF'
import zipfile, os, re

exports_dir = "/app/exports"
output_dir = "/tmp/exports_patched"
os.makedirs(output_dir, exist_ok=True)

CLICKHOUSE_PASSWORD = os.getenv("CLICKHOUSE_PASSWORD", "clickhouse123")

for zip_name in os.listdir(exports_dir):
    if not zip_name.endswith(".zip"):
        continue
    src = os.path.join(exports_dir, zip_name)
    dst = os.path.join(output_dir, zip_name)

    with zipfile.ZipFile(src, 'r') as zin:
        with zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as zout:
            for item in zin.infolist():
                data = zin.read(item.filename)

                if item.filename.endswith("databases/ClickHouse.yaml"):
                    content = data.decode("utf-8")
                    # Reemplazar password enmascarado por el real
                    content = content.replace("XXXXXXXXXX", CLICKHOUSE_PASSWORD)
                    # Corregir base de datos en la URI si apunta a default
                    content = content.replace(
                        "clickhouse:8123/default",
                        "clickhouse:8123/analytics"
                    )
                    # Agregar campo password explícito si no existe
                    if "^password:" not in content:
                        content = re.sub(
                            r"(sqlalchemy_uri:.*)",
                            r"\1\npassword: " + CLICKHOUSE_PASSWORD,
                            content
                        )
                    data = content.encode("utf-8")
                    print(f"  🔑 Parcheado: {zip_name} -> {item.filename}")

                zout.writestr(item, data)

print("✅ Todos los ZIPs parcheados")
PYEOF

echo "📊 Importando dashboards..."
for ZIP in /tmp/exports_patched/*.zip; do
  echo "  📥 Importando $(basename $ZIP)..."
  superset import-dashboards -p "$ZIP" --username admin || true
done
echo "✅ Dashboards importados"

echo "===> Superset corriendo..."
wait $SUPERSET_PID
