# DCScripts/DCLMAPI.py
from __future__ import annotations

import subprocess
from typing import Callable, Optional
import requests


class DCLMAPI:
    """
    HTTP API + CLI сервера LM Studio/Bionic (чистый Python, без Qt).
    """

    def __init__(self, log_callback: Optional[Callable[[str], None]] = None):
        self._log = log_callback

    def log(self, msg: str) -> None:
        if self._log:
            self._log(msg)

    # ==================== URL ====================

    def normalize_url(self, server_url: str) -> str:
        """Нормализует URL: убирает пробелы, trailing slash, добавляет /v1 если нет"""
        url = (server_url or "").strip().rstrip('/')
        if not url:
            return ""
        if not url.endswith('/v1'):
            url += '/v1'
        return url

    # ==================== HTTP checks ====================

    def is_server_running(self, server_url: str, timeout: float = 2.0) -> bool:
        """
        Проверяет, отвечает ли сервер на HTTP запрос.
        Возвращает True/False (без исключений наружу).
        """
        try:
            response = requests.get(
                f"{server_url}/models",
                timeout=timeout
            )
            return response.status_code == 200
        except Exception:
            return False

    def fetch_models(self, server_url: str, timeout: float = 5.0) -> tuple[bool, list[str] | None, str]:
        """
        Получает список моделей через API.
        Возвращает: (success, models_list, error_message)

        models_list - список ID моделей БЕЗ 'embed' моделей.
        Фасад сам добавит '(отсутствует)' если нужно.
        """
        try:
            response = requests.get(
                f"{server_url}/models",
                timeout=timeout
            )

            if response.status_code != 200:
                return False, None, f"HTTP {response.status_code}: {response.text}"

            data = response.json()
            models: list[str] = []

            for model_info in data.get("data", []):
                model_id = model_info.get("id", "")
                if model_id and "embed" not in model_id.lower():
                    models.append(model_id)

            return True, models, ""

        except requests.exceptions.ConnectionError as e:
            return False, None, f"Не удалось подключиться к серверу ({server_url}): {e}"

        except Exception as e:
            return False, None, f"Ошибка загрузки моделей: {e}"

    # ==================== Server control via CLI ====================

    def start_server(self, cli_path: str, timeout: float = 10.0) -> tuple[bool, str]:
        """
        Запускает сервер через CLI.
        Возвращает: (success, error_message)
        """
        if not cli_path:
            return False, "Путь к CLI не указан"

        try:
            result = subprocess.run(
                [cli_path, "server", "start"],
                capture_output=True,
                text=True,
                timeout=timeout
            )

            if result.returncode == 0:
                return True, ""
            else:
                return False, f"Ошибка выполнения команды: {result.stderr}"

        except Exception as e:
            return False, f"Ошибка запуска сервера: {str(e)}"

    def stop_server(self, cli_path: str, timeout: float = 10.0) -> tuple[bool, str]:
        """
        Останавливает сервер через CLI.
        Возвращает: (success, error_message)
        """
        if not cli_path:
            return False, "Путь к CLI не указан"

        try:
            result = subprocess.run(
                [cli_path, "server", "stop"],
                capture_output=True,
                text=True,
                timeout=timeout
            )

            if result.returncode == 0:
                return True, ""
            else:
                return False, f"Ошибка выполнения команды: {result.stderr}"

        except Exception as e:
            return False, f"Ошибка остановки сервера: {str(e)}"
