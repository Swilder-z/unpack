from datetime import timedelta

from django.core.paginator import Paginator
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404, render
from django.utils import timezone

from apps.unpack_tasks.models import TaskExecutionLog, TaskStatus, UnpackJob


def task_list(request):
    status = request.GET.get('status', '').strip()
    shell_type = request.GET.get('shell_type', '').strip()
    strategy = request.GET.get('strategy', '').strip()
    user = request.GET.get('user', '').strip()

    qs = UnpackJob.objects.select_related('sample', 'shell_detection').all()

    if status:
        qs = qs.filter(status=status)
    if shell_type:
        qs = qs.filter(shell_detection__shell_type__icontains=shell_type)
    if strategy:
        qs = qs.filter(strategy=strategy)
    if user:
        qs = qs.filter(
            Q(sample__meta_json__uploader__icontains=user)
            | Q(sample__meta_json__uploaded_by__icontains=user)
        )

    paginator = Paginator(qs, 20)
    page_obj = paginator.get_page(request.GET.get('page'))

    status_stats = UnpackJob.objects.values('status').annotate(total=Count('id')).order_by('status')
    shell_stats = (
        UnpackJob.objects.values('shell_detection__shell_type')
        .annotate(total=Count('id'))
        .order_by('-total')[:10]
    )

    context = {
        'page_obj': page_obj,
        'status_choices': TaskStatus.choices,
        'strategy_choices': UnpackJob._meta.get_field('strategy').choices,
        'filters': {
            'status': status,
            'shell_type': shell_type,
            'strategy': strategy,
            'user': user,
        },
        'status_stats': status_stats,
        'shell_stats': shell_stats,
    }
    return render(request, 'task_ops/task_list.html', context)


def task_detail(request, job_id: int):
    job = get_object_or_404(
        UnpackJob.objects.select_related('sample', 'shell_detection'),
        id=job_id,
    )

    logs = TaskExecutionLog.objects.filter(job=job).order_by('created_at')
    timeline = _build_timeline(job, logs)
    total_duration = _get_total_duration(job)

    context = {
        'job': job,
        'timeline': timeline,
        'total_duration': total_duration,
        'recent_logs': logs.order_by('-created_at')[:20],
    }
    return render(request, 'task_ops/task_detail.html', context)


def task_logs(request, job_id: int):
    job = get_object_or_404(UnpackJob, id=job_id)
    logs = TaskExecutionLog.objects.filter(job=job).order_by('-created_at')

    level = request.GET.get('level', '').strip()
    stage = request.GET.get('stage', '').strip()

    if level:
        logs = logs.filter(level=level)
    if stage:
        logs = logs.filter(stage=stage)

    paginator = Paginator(logs, 50)
    page_obj = paginator.get_page(request.GET.get('page'))

    context = {
        'job': job,
        'page_obj': page_obj,
        'level': level,
        'stage': stage,
        'level_choices': ['INFO', 'WARNING', 'ERROR'],
    }
    return render(request, 'task_ops/task_logs.html', context)


def _build_timeline(job: UnpackJob, logs):
    timeline = []
    last_time = job.started_at or job.created_at
    for log in logs:
        elapsed = None
        if last_time:
            elapsed_delta = log.created_at - last_time
            elapsed = _format_duration(elapsed_delta)
        timeline.append(
            {
                'time': log.created_at,
                'stage': log.stage,
                'level': log.level,
                'message': log.message,
                'elapsed_since_previous': elapsed,
            }
        )
        last_time = log.created_at
    return timeline


def _get_total_duration(job: UnpackJob) -> str:
    if not job.started_at:
        return '-'
    end = job.finished_at or timezone.now()
    delta = end - job.started_at
    return _format_duration(delta)


def _format_duration(delta: timedelta) -> str:
    total_seconds = int(delta.total_seconds())
    if total_seconds < 0:
        total_seconds = 0
    minutes, seconds = divmod(total_seconds, 60)
    hours, minutes = divmod(minutes, 60)
    return f'{hours:02d}:{minutes:02d}:{seconds:02d}'
