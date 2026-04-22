import os

SQLALCHEMY_DATABASE_URI = "postgresql+psycopg2://postgres:postgres123@postgres:5432/superset"

CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_REDIS_HOST": "redis",
    "CACHE_REDIS_PORT": 6379,
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_REDIS_URL": "redis://redis:6379/0",
}

DATA_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_REDIS_HOST": "redis",
    "CACHE_REDIS_PORT": 6379,
    "CACHE_DEFAULT_TIMEOUT": 300,
    "CACHE_REDIS_URL": "redis://redis:6379/1",
}

WTF_CSRF_ENABLED = True
SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "dev-key-change-in-production")

SESSION_COOKIE_SAMESITE = None
SESSION_COOKIE_SECURE = False
SESSION_COOKIE_HTTPONLY = True

FEATURE_FLAGS = {
    "DASHBOARD_CROSS_FILTERS": True,
}
