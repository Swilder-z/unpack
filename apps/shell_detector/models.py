from django.db import models

from apps.samples.models import APKSample


class UnpackStrategy(models.TextChoices):
    NO_UNPACK = 'NO_UNPACK', '无需脱壳'
    BLACKDEX = 'BLACKDEX', 'BlackDex'
    FRIDA = 'FRIDA', 'Frida'
    BLACKDEX_THEN_FRIDA = 'BLACKDEX_THEN_FRIDA', 'BlackDex 后 Frida'
    MANUAL_REVIEW = 'MANUAL_REVIEW', '人工复核'


class ShellDetectionResult(models.Model):
    sample = models.ForeignKey(APKSample, on_delete=models.CASCADE, related_name='shell_detections')

    shell_type = models.CharField(max_length=128, blank=True, default='UNKNOWN')
    confidence = models.FloatField(default=0.0)
    evidence = models.TextField(blank=True, default='')

    strategy = models.CharField(
        max_length=32,
        choices=UnpackStrategy.choices,
        default=UnpackStrategy.BLACKDEX_THEN_FRIDA,
    )

    raw_output = models.JSONField(default=dict, blank=True)
    command = models.CharField(max_length=255, blank=True, default='')
    exit_code = models.IntegerField(null=True, blank=True)
    error_message = models.TextField(blank=True, default='')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['shell_type']),
            models.Index(fields=['strategy']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self) -> str:
        return f'ShellDetection(sample={self.sample_id}, shell={self.shell_type}, strategy={self.strategy})'
