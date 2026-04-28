-- ============================================================
-- 01_postgres_dummy.sql
-- Tablas dummy en PostgreSQL para plataforma de datos genérica
-- Schema: analytics (separado del metadata de Superset)
-- IDEMPOTENTE: seguro de ejecutar múltiples veces (reboot/reinicio)
-- ============================================================

CREATE SCHEMA IF NOT EXISTS analytics;

-- ============================================================
-- TABLA 1 — dim_clientes
-- ============================================================
CREATE TABLE IF NOT EXISTS analytics.dim_clientes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      VARCHAR(150) NOT NULL,
    sector      VARCHAR(80),
    region      VARCHAR(80),
    tipo        VARCHAR(50),
    activo      BOOLEAN DEFAULT true,
    created_at  TIMESTAMP DEFAULT NOW()
);

ALTER TABLE analytics.dim_clientes REPLICA IDENTITY FULL;

INSERT INTO analytics.dim_clientes (nombre, sector, region, tipo)
SELECT * FROM (VALUES
    ('Gobierno del Estado Norte',   'Gobierno',      'Norte',   'Publico'),
    ('Comercial del Pacífico SA',   'Comercio',      'Oeste',   'Privado'),
    ('Fundación Educativa Sur',     'Educación',     'Sur',     'ONG'),
    ('Manufactura Central SA',      'Industria',     'Centro',  'Privado'),
    ('Servicios Digitales MX',      'Tecnología',    'Centro',  'Privado'),
    ('Hospital Regional Este',      'Salud',         'Este',    'Publico'),
    ('Constructora del Valle',      'Construcción',  'Norte',   'Privado'),
    ('Distribuidora Nacional',      'Logística',     'Sur',     'Privado'),
    ('Instituto Tecnológico MX',    'Educación',     'Centro',  'Publico'),
    ('Agencia de Viajes Express',   'Turismo',       'Oeste',   'Privado')
) AS v(nombre, sector, region, tipo)
WHERE NOT EXISTS (SELECT 1 FROM analytics.dim_clientes LIMIT 1);

-- ============================================================
-- TABLA 2 — dim_productos
-- ============================================================
CREATE TABLE IF NOT EXISTS analytics.dim_productos (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      VARCHAR(150) NOT NULL,
    categoria   VARCHAR(80),
    unidad      VARCHAR(30),
    precio      NUMERIC(12,2),
    activo      BOOLEAN DEFAULT true,
    created_at  TIMESTAMP DEFAULT NOW()
);

ALTER TABLE analytics.dim_productos REPLICA IDENTITY FULL;

INSERT INTO analytics.dim_productos (nombre, categoria, unidad, precio)
SELECT * FROM (VALUES
    ('Laptop Pro 15',           'Electronica',    'Pieza',     25999.99::NUMERIC),
    ('Mouse Inalambrico',       'Accesorios',     'Pieza',       349.00::NUMERIC),
    ('Teclado Mecanico',        'Accesorios',     'Pieza',       899.50::NUMERIC),
    ('Monitor 27 pulgadas',     'Electronica',    'Pieza',      8499.00::NUMERIC),
    ('Silla Ergonómica',        'Mobiliario',     'Pieza',      4200.00::NUMERIC),
    ('Licencia Office 365',     'Software',       'Licencia',   2100.00::NUMERIC),
    ('Servidor Cloud Basic',    'Infraestructura','Mes',         5500.00::NUMERIC),
    ('Capacitación Online',     'Servicios',      'Hora',        800.00::NUMERIC),
    ('Disco SSD 1TB',           'Almacenamiento', 'Pieza',      1850.00::NUMERIC),
    ('Webcam HD',               'Accesorios',     'Pieza',      1299.00::NUMERIC),
    ('Impresora Laser',         'Electronica',    'Pieza',      6300.00::NUMERIC),
    ('UPS 1200VA',              'Electronica',    'Pieza',      3200.00::NUMERIC)
) AS v(nombre, categoria, unidad, precio)
WHERE NOT EXISTS (SELECT 1 FROM analytics.dim_productos LIMIT 1);

-- ============================================================
-- TABLA 3 — dim_empleados
-- ============================================================
CREATE TABLE IF NOT EXISTS analytics.dim_empleados (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre        VARCHAR(150) NOT NULL,
    area          VARCHAR(80),
    puesto        VARCHAR(80),
    nivel         VARCHAR(30),
    activo        BOOLEAN DEFAULT true,
    fecha_ingreso DATE DEFAULT CURRENT_DATE,
    created_at    TIMESTAMP DEFAULT NOW()
);

ALTER TABLE analytics.dim_empleados REPLICA IDENTITY FULL;

INSERT INTO analytics.dim_empleados (nombre, area, puesto, nivel, fecha_ingreso)
SELECT * FROM (VALUES
    ('Ana García López',        'Tecnología',  'Data Engineer',        'Senior',  '2022-03-15'::DATE),
    ('Carlos Mendoza Ruiz',     'Ventas',      'Ejecutivo de Cuenta',  'Junior',  '2023-07-01'::DATE),
    ('María Torres Sánchez',    'Operaciones', 'Coordinadora',         'Lead',    '2021-01-10'::DATE),
    ('Luis Hernández Cruz',     'Finanzas',    'Analista',             'Senior',  '2020-08-20'::DATE),
    ('Patricia Flores Vega',    'RRHH',        'Gestión de Talento',   'Manager', '2019-05-05'::DATE),
    ('Roberto Díaz Morales',    'Tecnología',  'DevOps',               'Senior',  '2022-11-30'::DATE),
    ('Sandra Ramírez Luna',     'Ventas',      'Gerente Comercial',    'Manager', '2018-02-14'::DATE),
    ('Jorge Castillo Peña',     'Operaciones', 'Analista',             'Junior',  '2024-01-08'::DATE),
    ('Verónica Núñez Ríos',     'Finanzas',    'Contadora',            'Senior',  '2021-09-22'::DATE),
    ('Miguel Ortega Salinas',   'Tecnología',  'Backend Developer',    'Lead',    '2023-04-17'::DATE)
) AS v(nombre, area, puesto, nivel, fecha_ingreso)
WHERE NOT EXISTS (SELECT 1 FROM analytics.dim_empleados LIMIT 1);

-- ============================================================
-- TABLA 4 — fact_ventas
-- ============================================================
CREATE TABLE IF NOT EXISTS analytics.fact_ventas (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente  UUID,
    id_producto UUID,
    id_empleado UUID,
    cantidad    INT DEFAULT 1,
    monto       NUMERIC(14,2),
    descuento   NUMERIC(5,2) DEFAULT 0,
    estatus     VARCHAR(50),
    fecha_venta TIMESTAMP DEFAULT NOW(),
    created_at  TIMESTAMP DEFAULT NOW()
);

ALTER TABLE analytics.fact_ventas REPLICA IDENTITY FULL;

INSERT INTO analytics.fact_ventas (id_cliente, id_producto, id_empleado, cantidad, monto, descuento, estatus, fecha_venta)
SELECT
    (SELECT id FROM analytics.dim_clientes ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM analytics.dim_productos ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM analytics.dim_empleados ORDER BY RANDOM() LIMIT 1),
    (FLOOR(RANDOM() * 10) + 1)::INT,
    ROUND((RANDOM() * 50000 + 500)::NUMERIC, 2),
    ROUND((RANDOM() * 15)::NUMERIC, 2),
    (ARRAY['Pendiente','Pagada','Cancelada','En proceso'])[FLOOR(RANDOM()*4+1)],
    NOW() - (FLOOR(RANDOM() * 180) || ' days')::INTERVAL
FROM generate_series(1, 80)
WHERE NOT EXISTS (SELECT 1 FROM analytics.fact_ventas LIMIT 1);

-- ============================================================
-- TABLA 5 — fact_operaciones
-- ============================================================
CREATE TABLE IF NOT EXISTS analytics.fact_operaciones (
    id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente            UUID,
    id_empleado           UUID,
    tipo                  VARCHAR(80),
    descripcion           VARCHAR(255),
    estatus               VARCHAR(50),
    prioridad             VARCHAR(30),
    tiempo_resolucion_hrs NUMERIC(6,2),
    fecha_apertura        TIMESTAMP DEFAULT NOW(),
    fecha_cierre          TIMESTAMP,
    created_at            TIMESTAMP DEFAULT NOW()
);

ALTER TABLE analytics.fact_operaciones REPLICA IDENTITY FULL;

INSERT INTO analytics.fact_operaciones (id_cliente, id_empleado, tipo, descripcion, estatus, prioridad, tiempo_resolucion_hrs, fecha_apertura, fecha_cierre)
SELECT
    (SELECT id FROM analytics.dim_clientes ORDER BY RANDOM() LIMIT 1),
    (SELECT id FROM analytics.dim_empleados ORDER BY RANDOM() LIMIT 1),
    (ARRAY['Ticket','Tramite','Incidencia','Solicitud'])[FLOOR(RANDOM()*4+1)],
    (ARRAY['Soporte técnico requerido','Actualización de datos','Consulta general','Error en sistema','Solicitud de acceso'])[FLOOR(RANDOM()*5+1)],
    (ARRAY['Abierto','En proceso','Resuelto','Cancelado'])[FLOOR(RANDOM()*4+1)],
    (ARRAY['Alta','Media','Baja'])[FLOOR(RANDOM()*3+1)],
    ROUND((RANDOM() * 72)::NUMERIC, 2),
    NOW() - (FLOOR(RANDOM() * 120) || ' days')::INTERVAL,
    CASE WHEN RANDOM() > 0.3 THEN NOW() - (FLOOR(RANDOM() * 60) || ' days')::INTERVAL ELSE NULL END
FROM generate_series(1, 100)
WHERE NOT EXISTS (SELECT 1 FROM analytics.fact_operaciones LIMIT 1);

-- ============================================================
-- TABLA 6 — fact_presupuesto
-- ============================================================
CREATE TABLE IF NOT EXISTS analytics.fact_presupuesto (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    area         VARCHAR(80),
    mes          INT,
    anio         INT,
    asignado     NUMERIC(14,2),
    ejercido     NUMERIC(14,2),
    comprometido NUMERIC(14,2),
    estatus      VARCHAR(50),
    created_at   TIMESTAMP DEFAULT NOW()
);

ALTER TABLE analytics.fact_presupuesto REPLICA IDENTITY FULL;

INSERT INTO analytics.fact_presupuesto (area, mes, anio, asignado, ejercido, comprometido, estatus)
SELECT * FROM (VALUES
    ('Tecnología',  1, 2026, 500000::NUMERIC, 420000::NUMERIC, 50000::NUMERIC, 'Normal'),
    ('Ventas',      1, 2026, 300000::NUMERIC, 310000::NUMERIC, 20000::NUMERIC, 'Sobreejercido'),
    ('Operaciones', 1, 2026, 450000::NUMERIC, 380000::NUMERIC, 40000::NUMERIC, 'Normal'),
    ('Finanzas',    1, 2026, 200000::NUMERIC, 180000::NUMERIC, 15000::NUMERIC, 'Normal'),
    ('RRHH',        1, 2026, 250000::NUMERIC, 230000::NUMERIC, 25000::NUMERIC, 'Normal'),
    ('Tecnología',  2, 2026, 500000::NUMERIC, 460000::NUMERIC, 30000::NUMERIC, 'Alerta'),
    ('Ventas',      2, 2026, 300000::NUMERIC, 280000::NUMERIC, 10000::NUMERIC, 'Normal'),
    ('Operaciones', 2, 2026, 450000::NUMERIC, 410000::NUMERIC, 35000::NUMERIC, 'Normal'),
    ('Finanzas',    2, 2026, 200000::NUMERIC, 195000::NUMERIC, 10000::NUMERIC, 'Alerta'),
    ('RRHH',        2, 2026, 250000::NUMERIC, 240000::NUMERIC, 20000::NUMERIC, 'Normal'),
    ('Tecnología',  3, 2026, 500000::NUMERIC, 510000::NUMERIC, 10000::NUMERIC, 'Sobreejercido'),
    ('Ventas',      3, 2026, 300000::NUMERIC, 270000::NUMERIC,  5000::NUMERIC, 'Normal'),
    ('Operaciones', 3, 2026, 450000::NUMERIC, 430000::NUMERIC, 20000::NUMERIC, 'Normal'),
    ('Finanzas',    3, 2026, 200000::NUMERIC, 190000::NUMERIC, 12000::NUMERIC, 'Normal'),
    ('RRHH',        3, 2026, 250000::NUMERIC, 245000::NUMERIC, 15000::NUMERIC, 'Alerta'),
    ('Tecnología',  4, 2026, 500000::NUMERIC, 150000::NUMERIC, 80000::NUMERIC, 'Normal'),
    ('Ventas',      4, 2026, 300000::NUMERIC, 120000::NUMERIC, 30000::NUMERIC, 'Normal'),
    ('Operaciones', 4, 2026, 450000::NUMERIC, 200000::NUMERIC, 60000::NUMERIC, 'Normal'),
    ('Finanzas',    4, 2026, 200000::NUMERIC,  80000::NUMERIC, 20000::NUMERIC, 'Normal'),
    ('RRHH',        4, 2026, 250000::NUMERIC, 100000::NUMERIC, 40000::NUMERIC, 'Normal')
) AS v(area, mes, anio, asignado, ejercido, comprometido, estatus)
WHERE NOT EXISTS (SELECT 1 FROM analytics.fact_presupuesto LIMIT 1);

-- ============================================================
-- TABLA user_region_mapping (pivote para RLS)
-- ============================================================
CREATE TABLE IF NOT EXISTS analytics.user_region_mapping (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

ALTER TABLE analytics.user_region_mapping REPLICA IDENTITY FULL;

-- Insertar datos iniciales
INSERT INTO analytics.user_region_mapping (email, username, region, is_admin) VALUES
    ('norte@empresa.com', 'analista_norte', 'NORTE', FALSE),
    ('sur@empresa.com', 'analista_sur', 'SUR', FALSE),
    ('este@empresa.com', 'analista_este', 'ESTE', FALSE),
    ('oeste@empresa.com', 'analista_oeste', 'OESTE', FALSE),
    ('gerente@empresa.com', 'gerente_ventas', 'TODAS', TRUE),
    ('admin@example.com', 'admin', 'TODAS', TRUE)
ON CONFLICT (email) DO UPDATE SET
    region = EXCLUDED.region,
    updated_at = NOW();
