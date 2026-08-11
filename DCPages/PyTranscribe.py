import os
import sys
import subprocess
import threading
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QThread

"""Python-бэкенд"""
class TranscriberWorker(QThread):
    """Рабочий поток для запуска DCTranscribe.py"""
    
    logMessage = pyqtSignal(str)#Сообщения из скрипта
    progressUpdate = pyqtSignal(int, int)#(текущий файл, всего файлов)
    finished = pyqtSignal(bool, str)#(успех, финальное сообщение)
    
    def __init__(self, audio_path: str, text_path: str):
        super().__init__()
        self.audio_path = audio_path
        self.text_path = text_path
        self.process = None
        self._should_stop = False

    def run(self):
        """Запуск DCTranscribe.py с передачей путей"""
        try:
            script_path = Path(__file__).parent.parent / "DCScripts" / "DCTranscribe.py"
            
            if not script_path.exists():
                self.logMessage.emit(f"❌ Ошибка: скрипт не найден: {script_path}")#Сообщение в программу
                self.finished.emit(False, "Скрипт DCTranscribe.py не найден")#Сообщение в консоль
                return
            #Формируем команду запуска
            cmd = [
                sys.executable,
                str(script_path)
            ]
            #Устанавливаем переменные окружения для путей
            env = os.environ.copy()
            env['TRANSCRIBE_INPUT_DIR'] = self.audio_path
            env['TRANSCRIBE_OUTPUT_DIR'] = self.text_path
            env['TRANSCRIBE_GUI_MODE'] = '1' #Включаем GUI режим
            #Запускаем процесс
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                env=env,
                universal_newlines=True
            )
            #Читаем вывод построчно
            for line in iter(self.process.stdout.readline, ''):
                if self._should_stop:
                    self.process.terminate()
                    self.logMessage.emit("\n⚠️ Транскрибация остановлена пользователем")#Сообщение в программу
                    self.finished.emit(False, "Остановлено пользователем")#Сообщение в консоль
                    return
                
                line = line.rstrip()
                if line:
                    self.logMessage.emit(line)
                    #Парсим прогресс из вывода. Пример: "📂 (2/5) файл.m4a"
                    if line.startswith("📂 (") and "/" in line:
                        try:
                            progress_part = line.split("(")[1].split(")")[0]
                            current, total = map(int, progress_part.split("/"))
                            self.progressUpdate.emit(current, total)
                        except:
                            pass
            
            #Ждём завершения
            return_code = self.process.wait()
            
            if return_code == 0:
                self.logMessage.emit("\n✅ Транскрибация завершена успешно!")#Сообщение в программу
                self.finished.emit(True, "Транскрибация завершена.")#Сообщение в консоль
            else:
                self.logMessage.emit(f"\n❌ Ошибка: код возврата {return_code}")#Сообщение в программу
                self.finished.emit(False, f"Ошибка выполнения (код {return_code})")#Сообщение в консоль
        
        except Exception as e:
            self.logMessage.emit(f"\n❌ Критическая ошибка: {str(e)}")#Сообщение в программу
            self.finished.emit(False, str(e))#Сообщение в консоль

    def stop(self):
        """Остановка процесса"""
        self._should_stop = True
        if self.process and self.process.poll() is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()


class DCTranscribe(QObject):
    """Класс для управления транскрибацией из QML"""
    logMessage = pyqtSignal(str)
    progressUpdate = pyqtSignal(int, int)
    transcriptionStarted = pyqtSignal()
    transcriptionFinished = pyqtSignal(bool, str)
    
    def __init__(self):
        super().__init__()
        self.worker = None
    
    @pyqtSlot(str, str)
    def start(self, audio_path: str, text_path: str):
        """Запуск транскрибации"""
        #Проверка путей
        if not audio_path or not Path(audio_path).exists():
            self.logMessage.emit(f"❌ Ошибка: папка с аудио не существует: {audio_path}")
            return
        if not text_path:
            self.logMessage.emit(f"❌ Ошибка: не указана папка для сохранения результатов")
            return
        #Создаём выходную папку если её нет
        try:
            Path(text_path).mkdir(parents=True, exist_ok=True)
        except Exception as e:
            self.logMessage.emit(f"❌ Ошибка создания папки: {e}")
            return
        #Останавливаем предыдущий процесс если есть
        if self.worker and self.worker.isRunning():
            self.logMessage.emit("⚠️ Транскрибация уже запущена")
            return
        #Создаём рабочий поток
        self.worker = TranscriberWorker(audio_path, text_path)
        self.worker.logMessage.connect(self.logMessage.emit)
        self.worker.progressUpdate.connect(self.progressUpdate.emit)
        self.worker.finished.connect(self._on_finished)
        
        self.transcriptionStarted.emit()
        self.worker.start()
    
    @pyqtSlot()
    def stop(self):
        """Остановка транскрибации"""
        if self.worker and self.worker.isRunning():
            self.logMessage.emit("\n⏹️ Останавливаем транскрибацию...")
            self.worker.stop()
        else:
            self.logMessage.emit("⚠️ Транскрибация не запущена")
    
    def _on_finished(self, success: bool, message: str):
        """Обработчик завершения"""
        self.transcriptionFinished.emit(success, message)
