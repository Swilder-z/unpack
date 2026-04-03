from pathlib import Path

from django.conf import settings
from django.db import transaction
from django.utils import timezone

from apps.execution.blackdex_runner import BlackDexRunner, RunnerError
from apps.execution.emulator_manager import EmulatorError, EmulatorManager
from apps.execution.frida_runner import FridaRunner
from apps.execution.task_logger import log_stage
from apps.shell_detector.models import UnpackStrategy
from apps.unpack_tasks.models import TaskStatus, UnpackJob


def execute_unpack_flow(job: UnpackJob) -> dict:
    artifact_dir = Path(getattr(settings, 'ARTIFACT_DIR', settings.BASE_DIR / 'artifacts')) / f'job_{job.id}'
    artifact_dir.mkdir(parents=True, exist_ok=True)

    _update_status(job, TaskStatus.IDENTIFYING_SHELL, '开始识壳阶段')
    if job.shell_detection_id is None:
        _fail_job(job, '缺少 shell_detection 结果，无法继续')
        return {'ok': False, 'reason': 'missing_shell_detection'}

    _update_status(job, TaskStatus.SELECTING_STRATEGY, '开始策略选择')
    strategy = job.strategy or job.shell_detection.strategy
    job.strategy = strategy
    job.artifact_dir = str(artifact_dir)
    job.save(update_fields=['strategy', 'artifact_dir', 'updated_at'])
    log_stage(job, 'SELECTING_STRATEGY', f'策略为 {strategy}', data={'strategy': strategy})

    if strategy == UnpackStrategy.NO_UNPACK:
        _update_status(job, TaskStatus.SUCCESS, '无需脱壳，流程结束')
        _finish_job(job)
        return {'ok': True, 'status': TaskStatus.SUCCESS, 'artifacts': []}

    if strategy == UnpackStrategy.MANUAL_REVIEW:
        job.requires_review = True
        job.save(update_fields=['requires_review', 'updated_at'])
        _update_status(job, TaskStatus.REVIEW_REQUIRED, '策略要求人工复核')
        _finish_job(job)
        return {'ok': False, 'status': TaskStatus.REVIEW_REQUIRED}

    artifacts: list[str] = []
    stage_errors: list[str] = []
    manager = EmulatorManager()

    if strategy in {UnpackStrategy.FRIDA, UnpackStrategy.BLACKDEX_THEN_FRIDA}:
        try:
            _update_status(job, TaskStatus.STARTING_EMULATOR, '启动模拟器')
            log_stage(job, 'STARTING_EMULATOR', '准备启动模拟器')
            manager.start()
            if not manager.is_online():
                raise EmulatorError('模拟器未在线')

            _update_status(job, TaskStatus.INSTALLING_APK, '向模拟器安装APK')
            manager.install_apk(job.sample.file.path)
            log_stage(job, 'INSTALLING_APK', 'APK 安装完成')
        except EmulatorError as exc:
            stage_errors.append(str(exc))
            log_stage(job, 'EMULATOR', str(exc), level='ERROR')
            if strategy == UnpackStrategy.FRIDA:
                return _handle_failure_or_review(job, stage_errors)

    if strategy in {UnpackStrategy.BLACKDEX, UnpackStrategy.BLACKDEX_THEN_FRIDA}:
        try:
            _update_status(job, TaskStatus.RUNNING_BLACKDEX, '运行 BlackDex')
            blackdex_result = BlackDexRunner().run(job.sample.file.path, artifact_dir)
            artifacts.append(blackdex_result['artifact'])
            log_stage(job, 'RUNNING_BLACKDEX', 'BlackDex 执行成功', data=blackdex_result)
        except RunnerError as exc:
            stage_errors.append(str(exc))
            log_stage(job, 'RUNNING_BLACKDEX', str(exc), level='ERROR')
            if strategy == UnpackStrategy.BLACKDEX:
                return _handle_failure_or_review(job, stage_errors)

    if strategy in {UnpackStrategy.FRIDA, UnpackStrategy.BLACKDEX_THEN_FRIDA}:
        try:
            _update_status(job, TaskStatus.RUNNING_FRIDA, '运行 Frida')
            frida_result = FridaRunner().run(job.sample.file.path, artifact_dir)
            artifacts.append(frida_result['artifact'])
            log_stage(job, 'RUNNING_FRIDA', 'Frida 执行成功', data=frida_result)
        except RunnerError as exc:
            stage_errors.append(str(exc))
            log_stage(job, 'RUNNING_FRIDA', str(exc), level='ERROR')
            if strategy == UnpackStrategy.FRIDA:
                return _handle_failure_or_review(job, stage_errors)

    _update_status(job, TaskStatus.COLLECTING_ARTIFACTS, '收集产物文件')
    existing_artifacts = [p for p in artifacts if Path(p).exists()]

    job.artifact_paths = existing_artifacts
    job.result_summary = {
        'artifact_count': len(existing_artifacts),
        'errors': stage_errors,
        'strategy': strategy,
    }
    job.save(update_fields=['artifact_paths', 'result_summary', 'updated_at'])

    try:
        manager.stop()
    except EmulatorError as exc:
        log_stage(job, 'STOP_EMULATOR', f'模拟器关闭失败: {exc}', level='WARNING')

    if existing_artifacts and not stage_errors:
        _update_status(job, TaskStatus.SUCCESS, '任务执行成功')
        _finish_job(job)
        return {'ok': True, 'status': TaskStatus.SUCCESS, 'artifacts': existing_artifacts}

    if existing_artifacts:
        _update_status(job, TaskStatus.PARTIAL_SUCCESS, '部分阶段成功，需复核')
        job.requires_review = True
        job.save(update_fields=['requires_review', 'updated_at'])
        _finish_job(job)
        return {'ok': True, 'status': TaskStatus.PARTIAL_SUCCESS, 'artifacts': existing_artifacts, 'errors': stage_errors}

    return _handle_failure_or_review(job, stage_errors)


def _handle_failure_or_review(job: UnpackJob, errors: list[str]) -> dict:
    joined = '; '.join(errors) if errors else '未知错误'
    if job.retry_count < job.max_retries:
        job.retry_count += 1
        job.error_message = joined
        job.status = TaskStatus.FAILED
        job.save(update_fields=['retry_count', 'error_message', 'status', 'updated_at'])
        log_stage(job, 'FAILED', f'任务失败，准备重试({job.retry_count}/{job.max_retries})', level='ERROR')
        raise RuntimeError(joined)

    job.error_message = joined
    job.requires_review = True
    job.status = TaskStatus.REVIEW_REQUIRED
    job.save(update_fields=['error_message', 'requires_review', 'status', 'updated_at'])
    log_stage(job, 'REVIEW_REQUIRED', '重试耗尽，转人工复核', level='ERROR', data={'errors': errors})
    _finish_job(job)
    return {'ok': False, 'status': TaskStatus.REVIEW_REQUIRED, 'errors': errors}


def _update_status(job: UnpackJob, new_status: str, message: str) -> None:
    with transaction.atomic():
        locked = UnpackJob.objects.select_for_update().get(id=job.id)
        if not locked.can_transition_to(new_status) and locked.status != new_status:
            raise RuntimeError(f'非法状态流转: {locked.status} -> {new_status}')

        locked.status = new_status
        locked.save(update_fields=['status', 'updated_at'])
        log_stage(locked, new_status, message)

    job.status = new_status


def _fail_job(job: UnpackJob, reason: str) -> None:
    job.status = TaskStatus.FAILED
    job.error_message = reason
    job.save(update_fields=['status', 'error_message', 'updated_at'])
    log_stage(job, 'FAILED', reason, level='ERROR')


def _finish_job(job: UnpackJob) -> None:
    if job.finished_at is None:
        job.finished_at = timezone.now()
        job.save(update_fields=['finished_at', 'updated_at'])
