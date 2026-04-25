#!/usr/bin/env python3
"""
Importa Alertas y Reportes a Superset desde JSON.
Ejecutado automáticamente por el servicio init.
"""

import json
import os
import requests
import time
from pathlib import Path

SUPERSET_URL = "http://superset:8088"
ADMIN_USER = os.getenv("SUPERSET_ADMIN_USER", "admin")
ADMIN_PASSWORD = os.getenv("SUPERSET_ADMIN_PASSWORD", "admin")
JSON_PATH = Path("/app/alertas_reportes")

def get_session_with_csrf():
    """Obtener session con CSRF token"""
    session = requests.Session()
    
    # Login
    resp = session.post(f"{SUPERSET_URL}/api/v1/security/login", json={
        "username": ADMIN_USER,
        "password": ADMIN_PASSWORD,
        "provider": "db"
    })
    if resp.status_code != 200:
        raise Exception(f"Login failed: {resp.text}")
    
    token = resp.json()["access_token"]
    session.headers.update({"Authorization": f"Bearer {token}"})
    
    # Obtener CSRF token
    resp = session.get(f"{SUPERSET_URL}/api/v1/security/csrf_token/")
    csrf_token = resp.json()["result"]
    session.headers.update({
        "X-CSRFToken": csrf_token,
        "Content-Type": "application/json"
    })
    
    print("✅ Session creada con CSRF token")
    return session

def import_from_json(session, json_file):
    if not json_file.exists():
        print(f"⚠️ No existe: {json_file.name}")
        return 0
    
    with open(json_file) as f:
        items = json.load(f)
    
    imported = 0
    for item in items:
        # Construir payload según la estructura correcta de la API
        payload = {
            "name": item["name"],
            "description": item.get("description", ""),
            "active": item.get("active", False),
            "crontab": item.get("crontab", "0 9 * * *"),
            "type": item["type"],
            "timezone": item.get("timezone", "UTC"),
            "owners": [1],
        }
        
        # Agregar campo específico según el tipo
        if item["type"] == "Alert":
            if item.get("chart_id"):
                payload["chart"] = item["chart_id"]
            if item.get("database_id"):
                payload["database"] = item["database_id"]
            if item.get("sql"):
                payload["sql"] = item["sql"]
        elif item["type"] == "Report":
            if item.get("dashboard_id"):
                payload["dashboard"] = item["dashboard_id"]
        
        # NOTA: recipients se omite porque la API no lo acepta directamente
        # Los destinatarios se configuran manualmente después
        
        print(f"  Importando: {item['name']} ({item['type']})")
        try:
            resp = session.post(f"{SUPERSET_URL}/api/v1/report/", json=payload)
            if resp.status_code in [200, 201]:
                imported += 1
                print(f"    ✅ OK (ID: {resp.json().get('id')})")
            else:
                print(f"    ⚠️ Error {resp.status_code}: {resp.text[:200]}")
        except Exception as e:
            print(f"    ❌ Excepción: {e}")
    
    return imported

def main():
    print("\n🔔 Importando Alertas y Reportes...")
    
    # Esperar a que Superset esté listo
    for attempt in range(12):
        try:
            session = get_session_with_csrf()
            break
        except Exception as e:
            print(f"⏳ Esperando Superset... {attempt + 1}/12: {e}")
            time.sleep(5)
    else:
        print("❌ No se pudo conectar a Superset")
        return
    
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
