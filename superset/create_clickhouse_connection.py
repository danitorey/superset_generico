import requests
import os

BASE_URL = "http://localhost:8088"
ADMIN_USER = os.getenv("SUPERSET_ADMIN_USER", "admin")
ADMIN_PASS = os.getenv("SUPERSET_ADMIN_PASSWORD", "admin")

session = requests.Session()

# Login
login = session.post(f"{BASE_URL}/api/v1/security/login", json={
    "username": ADMIN_USER,
    "password": ADMIN_PASS,
    "provider": "db"
})
token = login.json()["access_token"]

# Obtener CSRF token
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

# Crear conexión ClickHouse
payload = {
    "database_name": "ClickHouse",
    "sqlalchemy_uri": "clickhousedb://default:clickhouse123@clickhouse:8123/analytics",
    "expose_in_sqllab": True,
    "allow_run_async": False,
    "extra": "{}"
}

r = session.post(f"{BASE_URL}/api/v1/database/", json=payload, headers=headers)
print(f"Conexión ClickHouse: {r.status_code} - {r.json()}")
