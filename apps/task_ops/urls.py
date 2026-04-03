from django.urls import path

from apps.task_ops import views

app_name = 'task_ops'

urlpatterns = [
    path('tasks/', views.task_list, name='task_list'),
    path('tasks/<int:job_id>/', views.task_detail, name='task_detail'),
    path('tasks/<int:job_id>/logs/', views.task_logs, name='task_logs'),
]
