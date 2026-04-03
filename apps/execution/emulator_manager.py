import subprocess

from django.conf import settings


class EmulatorError(RuntimeError):
    pass


class EmulatorManager:
    def __init__(self):
        self.start_cmd = getattr(settings, 'EMULATOR_START_COMMAND', ['echo', 'start_emulator'])
        self.stop_cmd = getattr(settings, 'EMULATOR_STOP_COMMAND', ['echo', 'stop_emulator'])
        self.status_cmd = getattr(settings, 'EMULATOR_STATUS_COMMAND', ['echo', 'online'])
        self.install_cmd = getattr(settings, 'EMULATOR_INSTALL_APK_COMMAND', ['echo', 'install_apk'])
        self.timeout = int(getattr(settings, 'EMULATOR_TIMEOUT', 180))

    def start(self) -> str:
        return self._run(self.start_cmd, '启动模拟器失败')

    def stop(self) -> str:
        return self._run(self.stop_cmd, '关闭模拟器失败')

    def is_online(self) -> bool:
        output = self._run(self.status_cmd, '检查模拟器在线状态失败')
        return 'online' in output.lower() or 'device' in output.lower()

    def install_apk(self, apk_path: str) -> str:
        cmd = [*self.install_cmd, apk_path]
        return self._run(cmd, '安装APK到模拟器失败')

    def _run(self, cmd: list[str], error_prefix: str) -> str:
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self.timeout,
                check=False,
            )
        except subprocess.TimeoutExpired as exc:
            raise EmulatorError(f'{error_prefix}: 命令超时') from exc
        except OSError as exc:
            raise EmulatorError(f'{error_prefix}: 系统错误 {exc}') from exc

        if result.returncode != 0:
            raise EmulatorError(f'{error_prefix}: {result.stderr.strip() or result.stdout.strip()}')

        return (result.stdout or '').strip()
