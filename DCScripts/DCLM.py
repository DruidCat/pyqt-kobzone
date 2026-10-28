# DCScripts/DCLM.py
import threading
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer
from DCScripts.DCLMSandbox import DCLMSandbox, SandboxNotAvailable
from DCScripts.DCLMHDD import DCLMHDD, DCPassport
from DCScripts.DCLMApp import DCLMApp
from DCScripts.DCLMAPI import DCLMAPI, ApiErrorType
from DCScripts.DCLMCLI import DCLMCLI
from DCScripts.DCLMMmproj import DCLMMmproj

class DCLM(QObject):
    """Управление LM Studio/Bionic: запуск/остановка и работа с моделями"""
    
    # ==================== КОНСТАНТЫ ====================
    # Таймауты (секунды)
    TIMEOUT_MODEL_LIST = 5
    TIMEOUT_SERVER_CHECK = 2
    TIMEOUT_SERVER_START = 10
    TIMEOUT_MODEL_LOAD = 180
    # Задержки (миллисекунды)
    DELAY_SERVER_STOP = 3000
    DELAY_SERVER_CHECK = 2000
    DELAY_GRACEFUL_SHUTDOWN = 3  # секунды для graceful shutdown
    # Проверки запуска
    MAX_STARTUP_CHECKS = 10
    STARTUP_CHECK_INTERVAL = 3000
    MAX_SERVER_CHECKS = 10
    SERVER_CHECK_INTERVAL = 2000
    # Модели
    NO_MODEL_NAME = "(отсутствует)"
    # Название приложения (дефолт на уровне класса, но реально переопределяется per-instance в __init__)
    APP_NAME = "LM Studio"
    # ==================== СИГНАЛЫ ====================
    sigLog = pyqtSignal(str)                # Лог
    sigError = pyqtSignal(int, str)         # Ошибка
    sigCLIPut = pyqtSignal(str)             # Возвращает путь к cli lms
    sigLMSPut = pyqtSignal(str)             # Возвращаем путь к Студии.
    sigStudioStarted = pyqtSignal()         # Начата проверка запуска LM Studio/Bionic
    sigStudioZapuschen = pyqtSignal()       # LM Studio/Bionic запущен
    sigStudioStoped = pyqtSignal()          # Начата проверка остановки LM Studio/Bionic
    sigStudioOstanovlen = pyqtSignal()      # LM Studio/Bionic остановлен
    sigStudioStatus = pyqtSignal(bool)      # Статус LM Studio/Bionic (True - запущен, False - остановлен)
    sigModelsLoaded = pyqtSignal(list)      # Список моделей загружен
    sigModelZagrujena = pyqtSignal(str, int)# Модель загружена (model_name, max_content)
    sigModelVigrujena = pyqtSignal(bool)    # Модель выгружена (bool)
    sigModelProgress = pyqtSignal(int)      # Процент загрузки модели (0-100)
    # Сигналы для сервера
    sigServerURLIzmenen = pyqtSignal(str)   # URL сервера изменён
    sigParametriIzmeneni = pyqtSignal(str, int)  # Сигнал (model_name, max_context)
    sigServerZapuschen = pyqtSignal()       # Сервер запущен
    sigServerOstanovlen = pyqtSignal()      # Сервер остановлен
    sigServerStatus = pyqtSignal(bool)      # Статус сервера (True - запущен, False - остановлен)
    sigServerError = pyqtSignal(str)        # Ошибка сервера
    sigAppName = pyqtSignal(str)            # Имя приложения изменилось (LM Studio/Bionic)    
    # Сигналы для mmproj (мультимодальность)
    sigMmprojStatus = pyqtSignal(bool, bool)# (is_multimodal, enabled) — статус после загрузки/проверки
    sigMmprojPereklyuchen = pyqtSignal(bool)# mmproj успешно переключён, новое состояние (enabled)

    def __init__(self):
        super().__init__()
        self._hdd = DCLMHDD(log_callback=self.sigLog.emit)
        self._app = DCLMApp(log_callback=self.sigLog.emit)
        self._api = DCLMAPI(log_callback=self.sigLog.emit)
        self._cli = DCLMCLI(log_callback=self.sigLog.emit)
        self._mmproj = DCLMMmproj(log_callback=self.sigLog.emit)
        self._passport = DCPassport()  # По умолчанию создаётся паспорт для LM Studio

        # ВАЖНО: APP_NAME теперь атрибут ЭКЗЕМПЛЯРА (а не класса), чтобы несколько
        # инстансов DCLM (если появятся) не перетирали имя друг другу.
        self.APP_NAME = type(self).APP_NAME

        # Управление моделями
        self._current_model = ""
        # Управление процессом
        self._custom_path = ""
        self._cli_path = ""
        
        self._timer = None
        self._server_timer = None
        
        self._popitki = 0
        self._max_popitok = self.MAX_STARTUP_CHECKS
        self._zapusk_v_processe = False
        self._zapusk_lock = threading.Lock()  # защищает _zapusk_v_processe от гонок между потоками
        # Состояние сервера
        self._server_zapuschen = False
        self._server_popitki = 0
        self._server_max_popitok = self.MAX_SERVER_CHECKS
        # URL сервера (можно изменить)
        self._server_url = "http://localhost:1234/v1"
        # Sandbox
        self._sandbox_name = ""          # "" = без sandbox
        self._restart_after_stop = False # если True — после остановки запускаем заново
        self.sigStudioOstanovlen.connect(self._on_studio_stopped_internal)
    
    def __del__(self):
        """Очистка ресурсов при удалении объекта"""
        try:
            if self._timer and self._timer.isActive():
                self._timer.stop()
            
            if self._server_timer and self._server_timer.isActive():
                self._server_timer.stop()
        except Exception:
            pass  # При завершении приложения Qt объекты могут быть уже удалены

    # ==================== РАБОТА С ФАЙЛАМИ ЧЕРЕЗ DCLMHDD====================
    @pyqtSlot(str, result=bool)
    def proverkaServerURL(self, server_url):
        """Проверяет корректность URL сервера LM Studio/Bionic"""
        return self._hdd.proverka_server_url(server_url)

    @pyqtSlot(str, result=bool)
    def proverkaLMSFaila(self, file_path: str) -> bool:
        """Проверяет, является ли файл корректным исполняемым файлом lms CLI"""
        return self._hdd.proverka_lms_faila(file_path, cli_name=self._passport.cli_name)

    @pyqtSlot(str, result=bool)
    def proverkaFaila(self, file_path: str) -> bool:
        """Проверяет, существует ли файл по указанному пути."""
        return self._hdd.proverka_faila(file_path)

    @pyqtSlot(str)
    def ustPutCLI(self, path):
        """Устанавливает путь к CLI lms"""
        self._cli_path = path
        print(f"✓ Путь к lms CLI: {path}")

    @pyqtSlot(str, result=str)
    def fnSpisok_Papki(self, path):
        """Возвращает JSON список содержимого папки, включая скрытые файлы и папки (для панели выбора путей)"""
        import json
        try:
            papka = Path(path) if path else Path.home()
            if not papka.is_dir():
                papka = Path.home()
            sp = []
            for element in sorted(papka.iterdir(), key=lambda e: (not e.is_dir(), str(e).lower())):
                sp.append({"name": element.name, "path": str(element), "isFolder": element.is_dir()})
            return json.dumps(sp, ensure_ascii=False)
        except Exception as e:
            print(f"\033[31m Ошибка списка папки {path}: {e}\033[0m")
            return "[]"

    @pyqtSlot(str)
    def ustPutStudio(self, path):
        """Устанавливает путь к LM Studio/Bionic и определяет тип приложения"""
        self._custom_path = path

        try:
            passport = self._detect_passport_from_path(path)
            self._apply_passport(passport)
        except Exception as e:
            self.sigLog.emit(f"⚠ Не удалось определить тип приложения: {e}")

        print(f"✓ Путь к {self.APP_NAME}: {path}")

    def _naitiLMS_CLI(self) -> str | None:
        """
        ФАСАДНЫЙ метод: DCLMHDD ищет CLI, а DCLM:
        - эмитит sigCLIPut (чтобы QML сохранил в DCSettings)
        - генерирует _emit_error(9), если не найдено
        """
        lms_cli = self._hdd.naiti_lms_cli(
            preferred_path=self._cli_path,
            cli_name=self._passport.cli_name
        )

        if not lms_cli:
            self._emit_error(9, "CLI lms не найден. Укажите путь в настройках (~/.lmstudio/bin/lms)")
            return None

        if lms_cli != self._cli_path:
            self._cli_path = lms_cli
            self.sigCLIPut.emit(lms_cli)

        return lms_cli

    def _naitiLMStudio(self) -> Path | None:
        """
        ФАСАДНЫЙ метод поиска приложения.
        Реальный поиск выполняет DCLMHDD, а фасад:
        - применяет DCPassport (обновит APP_NAME и отправит sigAppName)
        - если путь найден автопоиском ВПЕРВЫЕ (т.е. отличается от уже известного
          self._custom_path) — фиксирует его и эмитит sigLMSPut, чтобы QML сохранил
          путь в настройках (реестре). Это нужно, чтобы при повторных запусках
          zapustitStudio() автопоиск по диску больше НЕ выполнялся (актуально,
          если в системе одновременно установлены и LM Studio, и Bionic —
          иначе автопоиск мог бы в следующий раз найти другое приложение).
        """
        staryj_put = self._custom_path

        app_path = self._hdd.naiti_put_prilozhenia(custom_path=self._custom_path)
        if not app_path:
            return None

        try:
            passport = self._detect_passport_from_path(str(app_path))
            self._apply_passport(passport)
        except Exception as e:
            self.sigLog.emit(f"⚠ Не удалось определить тип приложения: {e}")

        novyj_put = str(app_path)

        # Сравниваем с уже известным путём (с учётом возможных различий
        # в написании пути — например, относительный путь vs resolve()).
        put_izmenilsya = True
        if staryj_put:
            try:
                put_izmenilsya = (
                    Path(staryj_put).expanduser().resolve() != Path(novyj_put).expanduser().resolve()
                )
            except Exception:
                put_izmenilsya = (staryj_put != novyj_put)

        if put_izmenilsya:
            self._custom_path = novyj_put
            self.sigLog.emit(f"✓ Путь к {self.APP_NAME} определён автоматически: {novyj_put}")
            self.sigLMSPut.emit(novyj_put)

        return app_path

    def _detect_passport_from_path(self, app_path: str) -> DCPassport:
        """Обёртка над DCLMHDD.opredelit_pasport_po_puti."""
        return self._hdd.opredelit_pasport_po_puti(app_path, fallback=self._passport)

    def _apply_passport(self, passport: DCPassport) -> None:
        """Применяет DCPassport и обновляет APP_NAME (атрибут экземпляра!) для логов/команд."""
        old_name = self.APP_NAME

        self._passport = passport
        self.APP_NAME = passport.display_name  # <-- ИСПРАВЛЕНО: атрибут экземпляра, не класса

        if old_name != passport.display_name:
            self.sigLog.emit(f"✓ Определено приложение: {old_name or '(неизвестно)'} → {passport.display_name}")
            self.sigAppName.emit(passport.display_name)

    # ==================== РАБОТА СО СТУДИЕЙ И SANDBOX ЧЕРЕЗ DCLMApp====================
    @pyqtSlot(str)
    def ustSandbox(self, sandbox_name: str):
        sandbox_name = DCLMSandbox.normalizovat(sandbox_name)

        if sandbox_name == self._sandbox_name:
            return

        try:
            DCLMSandbox.proverit_dostupnost(sandbox_name)
        except SandboxNotAvailable as e:
            self._emit_error(14, str(e))
            return

        self._sandbox_name = sandbox_name

        if self._sandbox_name:
            self.sigLog.emit(f"✓ Sandbox выбран: {self._sandbox_name}")
        else:
            self.sigLog.emit("✓ Sandbox выключен")

        if self._proverkaZapushen():
            mode = self._sandbox_name if self._sandbox_name else "без sandbox"
            self.sigLog.emit(f"🔄 Перезапуск {self.APP_NAME} ({mode})...")
            self._restart_after_stop = True
            self.ostanovitStudio()

    @pyqtSlot()
    def zapustitStudio(self):
        """Запускает LM Studio/Bionic"""
        with self._zapusk_lock:
            if self._zapusk_v_processe:
                print("⚠ Запуск уже выполняется")
                return
            self._zapusk_v_processe = True

        if self._proverkaZapushen():
            self.sigLog.emit(f"{self.APP_NAME} уже работает")
            self.sigStudioZapuschen.emit()
            self.proverkaServera()
            with self._zapusk_lock:
                self._zapusk_v_processe = False
            return
        
        lms_path = self._naitiLMStudio()
        
        if not lms_path:
            error_msg = f"Не удалось найти {self.APP_NAME}. Укажите путь в настройках."
            self._emit_error(3, error_msg)
            with self._zapusk_lock:
                self._zapusk_v_processe = False
            return

        try:
            DCLMSandbox.proverit_dostupnost(self._sandbox_name)
        except SandboxNotAvailable as e:
            self._emit_error(14, str(e))
            with self._zapusk_lock:
                self._zapusk_v_processe = False
            return

        try:
            self.sigLog.emit(f"Запуск {self.APP_NAME}: {lms_path.name}")
            
            thread = threading.Thread(
                target=self._zapustitVPotoke,
                args=(lms_path,),
                daemon=True
            )
            thread.start()
            
            self._initTimer()
            self._popitki = 0
            self._timer.start(self.STARTUP_CHECK_INTERVAL)
            self.sigStudioStarted.emit()
            self.sigLog.emit(f"Ожидание запуска {self.APP_NAME}...")
        
        except Exception as e:
            error_msg = f"Ошибка запуска: {str(e)}"
            self._emit_error(4, error_msg)
            with self._zapusk_lock:
                self._zapusk_v_processe = False

    @pyqtSlot()
    def ostanovitStudio(self):
        """Останавливает LM Studio/Bionic с graceful shutdown (неблокирующий)"""
        thread = threading.Thread(
            target=self._ostanovitVPotoke,
            daemon=True
        )
        thread.start()
       
        self.sigStudioStoped.emit()
        self.sigLog.emit(f"Ожидание остановки {self.APP_NAME}...")

    @pyqtSlot()
    def proverkaStudio(self):
        """Проверяет доступность LM Studio/Bionic (приложения)"""
        if self._proverkaZapushen():
            self.sigStudioStatus.emit(True)
        else:
            self.sigStudioStatus.emit(False)

    @pyqtSlot(result=str)
    def polAppName(self) -> str:
        return self.APP_NAME

    def _zapustitVPotoke(self, lms_path):
        """Запускает LM Studio/Bionic в отдельном потоке через DCLMApp (не блокирует UI)"""
        try:
            self._app.zapustit(
                app_path=lms_path,
                sandbox_name=self._sandbox_name,
                cli_path=self._cli_path,
                app_name=self.APP_NAME
            )
        except Exception as e:
            self._emit_error(7, f"Ошибка запуска: {str(e)}")
        finally:
            with self._zapusk_lock:
                self._zapusk_v_processe = False

    def _ostanovitVPotoke(self):
        """Останавливает LM Studio/Bionic в отдельном потоке через DCLMApp (не блокирует UI)"""
        try:
            self._app.ostanovit(
                passport=self._passport,
                app_name=self.APP_NAME,
                graceful_seconds=self.DELAY_GRACEFUL_SHUTDOWN
            )

            self._server_zapuschen = False

            self.sigStudioOstanovlen.emit()
            self.sigServerStatus.emit(False)

        except Exception as e:
            self._emit_error(5, f"Ошибка остановки: {str(e)}")

    def _proverkaZapushen(self) -> bool:
        """Проверяет, запущено ли приложение (LM Studio/Bionic)"""
        return self._app.proverka_zapuschen(self._passport)

    def _initTimer(self):
        if self._timer is None:
            self._timer = QTimer()
            self._timer.timeout.connect(self._proverkaDostupnosti)

    def _proverkaDostupnosti(self):
        self._popitki += 1
        
        if self._proverkaZapushen():
            if self._timer:
                self._timer.stop()
            self._popitki = 0
            with self._zapusk_lock:
                self._zapusk_v_processe = False
            self.sigLog.emit(f"✓ {self.APP_NAME} приложение запущено!")
            self.sigStudioZapuschen.emit()
            
            self.sigLog.emit("Проверка статуса сервера...")
            QTimer.singleShot(2000, self.proverkaServera)
        else:
            if self._popitki >= self._max_popitok:
                if self._timer:
                    self._timer.stop()
                self._popitki = 0
                with self._zapusk_lock:
                    self._zapusk_v_processe = False
                error_msg = f"{self.APP_NAME} не запустился. Запустите вручную или проверьте путь."
                self._emit_error(8, error_msg)
            else:
                self.sigLog.emit(f"⏳ Попытка {self._popitki}/{self._max_popitok}...")

    @pyqtSlot()
    def _on_studio_stopped_internal(self):
        if not self._restart_after_stop:
            return
        self._restart_after_stop = False
        QTimer.singleShot(300, self.zapustitStudio)

    # ==================== РАБОТА С SERVER И API AI ====================
    @pyqtSlot(str)
    def ustServerURL(self, server_url):
        server_url = self._api.normalizovat_url(server_url)
        if not server_url:
            return

        old_url = self._server_url
        self._server_url = server_url

        self.sigLog.emit(f"✓ URL сервера обновлён: {server_url}")

        if old_url != server_url:
            print(f"✓ Сервер URL изменён: {old_url} → {server_url}")
            self.sigServerURLIzmenen.emit(server_url)
            self.proverkaServera()

    @pyqtSlot(result=str)
    def polServerURL(self):
        return self._server_url

    @pyqtSlot(result=bool)
    def proverkaServera(self) -> bool:
        zapuschen = self._proverkaServeraZapuschen()
        self._server_zapuschen = zapuschen
        self.sigServerStatus.emit(zapuschen)
        return zapuschen

    @pyqtSlot()
    def zapustitServer(self):
        """Запускает сервер LM Studio/Bionic через CLI команду"""
        if self._proverkaServeraZapuschen():
            self.sigLog.emit("⚠ Сервер уже запущен")
            self.sigServerZapuschen.emit()
            self.sigServerStatus.emit(True)
            self._server_zapuschen = True
            return
        
        if not self._proverkaZapushen():
            error_msg = f"{self.APP_NAME} не запущен. Сначала запустите приложение."
            self._emit_error(6, error_msg)
            return
        
        lms_cli = self._naitiLMS_CLI()
        
        if not lms_cli:
            error_msg = "CLI lms не найден. Укажите путь в настройках (~/.lmstudio/bin/lms)"
            self._emit_error(9, error_msg)
            return
        
        try:
            self.sigLog.emit(f"🔄 Запуск сервера {self.APP_NAME}...")

            success, error_msg = self._api.zapustit_server(lms_cli, timeout=self.TIMEOUT_SERVER_START)

            if success:
                self.sigLog.emit("✓ Команда запуска выполнена")
                self._zapustitProverkuServera()
            else:
                self.sigServerError.emit(error_msg)

        except Exception as e:
            self._emit_error(11, f"Ошибка запуска сервера: {str(e)}")

    @pyqtSlot()
    def ostanovitServer(self):
        """Останавливает сервер LM Studio/Bionic через CLI команду"""
        if not self._proverkaServeraZapuschen():
            self.sigLog.emit("⚠ Сервер уже остановлен")
            self.sigServerOstanovlen.emit()
            self.sigServerStatus.emit(False)
            self._server_zapuschen = False
            return
        
        lms_cli = self._naitiLMS_CLI()
        
        if not lms_cli:
            error_msg = "CLI lms не найден. Укажите путь в настройках"
            self.sigServerError.emit(error_msg)
            return
        
        try:
            self.sigLog.emit(f"🔄 Остановка сервера {self.APP_NAME}...")

            success, error_msg = self._api.ostanovit_server(lms_cli, timeout=self.TIMEOUT_SERVER_START)

            if success:
                self._server_zapuschen = False
                self.sigLog.emit("✓ Сервер остановлен")
                self.sigServerOstanovlen.emit()
                self.sigServerStatus.emit(False)
            else:
                self.sigServerError.emit(error_msg)

        except Exception as e:
            self._emit_error(12, f"Ошибка остановки сервера: {str(e)}")

    @pyqtSlot()
    def zagruzitModeli(self):
        """Загружает список доступных моделей из LM Studio/Bionic (через DCLMAPI)"""
        success, models, error_msg, error_type = self._api.poluchit_modeli(
            self._server_url,
            timeout=self.TIMEOUT_MODEL_LIST
        )

        if not success:
            # Точная классификация по явному типу ошибки (а не по тексту)
            if error_type == ApiErrorType.CONNECTION:
                self._emit_error(1, error_msg)
            elif error_type == ApiErrorType.TIMEOUT:
                self._emit_error(1, error_msg)
            elif error_type == ApiErrorType.HTTP:
                self._emit_error(0, error_msg)
            else:
                self._emit_error(2, error_msg)

            self.sigModelsLoaded.emit([self.NO_MODEL_NAME])
            return

        full_list = [self.NO_MODEL_NAME] + models
        self.sigModelsLoaded.emit(full_list)
        print(f"✓ Загружено моделей: {len(models)}")

    @pyqtSlot()
    def zapustitProverkuServera(self):
        self._zapustitProverkuServera()

    def _proverkaServeraZapuschen(self) -> bool:
        return self._api.proverka_servera_zapuschen(self._server_url, timeout=self.TIMEOUT_SERVER_CHECK)

    def _zapustitProverkuServera(self):
        self.sigLog.emit("⏳ Ожидание запуска сервера...")
        
        self._server_popitki = 0
        
        if self._server_timer is None:
            self._server_timer = QTimer()
            self._server_timer.timeout.connect(self._proverkaServeraAvto)
        
        self._server_timer.start(self.SERVER_CHECK_INTERVAL)

    def _proverkaServeraAvto(self):
        self._server_popitki += 1
        
        if self._proverkaServeraZapuschen():
            if self._server_timer:
                self._server_timer.stop()
            
            self._server_popitki = 0
            self._server_zapuschen = True
            self.sigLog.emit("✓ Сервер запущен и готов к работе!")
            self.sigServerZapuschen.emit()
            self.sigServerStatus.emit(True)
        else:
            if self._server_popitki >= self._server_max_popitok:
                if self._server_timer:
                    self._server_timer.stop()
                
                self._server_popitki = 0
                error_msg = "Сервер не запустился за отведённое время"
                self.sigServerError.emit(error_msg)
            else:
                self.sigLog.emit(f"⏳ Проверка сервера... ({self._server_popitki}/{self._server_max_popitok})")
    
    # ------------------ РАБОТА С КОМАНДНОЙ СТРОКОЙ CLI ЧЕРЕЗ DCLMCLI ---------------------
    @pyqtSlot(result=str)
    def polModelNoName(self) -> str:
        return self.NO_MODEL_NAME

    @pyqtSlot(result=str)
    def polModel(self) -> str:
        return self._current_model 

    @pyqtSlot(result=bool)
    def vigruzitModel(self) -> bool:
        """Выгружаем модель из LM Studio/Bionic"""
        if self._cli_path == "":
            return False
        return self._vigruzitModel(self._cli_path)

    @pyqtSlot(str, int, int, result=bool)
    def ustParametri(self, model_name, max_context, gpu_offload) -> bool:
        if not model_name or model_name == self.NO_MODEL_NAME:
            self.vigruzitModel()
            self._current_model = ""
            error_msg = "Модель не выбрана. Выберите модель из списка."
            self._emit_error(13, error_msg)
            return False

        if not self._proverkaZapushen():
            error_msg = f"{self.APP_NAME} не запущен. Сначала запустите приложение."
            self._emit_error(6, error_msg)
            return False
        
        success = self._ustParametri(model_name, max_context, gpu_offload)

        if success:
            self._current_model = model_name
            self.sigParametriIzmeneni.emit(self._current_model, max_context)
        else:
            self._emit_error(10, f"Не удалось начать загрузку модели {model_name}")
        
        return success 

    @pyqtSlot(str, int)
    def zagruzitCherezConfig(self, model_name, max_content):
        self._zagruzitCherezConfig(model_name, max_content)

    def _ustParametri(self, model_name, max_context, gpu_offload):
        lms_cli = self._naitiLMS_CLI()
        
        if not lms_cli:
            self.sigLog.emit("⚠ CLI lms не найден...")
            return self._zagruzitCherezConfig(model_name, max_context)
        
        thread = threading.Thread(
            target=self._zagruzitModelVPotoke,
            args=(lms_cli, model_name, max_context, gpu_offload),
            daemon=True
        )
        thread.start()
        
        return True

    def _zagruzitModelVPotoke(self, lms_cli, model_name, max_content, gpu_offload):
        """Загружает модель в отдельном потоке (не блокирует UI) через DCLMCLI"""
        try:
            res = self._cli.zagruzit_model(
                lms_cli=lms_cli,
                model_name=model_name,
                max_context=max_content,
                gpu_offload=gpu_offload,
                timeout=self.TIMEOUT_MODEL_LOAD,
                progress_cb=self.sigModelProgress.emit
            )

            if res.success:
                self.sigModelProgress.emit(100)

                self.sigLog.emit(f"✓ Модель загружена: {model_name}")
                self.sigLog.emit(f"✓ Контекст: {max_content}")
                if res.used_gpu_desc:
                    self.sigLog.emit(f"✓ GPU: {res.used_gpu_desc}")

                self._cli_path = lms_cli
                self._current_model = model_name

                self.sigModelZagrujena.emit(model_name, max_content)
                self._proverkaMmprojVPotoke(model_name) # авто-проверка мультимодальности сразу после загрузки
                return

            self.sigModelProgress.emit(0)
            self._current_model = ""

            for line in (res.hints or []):
                self.sigLog.emit(line)

            self.sigLog.emit("✗ Ошибка загрузки модели:")
            if res.error:
                self.sigLog.emit(f"   {res.error[:300]}")

            if res.timeout:
                self._emit_error(10, f"Таймаут: {model_name}")
            else:
                msg = res.error[:300] if res.error else "Неизвестная ошибка"
                self._emit_error(10, f"Ошибка загрузки модели {model_name}: {msg}")

            self._fallback_to_config(model_name, max_content)

        except Exception as e:
            self.sigModelProgress.emit(0)
            self._current_model = ""
            self._emit_error(10, f"{model_name}: {str(e)}")
            self._fallback_to_config(model_name, max_content)

    def _vigruzitModel(self, lms_cli):
        ok = self._cli.vigruzit_model(lms_cli)
        self._current_model = ""
        self.sigModelVigrujena.emit(bool(ok))
        self.sigMmprojStatus.emit(False, False) #сброс индикатора mmproj в UI при выгрузке
        return bool(ok)

    def _fallback_to_config(self, model_name, max_content):
        from PyQt6.QtCore import QMetaObject, Qt, Q_ARG
        QMetaObject.invokeMethod(
            self,
            "zagruzitCherezConfig",
            Qt.ConnectionType.QueuedConnection,
            Q_ARG(str, model_name),
            Q_ARG(int, max_content)
        )

    def _zagruzitCherezConfig(self, model_name, max_content):
        try:
            self.sigLog.emit(f"🔄 Настройка через конфигурацию...")
            
            config_updated = self._ustServerConfig(max_content)
            
            if not config_updated:
                self._emit_error(10, f"Не удалось обновить конфигурацию для модели {model_name}")
                return False
            
            server_running = self._proverkaServeraZapuschen()
            
            if server_running:
                self.sigLog.emit("⚠ Для применения изменений перезапускаем сервер")
                self.sigLog.emit("🔄 Остановка сервера...")
                
                self.ostanovitServer()
                
                self.sigLog.emit("⏳ Ожидание остановки сервера...")
                QTimer.singleShot(self.DELAY_SERVER_STOP, lambda: self._zapustitServerPosledujushii())
                
                self.sigLog.emit(f"✓ Конфигурация обновлена: контекст {max_content}")
                return True
            else:
                self.sigLog.emit(f"✓ Конфигурация обновлена: контекст {max_content}")
                self.sigLog.emit("⚠ Запустите сервер для применения изменений")
                return True
        
        except Exception as e:
            self._emit_error(10, f"Ошибка настройки конфигурации для модели {model_name}: {str(e)}")
            return False

    def _ustServerConfig(self, max_context):
        return self._cli.obnovit_konfig_servera(max_context)

    def _zapustitServerPosledujushii(self):
        self.sigLog.emit("🔄 Запуск сервера с новыми параметрами...")
        self.zapustitServer()

    # ==================== РАБОТА С MMPROJ (мультимодальность) ====================
    @pyqtSlot(str)
    def proverkaMmproj(self, model_name: str) -> None:
        """
        Публичный слот: проверяет mmproj-статус указанной модели и эмитит sigMmprojStatus.
        Можно вызывать для ЛЮБОЙ модели из списка (не обязательно загруженной),
        например чтобы показать иконку "мультимодальная" в выпадающем списке.
        """
        threading.Thread(
            target=self._proverkaMmprojVPotoke, args=(model_name,), daemon=True
        ).start()

    def _proverkaMmprojVPotoke(self, model_name: str) -> None:
        lms_cli = self._naitiLMS_CLI()
        if not lms_cli:
            return  # ошибка 9 уже отправлена внутри _naitiLMS_CLI
        status = self._mmproj.proverit_status(model_name, lms_cli_put=Path(lms_cli))
        self.sigMmprojStatus.emit(status.is_multimodal, status.enabled)

    @pyqtSlot(str, bool)
    def pereklyuchitMmproj(self, model_name: str, vkliuchit: bool) -> None:
        """
        Включает/выключает mmproj для указанной модели.
        Если эта модель сейчас загружена в LM Studio/Bionic — сначала выгружает её
        (чтобы не менять файлы "на лету" под уже запущенным сервером).
        После переключения self._current_model сбрасывается (если это была
        текущая модель) — пользователю нужно будет заново выбрать/загрузить модель.
        """
        threading.Thread(
            target=self._pereklyuchitMmprojVPotoke,
            args=(model_name, vkliuchit),
            daemon=True,
        ).start()

    def _pereklyuchitMmprojVPotoke(self, model_name: str, vkliuchit: bool) -> None:
        lms_cli = self._naitiLMS_CLI()
        if not lms_cli:
            return

        if self._current_model == model_name:
            ok = self._vigruzitModel(lms_cli)
            if not ok:
                self._emit_error( 15,
                    f"Не удалось выгрузить модель {model_name} перед переключением mmproj"
                )
                return

        cli_put = Path(lms_cli)
        if vkliuchit:
            result = self._mmproj.vklyuchit(model_name, lms_cli_put=cli_put)
        else:
            result = self._mmproj.vyklyuchit(model_name, lms_cli_put=cli_put)

        if result.success:
            self.sigMmprojPereklyuchen.emit(result.status.enabled)
            self.sigMmprojStatus.emit(result.status.is_multimodal, result.status.enabled)
        else:
            self._emit_error(15, result.error)

    # ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================
    def _emit_error(self, code, message):
        self.sigLog.emit(f"✗ Ошибка {code}: {message}")
        self.sigError.emit(code, message)
