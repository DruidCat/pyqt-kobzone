from pathlib import Path
from datetime import datetime, timedelta
from PyQt6.QtCore import QObject, pyqtSlot, pyqtSignal


class DCJurnal(QObject):
	"""Класс для работы с журналом логов"""
	
	logWritten = pyqtSignal(str)  # Сигнал при успешной записи лога
	logReadFinished = pyqtSignal(str)  # Сигнал при чтении логов
	
	def __init__(self):
		super().__init__()
		self.log_file = Path(__file__).parent.parent / "logs.txt"
		
		# Создаём файл логов, если его нет
		if not self.log_file.exists():
			self.log_file.parent.mkdir(parents=True, exist_ok=True)
			self.log_file.touch()
			print(f"✓ Создан файл логов: {self.log_file}")
		else:
			print(f"✓ Файл логов найден: {self.log_file}")
	
	@pyqtSlot(str)
	def writeLog(self, strLog):
		"""Записывает лог в файл с меткой времени"""
		if not strLog or strLog.strip() == "":
			return
		
		try:
			# Формируем строку с временной меткой
			timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
			log_entry = f"{timestamp} {strLog}\n"
			
			# Записываем в файл
			with open(self.log_file, 'a', encoding='utf-8') as f:
				f.write(log_entry)
			
			print(f"✓ Лог записан: {log_entry.strip()}")
			self.logWritten.emit(log_entry.strip())
			
		except Exception as e:
			print(f"✗ Ошибка записи лога: {e}")
	
	@pyqtSlot(result=str)
	def polDebugNedelya(self):
		"""Получает логи за последнюю неделю"""
		return self._get_logs_for_period(days=7)
	
	@pyqtSlot(result=str)
	def polDebugMesyac(self):
		"""Получает логи за последний месяц"""
		return self._get_logs_for_period(days=30)
	
	@pyqtSlot(result=str)
	def polDebugGod(self):
		"""Получает логи за последний год"""
		return self._get_logs_for_period(days=365)
	
	def _get_logs_for_period(self, days):
		"""Внутренняя функция для получения логов за указанный период"""
		try:
			if not self.log_file.exists():
				return "[Файл логов не найден]"
			
			# Вычисляем дату начала периода
			start_date = datetime.now() - timedelta(days=days)
			
			# Читаем все логи
			with open(self.log_file, 'r', encoding='utf-8') as f:
				all_logs = f.readlines()
			
			# Фильтруем логи по дате
			filtered_logs = []
			
			for log_line in all_logs:
				try:
					# Извлекаем временную метку (первые 19 символов: "YYYY-MM-DD HH:MM:SS")
					if len(log_line) < 19:
						continue
					
					timestamp_str = log_line[:19]
					log_date = datetime.strptime(timestamp_str, "%Y-%m-%d %H:%M:%S")
					
					# Если дата попадает в период — добавляем
					if log_date >= start_date:
						filtered_logs.append(log_line.rstrip())
				
				except ValueError:
					# Если не удалось распарсить дату — пропускаем строку
					continue
			
			if not filtered_logs:
				period_name = {7: "неделю", 30: "месяц", 365: "год"}
				return f"[Нет логов за последнюю {period_name.get(days, 'период')}]"
			
			# Формируем итоговую строку
			result = "\n".join(filtered_logs)
			
			print(f"✓ Загружено логов за {days} дней: {len(filtered_logs)} записей")
			self.logReadFinished.emit(result)
			
			return result
		
		except Exception as e:
			error_msg = f"[Ошибка чтения логов: {str(e)}]"
			print(f"✗ {error_msg}")
			return error_msg
	
	@pyqtSlot(result=str)
	def getAllLogs(self):
		"""Получает все логи из файла"""
		try:
			if not self.log_file.exists():
				return "[Файл логов не найден]"
			
			with open(self.log_file, 'r', encoding='utf-8') as f:
				content = f.read()
			
			if not content.strip():
				return "[Журнал логов пуст]"
			
			return content
		
		except Exception as e:
			return f"[Ошибка чтения логов: {str(e)}]"
	
	@pyqtSlot()
	def clearLogs(self):
		"""Очищает файл логов"""
		try:
			with open(self.log_file, 'w', encoding='utf-8') as f:
				f.write("")
			
			print("✓ Журнал логов очищен")
			self.logWritten.emit("[Журнал очищен]")
		
		except Exception as e:
			print(f"✗ Ошибка очистки логов: {e}")
