from django.db import models

from apps.samples.models import APKSample
from apps.shell_detector.models import ShellDetectionResult, UnpackStrategy


class TaskStatus(models.TextChoices):
    PENDING = 'PENDING', '待处理'
    QUEUED = 'QUEUED', '已入队'
    IDENTIFYING_SHELL = 'IDENTIFYING_SHELL', '识壳中'
    SELECTING_STRATEGY = 'SELECTING_STRATEGY', '选择策略'
    STARTING_EMULATOR = 'STARTING_EMULATOR', '启动模拟器'
    INSTALLING_APK = 'INSTALLING_APK', '安装APK'
    RUNNING_BLACKDEX = 'RUNNING_BLACKDEX', '运行BlackDex'
    RUNNING_FRIDA = 'RUNNING_FRIDA', '运行Frida'
    COLLECTING_ARTIFACTS = 'COLLECTING_ARTIFACTS', '收集产物'
    SUCCESS = 'SUCCESS', '成功'
    PARTIAL_SUCCESS = 'PARTIAL_SUCCESS', '部分成功'
    FAILED = 'FAILED', '失败'
    REVIEW_REQUIRED = 'REVIEW_REQUIRED', '人工复核'


ALLOWED_TRANSITIONS: dict[str, set[str]] = {
    TaskStatus.PENDING: {TaskStatus.QUEUED, TaskStatus.FAILED},
    TaskStatus.QUEUED: {TaskStatus.IDENTIFYING_SHELL, TaskStatus.SELECTING_STRATEGY, TaskStatus.FAILED},
    TaskStatus.IDENTIFYING_SHELL: {TaskStatus.SELECTING_STRATEGY, TaskStatus.REVIEW_REQUIRED, TaskStatus.FAILED},
    TaskStatus.SELECTING_STRATEGY: {
        TaskStatus.STARTING_EMULATOR,
        TaskStatus.RUNNING_BLACKDEX,
        TaskStatus.RUNNING_FRIDA,
        TaskStatus.REVIEW_REQUIRED,
        TaskStatus.SUCCESS,
        TaskStatus.FAILED,
    },
    TaskStatus.STARTING_EMULATOR: {TaskStatus.INSTALLING_APK, TaskStatus.RUNNING_BLACKDEX, TaskStatus.RUNNING_FRIDA, TaskStatus.FAILED},
    TaskStatus.INSTALLING_APK: {TaskStatus.RUNNING_BLACKDEX, TaskStatus.RUNNING_FRIDA, TaskStatus.FAILED},
    TaskStatus.RUNNING_BLACKDEX: {TaskStatus.RUNNING_FRIDA, TaskStatus.COLLECTING_ARTIFACTS, TaskStatus.SUCCESS, TaskStatus.PARTIAL_SUCCESS, TaskStatus.FAILED},
    TaskStatus.RUNNING_FRIDA: {TaskStatus.COLLECTING_ARTIFACTS, TaskStatus.SUCCESS, TaskStatus.PARTIAL_SUCCESS, TaskStatus.FAILED},
    TaskStatus.COLLECTING_ARTIFACTS: {TaskStatus.SUCCESS, TaskStatus.PARTIAL_SUCCESS, TaskStatus.FAILED},
    TaskStatus.SUCCESS: set(),
    TaskStatus.PARTIAL_SUCCESS: {TaskStatus.REVIEW_REQUIRED},
    TaskStatus.FAILED: {TaskStatus.QUEUED, TaskStatus.REVIEW_REQUIRED},
    TaskStatus.REVIEW_REQUIRED: {TaskStatus.QUEUED, TaskStatus.SUCCESS, TaskStatus.FAILED},
}


class UnpackJob(models.Model):
    sample = models.ForeignKey(APKSample, on_delete=models.CASCADE, related_name='unpack_jobs')
    shell_detection = models.ForeignKey(
        ShellDetectionResult,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='unpack_jobs',
    )

    status = models.CharField(max_length=32, choices=TaskStatus.choices, default=TaskStatus.PENDING)
    strategy = models.CharField(
        max_length=32,
        choices=UnpackStrategy.choices,
        default=UnpackStrategy.BLACKDEX_THEN_FRIDA,
    )

    retry_count = models.PositiveIntegerField(default=0)
    max_retries = models.PositiveIntegerField(default=3)

    celery_task_id = models.CharField(max_length=64, blank=True, default='')

    artifact_dir = models.CharField(max_length=512, blank=True, default='')
    artifact_paths = models.JSONField(default=list, blank=True)
    result_summary = models.JSONField(default=dict, blank=True)

    error_message = models.TextField(blank=True, default='')
    requires_review = models.BooleanField(default=False)

    started_at = models.DateTimeField(null=True, blank=True)
    finished_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['strategy']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self) -> str:
        return f'UnpackJob#{self.id} sample={self.sample_id} status={self.status}'

    def can_transition_to(self, new_status: str) -> bool:
        return new_status in ALLOWED_TRANSITIONS.get(self.status, set())


class TaskExecutionLog(models.Model):
    job = models.ForeignKey(UnpackJob, on_delete=models.CASCADE, related_name='logs')
    stage = models.CharField(max_length=64)
    level = models.CharField(max_length=16, default='INFO')
    message = models.TextField()
    data = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']
        indexes = [
            models.Index(fields=['stage']),
            models.Index(fields=['level']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self) -> str:
        return f'Log(job={self.job_id}, stage={self.stage}, level={self.level})'
