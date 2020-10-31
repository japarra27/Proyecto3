"""
Django settings for DesignMatch project.

Generated by 'django-admin startproject' using Django 3.1.

For more information on this file, see
https://docs.djangoproject.com/en/3.1/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/3.1/ref/settings/
"""

from __future__ import absolute_import, unicode_literals
from celery.schedules import crontab
import apirest.tasks
import os
from pathlib import Path
from helpers import env_vars

# list of secret keys stored in the gcp secret manager 
env_keys = env_vars.access_secret_version()

# Build paths inside the project like this: BASE_DIR / 'subdir'.
# BASE_DIR = Path(__file__).resolve(strict=True).parent.parent
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/3.1/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = env_keys["DJANGO_PASSWORD"]

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True
SENDGRID_SANDBOX_MODE_IN_DEBUG = False  

ALLOWED_HOSTS = ['*']
CORS_ORIGIN_ALLOW_ALL = True


# CELERY CONFIGURATION
CELERY_BROKER_URL= "redis://10.57.0.4:6379/1"
CELERY_TIMEZONE = 'America/Bogota'

# Cache time to live is 15 minutes.
CACHE_TTL = 60 * 15

CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://10.57.0.4:6379/1",
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        }
    }
}

CELERY_BEAT_SCHEDULE = {
    "conversion_video": {
        "task": "apirest.tasks.conversion_design",
        "schedule": 1.0,
    },
}


# INSTALLED DJANGO APPS
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken',
    'apirest',
    'django_celery_beat',
    'corsheaders',
    'storages',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.TokenAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ]
}

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'corsheaders.middleware.CorsMiddleware',
]

ROOT_URLCONF = 'DesignMatch.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'DesignMatch.wsgi.application'


# Database
# https://docs.djangoproject.com/en/3.1/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': env_keys['DB_NAME_MDC'],
        'USER': env_keys['DB_USER_MDC'],
        'PASSWORD': env_keys['DB_PASSWORD_MDC'],
        'HOST': env_keys['DB_HOST_MDC'],
        'PORT': env_keys['DB_PORT_MDC'],
    }
}


# Password validation
# https://docs.djangoproject.com/en/3.1/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Enviar correos electronicos:
EMAIL_BACKEND = 'sendgrid_backend.SendgridBackend'
EMAIL_USE_TLS = True
EMAIL_HOST = env_keys["SENDGRID_HOST"]
EMAIL_HOST_USER = env_keys["SENDGRID_USER"]
EMAIL_HOST_PASSWORD = env_keys["SENDGRID_PASSWORD"]
EMAIL_PORT = env_keys["SENDGRID_PORT"]
SENDGRID_API_KEY = env_keys["SENDGRID_API_KEY"]

# Internationalization
# https://docs.djangoproject.com/en/3.1/topics/i18n/

LANGUAGE_CODE = 'es-co'

TIME_ZONE = 'America/Bogota'

USE_I18N = True

USE_L10N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/3.1/howto/static-files/

GS_BUCKET_NAME = "dsc-proyectos-mdd-cdn-bucket"

MEDIA_URL = 'https://storage.googleapis.com/{}/'.format(GS_BUCKET_NAME)
MEDIA_ROOT = "mnt/"

STATIC_URL = 'https://storage.googleapis.com/{}/'.format(GS_BUCKET_NAME)
STATIC_ROOT = "static/"


# Define static storage via django-storages[google]
STATICFILES_DIRS = []
DEFAULT_FILE_STORAGE = "storages.backends.gcloud.GoogleCloudStorage"
STATICFILES_STORAGE = "storages.backends.gcloud.GoogleCloudStorage"
GS_DEFAULT_ACL = "publicRead"
