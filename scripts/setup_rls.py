# scripts/setup_rls.py
"""
Crea roles y políticas RLS de forma idempotente.
Se ejecuta desde platform_init después de que Superset esté listo.

Ejemplo de políticas creadas:
  - Rol "Analista_Norte"  → solo ve region = 'Norte'
  - Rol "Analista_Sur"    → solo ve region = 'Sur'
  - Rol "Analista_Centro" → solo ve region = 'Centro'
"""

import requests
import os
import sys

BASE_URL = os.getenv("SUPERSET_URL", "http://superset:8088")
ADMIN_USER = os.getenv("SUPERSET_ADMIN_USER", "admin")
ADMIN_PASS = os.getenv("SUPERSET_ADMIN_PASSWORD", "admin")

def get_headers(session, token):
    csrf = session.get(
        f"{BASE_URL}/api/v1/security/csrf_token/",
        headers={"Authorization": f"Bearer {token}"}
    ).json()["result"]
    return {
        "Authorization": f"Bearer {token}",
        "X-CSRFToken": csrf,
        "Referer": BASE_URL,
        "Content-Type": "application/json",
    }

def login():
    s = requests.Session()
    r = s.post(f"{BASE_URL}/api/v1/security/login", json={
        "username": ADMIN_USER, "password": ADMIN_PASS, "provider": "db"
    })
    if r.status_code != 200:
        print(f"❌ Login fallido: {r.text}")
        sys.exit(1)
    return s, r.json()["access_token"]

def get_or_create_role(session, headers, role_name):
    """Devuelve el id del rol, creándolo si no existe."""
    r = session.get(f"{BASE_URL}/api/v1/security/roles/", headers=headers)
    roles = r.json().get("result", [])
    for role in roles:
        if role["name"] == role_name:
            print(f"⏭️  Rol '{role_name}' ya existe (id={role['id']})")
            return role["id"]
    # Crear rol
    r = session.post(f"{BASE_URL}/api/v1/security/roles/",
                     json={"name": role_name}, headers=headers)
    role_id = r.json()["id"]
    print(f"✅ Rol '{role_name}' creado (id={role_id})")
    return role_id

def get_table_id(session, headers, table_name):
    """Busca el id del dataset/tabla en Superset."""
    r = session.get(
        f"{BASE_URL}/api/v1/dataset/?q=(filters:!((col:table_name,opr:eq,val:{table_name})))",
        headers=headers
    )
    result = r.json().get("result", [])
    if not result:
        print(f"⚠️  Tabla '{table_name}' no encontrada en Superset — ¿ya fue registrada?")
        return None
    return result[0]["id"]

def rls_exists(session, headers, name):
    """Verifica si ya existe una política RLS con ese nombre."""
    r = session.get(f"{BASE_URL}/api/v1/rowlevelsecurity/", headers=headers)
    filters = r.json().get("result", [])
    return any(f.get("name") == name for f in filters)

def create_rls(session, headers, name, clause, role_ids, table_ids):
    if rls_exists(session, headers, name):
        print(f"⏭️  RLS '{name}' ya existe — omitiendo")
        return
    payload = {
        "name": name,
        "clause": clause,
        "filter_type": "Regular",
        "roles": role_ids,
        "tables": table_ids,
    }
    r = session.post(f"{BASE_URL}/api/v1/rowlevelsecurity/",
                     json=payload, headers=headers)
    if r.status_code in (200, 201):
        print(f"✅ RLS '{name}' creado")
    else:
        print(f"⚠️  RLS '{name}' → {r.status_code}: {r.text}")

# ── Main ─────────────────────────────────────────────────────
session, token = login()
headers = get_headers(session, token)

# Crear roles por región
roles = {
    "Analista_Norte":  "region = 'Norte'",
    "Analista_Sur":    "region = 'Sur'",
    "Analista_Centro": "region = 'Centro'",
    "Analista_Oeste":  "region = 'Oeste'",
    "Analista_Este":   "region = 'Este'",
}

role_ids = {}
for role_name, _ in roles.items():
    role_ids[role_name] = get_or_create_role(session, headers, role_name)

# Obtener id de la tabla dim_clientes (la que tiene columna region)
table_id = get_table_id(session, headers, "dim_clientes")

if table_id:
    for role_name, clause in roles.items():
        create_rls(
            session, headers,
            name=f"RLS_{role_name}",
            clause=clause,
            role_ids=[role_ids[role_name]],
            table_ids=[table_id],
        )

print("\n✅ Setup de RLS completado")
