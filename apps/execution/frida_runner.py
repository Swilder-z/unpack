import subprocess
from pathlib import Path

from django.conf import settings

from apps.execution.blackdex_runner import RunnerError


class FridaRunner:
    def __init__(self):
        self.base_cmd = getattr(settings, 'FRIDA_COMMAND', ['echo', 'frida'])
        self.timeout = int(getattr(settings, 'FRIDA_TIMEOUT', 300))

    def run(self, apk_path: str, output_dir: Path) -> dict:
        output_dir.mkdir(parents=True, exist_ok=True)
        out_file = output_dir / 'frida_unpacked.apk'
        cmd = [*self.base_cmd, apk_path]

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self.timeout,
                check=False,
            )
        except subprocess.TimeoutExpired as exc:
            raise RunnerError('Frida 执行超时') from exc
        except OSError as exc:
            raise RunnerError(f'Frida 启动失败: {exc}') from exc

        if result.returncode != 0:
            raise RunnerError(f'Frida 执行失败: {result.stderr.strip() or result.stdout.strip()}')

        out_file.write_text(result.stdout or 'frida placeholder artifact', encoding='utf-8')
        return {
            'tool': 'frida',
            'artifact': str(out_file),
            'stdout': result.stdout,
            'stderr': result.stderr,
            'returncode': result.returncode,
        }
