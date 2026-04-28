#!/usr/bin/env python3
"""
Crea usuarios en Superset automáticamente con rol Alpha
"""

import requests
import os
import sys
import time

SUPERSET_URL = "http://superset:8088"
ADMIN_USER = os.getenv("SUPERSET_ADMIN_USER", "admin")
ADMIN_PASS = os.getenv("SUPERSET_ADMIN_PASSWORD", "admin")

USERS = [
    ("analista_norte", "norte123", "norte@empresa.com", "Ana", "Lopez"),
    ("analista_sur", "sur123", "sur@empresa.com", "Luis", "Perez"),
    ("analista_este", "este123", "este@empresa.com", "Carlos", "Gomez"),
    ("analista_oeste", "oeste123", "oeste@empresa.com", "Maria", "Torres"),
    ("gerente_ventas", "gerente123", "gerente@empresa.com", "Juan", "Martinez"),
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

def get_access_token():
    resp = requests.post(f"{SUPERSET_URL}/api/v1/security/login",
                         json={"username": ADMIN_USER, "password": ADMIN_PASS, "provider": "db"})
    if resp.status_code == 200:
        return resp.json()["access_token"]
    return None

def get_role_id(session, headers, role_name):
    resp = session.get(f"{SUPERSET_URL}/api/v1/security/roles/", headers=headers)
    for role in resp.json().get("result", []):
        if role["name"] == role_name:
            return role["id"]
    return None

def user_exists(session, headers, username):
    resp = session.get(f"{SUPERSET_URL}/api/v1/security/users/", headers=headers)
    for user in resp.json().get("result", []):
        if user.get("username") == username:
            return user.get("id")
    return None

def create_user(session, headers, username, password, email, first_name, last_name, role_id):
    user_data = {
        "username": username,
        "password": password,
        "email": email,
        "first_name": first_name,
        "last_name": last_name,
        "active": True,
        "roles": [role_id]
    }
    resp = session.post(f"{SUPERSET_URL}/api/v1/security/users/", 
                        json=user_data, headers=headers)
    if resp.status_code in [200, 201]:
        print(f"✅ Usuario '{username}' creado con rol Alpha")
        return True
    elif resp.status_code == 422:
        # Usuario ya existe, actualizar su rol
        user_id = user_exists(session, headers, username)
        if user_id:
            update_data = {"roles": [role_id]}
            resp = session.put(f"{SUPERSET_URL}/api/v1/security/users/{user_id}",
                                json=update_data, headers=headers)
            if resp.status_code in [200, 201]:
                print(f"✅ Usuario '{username}' actualizado a rol Alpha")
                return True
    print(f"❌ Error: {resp.status_code} - {resp.text}")
    return False

def main():
    print("🚀 Creando usuarios en Superset...")
    
    if not wait_for_superset():
        print("❌ Superset no está listo")
        sys.exit(1)
    
    token = get_access_token()
    if not token:
        sys.exit(1)
    
    session = requests.Session()
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    
    # Obtener ID del rol Alpha
    alpha_id = get_role_id(session, headers, "Alpha")
    if not alpha_id:
        print("❌ Rol Alpha no encontrado")
        sys.exit(1)
    print(f"📋 Rol Alpha ID: {alpha_id}")
    
    for username, password, email, first_name, last_name in USERS:
        create_user(session, headers, username, password, email, first_name, last_name, alpha_id)
    
    print("\n✅ Todos los usuarios creados/actualizados")

if __name__ == "__main__":
    main()
