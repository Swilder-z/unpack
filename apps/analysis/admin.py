from django.contrib import admin

from apps.analysis.models import TaskEvent, UnpackTask


class TaskEventInline(admin.TabularInline):
    model = TaskEvent
    extra = 0
    readonly_fields = ('old_status', 'new_status', 'message', 'payload', 'created_at')


@admin.register(UnpackTask)
class UnpackTaskAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'sample',
        'status',
        'strategy',
        'requires_manual_review',
        'retry_count',
        'created_at',
    )
    list_filter = ('status', 'strategy', 'requires_manual_review', 'created_at')
    search_fields = ('sample__file_name', 'sample__sha256', 'shell_type')
    readonly_fields = ('created_at', 'updated_at', 'started_at', 'finished_at')
    inlines = [TaskEventInline]


@admin.register(TaskEvent)
class TaskEventAdmin(admin.ModelAdmin):
    list_display = ('id', 'task', 'old_status', 'new_status', 'created_at')
    list_filter = ('new_status', 'created_at')
    search_fields = ('task__sample__file_name', 'message')
