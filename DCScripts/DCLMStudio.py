import subprocess
import platform
import requests
import threading
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer


class DCLMStudio(QObject):
    """Управление LM Studio: запуск/остановка и работа с моделями"""
    
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
    # ==================== СИГНАЛЫ ====================
    # Сигналы для LM Studio
    sigLog = pyqtSignal(str)                # Лог
    sigError = pyqtSignal(int, str)         # Ошибка
    sigCLIPut = pyqtSignal(str)             # Возвращает путь к cli lms
    sigStudioStarted = pyqtSignal()         # Начата проверка запуска
    sigStudioZapuschen = pyqtSignal()       # LM Studio запущен
    sigStudioOstanovlen = pyqtSignal()      # LM Studio остановлен
    sigStudioStatus = pyqtSignal(bool)      # Статус LM Studio (True - запущен, False - остановлен)
    sigModelsLoaded = pyqtSignal(list)      # Список моделей загружен
    sigModelZagrujena = pyqtSignal(str, int)# (model_name, max_content)
    sigModelProgress = pyqtSignal(int)      # Процент загрузки модели (0-100)
    # Сигналы для сервера
    sigServerURLIzmenen = pyqtSignal(str)   # URL сервера изменён
    sigParametriIzmeneni = pyqtSignal(str, int, float)  # Сигнал (model_name, max_context, temperature)
    sigServerZapuschen = pyqtSignal()       # Сервер запущен
    sigServerOstanovlen = pyqtSignal()      # Сервер остановлен
    sigServerStatus = pyqtSignal(bool)      # Статус сервера (True - запущен, False - остановлен)
    sigServerError = pyqtSignal(str)        # Ошибка сервера
    
    def __init__(self):
        super().__init__()
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
        Проверяет корректность URL сервера LM Studio
        
        Args:
            server_url: Адрес сервера (например: http://localhost:1234)
        
        Returns:
            True - если URL корректен
            False - если URL некорректен
        """
        import re
        
        if not server_url:
            return False
        
        # Удаляем пробелы по краям
        server_url = server_url.strip()
        
        # Проверяем максимальную длину (30 символов)
        if len(server_url) > 30:
            self.sigLog.emit(f"⚠ URL слишком длинный: {len(server_url)} символов (максимум 30)")
            return False
        
        # Регулярное выражение для проверки формата
        # Допустимые форматы:
        # http://localhost:порт
        # http://127.0.0.1:порт
        # http://IP:порт (например: http://192.168.1.100:1234)
        pattern = re.compile(
            r'^http://'                          # Обязательно начинается с http://
            r'('                                 # Начало группы для хоста
            r'localhost|'                        # localhost ИЛИ
            r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}'  # IP адрес (например: 127.0.0.1)
            r')'                                 # Конец группы для хоста
            r':'                                 # Обязательное двоеточие
            r'(\d{1,5})'                         # Порт (от 1 до 5 цифр)
            r'$'                                 # Конец строки
        )
        
        match = pattern.match(server_url)
        
        if not match:
            self.sigLog.emit(f"⚠ Неверный формат URL: {server_url}")
            self.sigLog.emit("   Допустимый формат: http://localhost:1234 или http://127.0.0.1:1234")
            return False
        
        # Проверяем корректность IP адреса (если не localhost)
        host = match.group(1)
        port = int(match.group(2))
        
        if host != "localhost":
            # Проверяем, что каждый октет IP <= 255
            octets = host.split('.')
            for octet in octets:
                if int(octet) > 255:
                    self.sigLog.emit(f"⚠ Неверный IP адрес: {host} (октет {octet} > 255)")
                    return False
        
        # Проверяем корректность порта (1-65535)
        if port < 1 or port > 65535:
            self.sigLog.emit(f"⚠ Неверный порт: {port} (допустимый диапазон: 1-65535)")
            return False
        
        # Все проверки пройдены
        self.sigLog.emit(f"✓ URL корректен: {server_url}")
        return True

    @pyqtSlot(str, result=bool)
    def proverkaFaila(self, file_path: str) -> bool:
        """
        Проверяет, существует ли файл по указанному пути.
        Работает со скрытыми файлами (.file) и путями с ~ (домашняя директория).
        """
        if not file_path:
            return False
            
        try:
            # expanduser() превращает ~/ в /home/user/, что критично для Linux
            # resolve() очищает путь от лишних ./ или ../
            path = Path(file_path).expanduser().resolve()
            
            # is_file() проверяет, что это именно файл, а не папка
            return path.is_file()
            
        except Exception:
            return False

    # ==================== РАБОТА С МОДЕЛЯМИ ====================
    @pyqtSlot()
    def zagruzitModeli(self):
        """Загружает список доступных моделей из LM Studio"""
        try:
            response = requests.get(
                f"{self._server_url}/models",
                timeout=self.TIMEOUT_MODEL_LIST
            )
            
            if response.status_code == 200:
                data = response.json()
                models = []
                
                # Добавляем опцию "отсутствует" ПЕРВЫМ элементом
                models.append(self.NO_MODEL_NAME)  # "отсутствует" первым

                # Добавляем реальные модели (фильтруем embedding)
                for model_info in data.get("data", []):
                    model_id = model_info.get("id", "")
                    if model_id and "embed" not in model_id.lower():
                        models.append(model_id)
                
                self._models_list = models
                self.sigModelsLoaded.emit(models)
                
                print(f"✓ Загружено моделей: {len(models) - 1}")  # -1 для автовыбора
            else:
                error_msg = f"HTTP {response.status_code}: {response.text}"
                self._emit_error(0, error_msg)
                self.sigModelsLoaded.emit([self.AUTO_MODEL_NAME])
        
        except requests.exceptions.ConnectionError:
            error_msg = f"Не удалось подключиться к LM Studio ({self._server_url})"
            self._emit_error(1, error_msg)
            self.sigModelsLoaded.emit([self.AUTO_MODEL_NAME])
        
        except Exception as e:
            error_msg = f"Ошибка загрузки моделей: {str(e)}"
            self._emit_error(2, error_msg)
            self.sigModelsLoaded.emit([self.AUTO_MODEL_NAME])
    
    @pyqtSlot(str)
    def ustModel(self, model_name):
        """Устанавливает выбранную модель"""
        if model_name == self.NO_MODEL_NAME or not model_name:
            self._current_model = ""
        else:
            self._current_model = model_name 
    
    @pyqtSlot(result=str)
    def polModel(self):
        """Возвращает текущую модель"""
        return self._current_model 
    
    @pyqtSlot(str, int, float, int)
    def ustParametri(self, model_name, max_context, temperature, gpu_offload):
        """Публичный слот для загрузки модели с параметрами"""
        # если модель "(отсутствует)" или пустая
        if not model_name or model_name == self.NO_MODEL_NAME:
            self._current_model = model_name#чтоб я мог понять по polModel что модель не задана.
            error_msg = "Модель не выбрана. Выберите модель из списка."
            self._emit_error(13, error_msg)  # КОД ОШИБКИ 13
            return False

        if not self._proverkaZapushen():  # Проверка запуска LM Studio
            error_msg = "LM Studio не запущен. Сначала запустите приложение."
            self._emit_error(6, error_msg)
            return False
        
        # LM Studio запущен, продолжаем загрузку
        success = self._ustParametri(model_name, max_context, gpu_offload)

        if success:
            self.ustModel(model_name)  # Приравниваем к _current_model и убираем автовыбор
            self.sigParametriIzmeneni.emit(self._current_model, max_context, temperature)
        else:
            # Ошибка при начале загрузки
            self._emit_error(10, f"Не удалось начать загрузку модели {model_name}")
        
        return success 

    # ==================== УПРАВЛЕНИЕ СЕРВЕРОМ ====================
    @pyqtSlot(str)
    def ustServerURL(self, server_url):
        """Устанавливает URL сервера LM Studio"""
        server_url = server_url.strip().rstrip('/')
        
        if not server_url.endswith('/v1'):
            server_url += '/v1'
        
        old_url = self._server_url
        self._server_url = server_url
        
        self.sigLog.emit(f"✓ URL сервера обновлён: {server_url}")
        
        if old_url != server_url:
            print(f"✓ Сервер URL изменён: {old_url} → {server_url}")
            # Излучаем сигнал об изменении
            self.sigServerURLIzmenen.emit(server_url)
            # Проверяем доступность нового сервера
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

    def _naitiLMS_CLI(self):
        """Находит путь к lms CLI"""
        # Если задан пользовательский путь
        if self._cli_path:
            cli = Path(self._cli_path)
            if cli.exists():
                print(f"✓ Используется путь к CLI из настроек: {cli}")
                return str(cli)
        
        # Автопоиск в стандартных местах
        home = Path.home()
        
        if platform.system() == "Linux" or platform.system() == "Darwin":
            search_paths = [
                home / ".lmstudio" / "bin" / "lms",
                home / ".local" / "bin" / "lms",
                Path("/usr/local/bin/lms"),
                Path("/usr/bin/lms"),
            ]
            
            for path in search_paths:
                if path.exists():
                    print(f"✓ Найден lms CLI: {path}")
                    self.sigCLIPut.emit(str(path))
                    return str(path)
        
        elif platform.system() == "Windows":
            import os
            search_paths = [
                Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "LMStudio" / "lms.exe",
                Path(os.environ.get("APPDATA", "")) / "LMStudio" / "lms.exe",
            ]
            
            for path in search_paths:
                if path.exists():
                    print(f"✓ Найден lms CLI: {path}")
                    self.sigCLIPut.emit(str(path))
                    return str(path)
        
        # Проверяем, доступен ли lms в PATH
        try:
            result = subprocess.run(
                ["which", "lms"] if platform.system() != "Windows" else ["where", "lms"],
                capture_output=True,
                text=True,
                timeout=2
            )
            if result.returncode == 0:
                lms_path = result.stdout.strip().split('\n')[0]
                print(f"✓ Найден lms в PATH: {lms_path}")
                self.sigCLIPut.emit(lms_path)
                return lms_path
        except:
            pass
        
        error_msg = "CLI lms не найден. Укажите путь в настройках (~/.lmstudio/bin/lms)"
        self._emit_error(9, error_msg)
        return None

    @pyqtSlot()
    def zapustitServer(self):
        """Запускает сервер LM Studio через CLI команду"""
        if self._proverkaServeraZapuschen():
            self.sigLog.emit("⚠ Сервер уже запущен")
            self.sigServerZapuschen.emit()
            self.sigServerStatus.emit(True)
            self._server_zapuschen = True
            return
        
        if not self._proverkaZapushen():
            error_msg = "LM Studio не запущен. Сначала запустите приложение."
            self._emit_error(6, error_msg)
            return
        
        # Находим lms CLI
        lms_cli = self._naitiLMS_CLI()
        
        if not lms_cli:
            error_msg = "CLI lms не найден. Укажите путь в настройках (~/.lmstudio/bin/lms)"
            self._emit_error(9, error_msg)
            return
        
        try:
            self.sigLog.emit("🔄 Запуск сервера LM Studio...")
            
            # Выполняем команду запуска сервера
            result = subprocess.run(
                [lms_cli, "server", "start"],
                capture_output=True,
                text=True,
                timeout=self.TIMEOUT_SERVER_START
            )
            
            if result.returncode == 0:
                self.sigLog.emit("✓ Команда запуска выполнена")
                self._zapustitProverkuServera()
            else:
                error_msg = f"Ошибка выполнения команды: {result.stderr}"
                self.sigServerError.emit(error_msg)
        
        except Exception as e:
            error_msg = f"Ошибка запуска сервера: {str(e)}"
            self._emit_error(11, error_msg)

    @pyqtSlot()
    def ostanovitServer(self):
        """Останавливает сервер LM Studio через CLI команду"""
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
            self.sigLog.emit("🔄 Остановка сервера LM Studio...")
            
            result = subprocess.run(
                [lms_cli, "server", "stop"],
                capture_output=True,
                text=True,
                timeout=self.TIMEOUT_SERVER_START
            )
            
            if result.returncode == 0:
                self._server_zapuschen = False
                self.sigLog.emit("✓ Сервер остановлен")
                self.sigServerOstanovlen.emit()
                self.sigServerStatus.emit(False)
            else:
                error_msg = f"Ошибка выполнения команды: {result.stderr}"
                self.sigServerError.emit(error_msg)
        
        except Exception as e:
            error_msg = f"Ошибка остановки сервера: {str(e)}"
            self._emit_error(12, error_msg)

    @pyqtSlot()
    def proverkaServera(self):
        """Проверяет, запущен ли сервер LM Studio"""
        zapuschen = self._proverkaServeraZapuschen()
        self._server_zapuschen = zapuschen
        self.sigServerStatus.emit(zapuschen)
        self.sigLog.emit(f"Сервер LM Studio: {'запущен' if zapuschen else 'остановлен'}")
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
        """Устанавливает путь к LM Studio"""
        self._custom_path = path
        print(f"✓ Путь к LM Studio: {path}")
    
    @pyqtSlot()
    def zapustitStudio(self):
        """Запускает LM Studio"""
        if self._zapusk_v_processe:
            print("⚠ Запуск уже выполняется")
            return
        
        if self._proverkaZapushen():
            self.sigLog.emit("LM Studio уже работает")
            self.sigStudioZapuschen.emit()
            # Проверяем статус сервера
            self.proverkaServera()
            return
        
        lms_path = self._naitiLMStudio()
        
        if not lms_path:
            error_msg = "Не удалось найти LM Studio. Укажите путь в настройках."
            self._emit_error(3, error_msg)
            return
        
        try:
            self.sigLog.emit(f"Запуск LM Studio: {lms_path.name}")
            
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
            self.sigLog.emit("Ожидание запуска приложения...")
        
        except Exception as e:
            error_msg = f"Ошибка запуска: {str(e)}"
            self._emit_error(4, error_msg)
            self._zapusk_v_processe = False
    
    @pyqtSlot()
    def ostanovitStudio(self):
        """Останавливает LM Studio с graceful shutdown"""
        import time
        
        try:
            if platform.system() == "Linux":
                # Шаг 1: Проверяем, есть ли процессы
                result = subprocess.run(
                    ["pgrep", "-f", "lmstudio"],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                
                if result.returncode != 0:
                    self.sigLog.emit("LM Studio не запущен")
                    self._server_zapuschen = False
                    self.sigStudioOstanovlen.emit()
                    self.sigServerStatus.emit(False)
                    return
                
                pids = result.stdout.strip().split('\n')
                
                # Шаг 2: SIGTERM (мягкая остановка)
                self.sigLog.emit("Отправка SIGTERM...")
                for pid in pids:
                    if pid:
                        try:
                            subprocess.run(["kill", "-15", pid], timeout=2)
                        except Exception as e:
                            self.sigLog.emit(f"⚠ Не удалось отправить SIGTERM: {e}")
                
                # Шаг 3: Ждём 3 секунды
                time.sleep(self.DELAY_GRACEFUL_SHUTDOWN)
                
                # Шаг 4: Проверяем, завершились ли процессы
                result = subprocess.run(
                    ["pgrep", "-f", "lmstudio"],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                
                if result.returncode == 0:
                    # Процессы ещё живы — SIGKILL
                    self.sigLog.emit("⚠ Процесс не завершился, использую SIGKILL...")
                    pids = result.stdout.strip().split('\n')
                    
                    for pid in pids:
                        if pid:
                            try:
                                subprocess.run(["kill", "-9", pid], timeout=2)
                            except Exception as e:
                                self.sigLog.emit(f"✗ Ошибка SIGKILL: {e}")
                
                self._server_zapuschen = False
                self.sigLog.emit("✓ LM Studio остановлен")
                self.sigStudioOstanovlen.emit()
                self.sigServerStatus.emit(False)
            
            elif platform.system() == "Darwin":
                # macOS: аналогично Linux
                subprocess.run(["pkill", "-TERM", "-f", "LM Studio"], timeout=2)
                time.sleep(self.DELAY_GRACEFUL_SHUTDOWN)
                subprocess.run(["pkill", "-KILL", "-f", "LM Studio"], timeout=2)
                
                self._server_zapuschen = False
                self.sigLog.emit("✓ LM Studio остановлен")
                self.sigStudioOstanovlen.emit()
                self.sigServerStatus.emit(False)
            
            elif platform.system() == "Windows":
                # Windows: используем /T для дерева процессов
                subprocess.run(
                    ["taskkill", "/F", "/T", "/IM", "LM Studio.exe"],
                    shell=True,
                    timeout=5
                )
                
                self._server_zapuschen = False
                self.sigLog.emit("✓ LM Studio остановлен")
                self.sigStudioOstanovlen.emit()
                self.sigServerStatus.emit(False)
        
        except Exception as e:
            error_msg = f"Ошибка остановки: {str(e)}"
            self._emit_error(5, error_msg)
    
    @pyqtSlot()
    def proverkaStudio(self):
        """Проверяет доступность LM Studio (приложения)"""
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
        """Запускает LM Studio в отдельном потоке"""
        try:
            if platform.system() == "Linux":
                subprocess.Popen(
                    [str(lms_path), "--no-sandbox"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    start_new_session=True
                )
            elif platform.system() == "Darwin":
                subprocess.Popen(["open", "-a", str(lms_path)])
            elif platform.system() == "Windows":
                subprocess.Popen(
                    [str(lms_path)],
                    creationflags=subprocess.CREATE_NO_WINDOW
                )
            
            self._zapusk_v_processe = False
        
        except Exception as e:
            error_msg = f"Ошибка запуска: {str(e)}"
            self._emit_error(7, error_msg)
            self._zapusk_v_processe = False
    
    def _proverkaZapushen(self):
        """Проверяет, запущено ли приложение LM Studio (не сервер!)"""
        try:
            # Проверяем процесс, а не сервер
            if platform.system() == "Linux":
                result = subprocess.run(
                    ["pgrep", "-f", "lmstudio"],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                return result.returncode == 0
            
            elif platform.system() == "Darwin":
                result = subprocess.run(
                    ["pgrep", "-f", "LM Studio"],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                return result.returncode == 0
            
            elif platform.system() == "Windows":
                result = subprocess.run(
                    ["tasklist", "/FI", "IMAGENAME eq LM Studio.exe"],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                return "LM Studio.exe" in result.stdout
            
            return False
        except:
            return False
    
    def _proverkaDostupnosti(self):
        """Периодическая проверка доступности приложения"""
        self._popitki += 1
        
        # Проверяем ПРОЦЕСС, а не сервер
        if self._proverkaZapushen():
            if self._timer:
                self._timer.stop()
            self._popitki = 0
            self._zapusk_v_processe = False
            self.sigLog.emit("✓ LM Studio приложение запущено!")
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
                error_msg = "LM Studio не запустился. Запустите вручную или проверьте путь."
                self._emit_error(8, error_msg)
            else:
                self.sigLog.emit(f"⏳ Попытка {self._popitki}/{self._max_popitok}...")
    
    def _naitiLMStudio(self):
        """Находит путь к LM Studio"""
        if self._custom_path:
            custom = Path(self._custom_path)
            if custom.exists():
                print(f"✓ Используется путь из настроек: {custom}")
                return custom
            else:
                print(f"⚠ Путь из настроек не существует: {custom}")
        
        home = Path.home()
        
        if platform.system() == "Linux":
            paths = [
                home / ".local" / "share" / "applications" / "LM-Studio.AppImage",
                home / "Applications" / "LM-Studio.AppImage",
                home / ".cache" / "lmstudio" / "LM-Studio.AppImage",
                Path("/opt/LM-Studio/LM-Studio.AppImage")
            ]
            
            desktop_file = home / ".local" / "share" / "applications" / "lm-studio.desktop"
            if desktop_file.exists():
                try:
                    with open(desktop_file, 'r') as f:
                        for line in f:
                            if line.startswith("Exec="):
                                exec_path = line.split("=", 1)[1].strip().split()[0]
                                exec_path = exec_path.replace('"', '').replace("'", '')
                                path = Path(exec_path)
                                if path.exists():
                                    print(f"✓ Найден через .desktop: {path}")
                                    return path
                except Exception as e:
                    print(f"⚠ Ошибка чтения .desktop: {e}")
        
        elif platform.system() == "Darwin":
            paths = [
                Path("/Applications/LM Studio.app"),
                home / "Applications" / "LM Studio.app"
            ]
        
        elif platform.system() == "Windows":
            import os
            paths = [
                Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "LM Studio" / "LM Studio.exe",
                Path(os.environ.get("PROGRAMFILES", "")) / "LM Studio" / "LM Studio.exe"
            ]
        else:
            return None
        
        for path in paths:
            if path.exists():
                print(f"✓ Найден LM Studio: {path}")
                return path
        
        if platform.system() == "Linux":
            appimage = self._naitiAppImage()
            if appimage:
                return appimage
        
        return None
    
    def _naitiAppImage(self):
        """Рекурсивный поиск AppImage (только Linux)"""
        search_dirs = [
            Path.home() / ".local" / "share",
            Path.home() / "Applications",
            Path.home() / "Downloads",
            Path.home() / ".cache"
        ]
        
        for base_dir in search_dirs:
            if not base_dir.exists():
                continue
            
            try:
                for item in base_dir.iterdir():
                    if item.is_file():
                        name_lower = item.name.lower()
                        if ("lm" in name_lower and "studio" in name_lower and 
                            item.suffix.lower() == ".appimage"):
                            print(f"✓ Найден через поиск: {item}")
                            return item
            except PermissionError:
                continue
        
        return None

    def _proverkaServeraZapuschen(self):
        """Внутренняя проверка статуса сервера"""
        try:
            response = requests.get(
                f"{self._server_url}/models", 
                timeout=self.TIMEOUT_SERVER_CHECK
            )
            return response.status_code == 200
        except:
            return False

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
                return True
            else:
                # Если ошибка - возможно модель не была загружена, это нормально
                error_msg = unload_result.stderr.strip() if unload_result.stderr else ""
                if "no model" in error_msg.lower() or "not loaded" in error_msg.lower():
                    self.sigLog.emit("ℹ Нет загруженной модели для выгрузки")
                else:
                    self.sigLog.emit(f"⚠ Предупреждение при выгрузке: {error_msg[:100]}")
                return True  # Продолжаем в любом случае
        
        except Exception as e:
            self.sigLog.emit(f"⚠ Ошибка выгрузки модели: {str(e)}")
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
            self.sigLog.emit(f"   Модель: {model_name}")
            self.sigLog.emit(f"   Контекст: {max_content} токенов")
            self.sigLog.emit(f"   GPU: {gpu_description}")
            
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
