# DCScripts/DCLMSandbox.py
from __future__ import annotations

import os
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
    Унифицированная логика формирования команды запуска приложения (LM Studio / Bionic):
    - Linux: без sandbox (--no-sandbox) или firejail
    - Windows: без sandbox или sandboxie (Sandboxie/Sandboxie-Plus)
    - macOS: без sandbox
    """

    @staticmethod
    def normalize(name: str) -> str:
        name = (name or "").strip().lower()
        if name in ("off", "выкл", "none", "no", "-"):
            return ""
        return name

    # -------------------- Linux: firejail --------------------

    @staticmethod
    def _find_firejail() -> str | None:
        firejail_path = shutil.which("firejail")
        if firejail_path:
            return firejail_path

        for p in ("/usr/bin/firejail", "/bin/firejail", "/usr/local/bin/firejail"):
            if Path(p).exists():
                return p

        opt = Path("/opt/firejail/bin/firejail")
        if opt.exists():
            return str(opt)

        return None

    # -------------------- Windows: sandboxie --------------------

    @staticmethod
    def _windows_program_dirs() -> list[Path]:
        dirs: list[Path] = []
        for env in ("ProgramFiles", "ProgramFiles(x86)", "LOCALAPPDATA"):
            v = os.environ.get(env)
            if v:
                dirs.append(Path(v))
        return dirs

    @staticmethod
    def _sandboxie_common_dirs() -> list[Path]:
        """
        На разных системах Sandboxie может стоять в разных местах.
        Собираем максимально универсальный набор кандидатов.
        """
        candidates: list[Path] = []
        for base in DCLMSandbox._windows_program_dirs():
            candidates += [
                base / "Sandboxie",
                base / "Sandboxie-Plus",
                base / "Sandboxie Plus",
                base / "SandboxiePlus",
                base / "Sandboxie-plus",
            ]
        return candidates

    @staticmethod
    def _find_sandboxie_start_exe() -> Path | None:
        """
        Ищет Start.exe от Sandboxie/Sandboxie-Plus максимально универсально.
        """
        # 1) PATH
        p = shutil.which("Start.exe")
        if p:
            return Path(p)

        # 2) частые директории установки
        for d in DCLMSandbox._sandboxie_common_dirs():
            exe = d / "Start.exe"
            if exe.exists():
                return exe

        # 3) если папка называется иначе, но начинается на "Sandboxie"
        for base in DCLMSandbox._windows_program_dirs():
            try:
                if not base.exists():
                    continue
                for child in base.iterdir():
                    if child.is_dir() and child.name.lower().startswith("sandboxie"):
                        exe = child / "Start.exe"
                        if exe.exists():
                            return exe
            except Exception:
                pass

        # 4) реестр Uninstall (HKLM/HKCU + WOW6432Node)
        try:
            import winreg

            uninstall_roots = [
                (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"),
                (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"),
                (winreg.HKEY_CURRENT_USER, r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"),
            ]

            def scan_uninstall(root, subkey_path: str) -> Path | None:
                try:
                    key = winreg.OpenKey(root, subkey_path)
                except OSError:
                    return None

                try:
                    sub_count = winreg.QueryInfoKey(key)[0]
                    for i in range(sub_count):
                        try:
                            sk_name = winreg.EnumKey(key, i)
                            sk = winreg.OpenKey(key, sk_name)
                        except OSError:
                            continue

                        try:
                            disp, _ = winreg.QueryValueEx(sk, "DisplayName")
                        except OSError:
                            continue

                        if not disp or "sandboxie" not in str(disp).lower():
                            continue

                        # InstallLocation
                        for value_name in ("InstallLocation", "InstallSource"):
                            try:
                                loc, _ = winreg.QueryValueEx(sk, value_name)
                                if loc:
                                    candidate = Path(str(loc)) / "Start.exe"
                                    if candidate.exists():
                                        return candidate
                            except OSError:
                                pass

                        # DisplayIcon -> папка рядом
                        try:
                            icon, _ = winreg.QueryValueEx(sk, "DisplayIcon")
                            if icon:
                                icon_path = str(icon).split(",")[0].strip().strip('"')
                                icon_p = Path(icon_path)
                                if icon_p.exists():
                                    candidate = icon_p.parent / "Start.exe"
                                    if candidate.exists():
                                        return candidate
                        except OSError:
                            pass

                finally:
                    try:
                        winreg.CloseKey(key)
                    except Exception:
                        pass

                return None

            for root, sub in uninstall_roots:
                found = scan_uninstall(root, sub)
                if found:
                    return found

        except Exception:
            pass

        return None

    # -------------------- availability --------------------

    @staticmethod
    def check_available(sandbox_name: str) -> None:
        sandbox_name = DCLMSandbox.normalize(sandbox_name)
        if not sandbox_name:
            return

        os_name = platform.system()

        if sandbox_name == "firejail":
            if os_name != "Linux":
                raise SandboxNotAvailable("firejail поддерживается только на Linux")
            if not DCLMSandbox._find_firejail():
                raise SandboxNotAvailable("firejail не найден. Установите: sudo apt install firejail")
            return

        if sandbox_name == "sandboxie":
            if os_name != "Windows":
                raise SandboxNotAvailable("sandboxie поддерживается только на Windows")
            if not DCLMSandbox._find_sandboxie_start_exe():
                raise SandboxNotAvailable(
                    "Sandboxie не найден (Start.exe отсутствует). Установите Sandboxie или Sandboxie-Plus."
                )
            return

        raise SandboxNotAvailable(f"Неизвестный sandbox: {sandbox_name}")

    # -------------------- misc helpers --------------------

    @staticmethod
    def guess_lmstudio_dir_from_cli(cli_path: str | None) -> Path:
        """
        ~/.lmstudio/bin/lms -> ~/.lmstudio
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

    # -------------------- build command --------------------

    @staticmethod
    def build_launch_spec(
        lmstudio_path: str | Path,
        sandbox_name: str,
        cli_path: str | None = None,
        app_name: str = "LM Studio",
    ) -> LaunchSpec:
        sandbox_name = DCLMSandbox.normalize(sandbox_name)
        lmstudio_path = Path(lmstudio_path).expanduser().resolve()
        os_name = platform.system()

        # Linux
        if os_name == "Linux":
            if not sandbox_name:
                return LaunchSpec(
                    argv=[str(lmstudio_path), "--no-sandbox"],
                    description=f"Запуск {app_name} без sandbox (--no-sandbox)"
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
                    description=f"Запуск {app_name} в sandbox: firejail (whitelist: {whitelist_dir})"
                )

            raise SandboxNotAvailable(f"Sandbox '{sandbox_name}' не поддерживается на Linux")

        # macOS
        if os_name == "Darwin":
            if sandbox_name:
                raise SandboxNotAvailable(f"Sandbox '{sandbox_name}' не поддерживается на macOS")
            return LaunchSpec(
                argv=["open", "-a", str(lmstudio_path)],
                description=f"Запуск {app_name} (macOS)"
            )

        # Windows
        if os_name == "Windows":
            if not sandbox_name:
                return LaunchSpec(
                    argv=[str(lmstudio_path)],
                    description=f"Запуск {app_name} (Windows)"
                )

            if sandbox_name == "sandboxie":
                DCLMSandbox.check_available("sandboxie")
                start_exe = DCLMSandbox._find_sandboxie_start_exe()
                if not start_exe:
                    raise SandboxNotAvailable("Sandboxie Start.exe не найден")

                # можно расширять: "sandboxie:MyBox"
                box = "DefaultBox"
                if ":" in sandbox_name:
                    _, box = sandbox_name.split(":", 1)
                    box = box.strip() or "DefaultBox"

                return LaunchSpec(
                    argv=[str(start_exe), f"/box:{box}", str(lmstudio_path)],
                    description=f"Запуск {app_name} в sandbox: sandboxie (box: {box})"
                )

            raise SandboxNotAvailable(f"Sandbox '{sandbox_name}' не поддерживается на Windows")

        raise SandboxNotAvailable(f"Неподдерживаемая ОС: {os_name}")
