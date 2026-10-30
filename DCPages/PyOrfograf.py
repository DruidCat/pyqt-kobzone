"""
Модуль обработки орфографии (PyOrfograf.py)
Загружает .txt документы, режет на фрагменты с перекрытием,
просит ИИ исправить орфографию, склеивает и сохраняет файлы.
"""
import threading
import time
import json
import requests
import os
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSlot, pyqtSignal


class DCOrfograf(QObject):
    """
    Класс для исправления орфографии в текстовых документах через LLM
    """
    # СИГНАЛЫ
    sigProgress = pyqtSignal(str, int, int)  # (имя файла, фрагмент, всего фрагментов)
    sigVseGotovo = pyqtSignal(int, int)  # (обработано файлов, ошибок)
    sigDokumentGotov = pyqtSignal(str, str, int)  # (имя файла, путь, правок)
    strOshibka = pyqtSignal(int, str)  # Код ошибки и текст ошибки.
    strLog = pyqtSignal(str)  # Пишем в лог приложения.

    # КОДЫ ОШИБОК
    ERR_REQUEST = 1000  # Ошибки requests.HTTPError
    ERR_JSON = 1001  # Ошибки парсинга JSON (json.JSONDecodeError)
    ERR_GENERIC = 1002  # Прочие ошибки
    ERR_ANALYSIS = 1003  # Ошибки анализа текста ИИ

    def __init__(self, parent=None):
        super().__init__(parent)
        self.strServerURL = ""
        self.model_name = ""
        self.ntMaxToken = 8192
        self.blZapreshchen = False  # Пользователь запретил обработку
        self.blIsworking = False  # Идёт ли обработка прямо сейчас
        self.strSoderjankoe = ""  # Содержимое анализируемого фрагмента
        self.blAnalyzeActive = False  # Флаг активности процесса анализа

    @pyqtSlot(str)
    def ustServerURL(self, url):
        """Устанавливает URL сервера для HTTP-запросов"""
        self.strServerURL = url
        self.strLog.emit(f"URL сервера обновлён: {self.strServerURL}")

    @pyqtSlot(str, int)
    def ustParametri(self, model_name, ntMaxToken):
        """
        Устанавливает текущую модель и максимальный размер контекста
        Args:
            model_name (str): Название модели
            ntMaxToken (int): Максимальный размер контекста в токенах
        """
        self.model_name = model_name
        self.ntMaxToken = ntMaxToken
        self.strLog.emit(f"Параметры обновлены: {model_name}, контекст: {ntMaxToken}")

    @pyqtSlot(list, str, float, int, int)
    def startOrfografiya(self, filePaths, strPut, rlTemperatura,
                         ntKontekst, ntPerekritieProcent):
        """
        Запускает исправление орфографии в фоне, по одному документу.
        Args:
            filePaths (list): Список путей к .txt документам
            strPut (str): Папка сохранения исправленных документов
            rlTemperatura (float): Температура ИИ модели
            ntKontekst (int): Размер фрагмента в символах
            ntPerekritieProcent (int): Перекрытие фрагментов в процентах
        """
        if self.blIsworking:
            self.strOshibka.emit(self.ERR_ANALYSIS,
                                 "Обработка орфографии уже выполняется.")
            return
        if not self.strServerURL:
            self.strOshibka.emit(self.ERR_ANALYSIS,
                                 "URL сервера не установлен. Проверьте запуск сервера LLM.")
            return
        if not filePaths:
            self.strOshibka.emit(self.ERR_ANALYSIS, "Не выбраны документы для обработки.")
            return
        self.blZapreshchen = False  # Разрешаем новую обработку
        self.blIsworking = True
        threading.Thread(
            target=self._fnProtsitOrfografiju,
            args=(filePaths, strPut, rlTemperatura, ntKontekst, ntPerekritieProcent),
            daemon=True
        ).start()

    @pyqtSlot()
    def stopOrfografiya(self):
        """Пользователь отменил обработку орфографии"""
        self.blZapreshchen = True
        self.strLog.emit("Пользователь запретил обработку орфографии.")

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
        ntPerekritie = min(ntPerekritie, ntKontekst // 2)  # Перекрытие не больше половины
        ntShag = max(1, ntKontekst - ntPerekritie)
        ntNachalo = 0
        while ntNachalo < len_text:
            ntKonec = min(ntNachalo + ntKontekst, len_text)
            # Двигаем конец к границе предложения (ищем после желаемого конца)
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
    def _fnPostavitZapyt(self, strSoderjankoe, rlTemperatura):
        """
        Делает HTTP запрос к OpenAI-совместимому API на исправление орфографии.
        Returns: исправленный текст, "ОШИБКА: описание" или None при отмене.
        """
        try:
            url = f"{self.strServerURL}/chat/completions"
            payload = {
                "model": self.model_name,
                "messages": [
                    {
                        "role": "system",
                        "content": "Ты — корректор русских текстов. Исправь только орфографию, "
                                   "опечатки и пунктуацию. Не перефразируй, не меняй стиль, "
                                   "структуру и смысл, не удаляй и не добавляй абзацы. "
                                   "Ответь ТОЛЬКО исправленным текстом без пояснений, "
                                   "комментариев и разметки."
                    },
                    {"role": "user", "content": strSoderjankoe}
                ],
                "stream": False,
                "temperature": rlTemperatura
            }
            timeout = 600000  # 10 минут
            response = requests.post(url, json=payload, timeout=timeout)
            response.raise_for_status()
            result = response.json()
            if 'error' in result:
                self.strLog.emit(f"❌ API error: {result['error']}")
                return f"ОШИБКА: {result['error']}"
            content = result['choices'][0]['message']['content']
            return content.strip()
        except requests.exceptions.Timeout as e:
            self.strLog.emit(f"⏱️ Timeout: {str(e)}")
            return "ОШИБКА: Timeout"
        except requests.exceptions.RequestException as e:
            error_type = type(e).__name__
            status_code = getattr(e, 'status_code', 'N/A')
            self.strOshibka.emit(self.ERR_REQUEST, f"HTTP {status_code}: {error_type}")
            self.strLog.emit(f"❌ {status_code}: {error_type}")
            return f"ОШИБКА: {error_type}"
        except json.JSONDecodeError as e:
            self.strOshibka.emit(self.ERR_JSON, f"JSON ошибка: {str(e)}")
            return None
        except Exception as e:
            error_msg = str(e).lower()
            if "abort" in error_msg or "cancel" in error_msg or "canceled" in error_msg:
                return None
            self.strOshibka.emit(self.ERR_GENERIC, str(e))
            return "ОШИБКА: " + str(e)

    # ------------------------------------------------------------------
    def _fnSkleitFragmeny(self, fragments, corrected, ntKontekst, ntPerekritieProcent):
        """
        Склеивает исправленные фрагменты, убирая дублированное перекрытие:
        из каждого следующего фрагмента вырезается начало, совпадающее
        с концом предыдущего.
        Returns: склеенный текст
        """
        result = corrected[0]
        for i in range(1, len(corrected)):
            pred = result
            cur = corrected[i]
            ntPerekritie = min(int(ntKontekst * ntPerekritieProcent / 100),
                               len(pred), len(cur))
            ntNaideno = 0
            # Ищем самое длинное совпадение конца предыдущего с началом следующего
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
        """
        Строит путь сохранения: (имя)_орфография.txt, при конфликте _1, _2...
        Returns: полный путь
        """
        os.makedirs(strPapka, exist_ok=True)
        stem = Path(strImya).stem
        put = os.path.join(strPapka, stem + "_орфография.txt")
        nt = 1
        while os.path.exists(put):
            put = os.path.join(strPapka, f"{stem}_орфография_{nt}.txt")
            nt += 1
        return put

    # ------------------------------------------------------------------
    def _fnProtsitOrfografiju(self, filePaths, strPut, rlTemperatura,
                              ntKontekst, ntPerekritieProcent):
        """
        Основной поток обработки: каждый документ режется на фрагменты,
        каждый фрагмент исправляется ИИ, фрагменты склеиваются и сохраняются.
        """
        try:
            ntVseho = 0
            ntOshibok = 0
            if strPut == "":
                strPut = str(Path.home())
            for filePath in filePaths:  # Идём по списку документов
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
                corrected = []  # Исправленные фрагменты текущего документа
                blPrervali = False  # Прерываем только цикл по фрагментам
                for nt in range(len(fragments)):  # Идём по фрагментам текста
                    self.sigProgress.emit(strImya, nt, len(fragments))
                    self.strLog.emit(f"Обработка {strImya}: фрагмент {nt + 1}/{len(fragments)}")
                    self.blAnalyzeActive = True
                    self.strSoderjankoe = fragments[nt]
                    result = self._fnPostavitZapyt(self.strSoderjankoe, rlTemperatura)
                    if self.blZapreshchen or result is None:
                        blPrervali = True
                        break
                    if result.startswith("ОШИБКА:"):
                        corrected.append(fragments[nt])  # Оставляем как есть
                        continue
                    corrected.append(result)
                self.blAnalyzeActive = False
                if blPrervali:
                    self.strLog.emit(f"Документ не сохранён (отмена): {strImya}")
                    break
                # Склеиваем фрагменты с устранением перекрытий
                sborka = self._fnSkleitFragmeny(fragments, corrected,
                                                ntKontekst, ntPerekritieProcent)
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
                self.strLog.emit(f"Орфография прервана пользователем ({'остановлен' if not self.model_name else 'модель'})")
            self.strLog.emit(f"Обработка завершена. Сохранено: {ntVseho}, ошибок: {ntOshibok}")
            self.sigVseGotovo.emit(ntVseho, ntOshibok)
        except Exception as e:
            self.strOshibka.emit(self.ERR_GENERIC, str(e))
            self.strLog.emit(f"КРИТИЧЕСКАЯ ошибка обработки: {str(e)}")
        finally:
            self.blIsworking = False
            self.blAnalyzeActive = False
