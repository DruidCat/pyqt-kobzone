from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSlot, pyqtSignal, QUrl
from PyQt6.QtGui import QDesktopServices
import os
import subprocess
import urllib.parse


class DCFileOpener(QObject):
	"""Класс для открытия файлов в системном приложении"""
	
	signalFileOpened = pyqtSignal(bool, str)  # Сигнал: успех, сообщение
	
	def __init__(self):
		super().__init__()
	
	def _url_to_local_path(self, file_url):
		"""Преобразует URL в локальный путь кроссплатформенно"""
		# Сначала пробуем через QUrl
		url = QUrl(file_url)
		local_path = url.toLocalFile()
		
		# Если toLocalFile() вернул корректный путь
		if local_path and Path(local_path).exists():
			return local_path
		
		# Если не получилось, обрабатываем вручную
		local_path = file_url
		
		# Убираем file:///
		if local_path.startswith("file:///"):
			local_path = local_path[8:]  # Убираем "file:///"
		elif local_path.startswith("file://"):
			local_path = local_path[7:]  # Убираем "file://"
		
		# Декодируем URL-кодирование (%20 → пробел, %D0%94 → кириллица)
		local_path = urllib.parse.unquote(local_path)
		
		# Linux: убираем лишний слеш в начале (если есть)
		# Например: //home/user → /home/user
		if local_path.startswith("//"):
			local_path = local_path[1:]
		
		# Windows: если путь начинается с /C:/, убираем первый /
		if len(local_path) > 2 and local_path[0] == '/' and local_path[2] == ':':
			local_path = local_path[1:]
		
		return local_path
	
	@pyqtSlot(str, result=bool)
	def openFile(self, file_url):
		"""Открывает файл в системном приложении"""
		# Преобразуем URL в локальный путь
		local_path = self._url_to_local_path(file_url)
		file = Path(local_path)
		
		if not file.exists():
			error_msg = f"Файл не найден: {local_path}"
			print(f"✗ {error_msg}")
			self.signalFileOpened.emit(False, error_msg)
			return False
		
		print(f"✓ Открытие файла: {local_path}")
		
		try:
			# Для Linux/Unix используем системные команды напрямую
			# (QDesktopServices иногда передаёт закодированные пути)
			if os.name == 'posix':  # Linux/macOS
				if os.uname().sysname == 'Darwin':  # macOS
					result = subprocess.run(['open', str(file)], 
										  capture_output=True, 
										  text=True)
					if result.returncode == 0:
						print(f"✓ Файл открыт через open (macOS)")
						self.signalFileOpened.emit(True, "Файл открыт")
						return True
					else:
						print(f"✗ Ошибка open: {result.stderr}")
				else:  # Linux
					result = subprocess.run(['xdg-open', str(file)], 
										  capture_output=True, 
										  text=True)
					if result.returncode == 0:
						print(f"✓ Файл открыт через xdg-open (Linux)")
						self.signalFileOpened.emit(True, "Файл открыт")
						return True
					else:
						print(f"✗ Ошибка xdg-open: {result.stderr}")
			
			# Для Windows
			elif os.name == 'nt':
				os.startfile(str(file))
				print(f"✓ Файл открыт через os.startfile (Windows)")
				self.signalFileOpened.emit(True, "Файл открыт")
				return True
			
			# Запасной вариант: через QDesktopServices
			file_url_obj = QUrl.fromLocalFile(str(file))
			if QDesktopServices.openUrl(file_url_obj):
				print(f"✓ Файл открыт через QDesktopServices (запасной вариант)")
				self.signalFileOpened.emit(True, "Файл открыт")
				return True
			
		except Exception as e:
			error_msg = f"Ошибка открытия файла: {e}"
			print(f"✗ {error_msg}")
			self.signalFileOpened.emit(False, error_msg)
			return False
		
		error_msg = "Не удалось открыть файл"
		print(f"✗ {error_msg}")
		self.signalFileOpened.emit(False, error_msg)
		return False
	
	@pyqtSlot(str, result=bool)
	def openFolder(self, folder_url):
		"""Открывает папку в файловом менеджере"""
		# Преобразуем URL в локальный путь
		local_path = self._url_to_local_path(folder_url)
		folder = Path(local_path)
		
		if not folder.exists() or not folder.is_dir():
			error_msg = f"Папка не найдена: {local_path}"
			print(f"✗ {error_msg}")
			self.signalFileOpened.emit(False, error_msg)
			return False
		
		print(f"✓ Открытие папки: {local_path}")
		
		try:
			# Для Linux/Unix используем системные команды напрямую
			if os.name == 'posix':  # Linux/macOS
				if os.uname().sysname == 'Darwin':  # macOS
					result = subprocess.run(['open', str(folder)], 
										  capture_output=True, 
										  text=True)
					if result.returncode == 0:
						print(f"✓ Папка открыта через open (macOS)")
						self.signalFileOpened.emit(True, "Папка открыта")
						return True
				else:  # Linux
					result = subprocess.run(['xdg-open', str(folder)], 
										  capture_output=True, 
										  text=True)
					if result.returncode == 0:
						print(f"✓ Папка открыта через xdg-open (Linux)")
						self.signalFileOpened.emit(True, "Папка открыта")
						return True
			
			# Для Windows
			elif os.name == 'nt':
				os.startfile(str(folder))
				print(f"✓ Папка открыта через os.startfile (Windows)")
				self.signalFileOpened.emit(True, "Папка открыта")
				return True
			
			# Запасной вариант: через QDesktopServices
			folder_url_obj = QUrl.fromLocalFile(str(folder))
			if QDesktopServices.openUrl(folder_url_obj):
				print(f"✓ Папка открыта через QDesktopServices (запасной вариант)")
				self.signalFileOpened.emit(True, "Папка открыта")
				return True
		
		except Exception as e:
			error_msg = f"Ошибка открытия папки: {e}"
			print(f"✗ {error_msg}")
			self.signalFileOpened.emit(False, error_msg)
			return False
		
		error_msg = "Не удалось открыть папку"
		print(f"✗ {error_msg}")
		self.signalFileOpened.emit(False, error_msg)
		return False
