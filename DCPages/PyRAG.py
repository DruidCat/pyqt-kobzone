import os
import sys
import subprocess
import threading
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QThread

class RAGWorker(QThread):
    """Рабочий поток для запуска DCRAGMake.py"""
    
    logMessage = pyqtSignal(str)
    progressUpdate = pyqtSignal(int, int)
    finished = pyqtSignal(bool, str)
    
    def __init__(self, doc_path: str, db_path: str, use_gpu: bool = False, 
                 model_index: int = 0, batch_gpu: int = 8, batch_cpu: int = 4):
        super().__init__()
        self.doc_path = doc_path
        self.db_path = db_path
        self.use_gpu = use_gpu
        self.model_index = model_index
        self.batch_gpu = batch_gpu      # ← Новый параметр
        self.batch_cpu = batch_cpu      # ← Новый параметр
        self.process = None
        self._should_stop = False
    
    def run(self):
        """Запуск DCRAGMake.py с передачей путей"""
        try:
            script_path = Path(__file__).parent.parent / "DCScripts" / "DCRAGMake.py"
            
            if not script_path.exists():
                self.logMessage.emit(f"❌ Ошибка: скрипт не найден: {script_path}")
                self.finished.emit(False, "Скрипт DCRAGMake.py не найден")
                return
            
            # Формируем команду запуска
            cmd = [
                sys.executable,
                str(script_path)
            ]
            
            # Устанавливаем переменные окружения для путей
            env = os.environ.copy()
            env['RAG_DOC_DIR'] = self.doc_path
            env['RAG_DB_DIR'] = self.db_path
            env['RAG_GUI_MODE'] = '1'
            env['RAG_USE_GPU'] = '1' if self.use_gpu else '0'
            env['RAG_MODEL_INDEX'] = str(self.model_index)
            env['RAG_BATCH_GPU'] = str(self.batch_gpu)  # ← Передаём batch_gpu
            env['RAG_BATCH_CPU'] = str(self.batch_cpu)  # ← Передаём batch_cpu
            
            # Запускаем процесс
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                env=env,
                universal_newlines=True
            )
            
            # Читаем вывод построчно
            for line in iter(self.process.stdout.readline, ''):
                if self._should_stop:
                    self.process.terminate()
                    self.logMessage.emit("\n⚠️ Создание RAG остановлено пользователем")
                    self.finished.emit(False, "Остановлено пользователем")
                    return
                
                line = line.rstrip()
                if line:
                    self.logMessage.emit(line)
                    
                    # ПАРСЕР 1: "[2/5] ✓ file.txt"
                    if line.startswith("[") and "/" in line and "]" in line:
                        try:
                            progress_part = line.split("[")[1].split("]")[0]
                            current, total = map(int, progress_part.split("/"))
                            self.progressUpdate.emit(current, total)
                        except:
                            pass
                    
                    # ПАРСЕР 2: "  Обработано 149/14952 фрагментов (1%)"
                    elif "Обработано" in line and "/" in line and "фрагментов" in line:
                        try:
                            parts = line.split("Обработано")[1].split("фрагментов")[0].strip()
                            current, total = map(int, parts.split("/"))
                            self.progressUpdate.emit(current, total)
                        except:
                            pass
            
            # Ждём завершения
            return_code = self.process.wait()
            
            if return_code == 0:
                self.logMessage.emit("\n✅ Создание RAG завершено успешно!")
                self.finished.emit(True, "Создание RAG завершено.")
            else:
                self.logMessage.emit(f"\n❌ Ошибка: код возврата {return_code}")
                self.finished.emit(False, f"Ошибка выполнения (код {return_code})")
        
        except Exception as e:
            self.logMessage.emit(f"\n❌ Критическая ошибка: {str(e)}")
            self.finished.emit(False, str(e))
    
    def stop(self):
        """Остановка процесса"""
        self._should_stop = True
        if self.process and self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()

class DCRAG(QObject):
    """Класс для управления созданием RAG из QML"""
    
    logMessage = pyqtSignal(str)
    progressUpdate = pyqtSignal(int, int)
    sigRAGStarted = pyqtSignal()
    sigRAGFinished = pyqtSignal(bool, str)
    
    def __init__(self):
        super().__init__()
        self.worker = None
    
    @pyqtSlot(str, str, bool, int, int, int)  # ← Добавили два int для batch_size
    def start(self, doc_path: str, db_path: str, use_gpu: bool = False, 
              model_index: int = 0, batch_gpu: int = 8, batch_cpu: int = 4):
        """Запуск создания RAG"""
        # Проверка путей
        if not doc_path or not Path(doc_path).exists():
            self.logMessage.emit(f"❌ Ошибка: папка с документами не существует: {doc_path}")
            return
        
        if not db_path:
            self.logMessage.emit(f"❌ Ошибка: не указана папка для RAG базы данных")
            return
        
        # Проверка индекса модели
        if not 0 <= model_index <= 7:
            self.logMessage.emit(f"❌ Ошибка: неверный индекс модели {model_index}")
            return
        
        # Проверка batch_size
        if not 1 <= batch_gpu <= 256:
            self.logMessage.emit(f"❌ Ошибка: неверный batch_gpu {batch_gpu} (1-256)")
            return
        
        if not 1 <= batch_cpu <= 64:
            self.logMessage.emit(f"❌ Ошибка: неверный batch_cpu {batch_cpu} (1-64)")
            return
        
        # Создаём выходную папку если её нет
        try:
            Path(db_path).mkdir(parents=True, exist_ok=True)
        except Exception as e:
            self.logMessage.emit(f"❌ Ошибка создания папки: {e}")
            return
        
        # Останавливаем предыдущий процесс если есть
        if self.worker and self.worker.isRunning():
            self.logMessage.emit("⚠️ Создание RAG уже запущено")
            return
        
        # Создаём рабочий поток с batch_size
        self.worker = RAGWorker(doc_path, db_path, use_gpu, model_index, 
                                batch_gpu, batch_cpu)  # ← Передаём batch_size
        self.worker.logMessage.connect(self.logMessage.emit)
        self.worker.progressUpdate.connect(self.progressUpdate.emit)
        self.worker.finished.connect(self._on_finished)
        
        self.sigRAGStarted.emit()
        self.worker.start()
    
    @pyqtSlot()
    def stop(self):
        """Остановка создания RAG"""
        if self.worker and self.worker.isRunning():
            self.logMessage.emit("\n⏹️ Останавливаем создание RAG...")
            self.worker.stop()
        else:
            self.logMessage.emit("⚠️ Создание RAG не запущено")
    
    def _on_finished(self, success: bool, message: str):
        """Обработчик завершения"""
        self.sigRAGFinished.emit(success, message)
