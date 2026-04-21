-- ============================================================
-- 02_clickhouse_dummy.sql
-- Estructuras en ClickHouse para tablas dummy genéricas
-- 4 objetos por tabla: física + kafka + MV + vista
-- Base de datos: analytics
-- ============================================================

CREATE DATABASE IF NOT EXISTS analytics;

-- ============================================================
-- TABLA 1 — dim_clientes
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.dim_clientes (
    id          UUID,
    nombre      String,
    sector      String,
    region      String,
    tipo        String,
    activo      UInt8,
    created_at  DateTime,
    __deleted   UInt8 DEFAULT 0
) ENGINE = ReplacingMergeTree(__deleted)
ORDER BY id;

CREATE TABLE IF NOT EXISTS analytics.kafka_dim_clientes (
    id          UUID,
    nombre      String,
    sector      String,
    region      String,
    tipo        String,
    activo      UInt8,
    created_at  DateTime,
    __deleted   UInt8
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list   = 'analytics.analytics.dim_clientes',
         kafka_group_name   = 'clickhouse_analytics',
         kafka_format       = 'JSONEachRow';

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.dim_clientes_mv TO analytics.dim_clientes
AS SELECT id, nombre, sector, region, tipo, activo, created_at,
    if(__deleted = 1, 1, 0) AS __deleted
FROM analytics.kafka_dim_clientes;

CREATE VIEW IF NOT EXISTS analytics.vw_dim_clientes AS
SELECT id, nombre, sector, region, tipo, activo, created_at
FROM analytics.dim_clientes FINAL
WHERE __deleted = 0;

-- ============================================================
-- TABLA 2 — dim_productos
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.dim_productos (
    id          UUID,
    nombre      String,
    categoria   String,
    unidad      String,
    precio      Decimal(12,2),
    activo      UInt8,
    created_at  DateTime,
    __deleted   UInt8 DEFAULT 0
) ENGINE = ReplacingMergeTree(__deleted)
ORDER BY id;

CREATE TABLE IF NOT EXISTS analytics.kafka_dim_productos (
    id          UUID,
    nombre      String,
    categoria   String,
    unidad      String,
    precio      Decimal(12,2),
    activo      UInt8,
    created_at  DateTime,
    __deleted   UInt8
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list   = 'analytics.analytics.dim_productos',
         kafka_group_name   = 'clickhouse_analytics',
         kafka_format       = 'JSONEachRow';

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.dim_productos_mv TO analytics.dim_productos
AS SELECT id, nombre, categoria, unidad, precio, activo, created_at,
    if(__deleted = 1, 1, 0) AS __deleted
FROM analytics.kafka_dim_productos;

CREATE VIEW IF NOT EXISTS analytics.vw_dim_productos AS
SELECT id, nombre, categoria, unidad, precio, activo, created_at
FROM analytics.dim_productos FINAL
WHERE __deleted = 0;

-- ============================================================
-- TABLA 3 — dim_empleados
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.dim_empleados (
    id              UUID,
    nombre          String,
    area            String,
    puesto          String,
    nivel           String,
    activo          UInt8,
    fecha_ingreso   Date,
    created_at      DateTime,
    __deleted       UInt8 DEFAULT 0
) ENGINE = ReplacingMergeTree(__deleted)
ORDER BY id;

CREATE TABLE IF NOT EXISTS analytics.kafka_dim_empleados (
    id              UUID,
    nombre          String,
    area            String,
    puesto          String,
    nivel           String,
    activo          UInt8,
    fecha_ingreso   Date,
    created_at      DateTime,
    __deleted       UInt8
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list   = 'analytics.analytics.dim_empleados',
         kafka_group_name   = 'clickhouse_analytics',
         kafka_format       = 'JSONEachRow';

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.dim_empleados_mv TO analytics.dim_empleados
AS SELECT id, nombre, area, puesto, nivel, activo, fecha_ingreso, created_at,
    if(__deleted = 1, 1, 0) AS __deleted
FROM analytics.kafka_dim_empleados;

CREATE VIEW IF NOT EXISTS analytics.vw_dim_empleados AS
SELECT id, nombre, area, puesto, nivel, activo, fecha_ingreso, created_at
FROM analytics.dim_empleados FINAL
WHERE __deleted = 0;

-- ============================================================
-- TABLA 4 — fact_ventas
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.fact_ventas (
    id              UUID,
    id_cliente      UUID,
    id_producto     UUID,
    id_empleado     UUID,
    cantidad        Int32,
    monto           Decimal(14,2),
    descuento       Decimal(5,2),
    estatus         String,
    fecha_venta     DateTime,
    created_at      DateTime,
    __deleted       UInt8 DEFAULT 0
) ENGINE = ReplacingMergeTree(__deleted)
ORDER BY id;

CREATE TABLE IF NOT EXISTS analytics.kafka_fact_ventas (
    id              UUID,
    id_cliente      UUID,
    id_producto     UUID,
    id_empleado     UUID,
    cantidad        Int32,
    monto           Decimal(14,2),
    descuento       Decimal(5,2),
    estatus         String,
    fecha_venta     DateTime,
    created_at      DateTime,
    __deleted       UInt8
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list   = 'analytics.analytics.fact_ventas',
         kafka_group_name   = 'clickhouse_analytics',
         kafka_format       = 'JSONEachRow';

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.fact_ventas_mv TO analytics.fact_ventas
AS SELECT id, id_cliente, id_producto, id_empleado, cantidad, monto, descuento,
    estatus, fecha_venta, created_at,
    if(__deleted = 1, 1, 0) AS __deleted
FROM analytics.kafka_fact_ventas;

CREATE VIEW IF NOT EXISTS analytics.vw_fact_ventas AS
SELECT id, id_cliente, id_producto, id_empleado, cantidad, monto,
    descuento, estatus, fecha_venta, created_at
FROM analytics.fact_ventas FINAL
WHERE __deleted = 0;

-- ============================================================
-- TABLA 5 — fact_operaciones
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.fact_operaciones (
    id                      UUID,
    id_cliente              UUID,
    id_empleado             UUID,
    tipo                    String,
    descripcion             String,
    estatus                 String,
    prioridad               String,
    tiempo_resolucion_hrs   Decimal(6,2),
    fecha_apertura          DateTime,
    fecha_cierre            Nullable(DateTime),
    created_at              DateTime,
    __deleted               UInt8 DEFAULT 0
) ENGINE = ReplacingMergeTree(__deleted)
ORDER BY id;

CREATE TABLE IF NOT EXISTS analytics.kafka_fact_operaciones (
    id                      UUID,
    id_cliente              UUID,
    id_empleado             UUID,
    tipo                    String,
    descripcion             String,
    estatus                 String,
    prioridad               String,
    tiempo_resolucion_hrs   Decimal(6,2),
    fecha_apertura          DateTime,
    fecha_cierre            Nullable(DateTime),
    created_at              DateTime,
    __deleted               UInt8
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list   = 'analytics.analytics.fact_operaciones',
         kafka_group_name   = 'clickhouse_analytics',
         kafka_format       = 'JSONEachRow';

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.fact_operaciones_mv TO analytics.fact_operaciones
AS SELECT id, id_cliente, id_empleado, tipo, descripcion, estatus, prioridad,
    tiempo_resolucion_hrs, fecha_apertura, fecha_cierre, created_at,
    if(__deleted = 1, 1, 0) AS __deleted
FROM analytics.kafka_fact_operaciones;

CREATE VIEW IF NOT EXISTS analytics.vw_fact_operaciones AS
SELECT id, id_cliente, id_empleado, tipo, descripcion, estatus, prioridad,
    tiempo_resolucion_hrs, fecha_apertura, fecha_cierre, created_at
FROM analytics.fact_operaciones FINAL
WHERE __deleted = 0;

-- ============================================================
-- TABLA 6 — fact_presupuesto
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics.fact_presupuesto (
    id              UUID,
    area            String,
    mes             Int32,
    anio            Int32,
    asignado        Decimal(14,2),
    ejercido        Decimal(14,2),
    comprometido    Decimal(14,2),
    estatus         String,
    created_at      DateTime,
    __deleted       UInt8 DEFAULT 0
) ENGINE = ReplacingMergeTree(__deleted)
ORDER BY id;

CREATE TABLE IF NOT EXISTS analytics.kafka_fact_presupuesto (
    id              UUID,
    area            String,
    mes             Int32,
    anio            Int32,
    asignado        Decimal(14,2),
    ejercido        Decimal(14,2),
    comprometido    Decimal(14,2),
    estatus         String,
    created_at      DateTime,
    __deleted       UInt8
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list   = 'analytics.analytics.fact_presupuesto',
         kafka_group_name   = 'clickhouse_analytics',
         kafka_format       = 'JSONEachRow';

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.fact_presupuesto_mv TO analytics.fact_presupuesto
AS SELECT id, area, mes, anio, asignado, ejercido, comprometido, estatus, created_at,
    if(__deleted = 1, 1, 0) AS __deleted
FROM analytics.kafka_fact_presupuesto;

CREATE VIEW IF NOT EXISTS analytics.vw_fact_presupuesto AS
SELECT id, area, mes, anio, asignado, ejercido, comprometido, estatus, created_at
FROM analytics.fact_presupuesto FINAL
WHERE __deleted = 0;
