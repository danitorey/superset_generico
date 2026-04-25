#!/bin/bash
set -e

echo "📦 Parcheando ZIPs con password de ClickHouse..."
mkdir -p /tmp/exports_patched

python3 << 'PYEOF'
import zipfile, os, re, glob

exports_dir = "/app/exports"
output_dir = "/tmp/exports_patched"
os.makedirs(output_dir, exist_ok=True)

CLICKHOUSE_PASSWORD = os.getenv("CLICKHOUSE_PASSWORD", "clickhouse123")

for zip_path in glob.glob(os.path.join(exports_dir, "*.zip")):
    zip_name = os.path.basename(zip_path)
    src = zip_path
    dst = os.path.join(output_dir, zip_name)

    with zipfile.ZipFile(src, 'r') as zin:
        with zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as zout:
            for item in zin.infolist():
                data = zin.read(item.filename)

                if item.filename.endswith("databases/ClickHouse.yaml"):
                    content = data.decode("utf-8")
                    content = content.replace("XXXXXXXXXX", CLICKHOUSE_PASSWORD)
                    content = content.replace(
                        "clickhouse:8123/default",
                        "clickhouse:8123/analytics"
                    )
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
  if [ -f "$ZIP" ]; then
    echo "  📥 Importando $(basename "$ZIP")..."
    superset import-dashboards -p "$ZIP" --username admin || true
  fi
done
echo "✅ Dashboards importados"

echo "⏰ Importando Alertas y Reportes..."
python3 /app/import_alerts_reports_final.py || true
