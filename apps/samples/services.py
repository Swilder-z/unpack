import hashlib
import zipfile
from pathlib import Path

from apkutils2 import APK
from django.core.exceptions import ValidationError

from apps.samples.models import APKSample

ALLOWED_MIME_TYPES = {
    'application/vnd.android.package-archive',
    'application/zip',
    'application/octet-stream',
}


def calc_sha256(uploaded_file) -> str:
    hasher = hashlib.sha256()
    for chunk in uploaded_file.chunks():
        hasher.update(chunk)
    uploaded_file.seek(0)
    return hasher.hexdigest()


def validate_apk_upload(uploaded_file) -> None:
    if not uploaded_file.name.lower().endswith('.apk'):
        raise ValidationError('文件扩展名不合法，必须为 .apk')

    content_type = getattr(uploaded_file, 'content_type', '') or ''
    if content_type and content_type not in ALLOWED_MIME_TYPES:
        raise ValidationError(f'文件 MIME 类型不合法: {content_type}')

    header = uploaded_file.read(4)
    uploaded_file.seek(0)
    if header[:2] != b'PK':
        raise ValidationError('APK 文件头校验失败，非 ZIP/APK 文件')

    try:
        with zipfile.ZipFile(uploaded_file) as archive:
            names = set(archive.namelist())
            if 'AndroidManifest.xml' not in names:
                raise ValidationError('APK 文件缺少 AndroidManifest.xml')
    except zipfile.BadZipFile as exc:
        raise ValidationError('APK 压缩结构无效') from exc
    finally:
        uploaded_file.seek(0)


def extract_apk_meta(file_path: Path) -> dict:
    meta = {
        'package_name': '',
        'version_name': '',
        'version_code': '',
        'manifest': {},
    }
    try:
        apk = APK.from_file(str(file_path))
        manifest = apk.manifest_data or {}
        meta['manifest'] = manifest
        meta['package_name'] = manifest.get('@package', '')
        meta['version_name'] = manifest.get('@android:versionName', '')
        meta['version_code'] = str(manifest.get('@android:versionCode', ''))
    except Exception as exc:  # noqa: BLE001
        meta['parse_error'] = str(exc)
    return meta


def create_or_get_sample(uploaded_file) -> tuple[APKSample, bool]:
    validate_apk_upload(uploaded_file)
    sha256 = calc_sha256(uploaded_file)

    existing = APKSample.objects.filter(sha256=sha256).first()
    if existing:
        return existing, False

    sample = APKSample.objects.create(
        file=uploaded_file,
        file_name=uploaded_file.name,
        file_size=uploaded_file.size,
        mime_type=getattr(uploaded_file, 'content_type', '') or '',
        sha256=sha256,
        is_valid_apk=True,
    )

    meta = extract_apk_meta(Path(sample.file.path))
    sample.package_name = meta.get('package_name', '')
    sample.version_name = meta.get('version_name', '')
    sample.version_code = meta.get('version_code', '')
    sample.meta_json = meta
    sample.save(
        update_fields=['package_name', 'version_name', 'version_code', 'meta_json', 'updated_at']
    )
    return sample, True



def validate_apk_file(uploaded_file) -> None:
    """Backward-compatible alias for old analysis flow."""
    validate_apk_upload(uploaded_file)
