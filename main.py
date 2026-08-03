import sys
from pathlib import Path
from PyQt6.QtWidgets import QApplication, QFileDialog
from PyQt6.QtQml import QQmlApplicationEngine
from PyQt6.QtCore import QObject, pyqtSlot, QUrl

from text_analyzer import TextAnalyzer
import resources_rc # Импорт скомпилированных ресурсов

class FileManager(QObject):
    """Управление файлами через QML"""
    
    def __init__(self, content_callback):
        super().__init__()
        self.content_callback = content_callback
    
    @pyqtSlot()
    def load_file(self):
        """Открывает диалог выбора файла и загружает содержимое"""
        file_path, _ = QFileDialog.getOpenFileName(
            None,
            "Выберите текстовый файл",
            str(Path.home()),
            "Текстовые файлы (*.txt);;Все файлы (*.*)"
        )
        
        if file_path:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                self.content_callback(content)
            except Exception as e:
                print(f"Ошибка при загрузке файла: {e}")
                self.content_callback(f"[Ошибка загрузки: {str(e)}]")


class MainApp:
    """Главный класс приложения"""
    
    MAIN_QML_FILE = "ru.KOBzone.qml"  # ← Исправлено название!
    
    def __init__(self):
        self.app = QApplication(sys.argv)
        self.engine = QQmlApplicationEngine()
        
        self.analyzer = TextAnalyzer()
        self.file_manager = None
        
        self.setup_qml()
        
    def setup_qml(self):
        """Настройка QML и связей с Python"""
        
        project_dir = Path(__file__).parent
        
        # Добавляем пути к модулям
        self.engine.addImportPath(str(project_dir))
        
        print(f"✓ Добавлен путь импорта: {project_dir}")
        
        # Проверка qmldir файлов
        for module_name in ["DCButtons", "DCPages"]:
            module_path = project_dir / module_name
            qmldir_file = module_path / "qmldir"
            
            if qmldir_file.exists():
                print(f"✓ Модуль {module_name}: {qmldir_file}")
            else:
                print(f"✗ ОШИБКА: qmldir не найден для {module_name}")
        
        # Регистрируем объекты в QML контексте
        self.engine.rootContext().setContextProperty("analyzer", self.analyzer)
        
        # Загружаем главный QML файл
        qml_file = project_dir / self.MAIN_QML_FILE
        
        if not qml_file.exists():
            print(f"✗ ОШИБКА: QML файл не найден: {qml_file}")
            sys.exit(-1)
        
        print(f"✓ Загрузка QML: {qml_file}")
        
        self.engine.load(QUrl.fromLocalFile(str(qml_file)))
        
        if not self.engine.rootObjects():
            print("✗ Ошибка загрузки QML")
            sys.exit(-1)
        
        print("✓ QML успешно загружен")
        
        # Получаем корневой объект
        root = self.engine.rootObjects()[0]
        
        # Callback для обновления contentArea
        def update_content(text):
            content_area = root.findChild(QObject, "contentArea")
            if content_area:
                content_area.setProperty("text", text)
            else:
                print("✗ contentArea не найден")
        
        self.file_manager = FileManager(update_content)
        self.engine.rootContext().setContextProperty("window", self.file_manager)
    
    def run(self):
        """Запуск приложения"""
        return self.app.exec()


def main():
    """Точка входа"""
    app = MainApp()
    sys.exit(app.run())


if __name__ == '__main__':
    main()
