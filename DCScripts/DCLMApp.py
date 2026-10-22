# DCScripts/DCLMApp.py
from __future__ import annotations

import os
import platform
import signal
import subprocess
import time
from pathlib import Path
from typing import Callable, Optional

from DCScripts.DCLMSandbox import DCLMSandbox
from DCScripts.DCLMHDD import DCPassport


class DCLMApp:
    """
    Управление процессом приложения (LM Studio/Bionic): zapustit/ostanovit/proverka_zapuschen.
    Чистый Python: никаких Qt сигналов.
    """

    def __init__(self, log_callback: Optional[Callable[[str], None]] = None):
        self._log = log_callback
        # self.process хранит процесс, только если МЫ его запускали.
        # ВАЖНО: на macOS это процесс "open" (короткоживущий), а не само приложение.
        # На Windows/Linux с sandbox это может быть процесс-лаунчер, а не целевое приложение.
        # Поэтому proverka_zapuschen() всегда дополнительно делает OS-level проверку (pgrep/tasklist).
        self.process: subprocess.Popen | None = None

    def log(self, msg: str) -> None:
        if self._log:
            self._log(msg)

    # --- СТАТУС ---
    def proverka_zapuschen(self, passport: DCPassport) -> bool:
        """
        Проверяет запущено ли приложение.
        Сначала пытается по self.process, потом OS-level проверки.
        """
        try:
            if self.process is not None and self.process.poll() is None:
                return True
        except Exception:
            pass

        try:
            os_name = platform.system()

            if os_name == "Linux":
                r = subprocess.run(
                    ["pgrep", "-if", passport.linux_pgrep_pattern],
                    capture_output=True, text=True, timeout=2
                )
                return r.returncode == 0

            if os_name == "Darwin":
                r = subprocess.run(
                    ["pgrep", "-if", passport.mac_pgrep_pattern],
                    capture_output=True, text=True, timeout=2
                )
                return r.returncode == 0

            if os_name == "Windows":
                r = subprocess.run(
                    ["tasklist", "/FI", f"IMAGENAME eq {passport.windows_image_name}"],
                    capture_output=True, text=True, timeout=2
                )
                return passport.windows_image_name.lower() in r.stdout.lower()

        except Exception as e:
            self.log(f"⚠ Ошибка проверки статуса процесса: {e}")
            return False

        return False

    # --- СТАРТ ---
    def zapustit(self, app_path: str | Path, sandbox_name: str, cli_path: str | None,
                 app_name: str) -> None:
        """
        Запускает приложение. Бросает исключения наружу при ошибках.
        app_path: путь к AppImage/Exe/.app
        sandbox_name: "" | "firejail" | "sandboxie" ...
        """
        app_path = Path(app_path).expanduser().resolve()

        spec = DCLMSandbox.postroit_komandu_zapuska(
            lmstudio_path=app_path,
            sandbox_name=sandbox_name,
            cli_path=cli_path,
            app_name=app_name
        )

        self.log(spec.description)

        os_name = platform.system()

        if os_name == "Linux":
            # start_new_session=True чтобы можно было killpg
            self.process = subprocess.Popen(
                spec.argv,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True
            )
            return

        if os_name == "Darwin":
            # DCLMSandbox на macOS возвращает ["open", "-a", ...]
            # Popen будет короткоживущим (open), но это нормально.
            self.process = subprocess.Popen(
                spec.argv,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            return

        if os_name == "Windows":
            creationflags = 0
            if hasattr(subprocess, "CREATE_NO_WINDOW"):
                creationflags |= subprocess.CREATE_NO_WINDOW

            self.process = subprocess.Popen(
                spec.argv,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=creationflags
            )
            return

        raise RuntimeError(f"Unsupported OS: {os_name}")

    # --- СТОП ---
    def ostanovit(self, passport: DCPassport, app_name: str, graceful_seconds: int = 3) -> None:
        """
        Останавливает приложение.
        Пытается мягко, затем жёстко.
        """
        os_name = platform.system()

        if os_name == "Linux":
            self._ostanovit_linux(passport, app_name, graceful_seconds)
            return

        if os_name == "Darwin":
            self._ostanovit_macos(passport, app_name, graceful_seconds)
            return

        if os_name == "Windows":
            self._ostanovit_windows(passport, app_name)
            return

        raise RuntimeError(f"Unsupported OS: {os_name}")

    def _ostanovit_linux(self, passport: DCPassport, app_name: str, graceful_seconds: int) -> None:
        # 0) если есть process group (то, что мы запускали) — пробуем остановить
        try:
            if self.process is not None and self.process.poll() is None:
                self.log("Остановка (process group)...")
                try:
                    os.killpg(self.process.pid, signal.SIGTERM)
                    time.sleep(graceful_seconds)
                    if self.process.poll() is None:
                        os.killpg(self.process.pid, signal.SIGKILL)
                finally:
                    self.process = None
        except Exception as e:
            self.log(f"⚠ Не удалось остановить по PID: {e}")

        # 1) fallback: pgrep/kill по паттерну
        r = subprocess.run(
            ["pgrep", "-if", passport.linux_pgrep_pattern],
            capture_output=True, text=True, timeout=2
        )
        if r.returncode != 0:
            self.log(f"{app_name} не запущен")
            return

        pids = [p for p in r.stdout.strip().split("\n") if p.strip()]
        self.log("Отправка SIGTERM...")
        for pid in pids:
            try:
                subprocess.run(["kill", "-15", pid], timeout=2)
            except Exception as e:
                self.log(f"⚠ Не удалось отправить SIGTERM: {e}")

        time.sleep(graceful_seconds)

        r2 = subprocess.run(
            ["pgrep", "-if", passport.linux_pgrep_pattern],
            capture_output=True, text=True, timeout=2
        )
        if r2.returncode == 0:
            self.log("⚠ Процесс не завершился, использую SIGKILL...")
            pids = [p for p in r2.stdout.strip().split("\n") if p.strip()]
            for pid in pids:
                try:
                    subprocess.run(["kill", "-9", pid], timeout=2)
                except Exception as e:
                    self.log(f"✗ Ошибка SIGKILL: {e}")

        self.log(f"✓ {app_name} остановлен")

    def _ostanovit_macos(self, passport: DCPassport, app_name: str, graceful_seconds: int) -> None:
        subprocess.run(["pkill", "-TERM", "-f", passport.mac_pgrep_pattern], timeout=2)
        time.sleep(graceful_seconds)
        subprocess.run(["pkill", "-KILL", "-f", passport.mac_pgrep_pattern], timeout=2)
        self.process = None
        self.log(f"✓ {app_name} остановлен")

    def _ostanovit_windows(self, passport: DCPassport, app_name: str) -> None:
        # shell=True здесь не нужен — taskkill прекрасно работает без shell.
        subprocess.run(
            ["taskkill", "/F", "/T", "/IM", passport.windows_image_name],
            timeout=5
        )
        self.process = None
        self.log(f"✓ {app_name} остановлен")
