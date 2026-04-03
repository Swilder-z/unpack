from apps.analysis.models import UnpackTask
from apps.analysis.tasks import run_unpack_task
from apps.samples.models import APKSample


def create_unpack_task_for_sample(sample: APKSample) -> UnpackTask:
    task = UnpackTask.objects.create(sample=sample)
    celery_res = run_unpack_task.delay(task.id)
    task.celery_task_id = celery_res.id
    task.save(update_fields=['celery_task_id', 'updated_at'])
    return task
