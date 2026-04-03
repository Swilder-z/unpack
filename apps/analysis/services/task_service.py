from django.utils import timezone

from apps.analysis.models import TaskEvent, UnpackTask
from apps.analysis.services.state_machine import can_transition


def update_task_status(task: UnpackTask, new_status: str, message: str = '', payload: dict | None = None) -> None:
    payload = payload or {}
    if not can_transition(task.status, new_status) and task.status != new_status:
        raise ValueError(f'非法状态流转: {task.status} -> {new_status}')

    old_status = task.status
    task.status = new_status
    if new_status == 'RUNNING_UNPACK' and task.started_at is None:
        task.started_at = timezone.now()
    if new_status in {'SUCCESS', 'FAILED'}:
        task.finished_at = timezone.now()
    task.save(update_fields=['status', 'started_at', 'finished_at', 'updated_at'])

    TaskEvent.objects.create(
        task=task,
        old_status=old_status,
        new_status=new_status,
        message=message,
        payload=payload,
    )
