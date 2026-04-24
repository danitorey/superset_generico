# scripts/setup_monitoring_dashboard.py
"""
Crea datasets y el dashboard de monitoreo de la plataforma.
Idempotente: verifica si ya existe antes de crear.
"""

import requests
import os
import sys

BASE_URL = os.getenv("SUPERSET_URL", "http://superset:8088")
ADMIN_USER = os.getenv("SUPERSET_ADMIN_USER", "admin")
ADMIN_PASS = os.getenv("SUPERSET_ADMIN_PASSWORD", "admin")

def login():
    s = requests.Session()
    r = s.post(f"{BASE_URL}/api/v1/security/login", json={
        "username": ADMIN_USER, "password": ADMIN_PASS, "provider": "db"
    })
    if r.status_code != 200:
        print(f"❌ Login fallido: {r.text}"); sys.exit(1)
    token = r.json()["access_token"]
    csrf = s.get(f"{BASE_URL}/api/v1/security/csrf_token/",
                 headers={"Authorization": f"Bearer {token}"}).json()["result"]
    headers = {
        "Authorization": f"Bearer {token}",
        "X-CSRFToken": csrf,
        "Referer": BASE_URL,
        "Content-Type": "application/json",
    }
    return s, headers

def get_db_id(session, headers, db_name):
    r = session.get(
        f"{BASE_URL}/api/v1/database/?q=(filters:!((col:database_name,opr:eq,val:{db_name})))",
        headers=headers
    )
    result = r.json().get("result", [])
    return result[0]["id"] if result else None

def dataset_exists(session, headers, name):
    r = session.get(f"{BASE_URL}/api/v1/dataset/", headers=headers)
    return any(d.get("table_name") == name for d in r.json().get("result", []))

def create_virtual_dataset(session, headers, db_id, name, sql):
    if dataset_exists(session, headers, name):
        print(f"⏭️  Dataset '{name}' ya existe — omitiendo")
        return
    payload = {
        "database": db_id,
        "schema": "analytics",
        "table_name": name,
        "sql": sql,
    }
    r = session.post(f"{BASE_URL}/api/v1/dataset/", json=payload, headers=headers)
    if r.status_code in (200, 201):
        print(f"✅ Dataset '{name}' creado")
    else:
        print(f"⚠️  Dataset '{name}' → {r.status_code}: {r.text}")

def dashboard_exists(session, headers, title):
    r = session.get(f"{BASE_URL}/api/v1/dashboard/", headers=headers)
    return any(d.get("dashboard_title") == title for d in r.json().get("result", []))

def create_dashboard(session, headers, title):
    if dashboard_exists(session, headers, title):
        print(f"⏭️  Dashboard '{title}' ya existe — omitiendo")
        return
    r = session.post(f"{BASE_URL}/api/v1/dashboard/",
                     json={"dashboard_title": title, "published": True},
                     headers=headers)
    if r.status_code in (200, 201):
        print(f"✅ Dashboard '{title}' creado — agrega los charts manualmente en UI")
    else:
        print(f"⚠️  Dashboard → {r.status_code}: {r.text}")

session, headers = login()
db_id = get_db_id(session, headers, "ClickHouse")

if not db_id:
    print("❌ No se encontró la conexión ClickHouse Analytics"); sys.exit(1)

# ── Datasets virtuales para el dashboard de monitoreo ───────

create_virtual_dataset(session, headers, db_id,
    "monitor_conteo_registros",
    """
    SELECT 'dim_clientes' AS tabla, count(*) AS registros FROM analytics.vw_dim_clientes
    UNION ALL SELECT 'dim_productos', count(*) FROM analytics.vw_dim_productos
    UNION ALL SELECT 'dim_empleados', count(*) FROM analytics.vw_dim_empleados
    UNION ALL SELECT 'fact_ventas', count(*) FROM analytics.vw_fact_ventas
    UNION ALL SELECT 'fact_operaciones', count(*) FROM analytics.vw_fact_operaciones
    UNION ALL SELECT 'fact_presupuesto', count(*) FROM analytics.vw_fact_presupuesto
    """
)

create_virtual_dataset(session, headers, db_id,
    "monitor_calidad_datos",
    """
    SELECT dominio, fecha, filas_totales, filas_validas,
           filas_invalidas, porcentaje_calidad, estado, observacion
    FROM analytics.vw_calidad_datos
    ORDER BY fecha DESC, dominio
    """
)

create_virtual_dataset(session, headers, db_id,
    "monitor_ventas_por_hora",
    """
    SELECT
        toStartOfHour(fecha_venta) AS hora,
        count(*) AS num_ventas,
        round(sum(monto), 2) AS monto_total
    FROM analytics.vw_fact_ventas
    WHERE fecha_venta >= now() - INTERVAL 7 DAY
    GROUP BY hora
    ORDER BY hora
    """
)

create_virtual_dataset(session, headers, db_id,
    "monitor_tickets_criticos",
    """
    SELECT
        prioridad,
        estatus,
        count(*) AS total,
        round(avg(tiempo_resolucion_hrs), 2) AS avg_hrs_resolucion
    FROM analytics.vw_fact_operaciones
    WHERE fecha_apertura >= now() - INTERVAL 30 DAY
    GROUP BY prioridad, estatus
    ORDER BY prioridad, estatus
    """
)

create_virtual_dataset(session, headers, db_id,
    "monitor_presupuesto_estado",
    """
    SELECT area, mes, anio, asignado, ejercido, comprometido, estatus,
           round(100.0 * ejercido / asignado, 2) AS pct_ejercido
    FROM analytics.vw_fact_presupuesto
    WHERE anio = toYear(today())
    ORDER BY anio, mes, area
    """
)

# ── Crear el dashboard de monitoreo ─────────────────────────
create_dashboard(session, headers, "🔍 Monitoreo de Plataforma")

print("\n✅ Setup de Dashboard de Monitoreo completado")
print("📌 Entra a Superset → Dashboards → '🔍 Monitoreo de Plataforma'")
print("   y agrega charts usando los datasets 'monitor_*' recién creados")
