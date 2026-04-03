from pathlib import Path

from celery import shared_task
from django.conf import settings
from django.core.exceptions import ValidationError
from django.db import transaction

from apps.analysis.models import UnpackTask
from apps.analysis.services.runners.blackdex_runner import BlackDexRunner, RunnerError
from apps.analysis.services.runners.frida_runner import FridaRunner
from apps.analysis.services.shell_identifier import ShellIdentifierError, identify_shell
from apps.analysis.services.strategy_selector import choose_strategy
from apps.analysis.services.task_service import update_task_status
from apps.common.enums import TaskStatus, UnpackStrategy
from apps.samples.services import validate_apk_file


@shared_task(bind=True, autoretry_for=(RunnerError,), retry_backoff=True, retry_kwargs={'max_retries': 3})
def run_unpack_task(self, task_id: int):
    task = UnpackTask.objects.select_related('sample').get(id=task_id)

    with transaction.atomic():
        update_task_status(task, TaskStatus.VALIDATING, '开始校验 APK')
    try:
        with task.sample.file.open('rb') as f:
            validate_apk_file(f)
    except ValidationError as exc:
        task.error_message = str(exc)
        task.save(update_fields=['error_message', 'updated_at'])
        update_task_status(task, TaskStatus.FAILED, 'APK 校验失败')
        return

    update_task_status(task, TaskStatus.IDENTIFYING_SHELL, '开始 APKiD 识壳')
    try:
        shell_report = identify_shell(task.sample.file.path)
        task.shell_report = shell_report
        task.shell_type = str(shell_report)[:120]
        task.save(update_fields=['shell_report', 'shell_type', 'updated_at'])
    except ShellIdentifierError as exc:
        task.error_message = str(exc)
        task.requires_manual_review = True
        task.save(update_fields=['error_message', 'requires_manual_review', 'updated_at'])
        update_task_status(task, TaskStatus.REVIEW_REQUIRED, '识壳失败，转人工复核')
        return

    strategy, reason = choose_strategy(task.shell_report)
    task.strategy = strategy
    task.context_json = {'strategy_reason': reason}
    task.save(update_fields=['strategy', 'context_json', 'updated_at'])
    update_task_status(task, TaskStatus.STRATEGY_SELECTED, reason)

    if strategy == UnpackStrategy.MANUAL:
        task.requires_manual_review = True
        task.save(update_fields=['requires_manual_review', 'updated_at'])
        update_task_status(task, TaskStatus.REVIEW_REQUIRED, '策略要求人工复核')
        return

    update_task_status(task, TaskStatus.RUNNING_UNPACK, '开始执行脱壳')
    out_dir = Path(settings.ARTIFACT_ROOT) / f'task_{task.id}'

    try:
        if strategy == UnpackStrategy.BLACKDEX:
            artifact = BlackDexRunner().run(task.sample.file.path, out_dir)
        elif strategy == UnpackStrategy.FRIDA:
            artifact = FridaRunner().run(task.sample.file.path, out_dir)
        else:
            try:
                artifact = BlackDexRunner().run(task.sample.file.path, out_dir)
            except RunnerError:
                artifact = FridaRunner().run(task.sample.file.path, out_dir)

        task.result_artifact = str(artifact)
        task.error_message = ''
        task.save(update_fields=['result_artifact', 'error_message', 'updated_at'])
        update_task_status(task, TaskStatus.SUCCESS, '脱壳任务完成')
    except RunnerError as exc:
        task.retry_count += 1
        task.error_message = str(exc)
        if task.retry_count >= task.max_retries:
            task.requires_manual_review = True
            task.save(update_fields=['retry_count', 'error_message', 'requires_manual_review', 'updated_at'])
            update_task_status(task, TaskStatus.REVIEW_REQUIRED, '脱壳多次失败，转人工复核')
        else:
            task.save(update_fields=['retry_count', 'error_message', 'updated_at'])
            update_task_status(task, TaskStatus.FAILED, '脱壳失败，等待重试')
            raise
