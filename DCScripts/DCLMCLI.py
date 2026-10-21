# DCScripts/DCLMCLI.py
from __future__ import annotations

import json
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional
from dataclasses import dataclass, field

@dataclass(frozen=True)
class LoadResult:
    success: bool
    used_gpu_param: str = ""
    used_gpu_desc: str = ""
    error: str = ""
    oom: bool = False
    timeout: bool = False
    hints: list[str] = field(default_factory=list)

class DCLMCLI:
    """
    Работа с lms CLI (чистый Python, без Qt):
    - unload модели
    - load модели с прогрессом
    - fallback стратегии GPU при OOM
    - обновление ~/.lmstudio/server-config.json
    """

    def __init__(self, log_callback: Optional[Callable[[str], None]] = None):
        self._log = log_callback

    def log(self, msg: str) -> None:
        if self._log:
            self._log(msg)

    # -------------------- GPU params --------------------
    def get_gpu_params(self, gpu_offload: int) -> tuple[str, str]:
        if gpu_offload == 0:
            return "off", "CPU only"
        if gpu_offload >= 100:
            return "max", "Full GPU"
        return str(gpu_offload / 100.0), f"{gpu_offload}% GPU"

    def get_fallback_strategies(self, gpu_offload: int) -> list[tuple[str, str]]:
        if gpu_offload >= 100:
            return [("0.5", "50% GPU"), ("0.3", "30% GPU"), ("off", "CPU only")]
        if gpu_offload >= 50:
            return [("0.3", "30% GPU"), ("off", "CPU only")]
        if gpu_offload > 0:
            return [("off", "CPU only")]
        return []

    def _is_oom_error(self, text: str) -> bool:
        t = (text or "").lower()
        return ("out of memory" in t) or ("cuda" in t) or ("cublas" in t)

    # -------------------- unload --------------------
    def unload_model(self, lms_cli: str, timeout: float = 30.0) -> bool:
        """
        Выгружает модель. Возвращает True даже если модели не было (это не ошибка).
        """
        try:
            self.log("🔄 Выгрузка предыдущей модели...")

            r = subprocess.run(
                [lms_cli, "unload"],
                capture_output=True,
                text=True,
                timeout=timeout
            )

            if r.returncode == 0:
                self.log("✓ Предыдущая модель выгружена")
                return True

            err = (r.stderr or "").strip()
            # “нет модели” считаем нормальным исходом
            if "you don't have any models loaded" in err.lower():
                self.log("Нет загруженной модели для выгрузки")
                return True

            self.log(f"⚠ Предупреждение при выгрузке: {err[:200]}")
            return True

        except Exception as e:
            self.log(f"⚠ Ошибка выгрузки модели: {e}")
            return True  # не критично

    # -------------------- load (with progress) --------------------
    def load_model(
        self,
        lms_cli: str,
        model_name: str,
        max_context: int,
        gpu_offload: int,
        timeout: float,
        progress_cb: Optional[Callable[[int], None]] = None,
    ) -> LoadResult:
        """
        Пытается загрузить модель:
        1) unload
        2) load с прогрессом
        3) при OOM — fallback стратегии GPU
        """
        # unload всегда сначала
        self.unload_model(lms_cli)

        gpu_param, gpu_desc = self.get_gpu_params(gpu_offload)

        res = self._load_once_with_progress(
            lms_cli=lms_cli,
            model_name=model_name,
            max_context=max_context,
            gpu_param=gpu_param,
            timeout=timeout,
            progress_cb=progress_cb
        )

        if res.success:
            return LoadResult(True, used_gpu_param=gpu_param, used_gpu_desc=gpu_desc)

        # если OOM — пробуем fallback
        if res.oom:
            self.log(f"⚠ {gpu_desc}: не хватает памяти")
            self.log("🔄 Пробуем альтернативные стратегии GPU...")

            for fb_gpu, fb_desc in self.get_fallback_strategies(gpu_offload):
                self.log(f"🔄 Попытка: {fb_desc}...")

                fb = self._load_once_simple(
                    lms_cli=lms_cli,
                    model_name=model_name,
                    max_context=max_context,
                    gpu_param=fb_gpu,
                    timeout=timeout
                )
                if fb.success:
                    return LoadResult(True, used_gpu_param=fb_gpu, used_gpu_desc=f"{fb_desc} (fallback)")

                if fb.timeout:
                    return fb

                if fb.oom:
                    self.log(f"⚠ {fb_desc}: всё ещё не хватает памяти")
                    continue

                # другая ошибка — прекращаем fallback
                return fb

            # fallback не помог
            return res

        return res

    def _load_once_with_progress( self, lms_cli: str, model_name: str, max_context: int, gpu_param: str,
        timeout: float, progress_cb: Optional[Callable[[int], None]] = None,) -> LoadResult:
        """
        Запуск lms load через Popen + чтение stdout (stderr объединяем со stdout, чтобы не блокировалось).
        """
        try:
            self.log("🔄 Загрузка модели с новыми параметрами...")

            if progress_cb:
                progress_cb(0)

            cmd = [
                lms_cli, "load", model_name,
                "--context-length", str(max_context),
                "--gpu", gpu_param,
                "-y"
            ]

            process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )

            progress_pattern = re.compile(r'Loading\s+\S+\s+(\d+)%')
            last_progress = -1
            tail_lines: list[str] = []

            # читаем вывод построчно до завершения процесса
            while True:
                line = process.stdout.readline() if process.stdout else ""
                if not line:
                    break

                line = line.strip()
                if line:
                    tail_lines.append(line)
                    if len(tail_lines) > 60:
                        tail_lines.pop(0)

                m = progress_pattern.search(line)
                if m and progress_cb:
                    p = int(m.group(1))
                    if p != last_progress:
                        last_progress = p
                        progress_cb(p)

            process.wait(timeout=timeout)

            if process.returncode == 0:
                if progress_cb:
                    progress_cb(100)
                return LoadResult(True)

            err_text = "\n".join(tail_lines).strip() or "Неизвестная ошибка"
            oom = self._is_oom_error(err_text)
            if progress_cb:
                progress_cb(0)

            return LoadResult(
                success=False,
                error=err_text[:400],
                oom=oom,
                hints=self.make_hints(err_text, oom=oom, timeout=False)
            )

        except subprocess.TimeoutExpired:
            if progress_cb:
                progress_cb(0)
            return LoadResult(
                False,
                error="Таймаут загрузки модели",
                timeout=True,
                hints=self.make_hints("Таймаут загрузки модели", oom=False, timeout=True)
            )
        except Exception as e:
            if progress_cb:
                progress_cb(0)
            msg = str(e)
            return LoadResult(
                False,
                error=msg,
                hints=self.make_hints(msg, oom=False, timeout=False)
            )

    def _load_once_simple(
        self,
        lms_cli: str,
        model_name: str,
        max_context: int,
        gpu_param: str,
        timeout: float
    ) -> LoadResult:
        """
        Упрощённый запуск lms load через subprocess.run (без прогресса), удобно для fallback.
        """
        try:
            cmd = [
                lms_cli, "load", model_name,
                "--context-length", str(max_context),
                "--gpu", gpu_param,
                "-y"
            ]
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)

            if r.returncode == 0:
                return LoadResult(True)

            err = (r.stderr or r.stdout or "").strip() or "Неизвестная ошибка"
            oom = self._is_oom_error(err)

            return LoadResult(
                False,
                error=err[:400],
                oom=oom,
                hints=self.make_hints(err, oom=oom, timeout=False)
            )

        except subprocess.TimeoutExpired:
            return LoadResult(
                False,
                error="Таймаут загрузки модели",
                timeout=True,
                hints=self.make_hints("Таймаут загрузки модели", oom=False, timeout=True)
            )
        except Exception as e:
            return LoadResult(False, error=str(e))

    # -------------------- config --------------------

    def update_server_config(self, max_context: int) -> bool:
        """
        Обновляет ~/.lmstudio/server-config.json (или создаёт).
        """
        try:
            config_path = Path.home() / ".lmstudio" / "server-config.json"

            if not config_path.exists():
                self.log(f"⚠ Конфигурация не найдена: {config_path}")

                default_config = {
                    "maxContext": max_context,
                    "temperature": 0.7,
                    "topP": 0.9,
                    "repeatPenalty": 1.1,
                    "gpu": "auto"
                }

                config_path.parent.mkdir(parents=True, exist_ok=True)
                config_path.write_text(json.dumps(default_config, indent=2), encoding="utf-8")

                self.log(f"✓ Создан конфиг: {config_path}")
                return True

            config = json.loads(config_path.read_text(encoding="utf-8"))
            old_context = config.get("maxContext", 0)
            config["maxContext"] = max_context
            config_path.write_text(json.dumps(config, indent=2), encoding="utf-8")

            self.log(f"✓ Контекст обновлён: {old_context} → {max_context}")
            return True

        except Exception as e:
            self.log(f"✗ Ошибка обновления конфига: {e}")
            return False

    # --- ПОДСКАЗКИ ---
    def make_hints(self, error_text: str, oom: bool, timeout: bool) -> list[str]:
        t = (error_text or "").lower()
        hints: list[str] = []

        if timeout:
            hints.append("💡 Рекомендации:")
            hints.append("   1. Попробуйте подождать и повторить загрузку")
            hints.append("   2. Проверьте, что диск/файлы модели доступны")
            hints.append("   3. Уменьшите контекст (например, до 4096)")
            return hints

        if oom:
            hints.append("💡 Рекомендации:")
            hints.append("   1. Используйте модель меньшего размера (Q3, Q2)")
            hints.append("   2. Закройте другие приложения, использующие GPU")
            hints.append("   3. Уменьшите контекст (например, до 4096)")
            return hints

        if "not found" in t:
            hints.append('💡 Модель не найдена. Проверьте имя модели: "lms ls"')
            return hints

        return hints
