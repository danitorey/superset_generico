-- ============================================================
-- RLS (Row Level Security) para plataforma de datos
-- ============================================================

-- Crear usuarios
CREATE USER IF NOT EXISTS analista_norte IDENTIFIED WITH plaintext_password BY 'norte123';
CREATE USER IF NOT EXISTS analista_sur IDENTIFIED WITH plaintext_password BY 'sur123';
CREATE USER IF NOT EXISTS analista_este IDENTIFIED WITH plaintext_password BY 'este123';
CREATE USER IF NOT EXISTS analista_oeste IDENTIFIED WITH plaintext_password BY 'oeste123';
CREATE USER IF NOT EXISTS gerente_ventas IDENTIFIED WITH plaintext_password BY 'gerente123';

-- Otorgar permisos
GRANT SELECT ON analytics.* TO analista_norte, analista_sur, analista_este, analista_oeste, gerente_ventas;

-- Agregar columna región si no existe
ALTER TABLE analytics.fact_ventas ADD COLUMN IF NOT EXISTS region String DEFAULT 'DESCONOCIDA';

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

SELECT '✅ RLS configurado correctamente' AS status;
