from django.db import models

from apps.common.enums import TaskStatus, UnpackStrategy
from apps.samples.models import APKSample


class UnpackTask(models.Model):
    sample = models.ForeignKey(APKSample, on_delete=models.CASCADE, related_name='tasks')
    status = models.CharField(max_length=32, choices=TaskStatus.choices, default=TaskStatus.PENDING)
    strategy = models.CharField(max_length=16, choices=UnpackStrategy.choices, blank=True, default='')
    shell_type = models.CharField(max_length=128, blank=True, default='')
    shell_report = models.JSONField(default=dict, blank=True)
    retry_count = models.PositiveIntegerField(default=0)
    max_retries = models.PositiveIntegerField(default=3)
    requires_manual_review = models.BooleanField(default=False)
    review_note = models.TextField(blank=True, default='')
    celery_task_id = models.CharField(max_length=64, blank=True, default='')
    result_artifact = models.CharField(max_length=512, blank=True, default='')
    error_message = models.TextField(blank=True, default='')
    started_at = models.DateTimeField(null=True, blank=True)
    finished_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    context_json = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status']),
            models.Index(fields=['strategy']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f'Task#{self.id} sample={self.sample_id} status={self.status}'


class TaskEvent(models.Model):
    task = models.ForeignKey(UnpackTask, on_delete=models.CASCADE, related_name='events')
    old_status = models.CharField(max_length=32, blank=True, default='')
    new_status = models.CharField(max_length=32, choices=TaskStatus.choices)
    message = models.TextField(blank=True, default='')
    payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']
