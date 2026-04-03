from django.db.models import Count
from django.shortcuts import render

from apps.analysis.models import UnpackTask


def dashboard(request):
    status = request.GET.get('status', '').strip()
    qs = UnpackTask.objects.select_related('sample')
    if status:
        qs = qs.filter(status=status)

    task_stats = UnpackTask.objects.values('status').annotate(total=Count('id')).order_by('status')
    context = {
        'tasks': qs[:100],
        'task_stats': task_stats,
        'current_status': status,
    }
    return render(request, 'operations/task_list.html', context)
