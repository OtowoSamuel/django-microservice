from django.db import models

class TaskResult(models.Model):
    task_id = models.CharField(max_length=255, unique=True)
    email = models.EmailField()
    message = models.TextField()
    status = models.CharField(max_length=50, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return f"{self.task_id} - {self.status}"