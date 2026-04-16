Data Platform OLTP → CDC → OLAP → BI
Arquitectura completa: PostgreSQL (OLTP) → Debezium → Redpanda (Kafka) → ClickHouse (OLAP) → Superset (BI). Plataforma lista para usar con un solo comando.

Arquitectura
text
PostgreSQL (OLTP) → Debezium → Redpanda (Kafka) → ClickHouse (OLAP) → Superset (BI)
Capas
Capa	Tecnología	Puerto	Propósito
Origen	PostgreSQL 16	5432	Base de datos transaccional (OLTP)
CDC	Debezium Connect	8083	Captura de cambios en tiempo real
Streaming	Redpanda (Kafka)	9092	Transporte de eventos
Analítica	ClickHouse	8123/9000	Base de datos analítica (OLAP)
Visualización	Superset 6.0	8088	Dashboards y BI
Cache	Redis	6379	Cache de consultas
Requisitos
Docker 20.10+

Docker Compose 2.0+

8GB RAM mínimo (16GB recomendado)

🚀 Instalación Rápida
bash
git clone <tu-repositorio>
cd data-platform
docker compose up -d
Accede a Superset: http://localhost:8088 (admin/admin)

📁 Estructura del Proyecto
text
data-platform/
├── docker-compose.yml          # Orquestación de servicios
├── Dockerfile.superset         # Build de Superset con drivers
├── .env                        # Variables de entorno
├── superset/
│   ├── superset_config.py      # Configuración de Superset
│   └── init.sh                 # Script de inicialización
├── postgres/
│   └── init/                   # Scripts de inicialización
├── clickhouse/
│   └── init/                   # Scripts de inicialización
└── debezium/                   # Conectores (vía API)
🌐 Servicios y Puertos
Servicio	Puerto (host)	Puerto (container)	URL
Superset	8088	8088	http://localhost:8088
ClickHouse HTTP	18123	8123	http://localhost:18123
ClickHouse Native	19000	9000	-
PostgreSQL	5432	5432	localhost:5432
Redpanda (Kafka)	9092	9092	-
Debezium	8083	8083	http://localhost:8083
🔌 Conexión de Bases de Datos en Superset
Conectar PostgreSQL (OLTP)
Data → Databases → + Database

Selecciona PostgreSQL

Llena el formulario:

Campo	Valor
Host	IP de tu servidor PostgreSQL
Port	5432
Database	nombre_de_tu_bd
Username	tu_usuario
Password	tu_contraseña
Test Connection → Connect

Conectar ClickHouse (OLAP)
Data → Databases → + Database

Selecciona ClickHouse Connect

Llena el formulario:

Campo	Valor
Host	clickhouse
Port	8123
Database	default
Test Connection → Connect

⚙️ Configurar Debezium (CDC)
bash
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d '{
    "name": "tu-connector",
    "config": {
      "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
      "database.hostname": "10.4.2.153",
      "database.port": "5432",
      "database.user": "tu_usuario",
      "database.password": "tu_contraseña",
      "database.dbname": "tu_bd",
      "database.server.name": "servidor",
      "topic.prefix": "prefijo",
      "table.include.list": "public",
      "plugin.name": "pgoutput"
    }
  }'
Verificar estado:

bash
curl http://localhost:8083/connectors/tu-connector/status
💻 Comandos Útiles
bash
# Levantar todos los servicios
docker compose up -d

# Ver logs
docker compose logs -f

# Detener servicios
docker compose down

# Detener y eliminar volúmenes (reinicio completo)
docker compose down -v

# Reconstruir Superset
docker compose build --no-cache superset

# Ver estado de contenedores
docker ps

# Acceder a ClickHouse CLI
docker exec -it clickhouse clickhouse-client

# Acceder a PostgreSQL CLI
docker exec -it postgres psql -U postgres
✅ Validación de Servicios
bash
# Superset
curl http://localhost:8088/login/

# ClickHouse
curl http://localhost:18123/ping

# Debezium
curl http://localhost:8083/connectors
🔑 Credenciales por Defecto
Servicio	Usuario	Contraseña
Superset	admin	admin
PostgreSQL (local)	postgres	postgres123
ClickHouse	default	(vacío)
🛠️ Solución de Problemas
Superset no ve ClickHouse:

bash
docker exec -it superset python -c "import clickhouse_connect; print('OK')"
Error de conexión a PostgreSQL externo:

bash
docker exec -it superset nc -zv 10.4.2.153 5432
Reconstruir todo desde cero:

bash
docker compose down -v
docker compose build --no-cache
docker compose up -d
🎯 Principios de Diseño
✅ CDC en tiempo real, no batch

✅ Append-only en ClickHouse para máximo rendimiento

✅ Cache distribuido con Redis

✅ Infraestructura como código

✅ Reproducibilidad total con Docker

✅ Múltiples bases de datos conectables desde Superset

📄 Licencia
MIT