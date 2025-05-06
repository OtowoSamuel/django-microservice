from celery import shared_task
from time import sleep
from .models import TaskResult

from django.utils import timezone  # Add at top of file

@shared_task(bind=True)
def process_task(self, email, message):
    try:
        sleep(10)  # Simulate work
        TaskResult.objects.create(
            task_id=self.request.id,
            email=email,
            message=message,
            status='COMPLETED',
            completed_at=timezone.now()  # ← This addition
        )
        return {'status': 'success', 'task_id': self.request.id}
    except Exception as e:
        return {'status': 'failed', 'error': str(e)}