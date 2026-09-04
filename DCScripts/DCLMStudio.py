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
    sigServerOk = pyqtSignal()              # Сервер доступен
    sigZapuschen = pyqtSignal()             # LM Studio запущен
    sigOstanovlen = pyqtSignal()            # LM Studio остановлен
    sigError = pyqtSignal(int, str)         # Ошибка
    sigLog = pyqtSignal(str)                # Лог
    sigStarted = pyqtSignal()               # Начата проверка запуска
    
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
    
    # ==================== ЗАПУСК/ОСТАНОВКА ====================
    
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
            self.sigLog.emit("Ожидание запуска сервера...")
        
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
                    
                    self.sigLog.emit("LM Studio остановлен")
                    self.sigOstanovlen.emit()
                else:
                    self.sigLog.emit("LM Studio не запущен")
            
            elif platform.system() == "Darwin":
                subprocess.run(["pkill", "-f", "LM Studio"])
                self.sigLog.emit("LM Studio остановлен")
                self.sigOstanovlen.emit()
            
            elif platform.system() == "Windows":
                subprocess.run(["taskkill", "/F", "/IM", "LM Studio.exe"], shell=True)
                self.sigLog.emit("LM Studio остановлен")
                self.sigOstanovlen.emit()
        
        except Exception as e:
            error_msg = f"Ошибка остановки: {str(e)}"
            self.sigError.emit(5, error_msg)
    
    @pyqtSlot()
    def proverkaServera(self):
        """Проверяет доступность LM Studio"""
        if self._proverkaZapushen():
            self.sigServerOk.emit()
        else:
            self.sigError.emit(6, "LM Studio не запущен")
    
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
        """Проверяет, запущен ли LM Studio"""
        try:
            response = requests.get(f"{LM_STUDIO_URL}/models", timeout=2)
            return response.status_code == 200
        except:
            return False
    
    def _proverkaDostupnosti(self):
        """Периодическая проверка доступности"""
        self._popitki += 1
        
        if self._proverkaZapushen():
            if self._timer:
                self._timer.stop()
            self._popitki = 0
            self._zapusk_v_processe = False
            self.sigLog.emit("LM Studio сервер запущен!")
            self.sigZapuschen.emit()
        else:
            if self._popitki >= self._max_popitok:
                if self._timer:
                    self._timer.stop()
                self._popitki = 0
                self._zapusk_v_processe = False
                error_msg = "LM Studio не отвечает. Запустите вручную или проверьте путь."
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
