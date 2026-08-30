import subprocess
import platform
import requests
import threading
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer


class DCLMStart(QObject):
    """Запуск и остановка LM Studio"""
    
    # Сигналы
    sigZapuschen = pyqtSignal()
    sigOstanovlen = pyqtSignal()
    sigError = pyqtSignal(str)
    sigLog = pyqtSignal(str)
    sigProverkaStarted = pyqtSignal()
    
    def __init__(self):
        super().__init__()
        self._process = None
        self._custom_path = ""
        self._timer = None
        self._popitki = 0
        self._max_popitok = 10
        self._zapusk_v_processe = False
    
    def _initTimer(self):
        """Ленивая инициализация таймера"""
        if self._timer is None:
            self._timer = QTimer()
            self._timer.timeout.connect(self._proverkaDostupnosti)
    
    @pyqtSlot(str)
    def ustPut(self, path):
        """Устанавливает путь к LM Studio"""
        self._custom_path = path
        print(f"✓ Путь к LM Studio: {path}")
    
    def _zapustitVPotoke(self, lms_path):
        """Запускает LM Studio в отдельном потоке (чтобы не блокировать Qt)"""
        try:
            if platform.system() == "Linux":
                subprocess.Popen(
                    [str(lms_path), "--no-sandbox"],#Запускаем с флагом --no-sandbox
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
            self._zapusk_v_processe = False#Запускаем проверку доступности в главном потоке через Qt
            
        except Exception as e:
            error_msg = f"Ошибка запуска: {str(e)}"
            print(f"✗ {error_msg}")
            self.sigError.emit(error_msg)
            self._zapusk_v_processe = False
    
    @pyqtSlot()
    def zapustit(self):
        """Запускает LM Studio"""
        if self._zapusk_v_processe:
            print("⚠ Запуск уже выполняется")
            return
        
        if self._proverkaZapushen():
            print("⚠ LM Studio уже работает")
            self.sigLog.emit("LM Studio уже работает")
            self.sigZapuschen.emit()
            return
        
        lms_path = self._naitiLMStudio()
        
        if not lms_path:
            error_msg = "Не удалось найти LM Studio. Укажите путь в настройках."
            print(f"✗ {error_msg}")
            self.sigError.emit(error_msg)
            return
        
        try:
            print(f"✓ Запуск LM Studio: {lms_path}")
            self.sigLog.emit(f"Запуск: {lms_path.name}")
            
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
            self.sigProverkaStarted.emit()
            self.sigLog.emit("Ожидание запуска сервера...")
        
        except Exception as e:
            error_msg = f"Ошибка запуска: {str(e)}"
            print(f"✗ {error_msg}")
            self.sigError.emit(error_msg)
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
                    
                    print("✓ LM Studio остановлен")
                    self.sigLog.emit("LM Studio остановлен")
                    self.sigOstanovlen.emit()
                else:
                    print("⚠ LM Studio не запущен")
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
            print(f"✗ {error_msg}")
            self.sigError.emit(error_msg)
    
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
    
    def _proverkaZapushen(self):
        """Проверяет, запущен ли LM Studio"""
        try:
            response = requests.get("http://localhost:1234/v1/models", timeout=2)
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
            print("✓ LM Studio сервер доступен")
            self.sigLog.emit("✓ LM Studio сервер запущен!")
            self.sigZapuschen.emit()
        else:
            if self._popitki >= self._max_popitok:
                if self._timer:
                    self._timer.stop()
                self._popitki = 0
                self._zapusk_v_processe = False
                error_msg = "LM Studio не отвечает. Запустите вручную или проверьте путь."
                print(f"✗ {error_msg}")
                self.sigError.emit(error_msg)
            else:
                print(f"⏳ Проверка {self._popitki}/{self._max_popitok}...")
                self.sigLog.emit(f"Попытка {self._popitki}/{self._max_popitok}...")
