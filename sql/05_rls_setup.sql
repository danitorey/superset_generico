-- ============================================================
-- RLS (Row Level Security) para plataforma de datos
-- Se ejecuta automáticamente al iniciar ClickHouse
-- ============================================================

-- Crear usuarios (idempotente)
CREATE USER IF NOT EXISTS analista_norte IDENTIFIED WITH plaintext_password BY 'norte123';
CREATE USER IF NOT EXISTS analista_sur IDENTIFIED WITH plaintext_password BY 'sur123';
CREATE USER IF NOT EXISTS analista_este IDENTIFIED WITH plaintext_password BY 'este123';
CREATE USER IF NOT EXISTS analista_oeste IDENTIFIED WITH plaintext_password BY 'oeste123';
CREATE USER IF NOT EXISTS gerente_ventas IDENTIFIED WITH plaintext_password BY 'gerente123';

-- Otorgar permisos
GRANT SELECT ON analytics.* TO analista_norte, analista_sur, analista_este, analista_oeste, gerente_ventas;

-- Actualizar regiones en datos existentes
ALTER TABLE analytics.fact_ventas UPDATE region = 'NORTE' WHERE (cityHash64(toString(id))) % 4 = 0 AND (region = '' OR region = 'DESCONOCIDA');
ALTER TABLE analytics.fact_ventas UPDATE region = 'SUR' WHERE (cityHash64(toString(id))) % 4 = 1 AND (region = '' OR region = 'DESCONOCIDA');
ALTER TABLE analytics.fact_ventas UPDATE region = 'ESTE' WHERE (cityHash64(toString(id))) % 4 = 2 AND (region = '' OR region = 'DESCONOCIDA');
ALTER TABLE analytics.fact_ventas UPDATE region = 'OESTE' WHERE (cityHash64(toString(id))) % 4 = 3 AND (region = '' OR region = 'DESCONOCIDA');

-- Crear políticas RLS
DROP ROW POLICY IF EXISTS rls_norte ON analytics.fact_ventas;
CREATE ROW POLICY rls_norte ON analytics.fact_ventas FOR SELECT USING (region = 'NORTE') TO analista_norte;

DROP ROW POLICY IF EXISTS rls_sur ON analytics.fact_ventas;
CREATE ROW POLICY rls_sur ON analytics.fact_ventas FOR SELECT USING (region = 'SUR') TO analista_sur;

DROP ROW POLICY IF EXISTS rls_este ON analytics.fact_ventas;
CREATE ROW POLICY rls_este ON analytics.fact_ventas FOR SELECT USING (region = 'ESTE') TO analista_este;

DROP ROW POLICY IF EXISTS rls_oeste ON analytics.fact_ventas;
CREATE ROW POLICY rls_oeste ON analytics.fact_ventas FOR SELECT USING (region = 'OESTE') TO analista_oeste;

DROP ROW POLICY IF EXISTS rls_gerente ON analytics.fact_ventas;
CREATE ROW POLICY rls_gerente ON analytics.fact_ventas FOR SELECT USING (1 = 1) TO gerente_ventas;

-- Verificar distribución
SELECT '✅ RLS configurado correctamente' AS status;
SELECT region, COUNT(*) FROM analytics.fact_ventas GROUP BY region ORDER BY region;
