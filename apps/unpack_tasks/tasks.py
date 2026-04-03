from celery import shared_task
from django.db import transaction
from django.utils import timezone

from apps.execution.services import execute_unpack_flow
from apps.unpack_tasks.models import TaskStatus, UnpackJob


@shared_task(bind=True, autoretry_for=(RuntimeError,), retry_backoff=True, retry_kwargs={'max_retries': 3})
def run_unpack_job(self, job_id: int) -> dict:
    job = UnpackJob.objects.select_related('sample', 'shell_detection').get(id=job_id)
    _queue_job(job, self.request.id)
    result = execute_unpack_flow(job)
    return result


def enqueue_unpack_job(job: UnpackJob) -> UnpackJob:
    task_result = run_unpack_job.delay(job.id)
    _queue_job(job, task_result.id)
    return job


def _queue_job(job: UnpackJob, celery_task_id: str) -> None:
    with transaction.atomic():
        job = UnpackJob.objects.select_for_update().get(id=job.id)
        if job.status == TaskStatus.PENDING:
            job.status = TaskStatus.QUEUED
            job.started_at = timezone.now()
        job.celery_task_id = celery_task_id
        job.save(update_fields=['status', 'started_at', 'celery_task_id', 'updated_at'])
