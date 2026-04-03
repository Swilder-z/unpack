from django.contrib import admin
from django.contrib.admin.sites import AlreadyRegistered

from apps.unpack_tasks.models import TaskExecutionLog, UnpackJob


class TaskExecutionLogInline(admin.TabularInline):
    model = TaskExecutionLog
    extra = 0
    readonly_fields = ('stage', 'level', 'message', 'data', 'created_at')


class UnpackJobAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'sample',
        'status',
        'strategy',
        'retry_count',
        'requires_review',
        'created_at',
    )
    list_filter = ('status', 'strategy', 'requires_review', 'created_at')
    search_fields = ('sample__file_name', 'sample__sha256', 'celery_task_id')
    readonly_fields = ('created_at', 'updated_at', 'started_at', 'finished_at')
    inlines = [TaskExecutionLogInline]


class TaskExecutionLogAdmin(admin.ModelAdmin):
    list_display = ('id', 'job', 'stage', 'level', 'created_at')
    list_filter = ('level', 'stage', 'created_at')
    search_fields = ('job__sample__file_name', 'message')


try:
    admin.site.register(UnpackJob, UnpackJobAdmin)
except AlreadyRegistered:
    pass

try:
    admin.site.register(TaskExecutionLog, TaskExecutionLogAdmin)
except AlreadyRegistered:
    pass
