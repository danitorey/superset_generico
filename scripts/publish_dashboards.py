#!/usr/bin/env python3
import requests
import time

SUPERSET_URL = "http://superset:8088"

print("📢 Publicando dashboards...")

for i in range(30):
    try:
        requests.get(f"{SUPERSET_URL}/health", timeout=5)
        break
    except:
        print(f"⏳ Esperando Superset... {i+1}/30")
        time.sleep(5)

session = requests.Session()

resp = session.post(f"{SUPERSET_URL}/api/v1/security/login",
                    json={"username": "admin", "password": "admin", "provider": "db"})
token = resp.json()["access_token"]

resp = session.get(f"{SUPERSET_URL}/api/v1/security/csrf_token/",
                   headers={"Authorization": f"Bearer {token}"})
csrf = resp.json()["result"]

headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json",
    "X-CSRFToken": csrf
}

resp = session.get(f"{SUPERSET_URL}/api/v1/dashboard/", headers=headers)
for dash in resp.json()["result"]:
    result = session.put(f"{SUPERSET_URL}/api/v1/dashboard/{dash['id']}",
                         json={"published": True}, headers=headers)
    if result.status_code in [200, 201]:
        print(f"✅ {dash['dashboard_title']} publicado")
    else:
        print(f"❌ {dash['dashboard_title']}: {result.status_code}")

print("✅ Dashboards publicados")
