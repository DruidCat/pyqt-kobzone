# DCScripts/DCLMHDD.py
from __future__ import annotations

import json
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
    linux_pgrep_pattern: str = r"(lm[- ]?studio|lmstudio|lm-studio)" # regex для pgrep (Linux)
    mac_pgrep_pattern: str = r"(LM Studio|lmstudio|lm-studio)"       # regex для pgrep (macOS)
    windows_image_name: str = "LM Studio.exe"  # имя процесса для taskkill/tasklist (Windows)
    cli_name: str = "lms"                                            # имя CLI без расширения (lms / lms.exe)


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
        except Exception as e:
            self.log(f"⚠ Ошибка проверки файла {file_path}: {e}")
            return False

    # --- ПРОВЕРКА LMS ФАЙЛА ---
    def proverka_lms_faila(self, file_path: str, cli_name: str = "lms") -> bool:
        """
        Проверка, что путь указывает на корректный CLI под текущую ОС.
        cli_name — имя CLI без расширения (по умолчанию "lms").
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
            cli_name_lower = cli_name.lower()

            if current_os == "Linux":
                if file_name != cli_name_lower:
                    self.log(f"⚠ Неверное имя файла для Linux: {file_name}")
                    self.log(f"   Ожидается: {cli_name_lower}")
                    return False

                if os.access(path, os.X_OK):
                    self.log(f"✓ Найден {cli_name_lower} для Linux: {path}")
                    return True

                self.log(f"⚠ Файл не исполняемый: {path}")
                self.log(f"   Выполните: chmod +x {path}")
                return False

            if current_os == "Darwin":
                # Бандл .app — исполняемость не проверяем так (внутри своя структура)
                if file_suffix == ".app":
                    self.log(f"✓ Найден {cli_name_lower} для macOS (bundle): {path}")
                    return True

                if file_stem == cli_name_lower or file_name == cli_name_lower:
                    if not os.access(path, os.X_OK):
                        self.log(f"⚠ Файл не исполняемый: {path}")
                        self.log(f"   Выполните: chmod +x {path}")
                        return False
                    self.log(f"✓ Найден {cli_name_lower} для macOS: {path}")
                    return True

                self.log(f"⚠ Неверный файл для macOS: {file_name}")
                self.log(f"   Ожидается: {cli_name_lower} (без расширения)")
                return False

            if current_os == "Windows":
                if file_suffix != ".exe" or file_stem != cli_name_lower:
                    self.log(f"⚠ Неверный файл для Windows: {file_name}")
                    self.log(f"   Ожидается: {cli_name_lower}.exe")
                    return False

                self.log(f"✓ Найден {cli_name_lower} для Windows: {path}")
                return True

            self.log(f"⚠ Неподдерживаемая ОС: {current_os}")
            return False

        except Exception as e:
            self.log(f"✗ Ошибка проверки файла: {e}")
            return False

    # --- СПИСОК СОДЕРЖИМОГО ПАПКИ (для панели выбора путей) ---
    def pol_spisok_papki(self, path: str) -> str:
        """
        Возвращает JSON список содержимого папки, включая скрытые файлы и папки.
        Папки первыми, сортировка без учёта регистра. Пустой/невалидный путь -> домашняя папка.
        """
        try:
            papka = Path(path) if path else Path.home()
            if not papka.is_dir():
                papka = Path.home()
            sp = []
            for element in sorted(papka.iterdir(), key=lambda e: (not e.is_dir(), str(e).lower())):
                # as_posix(): прямые слеши в путях на всех ОС, в QML подъём ищется по "/"
                # (str(Path) на Windows даёт обратные слеши и навигация «назад» ломалась).
                sp.append({"name": element.name, "path": element.as_posix(),
                           "isFolder": element.is_dir()})
            return json.dumps(sp, ensure_ascii=False)
        except Exception as e:
            self.log(f"✗ Ошибка списка папки {path}: {e}")
            return "[]"

    # -------------------- определение паспорта приложения --------------------

    def opredelit_pasport_po_puti(self, app_path: str, fallback: DCPassport | None = None) -> DCPassport:
        """
        Определяет LM Studio или Bionic по имени файла (с учётом AppImage версий).
        """
        default = fallback or DCPassport(
            display_name="LM Studio",
            linux_pgrep_pattern=r"(lm[- ]?studio|lmstudio|lm-studio)",
            mac_pgrep_pattern=r"(LM Studio|lmstudio|lm-studio)",
            windows_image_name="LM Studio.exe",
            cli_name="lms",
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
                    cli_name="lms",  # при необходимости поменять на реальное имя CLI Bionic
                )

            # LM Studio: lm-studio / lm studio / lmstudio
            if ("lm-studio" in s) or ("lm studio" in s) or ("lmstudio" in s):
                return DCPassport(
                    display_name="LM Studio",
                    linux_pgrep_pattern=r"(lm[- ]?studio|lmstudio|lm-studio)",
                    mac_pgrep_pattern=r"(LM Studio|lmstudio|lm-studio)",
                    windows_image_name="LM Studio.exe",
                    cli_name="lms",
                )

            return default
        except Exception as e:
            self.log(f"⚠ Ошибка определения паспорта по пути {app_path}: {e}")
            return default

    # -------------------- поиск lms cli --------------------

    def naiti_lms_cli(self, preferred_path: str = "", cli_name: str = "lms") -> str | None:
        """
        Возвращает путь к CLI (lms) или None.
        preferred_path — путь из настроек, если задан.
        cli_name — имя CLI без расширения.
        """
        if preferred_path:
            p = Path(preferred_path).expanduser().resolve()
            if p.exists():
                # self.log(f"✓ Используется путь к CLI из настроек: {p}")
                return str(p)

        home = Path.home()
        os_name = platform.system()

        if os_name in ("Linux", "Darwin"):
            search_paths = [
                home / ".lmstudio" / "bin" / cli_name,
                home / ".local" / "bin" / cli_name,
                Path(f"/usr/local/bin/{cli_name}"),
                Path(f"/usr/bin/{cli_name}"),
            ]
            for p in search_paths:
                if p.exists():
                    self.log(f"✓ Найден {cli_name} CLI: {p}")
                    return str(p)

            found = shutil.which(cli_name)
            if found:
                self.log(f"✓ Найден {cli_name} в PATH: {found}")
                return found

        elif os_name == "Windows":
            exe_name = f"{cli_name}.exe"
            search_paths = [
                Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "LMStudio" / exe_name,
                Path(os.environ.get("APPDATA", "")) / "LMStudio" / exe_name,
            ]
            for p in search_paths:
                if p.exists():
                    self.log(f"✓ Найден {cli_name} CLI: {p}")
                    return str(p)

            found = shutil.which(exe_name) or shutil.which(cli_name)
            if found:
                self.log(f"✓ Найден {cli_name} в PATH: {found}")
                return found

        return None

    # --- ПОИСК ИСПОЛНЯЕМЫХ ФАЙЛОВ ---
    def naiti_put_prilozhenia(self, custom_path: str = "") -> Path | None:
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
            from_desktop = self._naiti_cherez_desktop_linux(home)
            if from_desktop and from_desktop.exists():
                self.log(f"✓ Найден через .desktop: {from_desktop}")
                return from_desktop

            search_dirs = [
                home / "lmstudio",
                home / "Applications",
                home / "Downloads",
                home / ".cache",
                home / ".local" / "share" / "applications",
                Path("/opt"),
                Path("/usr/local/bin"),
            ]

            found = self._naiti_appimage_v_papkah(
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

    def _naiti_cherez_desktop_linux(self, home: Path) -> Path | None:
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

        try:
            desktop_files += list(desktop_dir.glob("*lm*studio*.desktop"))
            desktop_files += list(desktop_dir.glob("*bionic*.desktop"))
        except Exception as e:
            self.log(f"⚠ Ошибка поиска .desktop файлов: {e}")

        for df in desktop_files:
            if not df.exists():
                continue
            p = self._razobrat_desktop_exec(df)
            if p and p.exists():
                return p

        return None

    def _razobrat_desktop_exec(self, desktop_file: Path) -> Path | None:
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
        except Exception as e:
            self.log(f"⚠ Ошибка разбора {desktop_file}: {e}")
            return None
        return None

    def _naiti_appimage_v_papkah(self, dirs: list[Path], keywords_any: list[tuple[str, ...]]) -> Path | None:
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
            except Exception as e:
                self.log(f"⚠ Ошибка сканирования {base_dir}: {e}")
                continue

        return None
