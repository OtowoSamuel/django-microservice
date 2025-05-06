from django.urls import path
from .views import ProcessView, TaskStatusView

urlpatterns = [
    path('process/', ProcessView.as_view(), name='process'),
    path('status/<str:task_id>/', TaskStatusView.as_view(), name='status'),
]

print("Tasks URLs loaded! Path patterns:", urlpatterns)