-- ============================================================
-- 01_postgres_dummy.sql
-- Tablas dummy en PostgreSQL para plataforma de datos genérica
-- Schema: analytics (separado del metadata de Superset)
-- ============================================================

-- Crear schema separado
CREATE SCHEMA IF NOT EXISTS analytics;

-- ============================================================
-- TABLA 1 — dim_clientes
-- ============================================================
CREATE TABLE analytics.dim_clientes (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      VARCHAR(150) NOT NULL,
    sector      VARCHAR(80),
    region      VARCHAR(80),
    tipo        VARCHAR(50),  -- Publico, Privado, ONG
    activo      BOOLEAN DEFAULT true,
    created_at  TIMESTAMP DEFAULT NOW()
);

ALTER TABLE analytics.dim_clientes REPLICA IDENTITY FULL;

INSERT INTO analytics.dim_clientes (nombre, sector, region, tipo) VALUES
    ('Gobierno del Estado Norte',   'Gobierno',      'Norte',   'Publico'),
    ('Comercial del Pacífico SA',   'Comercio',      'Oeste',   'Privado'),
    ('Fundación Educativa Sur',     'Educación',     'Sur',     'ONG'),
    ('Manufactura Central SA',      'Industria',     'Centro',  'Privado'),
    ('Servicios Digitales MX',      'Tecnología',    'Centro',  'Privado'),
    ('Hospital Regional Este',      'Salud',         'Este',    'Publico'),
    ('Constructora del Valle',      'Construcción',  'Norte',   'Privado'),
    ('Distribuidora Nacional',      'Logística',     'Sur',     'Privado'),
    ('Instituto Tecnológico MX',    'Educación',     'Centro',  'Publico'),
    ('Agencia de Viajes Express',   'Turismo',       'Oeste',   'Privado');

-- ============================================================
-- TABLA 2 — dim_productos
-- ============================================================
CREATE TABLE analytics.dim_productos (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      VARCHAR(150) NOT NULL,
    categoria   VARCHAR(80),
    unidad      VARCHAR(30),
    precio      NUMERIC(12,2),
    activo      BOOLEAN DEFAULT true,
    created_at  TIMESTAMP DEFAULT NOW()
);

ALTER TABLE analytics.dim_productos REPLICA IDENTITY FULL;

INSERT INTO analytics.dim_productos (nombre, categoria, unidad, precio) VALUES
    ('Laptop Pro 15',           'Electronica',   'Pieza',    25999.99),
    ('Mouse Inalambrico',       'Accesorios',    'Pieza',      349.00),
    ('Teclado Mecanico',        'Accesorios',    'Pieza',      899.50),
    ('Monitor 27 pulgadas',     'Electronica',   'Pieza',     8499.00),
    ('Silla Ergonómica',        'Mobiliario',    'Pieza',     4200.00),
    ('Licencia Office 365',     'Software',      'Licencia',  2100.00),
    ('Servidor Cloud Basic',    'Infraestructura','Mes',       5500.00),
    ('Capacitación Online',     'Servicios',     'Hora',       800.00),
    ('Disco SSD 1TB',           'Almacenamiento','Pieza',     1850.00),
    ('Webcam HD',               'Accesorios',    'Pieza',     1299.00),
    ('Impresora Laser',         'Electronica',   'Pieza',     6300.00),
    ('UPS 1200VA',              'Electronica',   'Pieza',     3200.00);

-- ============================================================
-- TABLA 3 — dim_empleados
-- ============================================================
CREATE TABLE analytics.dim_empleados (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      VARCHAR(150) NOT NULL,
    area        VARCHAR(80),
    puesto      VARCHAR(80),
    nivel       VARCHAR(30),  -- Junior, Senior, Lead, Manager
    activo      BOOLEAN DEFAULT true,
    fecha_ingreso DATE DEFAULT CURRENT_DATE,
    created_at  TIMESTAMP DEFAULT NOW()
);

ALTER TABLE analytics.dim_empleados REPLICA IDENTITY FULL;

INSERT INTO analytics.dim_empleados (nombre, area, puesto, nivel, fecha_ingreso) VALUES
    ('Ana García López',        'Tecnología',   'Data Engineer',        'Senior',  '2022-03-15'),
    ('Carlos Mendoza Ruiz',     'Ventas',       'Ejecutivo de Cuenta',  'Junior',  '2023-07-01'),
    ('María Torres Sánchez',    'Operaciones',  'Coordinadora',         'Lead',    '2021-01-10'),
    ('Luis Hernández Cruz',     'Finanzas',     'Analista',             'Senior',  '2020-08-20'),
    ('Patricia Flores Vega',    'RRHH',         'Gestión de Talento',   'Manager', '2019-05-05'),
    ('Roberto Díaz Morales',    'Tecnología',   'DevOps',               'Senior',  '2022-11-30'),
    ('Sandra Ramírez Luna',     'Ventas',       'Gerente Comercial',    'Manager', '2018-02-14'),
    ('Jorge Castillo Peña',     'Operaciones',  'Analista',             'Junior',  '2024-01-08'),
    ('Verónica Núñez Ríos',     'Finanzas',     'Contadora',            'Senior',  '2021-09-22'),
    ('Miguel Ortega Salinas',   'Tecnología',   'Backend Developer',    'Lead',    '2023-04-17');

-- ============================================================
-- TABLA 4 — fact_ventas
-- ============================================================
CREATE TABLE analytics.fact_ventas (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente      UUID,
    id_producto     UUID,
    id_empleado     UUID,
    cantidad        INT DEFAULT 1,
    monto           NUMERIC(14,2),
    descuento       NUMERIC(5,2) DEFAULT 0,
    estatus         VARCHAR(50),  -- Pendiente, Pagada, Cancelada, En proceso
    fecha_venta     TIMESTAMP DEFAULT NOW(),
    created_at      TIMESTAMP DEFAULT NOW()
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
FROM generate_series(1, 80);

-- ============================================================
-- TABLA 5 — fact_operaciones
-- ============================================================
CREATE TABLE analytics.fact_operaciones (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_cliente      UUID,
    id_empleado     UUID,
    tipo            VARCHAR(80),  -- Ticket, Tramite, Incidencia, Solicitud
    descripcion     VARCHAR(255),
    estatus         VARCHAR(50),  -- Abierto, En proceso, Resuelto, Cancelado
    prioridad       VARCHAR(30),  -- Alta, Media, Baja
    tiempo_resolucion_hrs NUMERIC(6,2),
    fecha_apertura  TIMESTAMP DEFAULT NOW(),
    fecha_cierre    TIMESTAMP,
    created_at      TIMESTAMP DEFAULT NOW()
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
FROM generate_series(1, 100);

-- ============================================================
-- TABLA 6 — fact_presupuesto
-- ============================================================
CREATE TABLE analytics.fact_presupuesto (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    area            VARCHAR(80),
    mes             INT,
    anio            INT,
    asignado        NUMERIC(14,2),
    ejercido        NUMERIC(14,2),
    comprometido    NUMERIC(14,2),
    estatus         VARCHAR(50),  -- Normal, Alerta, Sobreejercido
    created_at      TIMESTAMP DEFAULT NOW()
);

ALTER TABLE analytics.fact_presupuesto REPLICA IDENTITY FULL;

INSERT INTO analytics.fact_presupuesto (area, mes, anio, asignado, ejercido, comprometido, estatus) VALUES
    ('Tecnología',  1, 2026, 500000, 420000, 50000, 'Normal'),
    ('Ventas',      1, 2026, 300000, 310000, 20000, 'Sobreejercido'),
    ('Operaciones', 1, 2026, 450000, 380000, 40000, 'Normal'),
    ('Finanzas',    1, 2026, 200000, 180000, 15000, 'Normal'),
    ('RRHH',        1, 2026, 250000, 230000, 25000, 'Normal'),
    ('Tecnología',  2, 2026, 500000, 460000, 30000, 'Alerta'),
    ('Ventas',      2, 2026, 300000, 280000, 10000, 'Normal'),
    ('Operaciones', 2, 2026, 450000, 410000, 35000, 'Normal'),
    ('Finanzas',    2, 2026, 200000, 195000, 10000, 'Alerta'),
    ('RRHH',        2, 2026, 250000, 240000, 20000, 'Normal'),
    ('Tecnología',  3, 2026, 500000, 510000, 10000, 'Sobreejercido'),
    ('Ventas',      3, 2026, 300000, 270000,  5000, 'Normal'),
    ('Operaciones', 3, 2026, 450000, 430000, 20000, 'Normal'),
    ('Finanzas',    3, 2026, 200000, 190000, 12000, 'Normal'),
    ('RRHH',        3, 2026, 250000, 245000, 15000, 'Alerta'),
    ('Tecnología',  4, 2026, 500000, 150000, 80000, 'Normal'),
    ('Ventas',      4, 2026, 300000, 120000, 30000, 'Normal'),
    ('Operaciones', 4, 2026, 450000, 200000, 60000, 'Normal'),
    ('Finanzas',    4, 2026, 200000,  80000, 20000, 'Normal'),
    ('RRHH',        4, 2026, 250000, 100000, 40000, 'Normal');
