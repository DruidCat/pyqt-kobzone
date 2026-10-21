import threading
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer
from DCScripts.DCLMSandbox import DCLMSandbox, SandboxNotAvailable
from DCScripts.DCLMHDD import DCLMHDD, DCPassport
from DCScripts.DCLMApp import DCLMApp
from DCScripts.DCLMAPI import DCLMAPI
from DCScripts.DCLMCLI import DCLMCLI

class DCLMStudio(QObject):
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
    # Название приложения
    APP_NAME = "LM Studio" #по умолчанию
    # ==================== СИГНАЛЫ ====================
    # Сигналы для LM Studio/Bionic
    sigLog = pyqtSignal(str)                # Лог
    sigError = pyqtSignal(int, str)         # Ошибка
    sigCLIPut = pyqtSignal(str)             # Возвращает путь к cli lms
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

    def __init__(self):
        super().__init__()
        self._hdd = DCLMHDD(log_callback=self.sigLog.emit)
        self._passport = DCPassport()# По умолчанию создаётся паспорт для LM Studio
        self._app = DCLMApp(log_callback=self.sigLog.emit)
        self._api = DCLMAPI(log_callback=self.sigLog.emit)
        self._cli = DCLMCLI(log_callback=self.sigLog.emit)
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
        # Состояние сервера
        self._server_zapuschen = False
        self._server_popitki = 0
        self._server_max_popitok = self.MAX_SERVER_CHECKS
        # URL сервера (можно изменить)
        self._server_url = "http://localhost:1234/v1"
        # Sandbox
        self._sandbox_name = ""          # "" = без sandbox
        self._restart_after_stop = False # если True — после остановки запускаем заново
        self.sigStudioOstanovlen.connect(self._on_studio_stopped_internal)#перезапускать после полной остановк 
    
    def __del__(self):
        """Очистка ресурсов при удалении объекта"""
        try:
            if self._timer and self._timer.isActive():
                self._timer.stop()
            
            if self._server_timer and self._server_timer.isActive():
                self._server_timer.stop()
        except:
            pass  # При завершении приложения Qt объекты могут быть уже удалены

    # ==================== РАБОТА С ФАЙЛАМИ ЧЕРЕЗ DCLMHDD====================
    @pyqtSlot(str, result=bool)
    def proverkaServerURL(self, server_url):
        """
        Проверяет корректность URL сервера LM Studio/Bionic
        
        Args:
            server_url: Адрес сервера (например: http://localhost:1234)
        
        Return:
            True - если URL корректен
            False - если URL некорректен
        """
        return self._hdd.proverka_server_url(server_url)

    @pyqtSlot(str, result=bool)
    def proverkaLMSFaila(self, file_path: str) -> bool:
        """
        Проверяет, является ли файл корректным исполняемым файлом lms CLI
        """
        return self._hdd.proverka_lms_faila(file_path)

    @pyqtSlot(str, result=bool)
    def proverkaFaila(self, file_path: str) -> bool:
        """
        Проверяет, существует ли файл по указанному пути.
        Работает со скрытыми файлами (.file) и путями с ~ (домашняя директория).
        """
        return self._hdd.proverka_faila(file_path)

    @pyqtSlot(str)
    def ustPutCLI(self, path):
        """Устанавливает путь к CLI lms"""
        self._cli_path = path
        print(f"✓ Путь к lms CLI: {path}")

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
        ФАСАДНЫЙ метод: DCLMHDD ищет CLI, а DCLMStudio:
        - эмитит sigCLIPut (чтобы QML сохранил в DCSettings)
        - генерирует _emit_error(9), если не найдено
        """
        lms_cli = self._hdd.find_lms_cli(preferred_path=self._cli_path)

        if not lms_cli:
            self._emit_error(9, "CLI lms не найден. Укажите путь в настройках (~/.lmstudio/bin/lms)")
            return None

        # если нашли новый путь — сохраняем и уведомляем QML
        if lms_cli != self._cli_path:
            self._cli_path = lms_cli
            self.sigCLIPut.emit(lms_cli)

        return lms_cli

    def _naitiLMStudio(self) -> Path | None:
        """
        ФАСАДНЫЙ метод поиска приложения.
        Реальный поиск выполняет DCLMHDD, а фасад:
        - применяет DCPassport (обновит APP_NAME и отправит sigAppName)
        """
        app_path = self._hdd.find_app_path(custom_path=self._custom_path)
        if not app_path:
            return None

        # Применяем DCPassport (LM Studio/Bionic) по имени файла
        try:
            passport = self._detect_passport_from_path(str(app_path))
            self._apply_passport(passport)
        except Exception as e:
            self.sigLog.emit(f"⚠ Не удалось определить тип приложения: {e}")

        return app_path

    def _detect_passport_from_path(self, app_path: str) -> DCPassport:
        """
        Обёртка над DCLMHDD.detect_passport_from_path.
        Оставляем это имя, чтобы не менять остальной код.
        """
        return self._hdd.detect_passport_from_path(app_path, fallback=self._passport)

    def _apply_passport(self, passport: DCPassport) -> None:
        """Применяет DCPassport и обновляет APP_NAME для логов/команд."""
        old_name = getattr(self, "_passport", None).display_name if getattr(self, "_passport", None) else ""

        self._passport = passport
        type(self).APP_NAME = passport.display_name# ВАЖНО: обновляем именно классовую переменную (глобальную для класса)

        if old_name != passport.display_name:# Эмитим только если реально поменялось
            self.sigLog.emit(f"✓ Определено приложение: {old_name or '(неизвестно)'} → {passport.display_name}")
            self.sigAppName.emit(passport.display_name)

    # ==================== РАБОТА СО СТУДИЕЙ И SANDBOX ЧЕРЕЗ DCLMApp====================
    @pyqtSlot(str)
    def ustSandbox(self, sandbox_name: str):
        """
        sandbox_name:
          ""          -> обычный запуск (как сейчас, с --no-sandbox на Linux)
          "firejail"  -> запуск через firejail
          "sandboxie sandboxie Plus -> Windows"
        """
        sandbox_name = DCLMSandbox.normalize(sandbox_name)

        # ничего не делаем, если не менялось
        if sandbox_name == self._sandbox_name:
            return

        # проверяем доступность (установлен ли firejail и т.п.)
        try:
            DCLMSandbox.check_available(sandbox_name)
        except SandboxNotAvailable as e:
            # новый код ошибки (добавь в QML обработку)
            self._emit_error(14, str(e))
            return

        self._sandbox_name = sandbox_name

        if self._sandbox_name:
            self.sigLog.emit(f"✓ Sandbox выбран: {self._sandbox_name}")
        else:
            self.sigLog.emit("✓ Sandbox выключен")

        # Если LM Studio/Bionic уже запущен — перезапускаем с новыми параметрами
        if self._proverkaZapushen():
            mode = self._sandbox_name if self._sandbox_name else "без sandbox"
            self.sigLog.emit(f"🔄 Перезапуск {self.APP_NAME} ({mode})...")
            self._restart_after_stop = True
            self.ostanovitStudio()

    @pyqtSlot()
    def zapustitStudio(self):
        """Запускает LM Studio/Bionic"""
        if self._zapusk_v_processe:
            print("⚠ Запуск уже выполняется")
            return
        
        if self._proverkaZapushen():
            self.sigLog.emit(f"{self.APP_NAME} уже работает")
            self.sigStudioZapuschen.emit()
            # Проверяем статус сервера
            self.proverkaServera()
            return
        
        lms_path = self._naitiLMStudio()
        
        if not lms_path:
            error_msg = f"Не удалось найти {self.APP_NAME}. Укажите путь в настройках."
            self._emit_error(3, error_msg)
            return
        
        try:
            DCLMSandbox.check_available(self._sandbox_name)
        except SandboxNotAvailable as e:
            self._emit_error(14, str(e))
            return

        try:
            self.sigLog.emit(f"Запуск {self.APP_NAME}: {lms_path.name}")
            
            self._zapusk_v_processe = True
            
            # Запускаем в отдельном потоке
            thread = threading.Thread(
                target=self._zapustitVPotoke,
                args=(lms_path,),
                daemon=True
            )
            thread.start()
            
            # Начинаем проверку доступности
            self._initTimer()
            self._popitki = 0
            self._timer.start(self.STARTUP_CHECK_INTERVAL)
            self.sigStudioStarted.emit()
            self.sigLog.emit(f"Ожидание запуска {self.APP_NAME}...")
        
        except Exception as e:
            error_msg = f"Ошибка запуска: {str(e)}"
            self._emit_error(4, error_msg)
            self._zapusk_v_processe = False

    @pyqtSlot()
    def ostanovitStudio(self):
        """Останавливает LM Studio/Bionic с graceful shutdown (неблокирующий)"""
        # Запускаем остановку в отдельном потоке
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
            self._app.start(
                app_path=lms_path,
                sandbox_name=self._sandbox_name,
                cli_path=self._cli_path,
                app_name=self.APP_NAME
            )

            self._zapusk_v_processe = False

        except Exception as e:
            self._emit_error(7, f"Ошибка запуска: {str(e)}")
            self._zapusk_v_processe = False

    def _ostanovitVPotoke(self):
        """Останавливает LM Studio/Bionic в отдельном потоке через DCLMApp (не блокирует UI)"""
        try:
            self._app.stop(
                passport=self._passport,
                app_name=self.APP_NAME,
                graceful_seconds=self.DELAY_GRACEFUL_SHUTDOWN
            )

            # синхронизируем совместимость со старым полем
            self._server_zapuschen = False

            # Qt-сигналы (важно оставить в фасаде)
            self.sigStudioOstanovlen.emit()
            self.sigServerStatus.emit(False)

        except Exception as e:
            self._emit_error(5, f"Ошибка остановки: {str(e)}")

    def _proverkaZapushen(self) -> bool:
        """Проверяет, запущено ли приложение (LM Studio/Bionic)"""
        return self._app.is_running(self._passport) 

    def _initTimer(self):
        """Ленивая инициализация таймера"""
        if self._timer is None:
            self._timer = QTimer()
            self._timer.timeout.connect(self._proverkaDostupnosti)

    def _proverkaDostupnosti(self):
        """Периодическая проверка доступности приложения"""
        self._popitki += 1
        
        # Проверяем ПРОЦЕСС, а не сервер
        if self._proverkaZapushen():
            if self._timer:
                self._timer.stop()
            self._popitki = 0
            self._zapusk_v_processe = False
            self.sigLog.emit(f"✓ {self.APP_NAME} приложение запущено!")
            self.sigStudioZapuschen.emit()
            
            # Теперь проверяем сервер отдельно
            self.sigLog.emit("Проверка статуса сервера...")
            # Даём время на запуск UI
            QTimer.singleShot(2000, self.proverkaServera)
        else:
            if self._popitki >= self._max_popitok:
                if self._timer:
                    self._timer.stop()
                self._popitki = 0
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
        # небольшой зазор, чтобы ОС успела подчистить процессы/порты
        QTimer.singleShot(300, self.zapustitStudio)

    # ==================== РАБОТА С SERVER И API AI ====================
    @pyqtSlot(str)
    def ustServerURL(self, server_url):
        """Устанавливает URL сервера LM Studio/Bionic"""
        server_url = self._api.normalize_url(server_url)
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
        """Возвращает текущий URL сервера"""
        return self._server_url

    @pyqtSlot(result=bool)
    def proverkaServera(self) -> bool:
        """Проверяет, запущен ли сервер LM Studio/Bionic"""
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
        
        # Находим lms CLI
        lms_cli = self._naitiLMS_CLI()
        
        if not lms_cli:
            error_msg = "CLI lms не найден. Укажите путь в настройках (~/.lmstudio/bin/lms)"
            self._emit_error(9, error_msg)
            return
        
        try:
            self.sigLog.emit(f"🔄 Запуск сервера {self.APP_NAME}...")

            success, error_msg = self._api.start_server(lms_cli, timeout=self.TIMEOUT_SERVER_START)

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

            success, error_msg = self._api.stop_server(lms_cli, timeout=self.TIMEOUT_SERVER_START)

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
        success, models, error_msg = self._api.fetch_models(
            self._server_url,
            timeout=self.TIMEOUT_MODEL_LIST
        )

        if not success:
            # Определяем код ошибки по типу (упрощенно)
            if "подключиться" in error_msg.lower():
                self._emit_error(1, error_msg)
            elif "HTTP" in error_msg:
                self._emit_error(0, error_msg)
            else:
                self._emit_error(2, error_msg)

            # Возвращаем только "(отсутствует)"
            self.sigModelsLoaded.emit([self.NO_MODEL_NAME])
            return

        # Успех: добавляем "(отсутствует)" первым (UI-логика)
        full_list = [self.NO_MODEL_NAME] + models
        self.sigModelsLoaded.emit(full_list)
        print(f"✓ Загружено моделей: {len(models)}")

    @pyqtSlot()
    def zapustitProverkuServera(self):
        """Публичный слот для запуска проверки сервера (вызывается из потока)"""
        self._zapustitProverkuServera()

    def _proverkaServeraZapuschen(self) -> bool:
        """Внутренняя проверка статуса сервера (через DCLMAPI)"""
        return self._api.is_server_running(self._server_url, timeout=self.TIMEOUT_SERVER_CHECK)

    def _zapustitProverkuServera(self):
        """Запускает автоматическую проверку запуска сервера"""
        self.sigLog.emit("⏳ Ожидание запуска сервера...")
        
        self._server_popitki = 0
        
        if self._server_timer is None:
            self._server_timer = QTimer()
            self._server_timer.timeout.connect(self._proverkaServeraAvto)
        
        self._server_timer.start(self.SERVER_CHECK_INTERVAL)

    def _proverkaServeraAvto(self):
        """Автоматическая проверка запуска сервера"""
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
        """Возвращаем имя модели NO_MODEL_NAME"""
        return self.NO_MODEL_NAME

    @pyqtSlot(result=str)
    def polModel(self) -> str:
        """Возвращает текущую модель"""
        return self._current_model 

    @pyqtSlot(result=bool)
    def vigruzitModel(self) -> bool:
        """Выгружаем модель из LM Studio/Bionic"""
        if self._cli_path == "": #Если пустой путь, то...
            return False #возвращаем ошибку
        else:
            flag_vigruzki = self._vigruzitModel(self._cli_path)
            return flag_vigruzki#Возвращаем результат выгрузки модели.

    @pyqtSlot(str, int, int, result=bool)
    def ustParametri(self, model_name, max_context, gpu_offload) -> bool:
        """Публичный слот для загрузки модели с параметрами"""
        if not model_name or model_name == self.NO_MODEL_NAME:# если модель "(отсутствует)" или пустая
            self.vigruzitModel()#Выгружаем модель.
            self._current_model = ""#чтоб я мог понять по polModel что модель не задана.
            error_msg = "Модель не выбрана. Выберите модель из списка."
            self._emit_error(13, error_msg)  # КОД ОШИБКИ 13
            return False

        if not self._proverkaZapushen():  # Проверка запуска LM Studio/Bionic
            error_msg = f"{self.APP_NAME} не запущен. Сначала запустите приложение."
            self._emit_error(6, error_msg)
            return False
        
        # LM Studio/Bionic запущен, продолжаем загрузку
        success = self._ustParametri(model_name, max_context, gpu_offload)

        if success:
            self._current_model = model_name #присваеваем имя модели, когда она загрузилась.
            self.sigParametriIzmeneni.emit(self._current_model, max_context)
        else:
            # Ошибка при начале загрузки
            self._emit_error(10, f"Не удалось начать загрузку модели {model_name}")
        
        return success 

    @pyqtSlot(str, int)
    def zagruzitCherezConfig(self, model_name, max_content):
        """Публичный слот для загрузки через конфиг (вызывается из потока)"""
        self._zagruzitCherezConfig(model_name, max_content)

    def _ustParametri(self, model_name, max_context, gpu_offload):
        """Внутренний метод загрузки модели"""
        lms_cli = self._naitiLMS_CLI()
        
        if not lms_cli:
            self.sigLog.emit("⚠ CLI lms не найден...")
            return self._zagruzitCherezConfig(model_name, max_context)
        
        # Запускаем в потоке
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
            res = self._cli.load_model(
                lms_cli=lms_cli,
                model_name=model_name,
                max_context=max_content,
                gpu_offload=gpu_offload,
                timeout=self.TIMEOUT_MODEL_LOAD,
                progress_cb=self.sigModelProgress.emit
            )

            if res.success:
                # На всякий случай дожимаем 100 (обычно DCLMCLI уже эмитит 100)
                self.sigModelProgress.emit(100)

                self.sigLog.emit(f"✓ Модель загружена: {model_name}")
                self.sigLog.emit(f"✓ Контекст: {max_content}")
                if res.used_gpu_desc:
                    self.sigLog.emit(f"✓ GPU: {res.used_gpu_desc}")

                # фиксируем состояние
                self._cli_path = lms_cli
                self._current_model = model_name

                # уведомляем UI
                self.sigModelZagrujena.emit(model_name, max_content)
                return

            # Ошибка загрузки
            self.sigModelProgress.emit(0)
            self._current_model = ""

            # Подсказки (полностью сформированы внутри DCLMCLI)
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

            # fallback на конфиг (как и раньше)
            self._fallback_to_config(model_name, max_content)

        except Exception as e:
            self.sigModelProgress.emit(0)
            self._current_model = ""
            self._emit_error(10, f"{model_name}: {str(e)}")
            self._fallback_to_config(model_name, max_content)

    def _vigruzitModel(self, lms_cli):
        """Выгружает текущую загруженную модель"""
        ok = self._cli.unload_model(lms_cli)
        self._current_model = ""
        self.sigModelVigrujena.emit(bool(ok))
        return bool(ok)

    def _fallback_to_config(self, model_name, max_content):
        """Откатывается на загрузку через конфиг"""
        from PyQt6.QtCore import QMetaObject, Qt, Q_ARG
        QMetaObject.invokeMethod(
            self,
            "zagruzitCherezConfig",
            Qt.ConnectionType.QueuedConnection,
            Q_ARG(str, model_name),
            Q_ARG(int, max_content)
        )

    def _zagruzitCherezConfig(self, model_name, max_content):
        """Загрузка модели через обновление конфига + перезапуск сервера"""
        try:
            self.sigLog.emit(f"🔄 Настройка через конфигурацию...")
            
            # Обновляем конфиг
            config_updated = self._ustServerConfig(max_content)
            
            if not config_updated:
                self._emit_error(10, f"Не удалось обновить конфигурацию для модели {model_name}")
                return False
            
            # Проверяем, запущен ли сервер
            server_running = self._proverkaServeraZapuschen()
            
            if server_running:
                self.sigLog.emit("⚠ Для применения изменений перезапускаем сервер")
                self.sigLog.emit("🔄 Остановка сервера...")
                
                # Останавливаем сервер
                self.ostanovitServer()
                
                # Ждём остановки и запускаем снова (с задержкой 3 секунды)
                self.sigLog.emit("⏳ Ожидание остановки сервера...")
                QTimer.singleShot(self.DELAY_SERVER_STOP, lambda: self._zapustitServerPosledujushii())
                
                self.sigLog.emit(f"✓ Конфигурация обновлена: контекст {max_content}")
                return True
            else:
                self.sigLog.emit(f"✓ Конфигурация обновлена: контекст {max_content}")
                self.sigLog.emit("⚠ Запустите сервер для применения изменений")
                return True
        
        except Exception as e:
            error_msg = f"Ошибка настройки через конфиг: {str(e)}"
            self._emit_error(10, f"Ошибка настройки конфигурации для модели {model_name}: {str(e)}")
            return False

    def _ustServerConfig(self, max_context):
        """Обновляет server-config.json в ~/.lmstudio/"""
        return self._cli.update_server_config(max_context)


    def _zapustitServerPosledujushii(self):
        """Вспомогательный метод для отложенного запуска сервера"""
        self.sigLog.emit("🔄 Запуск сервера с новыми параметрами...")
        self.zapustitServer()

    # ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================
    def _emit_error(self, code, message):
        """Централизованная обработка ошибок"""
        self.sigLog.emit(f"✗ Ошибка {code}: {message}")
        self.sigError.emit(code, message)
