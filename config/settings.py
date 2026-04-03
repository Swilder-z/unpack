"""Core Django settings for android_unpack_platform."""

from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# -----------------------------
# Core settings
# -----------------------------
SECRET_KEY = 'replace-me-in-production'
DEBUG = True
ALLOWED_HOSTS = ['127.0.0.1', 'localhost']

# -----------------------------
# Application definition
# -----------------------------
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Business apps
    'users',
    'apps.task_ops',
    'dashboard',
    'apps.common',
    'apps.samples',
    'apps.shell_detector',
    'apps.unpack_tasks',
    'apps.execution',
    'apps.analysis',
    'apps.operations',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'
ASGI_APPLICATION = 'config.asgi.application'

# -----------------------------
# Database: PostgreSQL placeholder
# -----------------------------
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'android_unpack_platform',
        'USER': 'postgres',
        'PASSWORD': 'postgres',
        'HOST': '127.0.0.1',
        'PORT': '5432',
    }
}

# -----------------------------
# Password validation
# -----------------------------
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# -----------------------------
# i18n / timezone
# -----------------------------
LANGUAGE_CODE = 'zh-hans'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# -----------------------------
# Static & Media
# -----------------------------
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# -----------------------------
# Project directories (separated)
# -----------------------------
UPLOAD_DIR = BASE_DIR / 'data' / 'uploads'
LOG_DIR = BASE_DIR / 'data' / 'logs'
ARTIFACT_DIR = BASE_DIR / 'data' / 'artifacts'

for directory in (UPLOAD_DIR, LOG_DIR, ARTIFACT_DIR, MEDIA_ROOT):
    directory.mkdir(parents=True, exist_ok=True)

# -----------------------------
# Redis placeholder
# -----------------------------
REDIS_HOST = '127.0.0.1'
REDIS_PORT = 6379
REDIS_DB = 0
REDIS_URL = f'redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}'

# -----------------------------
# Celery settings
# -----------------------------
CELERY_BROKER_URL = REDIS_URL
CELERY_RESULT_BACKEND = REDIS_URL
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = TIME_ZONE
CELERY_ENABLE_UTC = True
CELERY_TASK_TRACK_STARTED = True
CELERY_TASK_TIME_LIMIT = 20 * 60
CELERY_TASK_SOFT_TIME_LIMIT = 15 * 60

APKiD_COMMAND = ['apkid', '-j']
APKiD_TIMEOUT = 120

EMULATOR_START_COMMAND = ['echo', 'start_emulator']
EMULATOR_STOP_COMMAND = ['echo', 'stop_emulator']
EMULATOR_STATUS_COMMAND = ['echo', 'online']
EMULATOR_INSTALL_APK_COMMAND = ['echo', 'install_apk']
EMULATOR_TIMEOUT = 180
BLACKDEX_COMMAND = ['echo', 'blackdex']
BLACKDEX_TIMEOUT = 300
FRIDA_COMMAND = ['echo', 'frida']
FRIDA_TIMEOUT = 300

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
