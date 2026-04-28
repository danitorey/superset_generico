import requests
import os
import sys

BASE_URL = "http://localhost:8088"
ADMIN_USER = os.getenv("SUPERSET_ADMIN_USER", "admin")
ADMIN_PASS = os.getenv("SUPERSET_ADMIN_PASSWORD", "admin")

session = requests.Session()

login = session.post(f"{BASE_URL}/api/v1/security/login", json={
    "username": ADMIN_USER,
    "password": ADMIN_PASS,
    "provider": "db"
})
if login.status_code != 200:
    print(f"❌ Login fallido: {login.status_code} - {login.text}")
    sys.exit(1)

token = login.json()["access_token"]

csrf_resp = session.get(
    f"{BASE_URL}/api/v1/security/csrf_token/",
    headers={"Authorization": f"Bearer {token}"}
)
csrf_token = csrf_resp.json()["result"]

headers = {
    "Authorization": f"Bearer {token}",
    "X-CSRFToken": csrf_token,
    "Referer": BASE_URL
}

list_resp = session.get(
    f"{BASE_URL}/api/v1/database/?q=(filters:!((col:database_name,opr:eq,value:ClickHouse Analytics)))",
    headers={"Authorization": f"Bearer {token}"}
)

databases = list_resp.json().get("result", [])
ya_existe = any(db.get("database_name") == "ClickHouse Analytics" for db in databases)

if ya_existe:
    print("⏭️  Conexión 'ClickHouse Analytics' ya existe — omitiendo creación")
    sys.exit(0)

payload = {
    "database_name": "ClickHouse Analytics",
    "sqlalchemy_uri": "clickhouse://default:clickhouse123@clickhouse:9000/analytics",
    "expose_in_sqllab": True,
    "allow_run_async": False,
    "extra": "{}"
}

r = session.post(f"{BASE_URL}/api/v1/database/", json=payload, headers=headers)

if r.status_code in (200, 201):
    print(f"✅ Conexión ClickHouse Analytics creada → HTTP {r.status_code}")
elif r.status_code == 422:
    print("⏭️  Conexión ya existente (422) — ignorando")
else:
    print(f"⚠️  Respuesta inesperada: {r.status_code} - {r.text}")
    sys.exit(1)
