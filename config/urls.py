"""Root URL configuration for android_unpack_platform."""

from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('dashboard.urls', namespace='dashboard')),
    path('samples/', include('apps.samples.urls', namespace='samples')),
    path('task-ops/', include('apps.task_ops.urls', namespace='task_ops')),
    path('analysis/', include('apps.analysis.urls', namespace='analysis')),
    path('operations/', include('apps.operations.urls', namespace='operations')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
