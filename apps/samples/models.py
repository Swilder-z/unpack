from django.db import models


class APKSample(models.Model):
    file = models.FileField(upload_to='apks/%Y/%m/%d/')
    file_name = models.CharField(max_length=255)
    file_size = models.BigIntegerField(default=0)
    mime_type = models.CharField(max_length=128, blank=True, default='')
    sha256 = models.CharField(max_length=64, unique=True)

    package_name = models.CharField(max_length=255, blank=True, default='')
    version_name = models.CharField(max_length=128, blank=True, default='')
    version_code = models.CharField(max_length=64, blank=True, default='')

    is_valid_apk = models.BooleanField(default=False)
    validation_errors = models.TextField(blank=True, default='')

    uploaded_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    meta_json = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ['-uploaded_at']
        indexes = [
            models.Index(fields=['sha256']),
            models.Index(fields=['package_name']),
            models.Index(fields=['uploaded_at']),
        ]

    def __str__(self) -> str:
        return f'{self.file_name} ({self.sha256[:10]})'
