from django.contrib import admin

from apps.shell_detector.models import ShellDetectionResult


@admin.register(ShellDetectionResult)
class ShellDetectionResultAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'sample',
        'shell_type',
        'confidence',
        'strategy',
        'exit_code',
        'created_at',
    )
    list_filter = ('shell_type', 'strategy', 'created_at')
    search_fields = ('sample__file_name', 'sample__sha256', 'shell_type', 'evidence')
    readonly_fields = ('created_at', 'updated_at')
