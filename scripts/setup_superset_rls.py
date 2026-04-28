#!/usr/bin/env python3
import requests
import os
import sys
import time

SUPERSET_URL = "http://superset:8088"
ADMIN_USER = os.getenv("SUPERSET_ADMIN_USER", "admin")
ADMIN_PASS = os.getenv("SUPERSET_ADMIN_PASSWORD", "admin")

# Todas las tablas que tienen o pueden tener columna region
TABLES = [
    "fact_ventas",
    "fact_operaciones", 
    "fact_presupuesto",
    "vw_fact_ventas",
    "vw_fact_operaciones",
    "vw_fact_presupuesto",
    "dim_clientes",
]

def wait_for_superset():
    print("🔔 Esperando Superset...")
    for i in range(30):
        try:
            resp = requests.get(f"{SUPERSET_URL}/health", timeout=5)
            if resp.status_code == 200:
                print("✅ Superset listo")
                return True
        except:
            pass
        print(f"⏳ Intento {i+1}/30")
        time.sleep(5)
    return False

def main():
    print("🚀 Configurando RLS nativo de Superset...")
    
    if not wait_for_superset():
        print("❌ Superset no está listo")
        sys.exit(1)
    
    session = requests.Session()
    
    # Login
    resp = session.post(f"{SUPERSET_URL}/api/v1/security/login",
                        json={"username": ADMIN_USER, "password": ADMIN_PASS, "provider": "db"})
    if resp.status_code != 200:
        print(f"❌ Login fallido: {resp.status_code}")
        sys.exit(1)
    
    token = resp.json()["access_token"]
    
    # CSRF
    resp = session.get(f"{SUPERSET_URL}/api/v1/security/csrf_token/",
                       headers={"Authorization": f"Bearer {token}"})
    csrf = resp.json()["result"]
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "X-CSRFToken": csrf
    }
    
    # Obtener rol Alpha
    resp = session.get(f"{SUPERSET_URL}/api/v1/security/roles/", headers=headers)
    alpha_id = None
    for role in resp.json()["result"]:
        if role["name"] == "Alpha":
            alpha_id = role["id"]
            break
    
    if not alpha_id:
        print("❌ Rol Alpha no encontrado")
        sys.exit(1)
    print(f"📋 Rol Alpha ID: {alpha_id}")
    
    # Obtener todos los datasets
    resp = session.get(f"{SUPERSET_URL}/api/v1/dataset/", headers=headers)
    datasets = {ds["table_name"]: ds["id"] for ds in resp.json()["result"]}
    print(f"📊 Datasets encontrados: {list(datasets.keys())}")
    
    clause = """
CASE 
    WHEN current_user_email() IN (SELECT email FROM analytics.user_region_mapping WHERE region = 'TODAS') THEN TRUE
    WHEN region IN (SELECT region FROM analytics.user_region_mapping WHERE email = current_user_email()) THEN TRUE
    ELSE FALSE
END
"""
    
    success = 0
    for table in TABLES:
        if table in datasets:
            table_id = datasets[table]
            payload = {
                "name": f"RLS_{table}",
                "clause": clause,
                "filter_type": "Regular",
                "roles": [alpha_id],
                "tables": [table_id]
            }
            resp = session.post(f"{SUPERSET_URL}/api/v1/rowlevelsecurity/", json=payload, headers=headers)
            if resp.status_code in [200, 201]:
                print(f"✅ RLS creado para {table}")
                success += 1
            elif resp.status_code == 400 and "already exists" in str(resp.text).lower():
                print(f"⏭️ RLS ya existe para {table}")
                success += 1
            else:
                print(f"⚠️ {table}: {resp.status_code}")
        else:
            print(f"⚠️ Tabla {table} no encontrada en Superset")
    
    print(f"\n🎉 RLS configurado en {success}/{len(TABLES)} tablas")

if __name__ == "__main__":
    main()
