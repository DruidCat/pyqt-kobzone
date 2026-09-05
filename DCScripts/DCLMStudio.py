import subprocess
import platform
import requests
import threading
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer

LM_STUDIO_URL = "http://localhost:1234/v1"


class DCLMStudio(QObject):
    """Управление LM Studio: запуск/остановка и работа с моделями"""
    
    # Сигналы
    sigModelsLoaded = pyqtSignal(list)      # Список моделей загружен
    sigModelChanged = pyqtSignal(str)       # Модель изменена
    sigLMSProverkaOK = pyqtSignal()         # Сигнал о том, что LM Studio запущен,после проверки lmsProverka()
    sigZapuschen = pyqtSignal()             # LM Studio запущен
    sigOstanovlen = pyqtSignal()            # LM Studio остановлен
    sigError = pyqtSignal(int, str)         # Ошибка
    sigLog = pyqtSignal(str)                # Лог
    sigStarted = pyqtSignal()               # Начата проверка запуска
    
    # Новые сигналы для сервера
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
        self._timer = None
        self._popitki = 0
        self._max_popitok = 10
        self._zapusk_v_processe = False
        
        # Состояние сервера
        self._server_zapuschen = False
    
    # ==================== РАБОТА С МОДЕЛЯМИ ====================
    
    @pyqtSlot()
    def zagruzitModeli(self):
        """Загружает список доступных моделей из LM Studio"""
        try:
            response = requests.get(
                f"{LM_STUDIO_URL}/models",
                timeout=5
            )
            
            if response.status_code == 200:
                data = response.json()
                models = []
                
                # Добавляем опцию "Автовыбор"
                models.append("(автовыбор модели)")
                
                # Добавляем реальные модели (фильтруем embedding)
                for model_info in data.get("data", []):
                    model_id = model_info.get("id", "")
                    if model_id and "embed" not in model_id.lower():
                        models.append(model_id)
                
                self._models_list = models
                self.sigModelsLoaded.emit(models)
                
                print(f"✓ Загружено моделей: {len(models) - 1}")
            else:
                error_msg = f"Ошибка {response.status_code}: {response.text}"
                print(f"✗ {error_msg}")
                self.sigError.emit(0, error_msg)
                self.sigModelsLoaded.emit(["(автовыбор модели)"])
        
        except requests.exceptions.ConnectionError:
            error_msg = f"Не удалось подключиться к LM Studio ({LM_STUDIO_URL})"
            print(f"✗ {error_msg}")
            self.sigError.emit(1, error_msg)
            self.sigModelsLoaded.emit(["(автовыбор модели)"])
        
        except Exception as e:
            error_msg = f"Ошибка загрузки моделей: {str(e)}"
            print(f"✗ {error_msg}")
            self.sigError.emit(2, error_msg)
            self.sigModelsLoaded.emit(["(автовыбор модели)"])
    
    @pyqtSlot(str)
    def ustModel(self, model_name):
        """Устанавливает выбранную модель"""
        if model_name == "(автовыбор модели)":
           self._current_model = ""
        else:
            self._current_model = model_name
        
        self.sigModelChanged.emit(self._current_model)
        print(f"✓ Выбрана модель: {model_name}")
    
    @pyqtSlot(result=str)
    def poluchitModel(self):
        """Возвращает текущую модель"""
        return self._current_model
    
    # ==================== ПРОВЕРКА СЕРВЕРА ====================
    
    @pyqtSlot()
    def proveritServer(self):
        """Проверяет, запущен ли сервер LM Studio"""
        zapuschen = self._proverkaServeraZapuschen()
        self._server_zapuschen = zapuschen
        self.sigServerStatus.emit(zapuschen)
        
        if zapuschen:
            self.sigLog.emit("✓ Сервер LM Studio запущен")
        else:
            self.sigLog.emit("✗ Сервер LM Studio остановлен")
        
        return zapuschen
    
    def _proverkaServeraZapuschen(self):
        """Внутренняя проверка статуса сервера"""
        try:
            response = requests.get(f"{LM_STUDIO_URL}/models", timeout=2)
            return response.status_code == 200
        except:
            return False
    
    # ==================== УПРАВЛЕНИЕ СЕРВЕРОМ ====================
    
    @pyqtSlot()
    def zapustitServer(self):
        """Запускает сервер LM Studio через CLI команду"""
        if self._proverkaServeraZapuschen():
            self.sigLog.emit("⚠ Сервер уже запущен")
            self.sigServerStatus.emit(True)
            self._server_zapuschen = True
            return
        
        # Проверяем, что LM Studio запущен
        if not self._proverkaZapushen():
            error_msg = "LM Studio не запущен. Сначала запустите приложение."
            self.sigServerError.emit(error_msg)
            self.sigError.emit(9, error_msg)
            return
        
        try:
            self.sigLog.emit("🔄 Запуск сервера LM Studio...")
            
            # Выполняем команду запуска сервера
            result = subprocess.run(
                ["lms", "server", "start"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                self.sigLog.emit("✓ Команда запуска выполнена")
                # Запускаем проверку с задержкой
                self._zapustitProverkuServera()
            else:
                error_msg = f"Ошибка выполнения команды: {result.stderr}"
                self.sigServerError.emit(error_msg)
                self.sigLog.emit(f"✗ {error_msg}")
        
        except FileNotFoundError:
            error_msg = "Команда 'lms' не найдена. Убедитесь, что LM Studio CLI установлен."
            self.sigServerError.emit(error_msg)
            self.sigLog.emit(f"✗ {error_msg}")
        
        except subprocess.TimeoutExpired:
            error_msg = "Превышено время ожидания выполнения команды"
            self.sigServerError.emit(error_msg)
            self.sigLog.emit(f"✗ {error_msg}")
        
        except Exception as e:
            error_msg = f"Ошибка запуска сервера: {str(e)}"
            self.sigServerError.emit(error_msg)
            self.sigLog.emit(f"✗ {error_msg}")

    @pyqtSlot()
    def ostanovitServer(self):
        """Останавливает сервер LM Studio через CLI команду"""
        if not self._proverkaServeraZapuschen():
            self.sigLog.emit("⚠ Сервер уже остановлен")
            self.sigServerStatus.emit(False)
            self._server_zapuschen = False
            return
        
        try:
            self.sigLog.emit("🔄 Остановка сервера LM Studio...")
            
            # Выполняем команду остановки сервера
            result = subprocess.run(
                ["lms", "server", "stop"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                self._server_zapuschen = False
                self.sigLog.emit("✓ Сервер остановлен")
                self.sigServerOstanovlen.emit()
                self.sigServerStatus.emit(False)
            else:
                error_msg = f"Ошибка выполнения команды: {result.stderr}"
                self.sigServerError.emit(error_msg)
                self.sigLog.emit(f"✗ {error_msg}")
        
        except FileNotFoundError:
            error_msg = "Команда 'lms' не найдена. Убедитесь, что LM Studio CLI установлен."
            self.sigServerError.emit(error_msg)
            self.sigLog.emit(f"✗ {error_msg}")
        
        except subprocess.TimeoutExpired:
            error_msg = "Превышено время ожидания выполнения команды"
            self.sigServerError.emit(error_msg)
            self.sigLog.emit(f"✗ {error_msg}")
        
        except Exception as e:
            error_msg = f"Ошибка остановки сервера: {str(e)}"
            self.sigServerError.emit(error_msg)
            self.sigLog.emit(f"✗ {error_msg}")

    def _zapustitProverkuServera(self):
        """Запускает автоматическую проверку запуска сервера"""
        self.sigLog.emit("⏳ Ожидание запуска сервера...")
        
        self._server_popitki = 0
        self._server_max_popitok = 10  # 10 попыток по 2 секунды = 20 секунд
        
        if not hasattr(self, '_server_timer') or self._server_timer is None:
            self._server_timer = QTimer()
            self._server_timer.timeout.connect(self._proverkaServeraAvto)
        
        self._server_timer.start(2000)  # Проверяем каждые 2 секунды

    def _proverkaServeraAvto(self):
        """Автоматическая проверка запуска сервера"""
        self._server_popitki += 1
        
        if self._proverkaServeraZapuschen():
            if hasattr(self, '_server_timer') and self._server_timer:
                self._server_timer.stop()
            
            self._server_popitki = 0
            self._server_zapuschen = True
            self.sigLog.emit("✓ Сервер запущен и готов к работе!")
            self.sigServerZapuschen.emit()
            self.sigServerStatus.emit(True)
        else:
            if self._server_popitki >= self._server_max_popitok:
                if hasattr(self, '_server_timer') and self._server_timer:
                    self._server_timer.stop()
                
                self._server_popitki = 0
                error_msg = "Сервер не запустился за отведённое время"
                self.sigServerError.emit(error_msg)
                self.sigLog.emit(f"⚠ {error_msg}")
            else:
                self.sigLog.emit(f"⏳ Проверка сервера... ({self._server_popitki}/{self._server_max_popitok})")
    
    @pyqtSlot(result=bool)
    def poluchitStatusServera(self):
        """Возвращает текущий статус сервера"""
        return self._server_zapuschen
    
    # ==================== ЗАПУСК/ОСТАНОВКА ПРИЛОЖЕНИЯ ====================
    
    @pyqtSlot(str)
    def ustPut(self, path):
        """Устанавливает путь к LM Studio"""
        self._custom_path = path
        print(f"✓ Путь к LM Studio: {path}")
    
    @pyqtSlot()
    def zapustit(self):
        """Запускает LM Studio"""
        if self._zapusk_v_processe:
            print("⚠ Запуск уже выполняется")
            return
        
        if self._proverkaZapushen():
            self.sigLog.emit("LM Studio уже работает")
            self.sigZapuschen.emit()
            # Проверяем статус сервера
            self.proveritServer()
            return
        
        lms_path = self._naitiLMStudio()
        
        if not lms_path:
            error_msg = "Не удалось найти LM Studio. Укажите путь в настройках."
            self.sigError.emit(3, error_msg)
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
            self._timer.start(3000)
            self.sigStarted.emit()
            self.sigLog.emit("Ожидание запуска приложения...")
        
        except Exception as e:
            error_msg = f"Ошибка запуска: {str(e)}"
            self.sigError.emit(4, error_msg)
            self._zapusk_v_processe = False
    
    @pyqtSlot()
    def ostanovit(self):
        """Останавливает LM Studio"""
        try:
            if platform.system() == "Linux":
                result = subprocess.run(
                    ["pgrep", "-f", "lmstudio"],
                    capture_output=True,
                    text=True
                )
                
                if result.returncode == 0:
                    pids = result.stdout.strip().split('\n')
                    for pid in pids:
                        if pid:
                            try:
                                subprocess.run(["kill", pid], timeout=2)
                            except:
                                subprocess.run(["kill", "-9", pid], timeout=2)
                    
                    self._server_zapuschen = False
                    self.sigLog.emit("LM Studio остановлен")
                    self.sigOstanovlen.emit()
                    self.sigServerStatus.emit(False)
                else:
                    self.sigLog.emit("LM Studio не запущен")
            
            elif platform.system() == "Darwin":
                subprocess.run(["pkill", "-f", "LM Studio"])
                self._server_zapuschen = False
                self.sigLog.emit("LM Studio остановлен")
                self.sigOstanovlen.emit()
                self.sigServerStatus.emit(False)
            
            elif platform.system() == "Windows":
                subprocess.run(["taskkill", "/F", "/IM", "LM Studio.exe"], shell=True)
                self._server_zapuschen = False
                self.sigLog.emit("LM Studio остановлен")
                self.sigOstanovlen.emit()
                self.sigServerStatus.emit(False)
        
        except Exception as e:
            error_msg = f"Ошибка остановки: {str(e)}"
            self.sigError.emit(5, error_msg)
    
    @pyqtSlot()
    def lmsProverka(self):
        """Проверяет доступность LM Studio (приложения)"""
        if self._proverkaZapushen():
            self.sigLMSProverkaOK.emit()
            # Также проверяем сервер
            self.proveritServer()
        else:
            self.sigError.emit(6, "LM Studio не запущен")
            self._server_zapuschen = False
            self.sigServerStatus.emit(False)
    
    # ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================
    
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
            self.sigError.emit(7, error_msg)
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
            self.sigZapuschen.emit()
            
            # Теперь проверяем сервер отдельно
            self.sigLog.emit("Проверка статуса сервера...")
            # Даём время на запуск UI
            QTimer.singleShot(2000, self.proveritServer)
        else:
            if self._popitki >= self._max_popitok:
                if self._timer:
                    self._timer.stop()
                self._popitki = 0
                self._zapusk_v_processe = False
                error_msg = "LM Studio не запустился. Запустите вручную или проверьте путь."
                self.sigError.emit(8, error_msg)
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
