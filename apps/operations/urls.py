from django.urls import path

from apps.operations import views

app_name = 'operations'

urlpatterns = [
    path('', views.dashboard, name='task_list'),
]
