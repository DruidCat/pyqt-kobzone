from PyQt6.QtCore import QObject, pyqtSlot
# DCConsoleLog.py
class DCConsoleLog(QObject):

    def __init__(self, parent = None):
        super().__init__()

    @pyqtSlot(str)
    def log(self, message: str):
        """Выводит сообщение в консоль с форматированием"""
        print(f"log: {message}")
