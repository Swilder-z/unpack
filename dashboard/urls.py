from django.urls import path

from dashboard.views import health

app_name = 'dashboard'

urlpatterns = [
    path('', health, name='health'),
]
