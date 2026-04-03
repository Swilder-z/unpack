from django.db import models


class TaskStatus(models.TextChoices):
    PENDING = 'PENDING', '待执行'
    VALIDATING = 'VALIDATING', '校验中'
    IDENTIFYING_SHELL = 'IDENTIFYING_SHELL', '识壳中'
    STRATEGY_SELECTED = 'STRATEGY_SELECTED', '策略已选择'
    RUNNING_UNPACK = 'RUNNING_UNPACK', '脱壳中'
    REVIEW_REQUIRED = 'REVIEW_REQUIRED', '待人工复核'
    SUCCESS = 'SUCCESS', '成功'
    FAILED = 'FAILED', '失败'


class UnpackStrategy(models.TextChoices):
    BLACKDEX = 'BLACKDEX', 'BlackDex'
    FRIDA = 'FRIDA', 'Frida'
    HYBRID = 'HYBRID', 'Hybrid'
    MANUAL = 'MANUAL', 'Manual'
