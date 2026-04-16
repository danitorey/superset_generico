CREATE DATABASE IF NOT EXISTS analytics;

CREATE TABLE analytics.alumnos (
  id UInt64,
  nombre String,
  activo UInt8,
  updated_at DateTime
)
ENGINE = ReplacingMergeTree(updated_at)
ORDER BY id;
