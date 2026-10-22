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
    - Windows: без sandbox или sandboxie (Sandboxie/Sandboxie-Plus), с опциональным "sandboxie:BoxName"
    - macOS: без sandbox
    """

    # -------------------- нормализация имени --------------------

    @staticmethod
    def normalizovat(name: str) -> str:
        """
        Нормализует имя sandbox'а. Поддерживает формат "sandboxie:BoxName" —
        при этом регистр BoxName СОХРАНЯЕТСЯ (box-имена могут быть чувствительны к регистру),
        а базовое имя sandbox'а приводится к нижнему регистру.
        """
        raw = (name or "").strip()
        if not raw:
            return ""

        if ":" in raw:
            base, box = raw.split(":", 1)
            base = base.strip().lower()
            box = box.strip()

            if base in ("off", "выкл", "none", "no", "-"):
                return ""

            return f"{base}:{box}" if box else base

        base = raw.lower()
        if base in ("off", "выкл", "none", "no", "-"):
            return ""
        return base

    @staticmethod
    def _bazovoe_imya(sandbox_name: str) -> str:
        """Возвращает базовое имя sandbox'а без суффикса ':BoxName'."""
        if not sandbox_name:
            return ""
        return sandbox_name.split(":", 1)[0]

    @staticmethod
    def _izvlech_box(sandbox_name: str, default: str = "DefaultBox") -> str:
        """Извлекает имя box'а из строки вида 'sandboxie:BoxName' (регистр сохраняется)."""
        if ":" in sandbox_name:
            _, box = sandbox_name.split(":", 1)
            box = box.strip()
            return box or default
        return default

    # -------------------- Linux: firejail --------------------

    @staticmethod
    def _naiti_firejail() -> str | None:
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
    def _poluchit_programm_papki_windows() -> list[Path]:
        dirs: list[Path] = []
        for env in ("ProgramFiles", "ProgramFiles(x86)", "LOCALAPPDATA"):
            v = os.environ.get(env)
            if v:
                dirs.append(Path(v))
        return dirs

    @staticmethod
    def _poluchit_obschie_papki_sandboxie() -> list[Path]:
        """
        На разных системах Sandboxie может стоять в разных местах.
        Собираем максимально универсальный набор кандидатов.
        """
        candidates: list[Path] = []
        for base in DCLMSandbox._poluchit_programm_papki_windows():
            candidates += [
                base / "Sandboxie",
                base / "Sandboxie-Plus",
                base / "Sandboxie Plus",
                base / "SandboxiePlus",
                base / "Sandboxie-plus",
            ]
        return candidates

    @staticmethod
    def _naiti_sandboxie_start_exe() -> Path | None:
        """
        Ищет Start.exe от Sandboxie/Sandboxie-Plus максимально универсально.
        """
        # 1) PATH
        p = shutil.which("Start.exe")
        if p:
            return Path(p)

        # 2) частые директории установки
        for d in DCLMSandbox._poluchit_obschie_papki_sandboxie():
            exe = d / "Start.exe"
            if exe.exists():
                return exe

        # 3) если папка называется иначе, но начинается на "Sandboxie"
        for base in DCLMSandbox._poluchit_programm_papki_windows():
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

                        for value_name in ("InstallLocation", "InstallSource"):
                            try:
                                loc, _ = winreg.QueryValueEx(sk, value_name)
                                if loc:
                                    candidate = Path(str(loc)) / "Start.exe"
                                    if candidate.exists():
                                        return candidate
                            except OSError:
                                pass

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

    # -------------------- проверка доступности --------------------

    @staticmethod
    def proverit_dostupnost(sandbox_name: str) -> None:
        sandbox_name = DCLMSandbox.normalizovat(sandbox_name)
        if not sandbox_name:
            return

        base_name = DCLMSandbox._bazovoe_imya(sandbox_name)
        os_name = platform.system()

        if base_name == "firejail":
            if os_name != "Linux":
                raise SandboxNotAvailable("firejail поддерживается только на Linux")
            if not DCLMSandbox._naiti_firejail():
                raise SandboxNotAvailable("firejail не найден. Установите: sudo apt install firejail")
            return

        if base_name == "sandboxie":
            if os_name != "Windows":
                raise SandboxNotAvailable("sandboxie поддерживается только на Windows")
            if not DCLMSandbox._naiti_sandboxie_start_exe():
                raise SandboxNotAvailable(
                    "Sandboxie не найден (Start.exe отсутствует). Установите Sandboxie или Sandboxie-Plus."
                )
            return

        raise SandboxNotAvailable(f"Неизвестный sandbox: {sandbox_name}")

    # -------------------- вспомогательное --------------------

    @staticmethod
    def opredelit_papku_lmstudio_po_cli(cli_path: str | None) -> Path:
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

    # -------------------- построение команды --------------------

    @staticmethod
    def postroit_komandu_zapuska(
        lmstudio_path: str | Path,
        sandbox_name: str,
        cli_path: str | None = None,
        app_name: str = "LM Studio",
    ) -> LaunchSpec:
        sandbox_name = DCLMSandbox.normalizovat(sandbox_name)
        base_name = DCLMSandbox._bazovoe_imya(sandbox_name)
        lmstudio_path = Path(lmstudio_path).expanduser().resolve()
        os_name = platform.system()

        # Linux
        if os_name == "Linux":
            if not sandbox_name:
                return LaunchSpec(
                    argv=[str(lmstudio_path), "--no-sandbox"],
                    description=f"Запуск {app_name} без sandbox (--no-sandbox)"
                )

            if base_name == "firejail":
                DCLMSandbox.proverit_dostupnost("firejail")
                firejail_bin = DCLMSandbox._naiti_firejail() or "firejail"
                whitelist_dir = DCLMSandbox.opredelit_papku_lmstudio_po_cli(cli_path)

                argv = [firejail_bin, f"--whitelist={whitelist_dir}"]
                # --appimage добавляем только если файл реально AppImage,
                # иначе firejail может отказаться запускать обычный бинарник/desktop-exec.
                if lmstudio_path.suffix.lower() == ".appimage":
                    argv.append("--appimage")
                argv.append(str(lmstudio_path))

                return LaunchSpec(
                    argv=argv,
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

            if base_name == "sandboxie":
                DCLMSandbox.proverit_dostupnost("sandboxie")
                start_exe = DCLMSandbox._naiti_sandboxie_start_exe()
                if not start_exe:
                    raise SandboxNotAvailable("Sandboxie Start.exe не найден")

                # теперь реально работает: "sandboxie:MyBox" -> box="MyBox" (регистр сохранён)
                box = DCLMSandbox._izvlech_box(sandbox_name)

                return LaunchSpec(
                    argv=[str(start_exe), f"/box:{box}", str(lmstudio_path)],
                    description=f"Запуск {app_name} в sandbox: sandboxie (box: {box})"
                )

            raise SandboxNotAvailable(f"Sandbox '{sandbox_name}' не поддерживается на Windows")

        raise SandboxNotAvailable(f"Неподдерживаемая ОС: {os_name}")
