#!/usr/bin/env python3
"""
Importa Alertas y Reportes a Superset desde JSON.
Ejecutado automáticamente por init.sh.
"""

import json
import os
import requests
import time
from pathlib import Path

SUPERSET_URL = "http://localhost:8088"
ADMIN_USER = os.getenv("SUPERSET_ADMIN_USER", "admin")
ADMIN_PASSWORD = os.getenv("SUPERSET_ADMIN_PASSWORD", "admin")
JSON_PATH = Path("/app/alertas_reportes")

def get_session_with_csrf(max_retries=30):
    """Espera a que Superset esté listo y obtiene session con CSRF token"""
    for attempt in range(max_retries):
        try:
            session = requests.Session()
            resp = session.post(f"{SUPERSET_URL}/api/v1/security/login", json={
                "username": ADMIN_USER,
                "password": ADMIN_PASSWORD,
                "provider": "db"
            }, timeout=3)
            if resp.status_code != 200:
                raise Exception(f"Login failed: {resp.status_code}")
            
            token = resp.json()["access_token"]
            session.headers.update({"Authorization": f"Bearer {token}"})
            
            resp = session.get(f"{SUPERSET_URL}/api/v1/security/csrf_token/")
            csrf_token = resp.json()["result"]
            session.headers.update({
                "X-CSRFToken": csrf_token,
                "Content-Type": "application/json"
            })
            
            print(f"✅ Sesión creada (intento {attempt + 1})")
            return session
        except Exception as e:
            print(f"⏳ Esperando Superset... {attempt + 1}/{max_retries}: {str(e)[:50]}")
            time.sleep(5)
    
    raise Exception("❌ No se pudo conectar a Superset después de 30 intentos")

def import_from_json(session, json_file):
    if not json_file.exists():
        print(f"⚠️ No existe: {json_file.name}")
        return 0
    
    with open(json_file) as f:
        items = json.load(f)
    
    imported = 0
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
            if item.get("chart"):
                payload["chart"] = item["chart"]
            if item.get("database"):
                payload["database"] = item["database"]
            if item.get("sql"):
                payload["sql"] = item["sql"]
        elif item["type"] == "Report":
            if item.get("dashboard"):
                payload["dashboard"] = item["dashboard"]
        
        # Verificar si ya existe para evitar duplicados
        resp_check = session.get(f"{SUPERSET_URL}/api/v1/report/")
        existing = [r.get("name") for r in resp_check.json().get("result", [])]
        
        if item["name"] in existing:
            print(f"  ⏭️ Ya existe: {item['name']} ({item['type']})")
            imported += 1
            continue
        
        print(f"  Importando: {item['name']} ({item['type']})")
        resp = session.post(f"{SUPERSET_URL}/api/v1/report/", json=payload)
        
        if resp.status_code in [200, 201]:
            imported += 1
            print(f"    ✅ OK")
        else:
            print(f"    ⚠️ Error {resp.status_code}: {resp.text[:100]}")
    
    return imported

def main():
    print("\n🔔 Importando Alertas y Reportes...")
    
    session = get_session_with_csrf()
    
    json_files = list(JSON_PATH.glob("*.json"))
    if not json_files:
        print("⚠️ No hay archivos JSON en /app/alertas_reportes/")
        return
    
    total = 0
    for json_file in sorted(json_files):
        print(f"\n📄 Procesando: {json_file.name}")
        total += import_from_json(session, json_file)
    
    print(f"\n✅ Importados: {total} elementos")

if __name__ == "__main__":
    main()
