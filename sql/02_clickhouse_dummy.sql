-- 02_clickhouse_dummy-2.sql
-- Bootstrap idempotente para ClickHouse con tablas, colas Kafka, MVs y vistas

CREATE DATABASE IF NOT EXISTS analytics;

CREATE TABLE IF NOT EXISTS analytics.dim_clientes
(
    id UUID,
    nombre String,
    sector String,
    region String,
    tipo String,
    activo UInt8,
    created_at DateTime,
    deleted UInt8 DEFAULT 0
)
ENGINE = ReplacingMergeTree(deleted)
ORDER BY id;

CREATE TABLE IF NOT EXISTS analytics.kafka_dim_clientes
(
    id UUID,
    nombre String,
    sector String,
    region String,
    tipo String,
    activo UInt8,
    created_at DateTime,
    deleted UInt8
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list = 'analytics.analytics.dim_clientes',
         kafka_group_name = 'clickhouse_analytics',
         kafka_format = 'JSONEachRow';

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.dim_clientes_mv
TO analytics.dim_clientes AS
SELECT id, nombre, sector, region, tipo, activo, created_at, if(deleted = 1, 1, 0) AS deleted
FROM analytics.kafka_dim_clientes;

CREATE VIEW IF NOT EXISTS analytics.vw_dim_clientes AS
SELECT id, nombre, sector, region, tipo, activo, created_at
FROM analytics.dim_clientes FINAL
WHERE deleted = 0;

CREATE TABLE IF NOT EXISTS analytics.dim_productos
(
    id UUID,
    nombre String,
    categoria String,
    unidad String,
    precio Decimal(12,2),
    activo UInt8,
    created_at DateTime,
    deleted UInt8 DEFAULT 0
)
ENGINE = ReplacingMergeTree(deleted)
ORDER BY id;

CREATE TABLE IF NOT EXISTS analytics.kafka_dim_productos
(
    id UUID,
    nombre String,
    categoria String,
    unidad String,
    precio Decimal(12,2),
    activo UInt8,
    created_at DateTime,
    deleted UInt8
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list = 'analytics.analytics.dim_productos',
         kafka_group_name = 'clickhouse_analytics',
         kafka_format = 'JSONEachRow';

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.dim_productos_mv
TO analytics.dim_productos AS
SELECT id, nombre, categoria, unidad, precio, activo, created_at, if(deleted = 1, 1, 0) AS deleted
FROM analytics.kafka_dim_productos;

CREATE VIEW IF NOT EXISTS analytics.vw_dim_productos AS
SELECT id, nombre, categoria, unidad, precio, activo, created_at
FROM analytics.dim_productos FINAL
WHERE deleted = 0;

CREATE TABLE IF NOT EXISTS analytics.dim_empleados
(
    id UUID,
    nombre String,
    area String,
    puesto String,
    nivel String,
    activo UInt8,
    fecha_ingreso Date,
    created_at DateTime,
    deleted UInt8 DEFAULT 0
)
ENGINE = ReplacingMergeTree(deleted)
ORDER BY id;

CREATE TABLE IF NOT EXISTS analytics.kafka_dim_empleados
(
    id UUID,
    nombre String,
    area String,
    puesto String,
    nivel String,
    activo UInt8,
    fecha_ingreso Date,
    created_at DateTime,
    deleted UInt8
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list = 'analytics.analytics.dim_empleados',
         kafka_group_name = 'clickhouse_analytics',
         kafka_format = 'JSONEachRow';

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.dim_empleados_mv
TO analytics.dim_empleados AS
SELECT id, nombre, area, puesto, nivel, activo, fecha_ingreso, created_at, if(deleted = 1, 1, 0) AS deleted
FROM analytics.kafka_dim_empleados;

CREATE VIEW IF NOT EXISTS analytics.vw_dim_empleados AS
SELECT id, nombre, area, puesto, nivel, activo, fecha_ingreso, created_at
FROM analytics.dim_empleados FINAL
WHERE deleted = 0;

CREATE TABLE IF NOT EXISTS analytics.fact_ventas
(
    id UUID,
    id_cliente UUID,
    id_producto UUID,
    id_empleado UUID,
    cantidad Int32,
    monto Decimal(14,2),
    descuento Decimal(5,2),
    estatus String,
    fecha_venta DateTime,
    created_at DateTime,
    deleted UInt8 DEFAULT 0
)
ENGINE = ReplacingMergeTree(deleted)
ORDER BY id;

CREATE TABLE IF NOT EXISTS analytics.kafka_fact_ventas
(
    id UUID,
    id_cliente UUID,
    id_producto UUID,
    id_empleado UUID,
    cantidad Int32,
    monto Decimal(14,2),
    descuento Decimal(5,2),
    estatus String,
    fecha_venta DateTime,
    created_at DateTime,
    deleted UInt8
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list = 'analytics.analytics.fact_ventas',
         kafka_group_name = 'clickhouse_analytics',
         kafka_format = 'JSONEachRow';

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.fact_ventas_mv
TO analytics.fact_ventas AS
SELECT id, id_cliente, id_producto, id_empleado, cantidad, monto, descuento, estatus, fecha_venta, created_at, if(deleted = 1, 1, 0) AS deleted
FROM analytics.kafka_fact_ventas;

CREATE VIEW IF NOT EXISTS analytics.vw_fact_ventas AS
SELECT id, id_cliente, id_producto, id_empleado, cantidad, monto, descuento, estatus, fecha_venta, created_at
FROM analytics.fact_ventas FINAL
WHERE deleted = 0;

CREATE TABLE IF NOT EXISTS analytics.fact_operaciones
(
    id UUID,
    id_cliente UUID,
    id_empleado UUID,
    tipo String,
    descripcion String,
    estatus String,
    prioridad String,
    tiempo_resolucion_hrs Decimal(6,2),
    fecha_apertura DateTime,
    fecha_cierre Nullable(DateTime),
    created_at DateTime,
    deleted UInt8 DEFAULT 0
)
ENGINE = ReplacingMergeTree(deleted)
ORDER BY id;

CREATE TABLE IF NOT EXISTS analytics.kafka_fact_operaciones
(
    id UUID,
    id_cliente UUID,
    id_empleado UUID,
    tipo String,
    descripcion String,
    estatus String,
    prioridad String,
    tiempo_resolucion_hrs Decimal(6,2),
    fecha_apertura DateTime,
    fecha_cierre Nullable(DateTime),
    created_at DateTime,
    deleted UInt8
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list = 'analytics.analytics.fact_operaciones',
         kafka_group_name = 'clickhouse_analytics',
         kafka_format = 'JSONEachRow';

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.fact_operaciones_mv
TO analytics.fact_operaciones AS
SELECT id, id_cliente, id_empleado, tipo, descripcion, estatus, prioridad, tiempo_resolucion_hrs, fecha_apertura, fecha_cierre, created_at, if(deleted = 1, 1, 0) AS deleted
FROM analytics.kafka_fact_operaciones;

CREATE VIEW IF NOT EXISTS analytics.vw_fact_operaciones AS
SELECT id, id_cliente, id_empleado, tipo, descripcion, estatus, prioridad, tiempo_resolucion_hrs, fecha_apertura, fecha_cierre, created_at
FROM analytics.fact_operaciones FINAL
WHERE deleted = 0;

CREATE TABLE IF NOT EXISTS analytics.fact_presupuesto
(
    id UUID,
    area String,
    mes Int32,
    anio Int32,
    asignado Decimal(14,2),
    ejercido Decimal(14,2),
    comprometido Decimal(14,2),
    estatus String,
    created_at DateTime,
    deleted UInt8 DEFAULT 0
)
ENGINE = ReplacingMergeTree(deleted)
ORDER BY id;

CREATE TABLE IF NOT EXISTS analytics.kafka_fact_presupuesto
(
    id UUID,
    area String,
    mes Int32,
    anio Int32,
    asignado Decimal(14,2),
    ejercido Decimal(14,2),
    comprometido Decimal(14,2),
    estatus String,
    created_at DateTime,
    deleted UInt8
)
ENGINE = Kafka
SETTINGS kafka_broker_list = 'redpanda:9092',
         kafka_topic_list = 'analytics.analytics.fact_presupuesto',
         kafka_group_name = 'clickhouse_analytics',
         kafka_format = 'JSONEachRow';

CREATE MATERIALIZED VIEW IF NOT EXISTS analytics.fact_presupuesto_mv
TO analytics.fact_presupuesto AS
SELECT id, area, mes, anio, asignado, ejercido, comprometido, estatus, created_at, if(deleted = 1, 1, 0) AS deleted
FROM analytics.kafka_fact_presupuesto;

CREATE VIEW IF NOT EXISTS analytics.vw_fact_presupuesto AS
SELECT id, area, mes, anio, asignado, ejercido, comprometido, estatus, created_at
FROM analytics.fact_presupuesto FINAL
WHERE deleted = 0;

CREATE OR REPLACE VIEW analytics.vw_ventas_por_producto AS
SELECT
    p.nombre AS nombre_producto,
    SUM(v.monto) AS total_ventas,
    COUNT(*) AS num_transacciones
FROM analytics.fact_ventas v
INNER JOIN analytics.dim_productos p
    ON v.id_producto = p.id
GROUP BY p.nombre
ORDER BY total_ventas DESC;

CREATE OR REPLACE VIEW analytics.vw_ventas_por_empleado AS
SELECT
    e.nombre AS nombre_empleado,
    SUM(v.monto) AS total_ventas,
    COUNT(*) AS num_transacciones
FROM analytics.fact_ventas v
INNER JOIN analytics.dim_empleados e
    ON v.id_empleado = e.id
GROUP BY e.nombre
ORDER BY total_ventas DESC;

CREATE OR REPLACE VIEW analytics.vw_calidad_datos AS
SELECT
    'ventas' AS dominio,
    toDate(fecha_venta) AS fecha,
    count() AS filas_totales,
    countIf(
        id_cliente IS NOT NULL
        AND id_producto IS NOT NULL
        AND id_empleado IS NOT NULL
        AND cantidad > 0
        AND monto > 0
        AND descuento >= 0
        AND estatus IN ('Pendiente', 'Pagada', 'Cancelada', 'En proceso')
    ) AS filas_validas,
    countIf(
        NOT (
            id_cliente IS NOT NULL
            AND id_producto IS NOT NULL
            AND id_empleado IS NOT NULL
            AND cantidad > 0
            AND monto > 0
            AND descuento >= 0
            AND estatus IN ('Pendiente', 'Pagada', 'Cancelada', 'En proceso')
        )
    ) AS filas_invalidas,
    round(100.0 * countIf(id_cliente IS NOT NULL AND id_producto IS NOT NULL AND id_empleado IS NOT NULL AND cantidad > 0 AND monto > 0 AND descuento >= 0 AND estatus IN ('Pendiente', 'Pagada', 'Cancelada', 'En proceso')) / count(), 2) AS porcentaje_calidad,
    if(round(100.0 * countIf(id_cliente IS NOT NULL AND id_producto IS NOT NULL AND id_empleado IS NOT NULL AND cantidad > 0 AND monto > 0 AND descuento >= 0 AND estatus IN ('Pendiente', 'Pagada', 'Cancelada', 'En proceso')) / count(), 2) >= 95, 'OK', 'Alerta') AS estado,
    'Validación de ventas' AS observacion
FROM analytics.vw_fact_ventas
GROUP BY fecha
UNION ALL
SELECT
    'operaciones' AS dominio,
    toDate(fecha_apertura) AS fecha,
    count() AS filas_totales,
    countIf(
        tiempo_resolucion_hrs >= 0
        AND prioridad IN ('Alta', 'Media', 'Baja')
        AND estatus IN ('Abierto', 'En proceso', 'Resuelto', 'Cancelado')
    ) AS filas_validas,
    countIf(
        NOT (
            tiempo_resolucion_hrs >= 0
            AND prioridad IN ('Alta', 'Media', 'Baja')
            AND estatus IN ('Abierto', 'En proceso', 'Resuelto', 'Cancelado')
        )
    ) AS filas_invalidas,
    round(100.0 * countIf(tiempo_resolucion_hrs >= 0 AND prioridad IN ('Alta', 'Media', 'Baja') AND estatus IN ('Abierto', 'En proceso', 'Resuelto', 'Cancelado')) / count(), 2) AS porcentaje_calidad,
    if(round(100.0 * countIf(tiempo_resolucion_hrs >= 0 AND prioridad IN ('Alta', 'Media', 'Baja') AND estatus IN ('Abierto', 'En proceso', 'Resuelto', 'Cancelado')) / count(), 2) >= 95, 'OK', 'Alerta') AS estado,
    'Validación de operaciones' AS observacion
FROM analytics.vw_fact_operaciones
GROUP BY fecha
UNION ALL
SELECT
    'presupuesto' AS dominio,
    toDate(concat(toString(anio), '-', leftPad(toString(mes), 2, '0'), '-01')) AS fecha,
    count() AS filas_totales,
    countIf(asignado >= 0 AND ejercido >= 0 AND comprometido >= 0) AS filas_validas,
    countIf(NOT (asignado >= 0 AND ejercido >= 0 AND comprometido >= 0)) AS filas_invalidas,
    round(100.0 * countIf(asignado >= 0 AND ejercido >= 0 AND comprometido >= 0) / count(), 2) AS porcentaje_calidad,
    if(round(100.0 * countIf(asignado >= 0 AND ejercido >= 0 AND comprometido >= 0) / count(), 2) >= 95, 'OK', 'Alerta') AS estado,
    'Validación de presupuesto' AS observacion
FROM analytics.vw_fact_presupuesto
GROUP BY fecha
UNION ALL
SELECT
    'clientes' AS dominio,
    toDate(created_at) AS fecha,
    count() AS filas_totales,
    countIf(nombre != '' AND region != '' AND sector != '' AND tipo != '') AS filas_validas,
    countIf(NOT (nombre != '' AND region != '' AND sector != '' AND tipo != '')) AS filas_invalidas,
    round(100.0 * countIf(nombre != '' AND region != '' AND sector != '' AND tipo != '') / count(), 2) AS porcentaje_calidad,
    if(round(100.0 * countIf(nombre != '' AND region != '' AND sector != '' AND tipo != '') / count(), 2) >= 95, 'OK', 'Alerta') AS estado,
    'Validación de clientes' AS observacion
FROM analytics.vw_dim_clientes
GROUP BY fecha
UNION ALL
SELECT
    'productos' AS dominio,
    toDate(created_at) AS fecha,
    count() AS filas_totales,
    countIf(nombre != '' AND categoria != '' AND unidad != '' AND precio > 0) AS filas_validas,
    countIf(NOT (nombre != '' AND categoria != '' AND unidad != '' AND precio > 0)) AS filas_invalidas,
    round(100.0 * countIf(nombre != '' AND categoria != '' AND unidad != '' AND precio > 0) / count(), 2) AS porcentaje_calidad,
    if(round(100.0 * countIf(nombre != '' AND categoria != '' AND unidad != '' AND precio > 0) / count(), 2) >= 95, 'OK', 'Alerta') AS estado,
    'Validación de productos' AS observacion
FROM analytics.vw_dim_productos
GROUP BY fecha
UNION ALL
SELECT
    'empleados' AS dominio,
    toDate(created_at) AS fecha,
    count() AS filas_totales,
    countIf(nombre != '' AND area != '' AND puesto != '' AND nivel != '') AS filas_validas,
    countIf(NOT (nombre != '' AND area != '' AND puesto != '' AND nivel != '')) AS filas_invalidas,
    round(100.0 * countIf(nombre != '' AND area != '' AND puesto != '' AND nivel != '') / count(), 2) AS porcentaje_calidad,
    if(round(100.0 * countIf(nombre != '' AND area != '' AND puesto != '' AND nivel != '') / count(), 2) >= 95, 'OK', 'Alerta') AS estado,
    'Validación de empleados' AS observacion
FROM analytics.vw_dim_empleados
GROUP BY fecha;
