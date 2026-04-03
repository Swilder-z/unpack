from django.urls import path

from apps.samples import views

app_name = 'samples'

urlpatterns = [
    path('upload/', views.upload_apk, name='upload_apk'),
    path('<int:sample_id>/', views.sample_detail, name='sample_detail'),
]
