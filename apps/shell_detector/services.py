import json
import subprocess
from dataclasses import dataclass

from django.conf import settings

from apps.samples.models import APKSample
from apps.shell_detector.models import ShellDetectionResult
from apps.shell_detector.strategy_selector import select_unpack_strategy


@dataclass
class NormalizedAPKiDResult:
    shell_type: str
    confidence: float
    evidence: str
    raw_output: dict
    command: str
    exit_code: int | None
    error_message: str


def _parse_shell_type(apkid_json: dict) -> tuple[str, str]:
    files = apkid_json.get('files', [])
    if not files:
        return 'UNKNOWN', 'APKiD 未返回 files 字段'

    first = files[0]
    matches = first.get('matches', {})
    for category, tags in matches.items():
        tags = tags if isinstance(tags, list) else [str(tags)]
        lowered = ' '.join(tags).lower()
        if '360' in lowered or 'qihoo' in lowered:
            return 'JIAGU_360', f'{category}: {tags}'
        if 'bangcle' in lowered:
            return 'BANGCLE', f'{category}: {tags}'
        if 'ijiami' in lowered:
            return 'IJIAMI', f'{category}: {tags}'
        if 'legu' in lowered or 'tencent' in lowered:
            return 'TENCENT_LEGU', f'{category}: {tags}'

    if matches:
        return 'UNKNOWN', str(matches)

    return 'NONE', '未识别到壳特征'


def run_apkid(file_path: str, timeout: int = 120) -> NormalizedAPKiDResult:
    base_cmd = getattr(settings, 'APKiD_COMMAND', ['apkid', '-j'])
    cmd = [*base_cmd, file_path]
    command_str = ' '.join(cmd)

    try:
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        return NormalizedAPKiDResult(
            shell_type='UNKNOWN',
            confidence=0.0,
            evidence='APKiD 执行超时',
            raw_output={'stdout': exc.stdout, 'stderr': exc.stderr},
            command=command_str,
            exit_code=None,
            error_message='timeout',
        )
    except FileNotFoundError:
        return NormalizedAPKiDResult(
            shell_type='UNKNOWN',
            confidence=0.0,
            evidence='未找到 apkid 命令，请检查环境安装',
            raw_output={},
            command=command_str,
            exit_code=None,
            error_message='apkid_not_found',
        )
    except OSError as exc:
        return NormalizedAPKiDResult(
            shell_type='UNKNOWN',
            confidence=0.0,
            evidence='系统无法启动 APKiD',
            raw_output={},
            command=command_str,
            exit_code=None,
            error_message=str(exc),
        )

    if proc.returncode != 0:
        return NormalizedAPKiDResult(
            shell_type='UNKNOWN',
            confidence=0.0,
            evidence='APKiD 返回非零退出码',
            raw_output={'stdout': proc.stdout, 'stderr': proc.stderr},
            command=command_str,
            exit_code=proc.returncode,
            error_message=proc.stderr.strip(),
        )

    try:
        parsed = json.loads(proc.stdout or '{}')
    except json.JSONDecodeError:
        parsed = {'stdout': proc.stdout, 'stderr': proc.stderr, 'parse_error': True}
        return NormalizedAPKiDResult(
            shell_type='UNKNOWN',
            confidence=0.0,
            evidence='APKiD 输出不是合法 JSON',
            raw_output=parsed,
            command=command_str,
            exit_code=proc.returncode,
            error_message='invalid_json',
        )

    shell_type, evidence = _parse_shell_type(parsed)
    strategy, confidence = select_unpack_strategy(shell_type)
    normalized_confidence = min(max(confidence, 0.0), 1.0)

    return NormalizedAPKiDResult(
        shell_type=shell_type,
        confidence=normalized_confidence,
        evidence=f'{evidence}; strategy={strategy}',
        raw_output=parsed,
        command=command_str,
        exit_code=proc.returncode,
        error_message='',
    )


def detect_shell_and_strategy(sample: APKSample) -> ShellDetectionResult:
    result = run_apkid(sample.file.path)
    strategy, _ = select_unpack_strategy(result.shell_type)
    return ShellDetectionResult.objects.create(
        sample=sample,
        shell_type=result.shell_type,
        confidence=result.confidence,
        evidence=result.evidence,
        strategy=strategy,
        raw_output=result.raw_output,
        command=result.command,
        exit_code=result.exit_code,
        error_message=result.error_message,
    )
