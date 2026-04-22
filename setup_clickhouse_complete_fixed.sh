#!/bin/bash

echo "========================================="
echo "🚀 SIGETI - Setup completo ClickHouse"
echo "========================================="

# ============================================
# 1. CREAR BASE DE DATOS Y TABLAS
# ============================================
echo ""
echo "📦 Creando base de datos y tablas en ClickHouse..."
echo "========================================="

docker exec -i clickhouse clickhouse-client << 'CLICKHOUSE_EOF'

CREATE DATABASE IF NOT EXISTS sigeti;

-- ct_aniosfiscales
CREATE TABLE IF NOT EXISTS sigeti.ct_aniosfiscales (
    id UUID DEFAULT generateUUIDv4(),
    noanio Int16 NOT NULL,
    boactivo Bool DEFAULT false
) ENGINE = MergeTree() ORDER BY id;

-- ct_meses
CREATE TABLE IF NOT EXISTS sigeti.ct_meses (
    id UUID DEFAULT generateUUIDv4(),
    nomesaplicacion Int16 NOT NULL,
    dsmes String NOT NULL,
    boactivo Bool DEFAULT true
) ENGINE = MergeTree() ORDER BY id;

-- ct_tipoaccionprocesos
CREATE TABLE IF NOT EXISTS sigeti.ct_tipoaccionprocesos (
    id UUID DEFAULT generateUUIDv4(),
    dsestatus String NOT NULL,
    dstipoaccion String NOT NULL,
    fcfecharegistro DateTime DEFAULT now(),
    boactivo Bool DEFAULT true
) ENGINE = MergeTree() ORDER BY id;

-- ct_dependencias
CREATE TABLE IF NOT EXISTS sigeti.ct_dependencias (
    id UUID,
    dsdependencia String NOT NULL,
    dsnombreemisor String NOT NULL,
    dsrfc String NOT NULL,
    fcfechacaducidadcertificado DateTime NOT NULL,
    bcertificadodigital String NOT NULL,
    dsfirmacertificado String NOT NULL,
    bsellodigital String NOT NULL,
    dscurp String NOT NULL,
    fcfecharegistro DateTime NOT NULL,
    fcfechaactualizacion Nullable(DateTime),
    dsregistropatronal String,
    regimenfiscal_id UUID NOT NULL,
    boactivo Bool DEFAULT true,
    tipo_proceso_id Nullable(UUID),
    nocertificado String,
    csd_bcertificadodigital String,
    csd_dscontrasenia String,
    csd_bllaveprivada String,
    csd_nocertificado String,
    templete String,
    dsadscripcion String,
    pwd_key_store String,
    alias_key String
) ENGINE = MergeTree() ORDER BY id;

-- ct_procesotimbrados
CREATE TABLE IF NOT EXISTS sigeti.ct_procesotimbrados (
    id UUID DEFAULT generateUUIDv4(),
    dsidentificador String NOT NULL,
    dsnombreproceso String NOT NULL,
    fcfecharegistropago DateTime NOT NULL,
    fcfechainiciopago Nullable(DateTime),
    fcfechafinpago Nullable(DateTime),
    dependencia_id UUID NOT NULL,
    periodicidad_id Nullable(UUID),
    tipo_nomina_id Nullable(UUID),
    boactivo Bool DEFAULT true,
    boeliminar Bool DEFAULT false,
    mes_id Nullable(UUID),
    anio_fiscal_id Nullable(UUID)
) ENGINE = MergeTree() ORDER BY id;

-- ct_facturas
CREATE TABLE IF NOT EXISTS sigeti.ct_facturas (
    id UUID DEFAULT generateUUIDv4(),
    fcfecharegistro DateTime NOT NULL,
    estatus_factura_id UUID NOT NULL,
    boactivo Bool DEFAULT true,
    noservidorpublico String,
    dsnombre String,
    dsrfc String,
    ndtotalpercepciones Float64,
    ndtotaldeducciones Float64,
    ndneto Float64,
    jsfactura String,
    uiidentificador_factura UUID,
    xmlfactura String,
    codigo_registro_head_id UUID,
    codigo_registro_foot_id UUID,
    dscurp String,
    noquincena String,
    ndisr Float64 DEFAULT 0,
    uuid_referencia UUID,
    ndsubsidio Float64 DEFAULT 0,
    proceso_timbrado_id UUID
) ENGINE = MergeTree() ORDER BY id;

-- crc_procesosfacturas
CREATE TABLE IF NOT EXISTS sigeti.crc_procesosfacturas (
    id UUID DEFAULT generateUUIDv4(),
    factura_id UUID NOT NULL,
    proceso_timbrado_id UUID NOT NULL,
    fcfecharegistro DateTime DEFAULT now(),
    boactivo Bool DEFAULT true
) ENGINE = MergeTree() ORDER BY id;

-- bt_procesotimbrados
CREATE TABLE IF NOT EXISTS sigeti.bt_procesotimbrados (
    id UUID DEFAULT generateUUIDv4(),
    usuario_id UUID NOT NULL,
    proceso_timbrado_id UUID NOT NULL,
    fcfecharegistro DateTime DEFAULT now(),
    dsdescripcion String NOT NULL,
    boactivo Bool DEFAULT true,
    tipo_accion_proceso_id Nullable(UUID),
    fcfechaactualizacion DateTime DEFAULT now()
) ENGINE = MergeTree() ORDER BY id;

-- bt_facturas
CREATE TABLE IF NOT EXISTS sigeti.bt_facturas (
    id UUID DEFAULT generateUUIDv4(),
    factura_id UUID NOT NULL,
    usuario_id UUID NOT NULL,
    tipo_accion_id UUID NOT NULL,
    dsaccion String NOT NULL,
    fcfecharegistro DateTime DEFAULT now(),
    boactivo Bool DEFAULT true,
    jsfactura String,
    ndtotalpercepciones Float64 DEFAULT 0,
    ndtotaldeducciones Float64 DEFAULT 0,
    ndneto Float64 DEFAULT 0,
    ndisr Float64 DEFAULT 0,
    ndsubsidio Float64 DEFAULT 0,
    uuid_factura Nullable(UUID)
) ENGINE = MergeTree() ORDER BY id;

SELECT '✅ Tablas creadas correctamente' as status;

CLICKHOUSE_EOF

# ============================================
# 2. EXPORTAR DATOS DESDE POSTGRESQL
# ============================================
echo ""
echo "📤 Exportando datos desde PostgreSQL..."
echo "========================================="

# Exportar ct_meses
echo "Exportando ct_meses..."
PGPASSWORD='sigeti#2021' psql -h 10.4.2.153 -U sigeti -d sigetidb -c "\COPY (SELECT id, nomesaplicacion, dsmes, boactivo FROM sigeti.ct_meses) TO '/tmp/ct_meses.csv' WITH CSV HEADER"

# Exportar ct_aniosfiscales
echo "Exportando ct_aniosfiscales..."
PGPASSWORD='sigeti#2021' psql -h 10.4.2.153 -U sigeti -d sigetidb -c "\COPY (SELECT id, noanio, boactivo FROM sigeti.ct_aniosfiscales) TO '/tmp/ct_aniosfiscales.csv' WITH CSV HEADER"

# Exportar ct_tipoaccionprocesos
echo "Exportando ct_tipoaccionprocesos..."
PGPASSWORD='sigeti#2021' psql -h 10.4.2.153 -U sigeti -d sigetidb -c "\COPY (SELECT id, dsestatus, dstipoaccion, fcfecharegistro, boactivo FROM sigeti.ct_tipoaccionprocesos) TO '/tmp/ct_tipoaccionprocesos.csv' WITH CSV HEADER"

# Exportar ct_dependencias
echo "Exportando ct_dependencias..."
PGPASSWORD='sigeti#2021' psql -h 10.4.2.153 -U sigeti -d sigetidb -c "\COPY (SELECT id, dsdependencia, dsnombreemisor, dsrfc, fcfechacaducidadcertificado, bcertificadodigital, dsfirmacertificado, bsellodigital, dscurp, fcfecharegistro, fcfechaactualizacion, dsregistropatronal, regimenfiscal_id, boactivo, tipo_proceso_id, nocertificado, csd_bcertificadodigital, csd_dscontrasenia, csd_bllaveprivada, csd_nocertificado, templete, dsadscripcion, pwd_key_store, alias_key FROM sigeti.ct_dependencias) TO '/tmp/ct_dependencias.csv' WITH CSV HEADER"

# Exportar ct_procesotimbrados
echo "Exportando ct_procesotimbrados..."
PGPASSWORD='sigeti#2021' psql -h 10.4.2.153 -U sigeti -d sigetidb -c "\COPY (SELECT id, dsidentificador, dsnombreproceso, fcfecharegistropago, fcfechainiciopago, fcfechafinpago, dependencia_id, periodicidad_id, tipo_nomina_id, boactivo, boeliminar, mes_id, anio_fiscal_id FROM sigeti.ct_procesotimbrados) TO '/tmp/ct_procesotimbrados.csv' WITH CSV HEADER"

# Exportar ct_facturas
echo "Exportando ct_facturas (1.3M registros - puede tardar)..."
PGPASSWORD='sigeti#2021' psql -h 10.4.2.153 -U sigeti -d sigetidb -c "\COPY (SELECT id, fcfecharegistro, estatus_factura_id, boactivo, noservidorpublico, dsnombre, dsrfc, ndtotalpercepciones, ndtotaldeducciones, ndneto, jsfactura, uiidentificador_factura, xmlfactura, codigo_registro_head_id, codigo_registro_foot_id, dscurp, noquincena, ndisr, uuid_referencia, ndsubsidio, proceso_timbrado_id FROM sigeti.ct_facturas) TO '/tmp/ct_facturas.csv' WITH CSV HEADER"

# Exportar crc_procesosfacturas
echo "Exportando crc_procesosfacturas..."
PGPASSWORD='sigeti#2021' psql -h 10.4.2.153 -U sigeti -d sigetidb -c "\COPY (SELECT id, factura_id, proceso_timbrado_id, fcfecharegistro, boactivo FROM sigeti.crc_procesosfacturas) TO '/tmp/crc_procesosfacturas.csv' WITH CSV HEADER"

# Exportar bt_procesotimbrados
echo "Exportando bt_procesotimbrados..."
PGPASSWORD='sigeti#2021' psql -h 10.4.2.153 -U sigeti -d sigetidb -c "\COPY (SELECT id, usuario_id, proceso_timbrado_id, fcfecharegistro, dsdescripcion, boactivo, tipo_accion_proceso_id, fcfechaactualizacion FROM sigeti.bt_procesotimbrados) TO '/tmp/bt_procesotimbrados.csv' WITH CSV HEADER"

# Exportar bt_facturas
echo "Exportando bt_facturas..."
PGPASSWORD='sigeti#2021' psql -h 10.4.2.153 -U sigeti -d sigetidb -c "\COPY (SELECT id, factura_id, usuario_id, tipo_accion_id, dsaccion, fcfecharegistro, boactivo, jsfactura, ndtotalpercepciones, ndtotaldeducciones, ndneto, ndisr, ndsubsidio, uuid_factura FROM sigeti.bt_facturas) TO '/tmp/bt_facturas.csv' WITH CSV HEADER"

echo "✅ Todos los datos exportados"

# ============================================
# 3. COPIAR CSV A CLICKHOUSE
# ============================================
echo ""
echo "📋 Copiando CSV a ClickHouse..."
echo "========================================="

docker cp /tmp/ct_meses.csv clickhouse:/tmp/
docker cp /tmp/ct_aniosfiscales.csv clickhouse:/tmp/
docker cp /tmp/ct_tipoaccionprocesos.csv clickhouse:/tmp/
docker cp /tmp/ct_dependencias.csv clickhouse:/tmp/
docker cp /tmp/ct_procesotimbrados.csv clickhouse:/tmp/
docker cp /tmp/ct_facturas.csv clickhouse:/tmp/
docker cp /tmp/crc_procesosfacturas.csv clickhouse:/tmp/
docker cp /tmp/bt_procesotimbrados.csv clickhouse:/tmp/
docker cp /tmp/bt_facturas.csv clickhouse:/tmp/

echo "✅ CSV copiados"

# ============================================
# 4. IMPORTAR CSV A CLICKHOUSE
# ============================================
echo ""
echo "📥 Importando datos a ClickHouse..."
echo "========================================="

echo "Importando ct_meses..."
docker exec -it clickhouse clickhouse-client --query "INSERT INTO sigeti.ct_meses FORMAT CSVWithNames" < /tmp/ct_meses.csv

echo "Importando ct_aniosfiscales..."
docker exec -it clickhouse clickhouse-client --query "INSERT INTO sigeti.ct_aniosfiscales FORMAT CSVWithNames" < /tmp/ct_aniosfiscales.csv

echo "Importando ct_tipoaccionprocesos..."
docker exec -it clickhouse clickhouse-client --query "INSERT INTO sigeti.ct_tipoaccionprocesos FORMAT CSVWithNames" < /tmp/ct_tipoaccionprocesos.csv

echo "Importando ct_dependencias..."
docker exec -it clickhouse clickhouse-client --query "INSERT INTO sigeti.ct_dependencias FORMAT CSVWithNames" < /tmp/ct_dependencias.csv

echo "Importando ct_procesotimbrados..."
docker exec -it clickhouse clickhouse-client --query "INSERT INTO sigeti.ct_procesotimbrados FORMAT CSVWithNames" < /tmp/ct_procesotimbrados.csv

echo "Importando ct_facturas (1.3M registros - puede tardar)..."
docker exec -it clickhouse clickhouse-client --query "INSERT INTO sigeti.ct_facturas FORMAT CSVWithNames" < /tmp/ct_facturas.csv

echo "Importando crc_procesosfacturas..."
docker exec -it clickhouse clickhouse-client --query "INSERT INTO sigeti.crc_procesosfacturas FORMAT CSVWithNames" < /tmp/crc_procesosfacturas.csv

echo "Importando bt_procesotimbrados..."
docker exec -it clickhouse clickhouse-client --query "INSERT INTO sigeti.bt_procesotimbrados FORMAT CSVWithNames" < /tmp/bt_procesotimbrados.csv

echo "Importando bt_facturas..."
docker exec -it clickhouse clickhouse-client --query "INSERT INTO sigeti.bt_facturas FORMAT CSVWithNames" < /tmp/bt_facturas.csv

# ============================================
# 5. VERIFICAR RESULTADOS
# ============================================
echo ""
echo "🔍 Verificando datos en ClickHouse..."
echo "========================================="

docker exec -it clickhouse clickhouse-client --query "
SELECT 'ct_aniosfiscales' as tabla, count() FROM sigeti.ct_aniosfiscales
UNION ALL
SELECT 'ct_meses', count() FROM sigeti.ct_meses
UNION ALL
SELECT 'ct_tipoaccionprocesos', count() FROM sigeti.ct_tipoaccionprocesos
UNION ALL
SELECT 'ct_dependencias', count() FROM sigeti.ct_dependencias
UNION ALL
SELECT 'ct_procesotimbrados', count() FROM sigeti.ct_procesotimbrados
UNION ALL
SELECT 'ct_facturas', count() FROM sigeti.ct_facturas
UNION ALL
SELECT 'crc_procesosfacturas', count() FROM sigeti.crc_procesosfacturas
UNION ALL
SELECT 'bt_procesotimbrados', count() FROM sigeti.bt_procesotimbrados
UNION ALL
SELECT 'bt_facturas', count() FROM sigeti.bt_facturas
FORMAT Pretty
"

echo ""
echo "========================================="
echo "✅ SETUP COMPLETADO EXITOSAMENTE"
echo "========================================="
