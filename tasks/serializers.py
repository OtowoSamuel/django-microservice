from rest_framework import serializers
from .models import TaskResult

class ProcessSerializer(serializers.Serializer):
    email = serializers.EmailField()
    message = serializers.CharField(max_length=500)

class TaskStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = TaskResult
        fields = ['task_id', 'email', 'message', 'status', 'created_at', 'completed_at']