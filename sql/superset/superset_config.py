from flask_caching.backends import RedisCache

CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_REDIS_HOST": "redis",
    "CACHE_REDIS_PORT": 6379,
    "CACHE_DEFAULT_TIMEOUT": 3600,
}

DATA_CACHE_CONFIG = {
    "CACHE_TYPE": "RedisCache",
    "CACHE_REDIS_HOST": "redis",
    "CACHE_REDIS_PORT": 6379,
    "CACHE_DEFAULT_TIMEOUT": 3600,
}

RESULTS_BACKEND = RedisCache(
    host="redis",
    port=6379,
    key_prefix="superset_results",
    db=1,
)

FEATURE_FLAGS = {
    "DASHBOARD_CROSS_FILTERS": True,
}
