#!/usr/bin/env python3
import psycopg2
import json
from kafka import KafkaProducer
import uuid
from datetime import datetime

# Configuración
POSTGRES_CONFIG = {
    "host": "10.4.2.153",
    "port": 5432,
    "user": "sigeti",
    "password": "sigeti#2021",
    "database": "sigetidb"
}

KAFKA_CONFIG = {
    "bootstrap_servers": "redpanda:9092",
    "api_version": (2, 8, 0)
}

def fetch_data_from_postgres():
    """Ejecuta la vista compleja y devuelve las filas"""
    conn = psycopg2.connect(**POSTGRES_CONFIG)
    cursor = conn.cursor()
    
    # Tu vista completa
    cursor.execute("SELECT * FROM sigeti.vw_procesostimbrados;")
    
    columns = [desc[0] for desc in cursor.description]
    rows = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return columns, rows

def send_to_kafka(rows, columns):
    """Envía cada fila al tópico de Kafka"""
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_CONFIG["bootstrap_servers"],
        value_serializer=lambda v: json.dumps(v, default=str).encode('utf-8')
    )
    
    for row in rows:
        message = dict(zip(columns, row))
        producer.send('sigeti.dashboard_procesos', message)
    
    producer.flush()
    print(f"✅ Enviados {len(rows)} registros a Kafka")

if __name__ == "__main__":
    print("🔄 Leyendo datos de PostgreSQL...")
    columns, rows = fetch_data_from_postgres()
    print(f"📊 {len(rows)} registros obtenidos")
    
    print("📤 Enviando a Kafka...")
    send_to_kafka(rows, columns)
    
    print("✅ Proceso completado")
