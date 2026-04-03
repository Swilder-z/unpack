"""Celery application bootstrap for android_unpack_platform."""

import os

from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

app = Celery('android_unpack_platform')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()


@app.task(bind=True)
def debug_task(self):
    """Simple debug task to verify worker setup."""
    print(f'Request: {self.request!r}')
