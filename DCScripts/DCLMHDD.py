# DCScripts/DCLMHDD.py
from __future__ import annotations

import os
import platform
import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional


@dataclass(frozen=True)
class DCPassport:
    display_name: str = "LM Studio"
    linux_pgrep_pattern: str = r"(lm[- ]?studio|lmstudio|lm-studio)"# regex для pgrep (Linux)
    mac_pgrep_pattern: str = r"(LM Studio|lmstudio|lm-studio)"      # regex для pgrep (macOS)
    windows_image_name: str = "LM Studio.exe"                       # имя процесса для taskkill/tasklist (Windows)

class DCLMHDD:
    """
    HDD/FileSystem/Path helpers (чистый Python, без Qt).
    - валидации (URL, файлы)
    - поиск путей (приложение, lms cli)
    - определение типа приложения (LM Studio / Bionic) по имени файла
    """

    def __init__(self, log_callback: Optional[Callable[[str], None]] = None):
        self._log = log_callback

    def log(self, msg: str) -> None:
        if self._log:
            self._log(msg)

    # --- ПРОВЕРКА IP СЕРВЕРА ---
    def proverka_server_url(self, server_url: str, max_len: int = 30) -> bool:
        if not server_url:
            return False

        server_url = server_url.strip()

        if len(server_url) > max_len:
            self.log(f"⚠ URL слишком длинный: {len(server_url)} символов (максимум {max_len})")
            return False

        pattern = re.compile(
            r'^http://'
            r'(localhost|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'
            r':(\d{1,5})$'
        )

        match = pattern.match(server_url)
        if not match:
            self.log(f"⚠ Неверный формат URL: {server_url}")
            self.log("   Допустимый формат: http://localhost:1234 или http://127.0.0.1:1234")
            return False

        host = match.group(1)
        port = int(match.group(2))

        if host != "localhost":
            octets = host.split(".")
            for octet in octets:
                if int(octet) > 255:
                    self.log(f"⚠ Неверный IP адрес: {host} (октет {octet} > 255)")
                    return False

        if port < 1 or port > 65535:
            self.log(f"⚠ Неверный порт: {port} (допустимый диапазон: 1-65535)")
            return False

        self.log(f"✓ URL корректен: {server_url}")
        return True

    def proverka_faila(self, file_path: str) -> bool:
        if not file_path:
            return False
        try:
            path = Path(file_path).expanduser().resolve()
            return path.is_file()
        except Exception:
            return False

    # --- ПРОВЕРКА LMS ФАЙЛА ---
    def proverka_lms_faila(self, file_path: str) -> bool:
        """
        Проверка, что путь указывает на корректный lms CLI под текущую ОС.
        """
        if not file_path:
            return False

        try:
            path = Path(file_path).expanduser().resolve()

            if not path.is_file():
                self.log(f"⚠ Файл не найден: {file_path}")
                return False

            file_name = path.name.lower()
            file_stem = path.stem.lower()
            file_suffix = path.suffix.lower()
            current_os = platform.system()

            if current_os == "Linux":
                if file_name != "lms":
                    self.log(f"⚠ Неверное имя файла для Linux: {file_name}")
                    self.log("   Ожидается: lms")
                    return False

                if os.access(path, os.X_OK):
                    self.log(f"✓ Найден lms для Linux: {path}")
                    return True

                self.log(f"⚠ Файл не исполняемый: {path}")
                self.log(f"   Выполните: chmod +x {path}")
                return False

            if current_os == "Darwin":
                # Обычно lms без расширения, иногда могут попытаться дать .app (редко)
                if file_name == "lms" or file_suffix == ".app":
                    if file_stem == "lms" or file_name == "lms":
                        if file_suffix != ".app" and not os.access(path, os.X_OK):
                            self.log(f"⚠ Файл не исполняемый: {path}")
                            self.log(f"   Выполните: chmod +x {path}")
                            return False

                        self.log(f"✓ Найден lms для macOS: {path}")
                        return True

                self.log(f"⚠ Неверный файл для macOS: {file_name}")
                self.log("   Ожидается: lms (без расширения)")
                return False

            if current_os == "Windows":
                if file_suffix != ".exe" or file_stem != "lms":
                    self.log(f"⚠ Неверный файл для Windows: {file_name}")
                    self.log("   Ожидается: lms.exe")
                    return False

                self.log(f"✓ Найден lms для Windows: {path}")
                return True

            self.log(f"⚠ Неподдерживаемая ОС: {current_os}")
            return False

        except Exception as e:
            self.log(f"✗ Ошибка проверки файла: {e}")
            return False

    # -------------------- detect app type --------------------

    def detect_passport_from_path(self, app_path: str, fallback: DCPassport | None = None) -> DCPassport:
        """
        Определяет LM Studio или Bionic по имени файла (с учётом AppImage версий).
        """
        default = fallback or DCPassport(
            display_name="LM Studio",
            linux_pgrep_pattern=r"(lm[- ]?studio|lmstudio|lm-studio)",
            mac_pgrep_pattern=r"(LM Studio|lmstudio|lm-studio)",
            windows_image_name="LM Studio.exe",
        )

        try:
            p = Path(app_path).expanduser().resolve()
            filename = p.name.lower()
            stem = p.stem.lower()
            s = f"{filename} {stem}"

            if "bionic" in s:
                return DCPassport(
                    display_name="Bionic",
                    linux_pgrep_pattern=r"(bionic)",
                    mac_pgrep_pattern=r"(Bionic|bionic)",
                    windows_image_name="Bionic.exe",
                )

            # LM Studio: lm-studio / lm studio / lmstudio
            if ("lm-studio" in s) or ("lm studio" in s) or ("lmstudio" in s):
                return DCPassport(
                    display_name="LM Studio",
                    linux_pgrep_pattern=r"(lm[- ]?studio|lmstudio|lm-studio)",
                    mac_pgrep_pattern=r"(LM Studio|lmstudio|lm-studio)",
                    windows_image_name="LM Studio.exe",
                )

            return default
        except Exception:
            return default

    # -------------------- find lms cli --------------------

    def find_lms_cli(self, preferred_path: str = "") -> str | None:
        """
        Возвращает путь к lms (CLI) или None.
        preferred_path — путь из настроек, если задан.
        """
        if preferred_path:
            p = Path(preferred_path).expanduser().resolve()
            if p.exists():
                self.log(f"✓ Используется путь к CLI из настроек: {p}")
                return str(p)

        home = Path.home()
        os_name = platform.system()

        if os_name in ("Linux", "Darwin"):
            search_paths = [
                home / ".lmstudio" / "bin" / "lms",
                home / ".local" / "bin" / "lms",
                Path("/usr/local/bin/lms"),
                Path("/usr/bin/lms"),
            ]
            for p in search_paths:
                if p.exists():
                    self.log(f"✓ Найден lms CLI: {p}")
                    return str(p)

            # PATH
            found = shutil.which("lms")
            if found:
                self.log(f"✓ Найден lms в PATH: {found}")
                return found

        elif os_name == "Windows":
            search_paths = [
                Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "LMStudio" / "lms.exe",
                Path(os.environ.get("APPDATA", "")) / "LMStudio" / "lms.exe",
            ]
            for p in search_paths:
                if p.exists():
                    self.log(f"✓ Найден lms CLI: {p}")
                    return str(p)

            found = shutil.which("lms.exe") or shutil.which("lms")
            if found:
                self.log(f"✓ Найден lms в PATH: {found}")
                return found

        return None

    # ---ПОИСК ИСПОЛНЯЕМЫХ ФАЙЛОВ---
    def find_app_path(self, custom_path: str = "") -> Path | None:
        """
        Ищет путь к LM Studio/Bionic.
        1) custom_path (если задан)
        2) Linux: .desktop
        3) Linux: AppImage в популярных каталогах (в т.ч. ~/lmstudio)
        4) Windows/macOS: типовые пути
        """
        if custom_path:
            p = Path(custom_path).expanduser().resolve()
            if p.exists():
                self.log(f"✓ Используется путь из настроек: {p}")
                return p
            self.log(f"⚠ Путь из настроек не существует: {p}")

        home = Path.home()
        os_name = platform.system()

        if os_name == "Linux":
            # 1) пробуем Exec= из desktop
            from_desktop = self._find_app_from_desktop_linux(home)
            if from_desktop and from_desktop.exists():
                self.log(f"✓ Найден через .desktop: {from_desktop}")
                return from_desktop

            # 2) ищем AppImage в популярных местах (без рекурсии)
            search_dirs = [
                home / "lmstudio",
                home / "Applications",
                home / "Downloads",
                home / ".cache",
                home / ".local" / "share" / "applications",
                Path("/opt"),
                Path("/usr/local/bin"),
            ]

            found = self._find_appimage_in_dirs(
                dirs=search_dirs,
                keywords_any=[("lm", "studio"), ("bionic",)]
            )
            if found:
                self.log(f"✓ Найден AppImage: {found}")
                return found

            return None

        if os_name == "Darwin":
            paths = [
                Path("/Applications/LM Studio.app"),
                Path("/Applications/Bionic.app"),
                home / "Applications" / "LM Studio.app",
                home / "Applications" / "Bionic.app",
            ]
            for p in paths:
                if p.exists():
                    self.log(f"✓ Найдено приложение: {p}")
                    return p
            return None

        if os_name == "Windows":
            paths = [
                Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "LM Studio" / "LM Studio.exe",
                Path(os.environ.get("PROGRAMFILES", "")) / "LM Studio" / "LM Studio.exe",
                Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "Bionic" / "Bionic.exe",
                Path(os.environ.get("PROGRAMFILES", "")) / "Bionic" / "Bionic.exe",
            ]
            for p in paths:
                if p.exists():
                    self.log(f"✓ Найдено приложение: {p}")
                    return p
            return None

        return None

    def _find_app_from_desktop_linux(self, home: Path) -> Path | None:
        """
        Поиск Exec=... в *.desktop.
        Сначала пытаемся известные имена, затем лёгкий glob.
        """
        desktop_dir = home / ".local" / "share" / "applications"
        if not desktop_dir.exists():
            return None

        desktop_files = [
            desktop_dir / "lm-studio.desktop",
            desktop_dir / "LM-Studio.desktop",
            desktop_dir / "bionic.desktop",
            desktop_dir / "Bionic.desktop",
        ]

        # добавим ещё “похожие” файлы, но без полного обхода всех desktop
        try:
            desktop_files += list(desktop_dir.glob("*lm*studio*.desktop"))
            desktop_files += list(desktop_dir.glob("*bionic*.desktop"))
        except Exception:
            pass

        for df in desktop_files:
            if not df.exists():
                continue
            p = self._parse_desktop_exec(df)
            if p and p.exists():
                return p

        return None

    def _parse_desktop_exec(self, desktop_file: Path) -> Path | None:
        """
        Достаёт путь из строки Exec=... и возвращает Path.
        """
        try:
            with desktop_file.open("r", encoding="utf-8", errors="ignore") as f:
                for line in f:
                    if line.startswith("Exec="):
                        exec_part = line.split("=", 1)[1].strip()
                        exec_path = exec_part.split()[0]
                        exec_path = exec_path.replace('"', "").replace("'", "")
                        p = Path(exec_path).expanduser()
                        return p
        except Exception:
            return None
        return None

    def _find_appimage_in_dirs(self, dirs: list[Path], keywords_any: list[tuple[str, ...]]) -> Path | None:
        """
        Ищет AppImage в указанных директориях без рекурсии.
        keywords_any: список наборов ключевых слов; если любое множество совпало — файл подходит.
        Пример: [("lm","studio"), ("bionic",)]
        """
        for base_dir in dirs:
            if not base_dir.exists():
                continue

            try:
                for item in base_dir.iterdir():
                    if not item.is_file():
                        continue

                    name_lower = item.name.lower()
                    if item.suffix.lower() != ".appimage":
                        continue

                    for keys in keywords_any:
                        if all(k in name_lower for k in keys):
                            return item
            except PermissionError:
                continue
            except Exception:
                continue

        return None
