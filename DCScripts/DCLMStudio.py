import subprocess
import platform
import requests
import threading
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QTimer

LM_STUDIO_URL = "http://localhost:1234/v1"


class DCLMStudio(QObject):
    """Управление LM Studio: запуск/остановка и работа с моделями"""
    
    #Сигналы для LM Studio
    sigLog = pyqtSignal(str)                # Лог
    sigError = pyqtSignal(int, str)         # Ошибка
    sigCLIPut = pyqtSignal(str)             # Возвращает путь к cli lms
    sigStudioStarted = pyqtSignal()         # Начата проверка запуска
    sigStudioZapuschen = pyqtSignal()       # LM Studio запущен
    sigStudioOstanovlen = pyqtSignal()      # LM Studio остановлен
    sigStudioStatus = pyqtSignal(bool)      # Статус LM Studio (True - запущен, False - остановлен)
    sigModelsLoaded = pyqtSignal(list)      # Список моделей загружен
    sigModelZagrujena = pyqtSignal(str, int)# (model_name, n_ctx)
    sigModelProgress = pyqtSignal(int)      # Процент загрузки модели (0-100)
    #Сигналы для сервера
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

    # ==================== РАБОТА С ФАЙЛАМИ ====================
    @pyqtSlot(str, result=bool)
    def proverkaFaila(self, file_path: str) -> bool:
        """
        Проверяет, существует ли файл по указанному пути.
        Работает со скрытыми файлами (.file) и путями с ~ (домашняя директория).
        """
        if not file_path or not isinstance(file_path, str):
            return False
            
        try:
            # expanduser() превращает ~/ в /home/user/, что критично для Linux
            # resolve() очищает путь от лишних ./ или ../
            path = Path(file_path).expanduser().resolve()
            
            # is_file() проверяет, что это именно файл, а не папка
            # Если нужно проверить и папку тоже, используйте path.exists()
            return path.is_file()
            
        except Exception:
            # В случае любых ошибок (например, недопустимые символы в пути)
            return False    
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
    
    @pyqtSlot(result=str)
    def poluchitModel(self):
        """Возвращает текущую модель"""
        return self._current_model 
    
    @pyqtSlot(str, int, int)
    def zagruzitModelSParametrami(self, model_name, n_ctx, gpu_offload=50):
        """Публичный слот для загрузки модели с параметрами"""
        if not self._proverkaZapushen():#Проверка запуска LM Studio
            error_msg = "LM Studio не запущен. Сначала запустите приложение."
            self.sigLog.emit(f"✗ {error_msg}")
            self.sigError.emit(6, error_msg)
            return False
        
        # LM Studio запущен, продолжаем загрузку
        success = self._zagruzitModelSParametrami(model_name, n_ctx, gpu_offload)

        if not success:# Ошибка при начале загрузки
            self.sigError.emit(10, f"Не удалось начать загрузку модели {model_name}")
        
        return success 

    # ==================== УПРАВЛЕНИЕ СЕРВЕРОМ ====================
    @pyqtSlot(str)
    def ustPutCLI(self, path):
        """Устанавливает путь к CLI lms"""
        self._cli_path = path
        print(f"✓ Путь к lms CLI: {path}")

    def _naitiLMS_CLI(self):
        """Находит путь к lms CLI"""
        # Если задан пользовательский путь
        if hasattr(self, '_cli_path') and self._cli_path:
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
                self.sigCLIPut.emit(str(path))
                return lms_path
        except:
            pass
        
        error_msg = "CLI lms не найден. Укажите путь в настройках (~/.lmstudio/bin/lms)"
        self.sigError.emit(9, error_msg)
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
            self.sigServerError.emit(error_msg)
            self.sigError.emit(6, error_msg)
            return
        
        # Находим lms CLI
        lms_cli = self._naitiLMS_CLI()
        
        if not lms_cli:
            error_msg = "CLI lms не найден. Укажите путь в настройках (~/.lmstudio/bin/lms)"
            self.sigServerError.emit(error_msg)
            self.sigError.emit(9, error_msg)
            return
        
        try:
            self.sigLog.emit("🔄 Запуск сервера LM Studio...")
            
            # Выполняем команду запуска сервера
            result = subprocess.run(
                [lms_cli, "server", "start"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            if result.returncode == 0:
                self.sigLog.emit("✓ Команда запуска выполнена")
                self._zapustitProverkuServera()
            else:
                error_msg = f"Ошибка выполнения команды: {result.stderr}"
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
        
        except Exception as e:
            error_msg = f"Ошибка остановки сервера: {str(e)}"
            self.sigServerError.emit(error_msg)
            self.sigLog.emit(f"✗ {error_msg}")

    @pyqtSlot()
    def proverkaServera(self):
        """Проверяет, запущен ли сервер LM Studio"""
        zapuschen = self._proverkaServeraZapuschen()
        self._server_zapuschen = zapuschen
        self.sigServerStatus.emit(zapuschen)
        self.sigLog.emit(f"Сервер LM Studio: {zapuschen}")
        return zapuschen

    @pyqtSlot()
    def zapustitProverkuServera(self):
        """Публичный слот для запуска проверки сервера (вызывается из потока)"""
        self._zapustitProverkuServera()

    @pyqtSlot(str, int)
    def zagruzitCherezConfig(self, model_name, n_ctx):
        """Публичный слот для загрузки через конфиг (вызывается из потока)"""
        self._zagruzitCherezConfig(model_name, n_ctx)

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
            self.sigStudioStarted.emit()
            self.sigLog.emit("Ожидание запуска приложения...")
        
        except Exception as e:
            error_msg = f"Ошибка запуска: {str(e)}"
            self.sigError.emit(4, error_msg)
            self._zapusk_v_processe = False
    
    @pyqtSlot()
    def ostanovitStudio(self):
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
                    self.sigStudioOstanovlen.emit()
                    self.sigServerStatus.emit(False)
                else:
                    self.sigLog.emit("LM Studio не запущен")
            
            elif platform.system() == "Darwin":
                subprocess.run(["pkill", "-f", "LM Studio"])
                self._server_zapuschen = False
                self.sigLog.emit("LM Studio остановлен")
                self.sigStudioOstanovlen.emit()
                self.sigServerStatus.emit(False)
            
            elif platform.system() == "Windows":
                subprocess.run(["taskkill", "/F", "/IM", "LM Studio.exe"], shell=True)
                self._server_zapuschen = False
                self.sigLog.emit("LM Studio остановлен")
                self.sigStudioOstanovlen.emit()
                self.sigServerStatus.emit(False)
        
        except Exception as e:
            error_msg = f"Ошибка остановки: {str(e)}"
            self.sigError.emit(5, error_msg)
    
    @pyqtSlot()
    def proverkaStudio(self):
        """Проверяет доступность LM Studio (приложения)"""
        if self._proverkaZapushen():
            self.sigStudioStatus.emit(True)
        else:
            self.sigStudioStatus.emit(False)
    
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

    def _proverkaServeraZapuschen(self):
        """Внутренняя проверка статуса сервера"""
        try:
            response = requests.get(f"{LM_STUDIO_URL}/models", timeout=2)
            return response.status_code == 200
        except:
            return False

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

    def _zagruzitModelSParametrami(self, model_name, n_ctx, gpu_offload):
        """Внутренний метод загрузки модели"""
        lms_cli = self._naitiLMS_CLI()
        
        if not lms_cli:
            self.sigLog.emit("⚠ CLI lms не найден...")
            return self._zagruzitCherezConfig(model_name, n_ctx)
        
        # Запускаем в потоке с новым параметром
        thread = threading.Thread(
            target=self._zagruzitModelVPotoke,
            args=(lms_cli, model_name, n_ctx, gpu_offload),
            daemon=True
        )
        thread.start()
        
        return True

    def _zagruzitModelVPotoke(self, lms_cli, model_name, n_ctx, gpu_offload):
        """Загружает модель в отдельном потоке (не блокирует UI)"""
        import time
        import re
        
        try:
            # УДАЛЕНО: Шаг 1 - Остановка сервера (не нужна!)
            # УДАЛЕНО: Ожидание полной остановки (не нужно!)
            
            # Шаг 1: ВЫГРУЖАЕМ предыдущую модель
            self._vigruzitModel(lms_cli)
            
            # Шаг 2: Преобразуем процент GPU в формат для lms
            if gpu_offload == 0:
                gpu_param = "off"
                gpu_description = "CPU only"
            elif gpu_offload >= 100:
                gpu_param = "max"
                gpu_description = "Full GPU"
            else:
                gpu_param = str(gpu_offload / 100.0)
                gpu_description = f"{gpu_offload}% GPU"
            
            # Шаг 3: Загружаем модель
            self.sigLog.emit("🔄 Загрузка модели с новыми параметрами...")
            self.sigLog.emit(f"   Модель: {model_name}")
            self.sigLog.emit(f"   Контекст: {n_ctx} токенов")
            self.sigLog.emit(f"   GPU: {gpu_description}")
            
            # Излучаем 0% в начале
            self.sigModelProgress.emit(0)
            
            # Формируем команду загрузки
            load_command = [
                lms_cli, "load", model_name, 
                "--context-length", str(n_ctx), 
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
            process.wait(timeout=180)
            
            # Проверяем результат
            if process.returncode == 0:
                # Успех
                self.sigModelProgress.emit(100)
                self.sigLog.emit(f"✓ Модель загружена: {model_name}")
                self.sigLog.emit(f"✓ Контекст: {n_ctx}")
                self.sigLog.emit(f"✓ GPU: {gpu_description}")
                load_success = True
            
            else:
                # Ошибка
                stderr_output = process.stderr.read() if process.stderr else ""
                error_msg = stderr_output.strip() if stderr_output else "Неизвестная ошибка"
                self.sigModelProgress.emit(0)
                
                if "out of memory" in error_msg.lower() or "cuda" in error_msg.lower():
                    self.sigLog.emit(f"⚠ {gpu_description}: не хватает памяти")
                    self.sigLog.emit("🔄 Пробуем альтернативные стратегии GPU...")
                    
                    fallback_strategies = []
                    if gpu_offload >= 100:
                        fallback_strategies = [("0.5", "50% GPU"), ("0.3", "30% GPU"), ("off", "CPU only")]
                    elif gpu_offload >= 50:
                        fallback_strategies = [("0.3", "30% GPU"), ("off", "CPU only")]
                    elif gpu_offload > 0:
                        fallback_strategies = [("off", "CPU only")]
                    
                    load_success = False
                    
                    for fb_gpu, fb_desc in fallback_strategies:
                        self.sigLog.emit(f"🔄 Попытка: {fb_desc}...")
                        self.sigModelProgress.emit(0)
                        
                        fb_command = [
                            lms_cli, "load", model_name, 
                            "--context-length", str(n_ctx), 
                            "--gpu", fb_gpu, 
                            "-y"
                        ]
                        
                        fb_result = subprocess.run(
                            fb_command,
                            capture_output=True,
                            text=True,
                            timeout=180
                        )
                        
                        if fb_result.returncode == 0:
                            self.sigModelProgress.emit(100)
                            self.sigLog.emit(f"✓ Модель загружена: {model_name}")
                            self.sigLog.emit(f"✓ Контекст: {n_ctx}")
                            self.sigLog.emit(f"✓ GPU: {fb_desc} (fallback)")
                            load_success = True
                            break
                        else:
                            fb_error = fb_result.stderr.strip() if fb_result.stderr else ""
                            if "out of memory" in fb_error.lower():
                                self.sigLog.emit(f"⚠ {fb_desc}: всё ещё не хватает памяти")
                                continue
                            else:
                                break
                    
                    if not load_success:
                        self.sigLog.emit(f"✗ Не удалось загрузить модель")
                        self.sigLog.emit(f"   Последняя ошибка: {error_msg[:200]}")
                        self.sigLog.emit("💡 Рекомендации:")
                        self.sigLog.emit("   1. Используйте модель меньшего размера (Q3, Q2)")
                        self.sigLog.emit("   2. Закройте другие приложения, использующие GPU")
                        self.sigLog.emit("   3. Уменьшите контекст (например, до 4096)")
                        
                        self.sigError.emit(10, f"Не удалось загрузить модель {model_name}: {error_msg[:200]}")
                        
                        from PyQt6.QtCore import QMetaObject, Qt, Q_ARG
                        QMetaObject.invokeMethod(
                            self,
                            "zagruzitCherezConfig",
                            Qt.ConnectionType.QueuedConnection,
                            Q_ARG(str, model_name),
                            Q_ARG(int, n_ctx)
                        )
                        return
                
                else:
                    # Ошибка НЕ связана с памятью
                    self.sigLog.emit(f"✗ Ошибка загрузки модели:")
                    self.sigLog.emit(f"   {error_msg[:300]}")
                    
                    if "not found" in error_msg.lower():
                        self.sigLog.emit("💡 Модель не найдена. Проверьте имя модели: lms ls")
                    
                    self.sigError.emit(10, f"Ошибка загрузки модели {model_name}: {error_msg[:300]}")
                    
                    from PyQt6.QtCore import QMetaObject, Qt, Q_ARG
                    QMetaObject.invokeMethod(
                        self,
                        "zagruzitCherezConfig",
                        Qt.ConnectionType.QueuedConnection,
                        Q_ARG(str, model_name),
                        Q_ARG(int, n_ctx)
                    )
                    return
            
            # УДАЛЕНО: Шаг 4 - Запуск сервера обратно (не нужен!)
            # Сервер продолжает работать с новой моделью
            
            # Шаг 5: Сигнал успеха
            self.sigModelZagrujena.emit(model_name, n_ctx)
        
        except subprocess.TimeoutExpired:
            self.sigModelProgress.emit(0)
            error_msg = "Превышено время ожидания загрузки модели (3 мин)"
            self.sigLog.emit(f"✗ {error_msg}")
            self.sigServerError.emit(error_msg)
            self.sigError.emit(10, f"Таймаут при загрузке модели {model_name}")
            
            from PyQt6.QtCore import QMetaObject, Qt, Q_ARG
            QMetaObject.invokeMethod(
                self,
                "zagruzitCherezConfig",
                Qt.ConnectionType.QueuedConnection,
                Q_ARG(str, model_name),
                Q_ARG(int, n_ctx)
            )
        
        except Exception as e:
            self.sigModelProgress.emit(0)
            error_msg = f"Критическая ошибка: {str(e)}"
            self.sigLog.emit(f"✗ {error_msg}")
            self.sigServerError.emit(error_msg)
            self.sigError.emit(10, f"Критическая ошибка при загрузке модели {model_name}: {str(e)}")
            
            from PyQt6.QtCore import QMetaObject, Qt, Q_ARG
            QMetaObject.invokeMethod(
                self,
                "zagruzitCherezConfig",
                Qt.ConnectionType.QueuedConnection,
                Q_ARG(str, model_name),
                Q_ARG(int, n_ctx)
            )

    def _zagruzitCherezConfig(self, model_name, n_ctx):
        """Загрузка модели через обновление конфига + перезапуск сервера"""
        try:
            self.sigLog.emit(f"🔄 Настройка через конфигурацию...")
            
            # Обновляем конфиг
            config_updated = self._ustServerConfig(n_ctx)
            
            if not config_updated:
                self.sigError.emit(10, f"Не удалось обновить конфигурацию для модели {model_name}")
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
                QTimer.singleShot(3000, lambda: self._zapustitServerPosledujushii())
                
                self.sigLog.emit(f"✓ Конфигурация обновлена: контекст {n_ctx}")
                return True
            else:
                self.sigLog.emit(f"✓ Конфигурация обновлена: контекст {n_ctx}")
                self.sigLog.emit("⚠ Запустите сервер для применения изменений")
                return True
        
        except Exception as e:
            error_msg = f"Ошибка настройки через конфиг: {str(e)}"
            self.sigLog.emit(f"✗ {error_msg}")
            self.sigError.emit(10, f"Ошибка настройки конфигурации для модели {model_name}: {str(e)}")
            return False

    def _zapustitServerPosledujushii(self):
        """Вспомогательный метод для отложенного запуска сервера"""
        self.sigLog.emit("🔄 Запуск сервера с новыми параметрами...")
        self.zapustitServer()
