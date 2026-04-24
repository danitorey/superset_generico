# scripts/setup_alerts.py
"""
Crea alertas y reportes en Superset de forma idempotente.
Alertas SQL que disparan correos cuando se cumplen condiciones.
"""

import requests
import os
import sys

BASE_URL = os.getenv("SUPERSET_URL", "http://superset:8088")
ADMIN_USER = os.getenv("SUPERSET_ADMIN_USER", "admin")
ADMIN_PASS = os.getenv("SUPERSET_ADMIN_PASSWORD", "admin")
ALERT_EMAIL = os.getenv("ALERT_EMAIL", "tucorreo@gmail.com")  # ← cambiar en .env

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

def alert_exists(session, headers, name):
    r = session.get(f"{BASE_URL}/api/v1/report/", headers=headers)
    reports = r.json().get("result", [])
    return any(rep.get("name") == name for rep in reports)

def get_db_id(session, headers, db_name):
    r = session.get(
        f"{BASE_URL}/api/v1/database/?q=(filters:!((col:database_name,opr:eq,val:{db_name})))",
        headers=headers
    )
    result = r.json().get("result", [])
    if not result:
        print(f"⚠️  Base '{db_name}' no encontrada"); return None
    return result[0]["id"]

def create_alert(session, headers, name, sql, db_id, cron, validator_config, description):
    if alert_exists(session, headers, name):
        print(f"⏭️  Alerta '{name}' ya existe — omitiendo")
        return
    payload = {
        "type": "Alert",
        "name": name,
        "description": description,
        "active": True,
        "crontab": cron,
        "sql": sql,
        "validator_type": "operator",
        "validator_config_json": validator_config,
        "database": db_id,
        "recipients": [
            {"type": "Email", "recipient_config_json": f'{{"target": "{ALERT_EMAIL}"}}'}
        ],
        "log_retention": 90,
        "working_timeout": 3600,
        "grace_period": 14400,
    }
    r = session.post(f"{BASE_URL}/api/v1/report/", json=payload, headers=headers)
    if r.status_code in (200, 201):
        print(f"✅ Alerta '{name}' creada")
    else:
        print(f"⚠️  Alerta '{name}' → {r.status_code}: {r.text}")

session, headers = login()

# Obtener ID de la base ClickHouse Analytics
db_id = get_db_id(session, headers, "ClickHouse")

if db_id:
    # ── Alerta 1: Ventas bajas del día ──────────────────────
    create_alert(
        session, headers,
        name="Alerta: Ventas bajas del día",
        sql="SELECT count(*) FROM analytics.vw_fact_ventas WHERE toDate(fecha_venta) = today()",
        db_id=db_id,
        cron="0 18 * * *",          # cada día a las 6 PM
        validator_config='{"op": "<", "threshold": 5}',
        description="Dispara si hay menos de 5 ventas registradas en el día"
    )

    # ── Alerta 2: Presupuesto sobreejercido ─────────────────
    create_alert(
        session, headers,
        name="Alerta: Áreas con presupuesto sobreejercido",
        sql="SELECT count(*) FROM analytics.vw_fact_presupuesto WHERE estatus = 'Sobreejercido' AND anio = toYear(today()) AND mes = toMonth(today())",
        db_id=db_id,
        cron="0 9 1 * *",           # primer día del mes a las 9 AM
        validator_config='{"op": ">", "threshold": 0}',
        description="Dispara si hay áreas con presupuesto sobreejercido en el mes actual"
    )

    # ── Alerta 3: Operaciones críticas sin resolver ─────────
    create_alert(
        session, headers,
        name="Alerta: Tickets Alta prioridad sin resolver",
        sql="SELECT count(*) FROM analytics.vw_fact_operaciones WHERE prioridad = 'Alta' AND estatus IN ('Abierto', 'En proceso') AND dateDiff('hour', fecha_apertura, now()) > 24",
        db_id=db_id,
        cron="0 */4 * * *",         # cada 4 horas
        validator_config='{"op": ">", "threshold": 0}',
        description="Dispara si hay tickets de Alta prioridad abiertos por más de 24 horas"
    )

    # ── Alerta 4: Calidad de datos degradada ────────────────
    create_alert(
        session, headers,
        name="Alerta: Calidad de datos bajo 95%",
        sql="SELECT count(*) FROM analytics.vw_calidad_datos WHERE porcentaje_calidad < 95 AND fecha = today()",
        db_id=db_id,
        cron="0 7 * * *",           # cada día a las 7 AM
        validator_config='{"op": ">", "threshold": 0}',
        description="Dispara si algún dominio de datos tiene calidad menor al 95% hoy"
    )

print("\n✅ Setup de Alertas completado")
