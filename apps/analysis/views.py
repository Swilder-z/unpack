from django.shortcuts import get_object_or_404, redirect, render

from apps.analysis.models import UnpackTask
from apps.analysis.tasks import run_unpack_task


def task_detail(request, task_id: int):
    task = get_object_or_404(UnpackTask.objects.select_related('sample'), id=task_id)
    return render(request, 'analysis/task_detail.html', {'task': task})


def retry_task(request, task_id: int):
    task = get_object_or_404(UnpackTask, id=task_id)
    if task.status in {'FAILED', 'REVIEW_REQUIRED'}:
        task.status = 'PENDING'
        task.save(update_fields=['status', 'updated_at'])
        res = run_unpack_task.delay(task.id)
        task.celery_task_id = res.id
        task.save(update_fields=['celery_task_id', 'updated_at'])
    return redirect('analysis:task_detail', task_id=task_id)
