from django.contrib import admin

from apps.samples.models import APKSample


@admin.register(APKSample)
class APKSampleAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'file_name',
        'sha256',
        'package_name',
        'version_name',
        'version_code',
        'file_size',
        'is_valid_apk',
        'uploaded_at',
    )
    list_filter = ('is_valid_apk', 'uploaded_at')
    search_fields = ('file_name', 'sha256', 'package_name')
    readonly_fields = ('uploaded_at', 'updated_at')
