# DCScripts/DCLMSandbox.py
from __future__ import annotations

import platform
import shutil
from dataclasses import dataclass
from pathlib import Path


class SandboxError(Exception):
    pass


class SandboxNotAvailable(SandboxError):
    """Sandbox не установлен или не поддерживается на ОС"""
    pass


@dataclass(frozen=True)
class LaunchSpec:
    argv: list[str]
    description: str


class DCLMSandbox:
    """
    Вся логика формирования команды запуска LM Studio:
    - без sandbox (как сейчас: --no-sandbox на Linux)
    - с firejail на Linux
    - расширяемо для других sandbox/ОС
    """

    @staticmethod
    def normalize(name: str) -> str:
        name = (name or "").strip().lower()
        if name in ("off", "выкл", "none", "no", "-"):
            return ""
        return name

    @staticmethod
    def check_available(sandbox_name: str) -> None:
        """Бросает исключение, если sandbox нельзя использовать."""
        sandbox_name = DCLMSandbox.normalize(sandbox_name)
        if not sandbox_name:
            return

        os_name = platform.system()

        if sandbox_name == "firejail":
            if os_name != "Linux":
                raise SandboxNotAvailable("firejail поддерживается только на Linux")
            if shutil.which("firejail") is None:
                raise SandboxNotAvailable("firejail не установлен. Установите: sudo apt install firejail")
            return

        # Заглушки на будущее
        if sandbox_name == "sandboxie":
            if os_name != "Windows":
                raise SandboxNotAvailable("sandboxie поддерживается только на Windows")
            # тут можно добавить shutil.which(...) для Sandboxie
            raise SandboxNotAvailable("sandboxie: проверка/запуск ещё не реализованы")

        raise SandboxNotAvailable(f"Неизвестный sandbox: {sandbox_name}")

    @staticmethod
    def guess_lmstudio_dir_from_cli(cli_path: str | None) -> Path:
        """
        Пытается вычислить ~/.lmstudio из пути к lms:
        ~/.lmstudio/bin/lms -> ~/.lmstudio

        Если cli_path не задан или лежит не в ~/.lmstudio, используем Path.home()/'.lmstudio'
        """
        if cli_path:
            try:
                p = Path(cli_path).expanduser().resolve()
                for parent in [p] + list(p.parents):
                    if parent.name == ".lmstudio":
                        return parent
            except Exception:
                pass
        return Path.home() / ".lmstudio"

    @staticmethod
    def build_launch_spec(
        lmstudio_path: str | Path,
        sandbox_name: str,
        cli_path: str | None = None
    ) -> LaunchSpec:
        sandbox_name = DCLMSandbox.normalize(sandbox_name)
        lmstudio_path = Path(lmstudio_path).expanduser().resolve()

        os_name = platform.system()

        if os_name == "Linux":
            if not sandbox_name:
                # как у тебя сейчас
                return LaunchSpec(
                    argv=[str(lmstudio_path), "--no-sandbox"],
                    description="Запуск LM Studio без sandbox (--no-sandbox)"
                )

            if sandbox_name == "firejail":
                DCLMSandbox.check_available("firejail")
                whitelist_dir = DCLMSandbox.guess_lmstudio_dir_from_cli(cli_path)

                return LaunchSpec(
                    argv=[
                        "firejail",
                        "--appimage",
                        f"--whitelist={str(whitelist_dir)}",
                        str(lmstudio_path)
                    ],
                    description=f"Запуск LM Studio в sandbox: firejail (whitelist: {whitelist_dir})"
                )

            raise SandboxNotAvailable(f"Sandbox '{sandbox_name}' не поддерживается на Linux")

        if os_name == "Darwin":
            if sandbox_name:
                raise SandboxNotAvailable(f"Sandbox '{sandbox_name}' не поддерживается на macOS")
            return LaunchSpec(argv=["open", "-a", str(lmstudio_path)], description="Запуск LM Studio (macOS)")

        if os_name == "Windows":
            if sandbox_name:
                raise SandboxNotAvailable(f"Sandbox '{sandbox_name}' пока не реализован на Windows")
            return LaunchSpec(argv=[str(lmstudio_path)], description="Запуск LM Studio (Windows)")

        raise SandboxNotAvailable(f"Неподдерживаемая ОС: {os_name}")
