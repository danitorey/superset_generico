# superset/superset_config.py
import os
from celery.schedules import crontab

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
    "CACHE_DEFAULT_TIMEOUT": 600,
    "CACHE_REDIS_URL": "redis://redis:6379/1",
}

FEATURE_FLAGS = {
    "DASHBOARD_CROSS_FILTERS": True,
    "ALERT_REPORTS": True,
    "ROW_LEVEL_SECURITY": True,
}

class CeleryConfig:
    broker_url = "redis://redis:6379/0"
    result_backend = "redis://redis:6379/0"
    worker_prefetch_multiplier = 1
    task_acks_late = False
    beat_schedule = {
        "reports.scheduler": {
            "task": "reports.scheduler",
            "schedule": crontab(minute="*", hour="*"),
        },
        "reports.prune_log": {
            "task": "reports.prune_log",
            "schedule": crontab(minute=0, hour=0),
        },
    }

CELERY_CONFIG = CeleryConfig

EMAIL_NOTIFICATIONS = True
ENABLE_SCHEDULED_EMAIL_REPORTS = True

SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_STARTTLS = True
SMTP_SSL = False
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
SMTP_MAIL_FROM = os.getenv("SMTP_MAIL_FROM", os.getenv("SMTP_USER", ""))

WEBDRIVER_BASEURL = "http://superset:8088/"
WEBDRIVER_BASEURL_USER_FRIENDLY = "http://localhost:8088/"

SECRET_KEY = os.environ.get("SUPERSET_SECRET_KEY", "dev-key-change-in-production")
WTF_CSRF_ENABLED = True
SESSION_COOKIE_SAMESITE = None
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SECURE = False
TALISMAN_ENABLED = False

# Webdriver headless
WEBDRIVER_TYPE = "firefox"
WEBDRIVER_OPTION_ARGS = [
    "--headless",
    "--no-sandbox",
    "--disable-dev-shm-usage",
    "--disable-gpu",
    "--window-size=1280,960",
]

# Webdriver headless
WEBDRIVER_TYPE = "firefox"
WEBDRIVER_OPTION_ARGS = [
    "--headless",
    "--no-sandbox",
    "--disable-dev-shm-usage",
    "--disable-gpu",
    "--window-size=1280,960",
]

# Screenshot timeouts
SCREENSHOT_LOCATE_WAIT = 30
SCREENSHOT_LOAD_WAIT = 90
SCREENSHOT_SELENIUM_HEADSTART = 10
SCREENSHOT_SELENIUM_RETRIES = 3
