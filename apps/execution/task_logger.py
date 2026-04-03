from apps.unpack_tasks.models import TaskExecutionLog, UnpackJob


def log_stage(job: UnpackJob, stage: str, message: str, level: str = 'INFO', data: dict | None = None) -> None:
    TaskExecutionLog.objects.create(
        job=job,
        stage=stage,
        level=level,
        message=message,
        data=data or {},
    )
