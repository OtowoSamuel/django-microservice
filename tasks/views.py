from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from .tasks import process_task
from .serializers import ProcessSerializer, TaskStatusSerializer
from .models import TaskResult

@api_view(['GET'])
@permission_classes([AllowAny])
def health_check(request):
    """
    A simple health check endpoint that doesn't require authentication.
    """
    return Response({"status": "healthy"}, status=status.HTTP_200_OK)

class ProcessView(APIView):
    def post(self, request):
        serializer = ProcessSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        task = process_task.delay(
            email=serializer.validated_data['email'],
            message=serializer.validated_data['message']
        )
        return Response({'task_id': task.id}, status=status.HTTP_202_ACCEPTED)

class TaskStatusView(APIView):
    def get(self, request, task_id):
        try:
            task_result = TaskResult.objects.get(task_id=task_id)
            serializer = TaskStatusSerializer(task_result)
            return Response(serializer.data)
        except TaskResult.DoesNotExist:
            return Response({'error': 'Task not found'}, status=status.HTTP_404_NOT_FOUND)