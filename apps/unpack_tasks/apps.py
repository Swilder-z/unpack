from django.apps import AppConfig


class UnpackTasksConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.unpack_tasks'
    verbose_name = '异步脱壳任务'
