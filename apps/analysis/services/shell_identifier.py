import json
import subprocess

from django.conf import settings


class ShellIdentifierError(Exception):
    pass


def identify_shell(apk_path: str) -> dict:
    cmd = [*settings.APKiD_COMMAND, apk_path]
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=settings.APKiD_TIMEOUT,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise ShellIdentifierError('APKiD 执行超时') from exc
    except OSError as exc:
        raise ShellIdentifierError(f'APKiD 执行失败: {exc}') from exc

    if result.returncode != 0:
        raise ShellIdentifierError(f'APKiD 返回非零状态: {result.stderr.strip()}')

    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise ShellIdentifierError('APKiD 输出解析失败') from exc
