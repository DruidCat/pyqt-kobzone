import os
import subprocess
import signal
import platform
import requests
import threading
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer
from DCScripts.DCLMSandbox import DCLMSandbox, SandboxNotAvailable
from DCScripts.DCLMHDD import DCLMHDD, AppSpec
from DCScripts.DCLMApp import DCLMApp
from DCScripts.DCLMAPI import DCLMAPI
from dataclasses import dataclass

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
        self._app = DCLMApp(log_callback=self.sigLog.emit)
        self._api = DCLMAPI(log_callback=self.sigLog.emit)
        # Управление моделями
        self._current_model = ""
        self._models_list = []
        # Управление процессом
        self._process = None
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
        # Название приложения
        self._app_spec = AppSpec(
            display_name="LM Studio",
            linux_pgrep_pattern=r"(lm[- ]?studio|lmstudio|lm-studio)",
            mac_pgrep_pattern=r"(LM Studio|lmstudio|lm-studio)",
            windows_image_name="LM Studio.exe",
        )
    
    def __del__(self):
        """Очистка ресурсов при удалении объекта"""
        try:
            if self._timer and self._timer.isActive():
                self._timer.stop()
            
            if self._server_timer and self._server_timer.isActive():
                self._server_timer.stop()
        except:
            pass  # При завершении приложения Qt объекты могут быть уже удалены

    # ==================== РАБОТА С ФАЙЛАМИ ====================
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

    # ==================== РАБОТА С SANDBOX ====================
    @pyqtSlot(str)
    def ustSandbox(self, sandbox_name: str):
        """
        sandbox_name:
          ""          -> обычный запуск (как сейчас, с --no-sandbox на Linux)
          "firejail"  -> запуск через firejail
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
    def _on_studio_stopped_internal(self):
        if not self._restart_after_stop:
            return
        self._restart_after_stop = False
        # небольшой зазор, чтобы ОС успела подчистить процессы/порты
        QTimer.singleShot(300, self.zapustitStudio)

    # ==================== РАБОТА С МОДЕЛЯМИ ====================
    @pyqtSlot()
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
        self._models_list = full_list
        self.sigModelsLoaded.emit(full_list)
        print(f"✓ Загружено моделей: {len(models)}")
    
    @pyqtSlot(result=bool)
    def vigruzitModel(self) -> bool:
        """Выгружаем модель из LM Studio/Bionic"""
        if self._cli_path == "": #Если пустой путь, то...
            return False #возвращаем ошибку
        else:
            flag_vigruzki = self._vigruzitModel(self._cli_path)
            return flag_vigruzki#Возвращаем результат выгрузки модели.

    @pyqtSlot(result=str)
    def polModelNoName(self) -> str:
        """Возвращаем имя модели NO_MODEL_NAME"""
        return self.NO_MODEL_NAME

    @pyqtSlot(result=str)
    def polModel(self) -> str:
        """Возвращает текущую модель"""
        return self._current_model 
   
    @pyqtSlot(result=str)
    def polAppName(self) -> str:
        return self.APP_NAME

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

    # ==================== УПРАВЛЕНИЕ СЕРВЕРОМ ====================
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

    @pyqtSlot(str)
    def ustPutCLI(self, path):
        """Устанавливает путь к CLI lms"""
        self._cli_path = path
        print(f"✓ Путь к lms CLI: {path}")

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

    @pyqtSlot(result=bool)
    def proverkaServera(self) -> bool:
        """Проверяет, запущен ли сервер LM Studio/Bionic"""
        zapuschen = self._proverkaServeraZapuschen()
        self._server_zapuschen = zapuschen
        self.sigServerStatus.emit(zapuschen)
        self.sigLog.emit(f"Сервер {self.APP_NAME}: {'запущен' if zapuschen else 'остановлен'}")
        return zapuschen

    @pyqtSlot()
    def zapustitProverkuServera(self):
        """Публичный слот для запуска проверки сервера (вызывается из потока)"""
        self._zapustitProverkuServera()

    @pyqtSlot(str, int)
    def zagruzitCherezConfig(self, model_name, max_content):
        """Публичный слот для загрузки через конфиг (вызывается из потока)"""
        self._zagruzitCherezConfig(model_name, max_content)

    # ==================== ЗАПУСК/ОСТАНОВКА ПРИЛОЖЕНИЯ ====================
    @pyqtSlot(str)
    def ustPutStudio(self, path):
        """Устанавливает путь к LM Studio/Bionic и определяет тип приложения"""
        self._custom_path = path

        try:
            spec = self._detect_app_spec_from_path(path)
            self._apply_app_spec(spec)
        except Exception as e:
            self.sigLog.emit(f"⚠ Не удалось определить тип приложения: {e}")

        print(f"✓ Путь к {self.APP_NAME}: {path}")
    
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
    
    # ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================
    def _emit_error(self, code, message):
        """Централизованная обработка ошибок"""
        self.sigLog.emit(f"✗ Ошибка {code}: {message}")
        self.sigError.emit(code, message)
    
    def _initTimer(self):
        """Ленивая инициализация таймера"""
        if self._timer is None:
            self._timer = QTimer()
            self._timer.timeout.connect(self._proverkaDostupnosti)
    
    def _zapustitVPotoke(self, lms_path):
        """Запускает LM Studio/Bionic в отдельном потоке через DCLMApp (не блокирует UI)"""
        try:
            self._app.start(
                app_path=lms_path,
                sandbox_name=self._sandbox_name,
                cli_path=self._cli_path,
                app_name=self.APP_NAME
            )

            # если тебе нужно хранить _process в DCLMStudio для совместимости
            self._process = self._app.process

            self._zapusk_v_processe = False

        except Exception as e:
            self._emit_error(7, f"Ошибка запуска: {str(e)}")
            self._zapusk_v_processe = False

    def _ostanovitVPotoke(self):
        """Останавливает LM Studio/Bionic в отдельном потоке через DCLMApp (не блокирует UI)"""
        try:
            self._app.stop(
                app_spec=self._app_spec,
                app_name=self.APP_NAME,
                graceful_seconds=self.DELAY_GRACEFUL_SHUTDOWN
            )

            # синхронизируем совместимость со старым полем
            self._process = None
            self._server_zapuschen = False

            # Qt-сигналы (важно оставить в фасаде)
            self.sigStudioOstanovlen.emit()
            self.sigServerStatus.emit(False)

        except Exception as e:
            self._emit_error(5, f"Ошибка остановки: {str(e)}")

    def _proverkaZapushen(self) -> bool:
        """Проверяет, запущено ли приложение (LM Studio/Bionic)"""
        return self._app.is_running(self._app_spec) 
    
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
    
    def _naitiLMStudio(self) -> Path | None:
        """
        ФАСАДНЫЙ метод поиска приложения.
        Реальный поиск выполняет DCLMHDD, а фасад:
        - применяет AppSpec (обновит APP_NAME и отправит sigAppName)
        """
        app_path = self._hdd.find_app_path(custom_path=self._custom_path)
        if not app_path:
            return None

        # Применяем AppSpec (LM Studio/Bionic) по имени файла
        try:
            spec = self._detect_app_spec_from_path(str(app_path))
            self._apply_app_spec(spec)
        except Exception as e:
            self.sigLog.emit(f"⚠ Не удалось определить тип приложения: {e}")

        return app_path
        
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

    def _vigruzitModel(self, lms_cli):
        """Выгружает текущую загруженную модель"""
        try:
            self.sigLog.emit("🔄 Выгрузка предыдущей модели...")
            
            unload_result = subprocess.run(
                [lms_cli, "unload"],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if unload_result.returncode == 0:
                self.sigLog.emit("✓ Предыдущая модель выгружена")
                self._current_model = "" #Модель выгружена, делаем её пустой.
                self.sigModelVigrujena.emit(True)
                return True
            else:
                # Если ошибка - возможно модель не была загружена, это нормально
                error_msg = unload_result.stderr.strip() if unload_result.stderr else ""
                if "you don't have any models loaded. use \"lms load\" to load a model." in error_msg.lower():
                    self.sigLog.emit(f"Нет загруженной модели для выгрузки")
                else:
                    self.sigLog.emit(f"⚠ Предупреждение при выгрузке: {error_msg[:100]}")
                
                self._current_model = ""#Модель выгружена, делаем её пустой.
                self.sigModelVigrujena.emit(True)
                return True  # Продолжаем в любом случае
        
        except Exception as e:
            self.sigLog.emit(f"⚠ Ошибка выгрузки модели: {str(e)}")
            self.sigModelVigrujena.emit(False)
            return True  # Не критично, продолжаем

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
        """Загружает модель в отдельном потоке (не блокирует UI)"""
        import time
        import re
        
        try:
            # Шаг 1: ВЫГРУЖАЕМ предыдущую модель
            self._vigruzitModel(lms_cli)
    
            # Шаг 2: Преобразуем процент GPU в формат для lms
            gpu_param, gpu_description = self._get_gpu_params(gpu_offload)
            
            # Шаг 3: Загружаем модель
            self.sigLog.emit("🔄 Загрузка модели с новыми параметрами...")
            # self.sigLog.emit(f"   Модель: {model_name}")
            # self.sigLog.emit(f"   Контекст: {max_content} токенов")
            # self.sigLog.emit(f"   GPU: {gpu_description}")
            
            # Излучаем 0% в начале
            self.sigModelProgress.emit(0)
            
            # Формируем команду загрузки
            load_command = [
                lms_cli, "load", model_name, 
                "--context-length", str(max_content), 
                "--gpu", gpu_param,
                "-y"
            ]
            
            # Запускаем процесс загрузки
            process = subprocess.Popen(
                load_command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Паттерн для парсинга прогресса
            progress_pattern = re.compile(r'Loading\s+\S+\s+(\d+)%')
            last_progress = 0
            
            # Читаем вывод построчно
            while True:
                line = process.stdout.readline()
                if not line:
                    break
                
                line = line.strip()
                match = progress_pattern.search(line)
                if match:
                    progress = int(match.group(1))
                    if progress != last_progress:
                        last_progress = progress
                        self.sigModelProgress.emit(progress)
            
            # Ждём завершения
            process.wait(timeout=self.TIMEOUT_MODEL_LOAD)
            
            # Проверяем результат
            if process.returncode == 0:
                # Успех
                self.sigModelProgress.emit(100)
                self.sigLog.emit(f"✓ Модель загружена: {model_name}")
                self.sigLog.emit(f"✓ Контекст: {max_content}")
                self.sigLog.emit(f"✓ GPU: {gpu_description}")
                self._cli_path = lms_cli #Если модель загрузилась, то путь действующий.
                self._current_model = model_name #присваеваем имя модели, когда она загрузилась.
                self.sigModelZagrujena.emit(model_name, max_content)
            
            else:
                # Ошибка
                stderr_output = process.stderr.read() if process.stderr else ""
                error_msg = stderr_output.strip() if stderr_output else "Неизвестная ошибка"
                self.sigModelProgress.emit(0)
                
                if "out of memory" in error_msg.lower() or "cuda" in error_msg.lower():
                    # Пробуем fallback стратегии
                    self.sigLog.emit(f"⚠ {gpu_description}: не хватает памяти")
                    self.sigLog.emit("🔄 Пробуем альтернативные стратегии GPU...")
                    
                    success = self._try_fallback_strategies(
                        lms_cli, model_name, max_content, gpu_offload
                    )
                    
                    if success:
                        return  # Успешно загружено через fallback
                    
                    # Если fallback не помог
                    self.sigLog.emit(f"✗ Не удалось загрузить модель")
                    self.sigLog.emit(f"   Последняя ошибка: {error_msg[:200]}")
                    self.sigLog.emit("💡 Рекомендации:")
                    self.sigLog.emit("   1. Используйте модель меньшего размера (Q3, Q2)")
                    self.sigLog.emit("   2. Закройте другие приложения, использующие GPU")
                    self.sigLog.emit("   3. Уменьшите контекст (например, до 4096)")
                    
                    self._emit_error(10, f"Не удалось загрузить модель {model_name}: {error_msg[:200]}")
                    self._fallback_to_config(model_name, max_content)
                
                else:
                    # Ошибка НЕ связана с памятью
                    self.sigLog.emit(f"✗ Ошибка загрузки модели:")
                    self.sigLog.emit(f"   {error_msg[:300]}")
                    
                    if "not found" in error_msg.lower():
                        self.sigLog.emit("💡 Модель не найдена. Проверьте имя модели: lms ls")
                    
                    self._emit_error(10, f"Ошибка загрузки модели {model_name}: {error_msg[:300]}")
                    self._fallback_to_config(model_name, max_content)
        
        except subprocess.TimeoutExpired:
            self._handle_timeout(model_name, max_content)
        
        except Exception as e:
            self._handle_critical_error(model_name, max_content, e)

    def _get_gpu_params(self, gpu_offload):
        """Преобразует процент GPU в формат для lms"""
        if gpu_offload == 0:
            return "off", "CPU only"
        elif gpu_offload >= 100:
            return "max", "Full GPU"
        else:
            return str(gpu_offload / 100.0), f"{gpu_offload}% GPU"

    def _try_fallback_strategies(self, lms_cli, model_name, max_content, gpu_offload):
        """Пробует альтернативные стратегии GPU при ошибке"""
        fallback_strategies = self._get_fallback_strategies(gpu_offload)
        
        for fb_gpu, fb_desc in fallback_strategies:
            self.sigLog.emit(f"🔄 Попытка: {fb_desc}...")
            self.sigModelProgress.emit(0)
            
            fb_command = [
                lms_cli, "load", model_name, 
                "--context-length", str(max_content), 
                "--gpu", fb_gpu, 
                "-y"
            ]
            
            fb_result = subprocess.run(
                fb_command,
                capture_output=True,
                text=True,
                timeout=self.TIMEOUT_MODEL_LOAD
            )
            
            if fb_result.returncode == 0:
                self.sigModelProgress.emit(100)
                self.sigLog.emit(f"✓ Модель загружена: {model_name}")
                self.sigLog.emit(f"✓ Контекст: {max_content}")
                self.sigLog.emit(f"✓ GPU: {fb_desc} (fallback)")
                self._cli_path = lms_cli #Если модель загрузилась, то путь действующий.
                self._current_model = model_name #присваеваем имя модели, когда она загрузилась.
                self.sigModelZagrujena.emit(model_name, max_content)
                return True
            else:
                fb_error = fb_result.stderr.strip() if fb_result.stderr else ""
                if "out of memory" in fb_error.lower():
                    self.sigLog.emit(f"⚠ {fb_desc}: всё ещё не хватает памяти")
                    continue
                else:
                    break
        
        return False

    def _get_fallback_strategies(self, gpu_offload):
        """Возвращает список fallback стратегий в зависимости от исходного offload"""
        if gpu_offload >= 100:
            return [("0.5", "50% GPU"), ("0.3", "30% GPU"), ("off", "CPU only")]
        elif gpu_offload >= 50:
            return [("0.3", "30% GPU"), ("off", "CPU only")]
        elif gpu_offload > 0:
            return [("off", "CPU only")]
        else:
            return []

    def _handle_timeout(self, model_name, max_content):
        """Обрабатывает таймаут загрузки модели"""
        self.sigModelProgress.emit(0)
        error_msg = "Превышено время ожидания загрузки модели (3 мин)"
        self._emit_error(10, f"Таймаут: {model_name}")
        self._fallback_to_config(model_name, max_content)

    def _handle_critical_error(self, model_name, max_content, exception):
        """Обрабатывает критические ошибки загрузки"""
        self.sigModelProgress.emit(0)
        error_msg = f"Критическая ошибка: {str(exception)}"
        self._emit_error(10, f"{model_name}: {str(exception)}")
        self._fallback_to_config(model_name, max_content)

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

    def _zapustitServerPosledujushii(self):
        """Вспомогательный метод для отложенного запуска сервера"""
        self.sigLog.emit("🔄 Запуск сервера с новыми параметрами...")
        self.zapustitServer()

    def _ustServerConfig(self, max_context):
        """Обновляет server-config.json в ~/.lmstudio/"""
        try:
            import json
            
            config_path = Path.home() / ".lmstudio" / "server-config.json"
            
            if not config_path.exists():
                self.sigLog.emit(f"⚠ Конфигурация не найдена: {config_path}")
                
                # Создаём конфиг по умолчанию
                default_config = {
                    "maxContext": max_context,
                    "temperature": 0.7,
                    "topP": 0.9,
                    "repeatPenalty": 1.1,
                    "gpu": "auto"
                }
                
                config_path.parent.mkdir(parents=True, exist_ok=True)
                
                with open(config_path, 'w') as f:
                    json.dump(default_config, f, indent=2)
                
                self.sigLog.emit(f"✓ Создан конфиг: {config_path}")
                return True
            
            # Читаем существующий конфиг
            with open(config_path, 'r') as f:
                config = json.load(f)
            
            # Обновляем maxContext
            old_context = config.get('maxContext', 0)
            config['maxContext'] = max_context
            
            # Сохраняем
            with open(config_path, 'w') as f:
                json.dump(config, f, indent=2)
            
            self.sigLog.emit(f"✓ Контекст обновлён: {old_context} → {max_context}")
            return True
        
        except Exception as e:
            self.sigLog.emit(f"✗ Ошибка обновления конфига: {e}")
            return False

    def _detect_app_spec_from_path(self, app_path: str) -> AppSpec:
        """
        Обёртка над DCLMHDD.detect_app_spec_from_path.
        Оставляем это имя, чтобы не менять остальной код.
        """
        return self._hdd.detect_app_spec_from_path(app_path, fallback=self._app_spec)

    def _apply_app_spec(self, spec: AppSpec) -> None:
        """Применяет AppSpec и обновляет APP_NAME для логов/команд."""
        old_name = getattr(self, "_app_spec", None).display_name if getattr(self, "_app_spec", None) else ""

        self._app_spec = spec
        type(self).APP_NAME = spec.display_name# ВАЖНО: обновляем именно классовую переменную (глобальную для класса)

        if old_name != spec.display_name:# Эмитим только если реально поменялось
            self.sigLog.emit(f"✓ Определено приложение: {old_name or '(неизвестно)'} → {spec.display_name}")
            self.sigAppName.emit(spec.display_name)

