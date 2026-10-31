"""
Модуль обработки орфографии (PyOrfograf.py)
Загружает .txt документы, режет на фрагменты с перекрытием,
просит ИИ исправить орфографию, склеивает и сохраняет файлы.
"""
import threading
import json
import requests
import os
from pathlib import Path
from PyQt6.QtCore import QObject, QThread, pyqtSlot, pyqtSignal

# ==================== КОНСТАНТЫ ====================
TIMEOUT_CONNECT = 15                # сек на установление TCP-соединения
TIMEOUT_READ_CHUNK = 600            # сек максимум МЕЖДУ соседними токенами в стриме (не на весь ответ!)
RESERV_TOKENS = 1500                # Запас токенов под системный промпт/служебку
CHARS_PER_TOKEN = 2.5               # Эвристика: символов на токен для кириллицы

MAX_TOKENS_RETRY_MULTIPLIER = 2.5   # во сколько раз увеличиваем бюджет при повторе
MAX_RETRY_ATTEMPTS = 2              # сколько раз пробуем увеличивать



class DCOrfografWorker(QThread):
    """Рабочий поток обработки документов"""
    def __init__(self, orfograf, filePaths, strPut, rlTemperatura, ntKontekst, ntPerekritieProcent):
        super().__init__()
        self.orfograf = orfograf
        self.filePaths = filePaths
        self.strPut = strPut
        self.rlTemperatura = rlTemperatura
        self.ntKontekst = ntKontekst
        self.ntPerekritieProcent = ntPerekritieProcent
    # ------------------------------------------------------------------
    def run(self):
        """Выполняется в отдельном потоке"""
        self.orfograf._fnProtsitOrfografiju(
            self.filePaths, self.strPut, self.rlTemperatura,
            self.ntKontekst, self.ntPerekritieProcent
        )



class DCOrfograf(QObject):
    """
    Класс для исправления орфографии в текстовых документах через LLM
    """
    # СИГНАЛЫ
    sigProgress = pyqtSignal(str, int, int)        # (имя файла, фрагмент, всего фрагментов)
    sigVseGotovo = pyqtSignal(int, int)            # (обработано файлов, ошибок)
    sigDokumentGotov = pyqtSignal(str, str, int)   # (имя файла, путь, правок)
    strOshibka = pyqtSignal(int, str)              # Код ошибки и текст ошибки.
    strLog = pyqtSignal(str)                       # Пишем в лог приложения.

    # КОДЫ ОШИБОК
    ERR_REQUEST = 1000
    ERR_JSON = 1001
    ERR_GENERIC = 1002
    ERR_ANALYSIS = 1003
    # ------------------------------------------------------------------
    def __init__(self, parent=None):
        super().__init__(parent)
        self.strServerURL = "http://localhost:1234/v1"
        self.model_name = None
        self.ntMaxToken = 8192
        self.strPrompt = ""
        self.blZapreshchen = False   # Пользователь запретил обработку
        self.blIsworking = False     # Идёт ли обработка прямо сейчас
        self.worker = None

        # ВАЖНО: ссылка на текущий открытый HTTP-response.
        # Нужна, чтобы по stopOrfografiya() реально оборвать соединение,
        # а не просто выставить флаг, который никто не проверяет во время
        # блокирующего ожидания ответа от сервера.
        self._active_response = None
        self._response_lock = threading.Lock()
    # ------------------------------------------------------------------
    @pyqtSlot(str)
    def ustServerURL(self, server_url):
        """Устанавливает URL сервера для HTTP-запросов"""
        server_url = server_url.strip().rstrip('/')
        if not server_url.endswith('/v1'):
            server_url += '/v1'
        self.strServerURL = server_url
        self.strLog.emit(f"pyOrfograf: URL сервера обновлён: {self.strServerURL}")
    # ------------------------------------------------------------------
    @pyqtSlot(str, int)
    def ustParametri(self, model_name, ntMaxToken):
        """Устанавливает текущую модель и максимальный размер контекста (в токенах)"""
        if model_name == "" or model_name == "(отсутствует)":
            self.model_name = None
        else:
            self.model_name = model_name
        self.ntMaxToken = ntMaxToken
        self.strLog.emit(f"Параметры обновлены: {model_name}, контекст: {ntMaxToken}")
    # ------------------------------------------------------------------
    @pyqtSlot(str)
    def ustPrompt(self, prompt):
        """Задаём промпт нейросети"""
        if prompt == "":
            self.strPrompt = ""
        else:
            self.strPrompt = prompt
    # ------------------------------------------------------------------
    @pyqtSlot(list, str, float, int, int)
    def startOrfografiya(self, filePaths, strPut, rlTemperatura, ntKontekst, ntPerekritieProcent):
        """
        Запускает исправление орфографии в фоне, по одному документу.
        Args:
            filePaths (list): Список путей к .txt документам
            strPut (str): Папка сохранения исправленных документов
            rlTemperatura (float): Температура ИИ модели
            ntKontekst (int): Размер фрагмента в СИМВОЛАХ (не путать с ntMaxToken!)
            ntPerekritieProcent (int): Перекрытие фрагментов в процентах
        """
        if self.blIsworking:
            self.strOshibka.emit(self.ERR_ANALYSIS, "Обработка орфографии уже выполняется.")
            return
        if not self.strServerURL:
            self.strOshibka.emit(self.ERR_ANALYSIS,
                                  "URL сервера не установлен. Проверьте запуск сервера LLM.")
            return
        if not filePaths:
            self.strOshibka.emit(self.ERR_ANALYSIS, "Не выбраны документы для обработки.")
            return

        # На всякий случай гасим предыдущий поток, если он почему-то ещё жив
        if self.worker and self.worker.isRunning():
            self.worker.quit()
            self.worker.wait()

        self.blZapreshchen = False
        self.blIsworking = True

        self.worker = DCOrfografWorker(self, filePaths, strPut, rlTemperatura,
                                        ntKontekst, ntPerekritieProcent)
        self.worker.start()
    # ------------------------------------------------------------------
    @pyqtSlot()
    def stopOrfografiya(self):
        """
        Пользователь отменил обработку орфографии.
        ВАЖНО: одного флага недостаточно — поток может стоять внутри
        блокирующего чтения ответа от сервера. Поэтому здесь дополнительно
        форсированно закрываем активное HTTP-соединение: в режиме stream=True
        сервер (LM Studio/llama.cpp) видит обрыв и реально прекращает генерацию
        токенов, а не продолжает считать "в пустоту".
        """
        self.blZapreshchen = True
        self.strLog.emit("Пользователь запретил обработку орфографии.")

        with self._response_lock:
            if self._active_response is not None:
                try:
                    self._active_response.close()
                    self.strLog.emit("🔌 Активное соединение с сервером разорвано.")
                except Exception:
                    pass

        if self.worker and self.worker.isRunning():
            self.worker.quit()
            if not self.worker.wait(3000):
                # Крайний случай — поток завис не в HTTP, а где-то ещё
                self.worker.terminate()
                self.worker.wait()

        self.blIsworking = False
    # ------------------------------------------------------------------
    def _fnRazrezatTekst(self, strTekst, ntKontekst, ntPerekritieProcent):
        """
        Режет текст на фрагменты нужного размера с перекрытием, стараясь
        не рвать предложения посередине.
        Returns: список фрагментов
        """
        fragments = []
        len_text = len(strTekst)
        if len_text == 0:
            return fragments
        ntPerekritie = int(ntKontekst * ntPerekritieProcent / 100)
        ntPerekritie = min(ntPerekritie, ntKontekst // 2)
        ntShag = max(1, ntKontekst - ntPerekritie)
        ntNachalo = 0
        while ntNachalo < len_text:
            ntKonec = min(ntNachalo + ntKontekst, len_text)
            if ntKonec < len_text:
                for ch in ('.', '!', '?', '\n'):
                    ntGranica = strTekst.find(ch, ntKonec - 1,
                                               min(ntKonec + int(ntKontekst * 0.1), len_text))
                    if ntGranica != -1:
                        ntKonec = ntGranica + 1
                        break
            fragments.append(strTekst[ntNachalo:ntKonec])
            if ntKonec >= len_text:
                break
            ntNachalo = max(ntNachalo + ntShag, ntNachalo + 1)
        return fragments
    # ------------------------------------------------------------------
    def _fnVichislitMaxTokens(self, strSoderjanie):
        """
        Считает безопасный max_tokens для ОДНОГО запроса исправления фрагмента.
        ВАЖНО: современные "thinking"/reasoning модели (MoE-архитектуры типа
        a3b/a4b) перед финальным ответом генерируют служебный блок размышлений
        (<think>...</think> или отдельное поле reasoning_content). Этот расход
        токенов НЕ зависит от длины входного текста — он может быть большим
        даже для одного предложения. Поэтому нельзя считать max_tokens только
        от длины фрагмента: при маленьком фрагменте модель получает мизерный
        лимит, тратит его весь на размышление и не успевает дать ответ —
        content остаётся пустым, хотя генерация честно отработала и упёрлась
        в лимит (finish_reason: length).
        """
        fragment_tokens = max(50, int(len(strSoderjanie) / CHARS_PER_TOKEN))
        zhelaemo = int(fragment_tokens * 1.5) + 200

        # Фиксированный запас под возможное "размышление" модели.
        # Если модель не thinking — эти токены просто не используются,
        # ответ придёт раньше лимита. Если thinking — без этого запаса
        # ответа не будет вообще никогда, независимо от размера фрагмента.
        THINKING_RESERV = 2000
        zhelaemo += THINKING_RESERV

        dostupno = max(512, self.ntMaxToken - fragment_tokens - RESERV_TOKENS)
        final_tokens = min(zhelaemo, dostupno)

        if final_tokens < zhelaemo:
            self.strLog.emit(
                f"⚠ Контекст модели ({self.ntMaxToken}) мал, ответ ограничен {final_tokens} токенами "
                f"(запрошено бы {zhelaemo})"
            )
        print(f"[DCOrfograf] max_tokens для фрагмента ({len(strSoderjanie)} симв.): {final_tokens}")
        return final_tokens
    # ------------------------------------------------------------------
    def _fnPostavitZapyt(self, strSoderjanie, rlTemperatura):
        if self.blZapreshchen:
            return None

        max_tokens = self._fnVichislitMaxTokens(strSoderjanie)
        # Потолок, выше которого увеличивать бессмысленно (упираемся в контекст модели)
        hard_ceiling = max(max_tokens, self.ntMaxToken - int(len(strSoderjanie) / CHARS_PER_TOKEN) - 500)

        attempt = 0
        while True:
            result, finish_reason, reasoning_len = self._fnOdinZapros(
                strSoderjanie, rlTemperatura, max_tokens
            )
            if result is None:  # остановлено пользователем / сетевая ошибка
                return None
            if not result.startswith("ОШИБКА:"):
                return result  # успех

            # Если пусто именно из-за нехватки токенов на размышление — пробуем повторить с большим лимитом
            if finish_reason == "length" and attempt < MAX_RETRY_ATTEMPTS and max_tokens < hard_ceiling:
                attempt += 1
                new_max_tokens = min(int(max_tokens * MAX_TOKENS_RETRY_MULTIPLIER), hard_ceiling)
                self.strLog.emit(
                    f"🔄 Модель не уложилась в {max_tokens} токенов (reasoning={reasoning_len} симв.), "
                    f"повтор #{attempt} с лимитом {new_max_tokens}..."
                )
                if self.blZapreshchen:
                    return None
                max_tokens = new_max_tokens
                continue

            # Исчерпали попытки или ошибка другого рода
            return result
    # ------------------------------------------------------------------
    def _fnOdinZapros(self, strSoderjanie, rlTemperatura, max_tokens):
        """
        Один HTTP-запрос к LLM. Возвращает (result, finish_reason, reasoning_len).
        result может начинаться с "ОШИБКА:" — тогда вызывающий код решает, повторять или нет.
        """
        if self.strPrompt == "":
            self.strPrompt =  self.strPrompt = "Ты — профессиональный корректор русского языка."
        payload = {
            "messages": [
                {
                    "role": "system",
                    "content": (self.strPrompt)
                },
                {"role": "user", "content": f"Исправь ошибки в следующем тексте:\n\n{strSoderjanie}"}
            ],
            "temperature": rlTemperatura,
            "max_tokens": max_tokens,
            "stream": True,
            # Пробуем отключить "размышление" для moделей, чья jinja-шаблон это поддерживает
            # (изначально параметр для Qwen3, но некоторые llama.cpp-шаблоны уважают его
            # универсально). Если модель/шаблон его не знает — просто игнорируется,
            # вреда не будет.
            "chat_template_kwargs": {"enable_thinking": False},
        }
        if self.model_name:
            payload["model"] = self.model_name

        url = f"{self.strServerURL}/chat/completions"
        response = None
        try:
            response = requests.post(
                url, json=payload, stream=True,
                timeout=(TIMEOUT_CONNECT, TIMEOUT_READ_CHUNK)
            )
            with self._response_lock:
                self._active_response = response
            response.raise_for_status()

            content_parts = []
            reasoning_parts = []
            finish_reason = None

            for raw_line in response.iter_lines():
                if self.blZapreshchen:
                    break
                if not raw_line:
                    continue
                line = raw_line.decode("utf-8", errors="replace")
                if not line.startswith("data:"):
                    continue
                data_str = line[len("data:"):].strip()
                if data_str == "[DONE]":
                    break
                try:
                    chunk = json.loads(data_str)
                except json.JSONDecodeError:
                    continue
                choices = chunk.get("choices") or [{}]
                choice0 = choices[0]
                delta = choice0.get("delta", {}) or {}
                if choice0.get("finish_reason"):
                    finish_reason = choice0.get("finish_reason")
                piece = delta.get("content", "")
                if piece:
                    content_parts.append(piece)
                reasoning_piece = delta.get("reasoning_content", "")
                if reasoning_piece:
                    reasoning_parts.append(reasoning_piece)

            if self.blZapreshchen:
                return None, None, 0

            result = "".join(content_parts).strip()
            reasoning_text = "".join(reasoning_parts).strip()

            if not result:
                return (f"ОШИБКА: Пустой ответ (finish_reason={finish_reason}, "
                        f"reasoning={len(reasoning_text)} симв.)", finish_reason, len(reasoning_text))
            return result, finish_reason, len(reasoning_text)

        except requests.exceptions.Timeout as e:
            if self.blZapreshchen:
                return None, None, 0
            self.strLog.emit(f"⏱️ Timeout: {str(e)}")
            return "ОШИБКА: Timeout", "timeout", 0
        except requests.exceptions.RequestException as e:
            if self.blZapreshchen:
                return None, None, 0
            error_type = type(e).__name__
            self.strOshibka.emit(self.ERR_REQUEST, f"{error_type}: {str(e)}")
            return f"ОШИБКА: {error_type}", "error", 0
        except Exception as e:
            if self.blZapreshchen:
                return None, None, 0
            self.strOshibka.emit(self.ERR_GENERIC, str(e))
            return "ОШИБКА: " + str(e), "error", 0
        finally:
            with self._response_lock:
                self._active_response = None
            if response is not None:
                try:
                    response.close()
                except Exception:
                    pass
    # ------------------------------------------------------------------
    def _fnSkleitFragmeny(self, fragments, corrected, ntKontekst, ntPerekritieProcent):
        """
        Склеивает исправленные фрагменты, убирая дублированное перекрытие.
        """
        result = corrected[0]
        for i in range(1, len(corrected)):
            pred = result
            cur = corrected[i]
            ntPerekritie = min(int(ntKontekst * ntPerekritieProcent / 100),
                                len(pred), len(cur))
            ntNaideno = 0
            for j in range(ntPerekritie, 9, -1):
                if pred[-j:] == cur[:j]:
                    ntNaideno = j
                    break
            if ntNaideno:
                result += cur[ntNaideno:]
            else:
                result += cur
        return result
    # ------------------------------------------------------------------
    def _fnPutDljaSohraneniya(self, strPapka, strImya):
        """Строит путь сохранения: (имя)_орфография.txt, при конфликте _1, _2..."""
        os.makedirs(strPapka, exist_ok=True)
        stem = Path(strImya).stem
        put = os.path.join(strPapka, stem + "_орфография.txt")
        nt = 1
        while os.path.exists(put):
            put = os.path.join(strPapka, f"{stem}_орфография_{nt}.txt")
            nt += 1
        return put
    # ------------------------------------------------------------------
    def _fnProtsitOrfografiju(self, filePaths, strPut, rlTemperatura, ntKontekst, ntPerekritieProcent):
        """
        Основной поток обработки: каждый документ режется на фрагменты,
        каждый фрагмент исправляется ИИ, фрагменты склеиваются и сохраняются.
        """
        try:
            ntVseho = 0
            ntOshibok = 0
            if strPut == "":
                strPut = str(Path.home())

            for filePath in filePaths:
                if self.blZapreshchen:
                    break

                strImya = os.path.basename(filePath)
                try:
                    with open(filePath, 'r', encoding='utf-8', errors='replace') as f:
                        strTekst = f.read()
                except Exception as e:
                    ntOshibok += 1
                    self.strOshibka.emit(self.ERR_GENERIC, f"{strImya}: {str(e)}")
                    continue

                fragments = self._fnRazrezatTekst(strTekst, ntKontekst, ntPerekritieProcent)
                if not fragments:
                    self.strLog.emit(f"Пустой документ пропущен: {strImya}")
                    continue

                corrected = []
                blPrervali = False
                for nt in range(len(fragments)):
                    if self.blZapreshchen:
                        blPrervali = True
                        break

                    self.sigProgress.emit(strImya, nt, len(fragments))
                    self.strLog.emit(f"Обработка {strImya}: фрагмент {nt + 1}/{len(fragments)}")

                    result = self._fnPostavitZapyt(fragments[nt], rlTemperatura)

                    if self.blZapreshchen or result is None:
                        blPrervali = True
                        break
                    if result.startswith("ОШИБКА:"):
                        msg = f"{strImya}, фрагмент {nt+1}/{len(fragments)}: {result}"
                        self.strLog.emit(f"⚠ Не исправлен: {msg}")
                        self.strOshibka.emit(self.ERR_ANALYSIS, msg)
                        corrected.append(fragments[nt])
                        continue

                    if result.strip() == fragments[nt].strip():#модель могла вернуть текст без изменений
                        print(f"[DCOrfograf] ⚠ Фрагмент {nt+1}: модель вернула ТЕКСТ БЕЗ ИЗМЕНЕНИЙ")
                        print(f"[DCOrfograf]   Оригинал:  {fragments[nt]!r}")
                        print(f"[DCOrfograf]   Результат: {result!r}")
                    corrected.append(result)

                if blPrervali:
                    self.strLog.emit(f"Документ не сохранён (отмена): {strImya}")
                    break

                sborka = self._fnSkleitFragmeny(fragments, corrected, ntKontekst, ntPerekritieProcent)
                put = self._fnPutDljaSohraneniya(strPut, strImya)
                try:
                    with open(put, 'w', encoding='utf-8') as f:
                        f.write(sborka)
                except Exception as e:
                    ntOshibok += 1
                    self.strOshibka.emit(self.ERR_GENERIC, f"{strImya}: {str(e)}")
                    continue

                ntVseho += 1
                ntIzmenenij = sum(1 for a, b in zip(fragments, corrected) if a != b)
                self.sigDokumentGotov.emit(strImya, put, ntIzmenenij)
                self.strLog.emit(f"✅ Документ сохранён: {put}")
                self.sigProgress.emit(strImya, len(fragments), len(fragments))

            if self.blZapreshchen:
                self.strLog.emit("Орфография прервана пользователем")

            self.strLog.emit(f"Обработка завершена. Сохранено: {ntVseho}, ошибок: {ntOshibok}")
            self.sigVseGotovo.emit(ntVseho, ntOshibok)

        except Exception as e:
            self.strOshibka.emit(self.ERR_GENERIC, str(e))
            self.strLog.emit(f"КРИТИЧЕСКАЯ ошибка обработки: {str(e)}")
        finally:
            self.blIsworking = False
