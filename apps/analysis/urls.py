from django.urls import path

from apps.analysis import views

app_name = 'analysis'

urlpatterns = [
    path('tasks/<int:task_id>/', views.task_detail, name='task_detail'),
    path('tasks/<int:task_id>/retry/', views.retry_task, name='retry_task'),
]
