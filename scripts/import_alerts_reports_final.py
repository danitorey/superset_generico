#!/usr/bin/env python3
import json, requests, time, sys, os
from pathlib import Path

SUPERSET_URL = "http://superset:8088"
ADMIN_USER = os.getenv("SUPERSET_ADMIN_USER", "admin")
ADMIN_PASSWORD = os.getenv("SUPERSET_ADMIN_PASSWORD", "admin")
JSON_PATH = Path("/app/alertas_reportes")

def wait_and_import():
    print("🔔 Esperando a que Superset esté listo...")
    for attempt in range(60):
        try:
            session = requests.Session()
            resp = session.post(f"{SUPERSET_URL}/api/v1/security/login", json={
                "username": ADMIN_USER, "password": ADMIN_PASSWORD, "provider": "db"
            }, timeout=3)
            if resp.status_code == 200:
                token = resp.json()["access_token"]
                session.headers.update({"Authorization": f"Bearer {token}"})
                resp = session.get(f"{SUPERSET_URL}/api/v1/security/csrf_token/")
                csrf = resp.json()["result"]
                session.headers.update({"X-CSRFToken": csrf, "Content-Type": "application/json"})
                print("✅ Conexión establecida")
                break
        except Exception as e:
            print(f"⏳ Intento {attempt+1}/60")
            time.sleep(5)
    else:
        print("❌ No se pudo conectar")
        return
    
    for json_file in JSON_PATH.glob("*.json"):
        print(f"\n📄 Procesando: {json_file.name}")
        with open(json_file) as f:
            items = json.load(f)
        
        for item in items:
            payload = {
                "name": item["name"],
                "description": item.get("description", ""),
                "active": item.get("active", False),
                "crontab": item.get("crontab", "0 9 * * *"),
                "type": item["type"],
                "timezone": item.get("timezone", "UTC"),
                "owners": [1],
            }
            if item["type"] == "Alert":
                if item.get("chart"): payload["chart"] = item["chart"]
                if item.get("database"): payload["database"] = item["database"]
                if item.get("sql"): payload["sql"] = item["sql"]
            elif item["type"] == "Report":
                if item.get("dashboard"): payload["dashboard"] = item["dashboard"]
            
            # Verificar si existe
            resp = session.get(f"{SUPERSET_URL}/api/v1/report/")
            existing = [r.get("name") for r in resp.json().get("result", [])]
            if item["name"] in existing:
                print(f"  ⏭️ Ya existe: {item['name']}")
                continue
            
            resp = session.post(f"{SUPERSET_URL}/api/v1/report/", json=payload)
            if resp.status_code in [200, 201]:
                print(f"  ✅ Creado: {item['name']} ({item['type']})")
            else:
                print(f"  ⚠️ Error: {resp.text[:100]}")
    
    print("\n✅ Importación completada")

if __name__ == "__main__":
    wait_and_import()
