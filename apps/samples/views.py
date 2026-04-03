from django.contrib import messages
from django.core.exceptions import ValidationError
from django.shortcuts import get_object_or_404, redirect, render

from apps.samples.forms import APKUploadForm
from apps.samples.models import APKSample
from apps.samples.services import create_or_get_sample
from apps.shell_detector.services import detect_shell_and_strategy


def upload_apk(request):
    if request.method == 'POST':
        form = APKUploadForm(request.POST, request.FILES)
        if form.is_valid():
            apk_file = form.cleaned_data['file']
            try:
                sample, created = create_or_get_sample(apk_file)
            except ValidationError as exc:
                form.add_error('file', str(exc))
                return render(request, 'samples/upload.html', {'form': form})

            detection = detect_shell_and_strategy(sample)
            if created:
                messages.success(request, 'APK 上传成功并完成识壳。')
            else:
                messages.info(request, '样本已存在，已返回历史记录并刷新识壳结果。')

            if detection.strategy == 'MANUAL_REVIEW':
                messages.warning(request, '检测到未知/复杂壳，建议人工复核。')

            return redirect('samples:sample_detail', sample_id=sample.id)
    else:
        form = APKUploadForm()

    return render(request, 'samples/upload.html', {'form': form})


def sample_detail(request, sample_id: int):
    sample = get_object_or_404(APKSample, id=sample_id)
    latest_detection = sample.shell_detections.order_by('-created_at').first()
    return render(
        request,
        'samples/detail.html',
        {
            'sample': sample,
            'detection': latest_detection,
        },
    )
