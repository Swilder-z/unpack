import subprocess
from pathlib import Path

from django.conf import settings


class RunnerError(Exception):
    pass


class BlackDexRunner:
    def run(self, apk_path: str, output_dir: Path) -> Path:
        output_dir.mkdir(parents=True, exist_ok=True)
        out_file = output_dir / 'blackdex_unpacked.apk'
        cmd = [*settings.BLACKDEX_COMMAND, apk_path]
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=settings.BLACKDEX_TIMEOUT,
                check=False,
            )
        except subprocess.TimeoutExpired as exc:
            raise RunnerError('BlackDex 执行超时') from exc
        except OSError as exc:
            raise RunnerError(f'BlackDex 启动失败: {exc}') from exc

        if result.returncode != 0:
            raise RunnerError(f'BlackDex 执行失败: {result.stderr.strip()}')

        out_file.write_text(result.stdout or 'blackdex output placeholder', encoding='utf-8')
        return out_file
