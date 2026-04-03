from django.contrib import admin
from django.contrib.admin.sites import AlreadyRegistered

from apps.unpack_tasks.models import TaskExecutionLog, UnpackJob


class TaskOpsUnpackJobAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'sample',
        'status',
        'strategy',
        'retry_count',
        'requires_review',
        'started_at',
        'finished_at',
    )
    list_filter = ('status', 'strategy', 'requires_review')
    search_fields = ('sample__file_name', 'sample__sha256', 'error_message')
    readonly_fields = ('created_at', 'updated_at', 'started_at', 'finished_at')


class TaskOpsExecutionLogAdmin(admin.ModelAdmin):
    list_display = ('id', 'job', 'stage', 'level', 'created_at')
    list_filter = ('level', 'stage', 'created_at')
    search_fields = ('job__sample__file_name', 'message')


try:
    admin.site.register(UnpackJob, TaskOpsUnpackJobAdmin)
except AlreadyRegistered:
    pass

try:
    admin.site.register(TaskExecutionLog, TaskOpsExecutionLogAdmin)
except AlreadyRegistered:
    pass
