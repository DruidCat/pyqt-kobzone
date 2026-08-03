import sys
from pathlib import Path
from PyQt6.QtWidgets import QApplication, QFileDialog
from PyQt6.QtQml import QQmlApplicationEngine
from PyQt6.QtCore import QObject, pyqtSlot, QUrl

from text_analyzer import TextAnalyzer


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
    
    # Константа с именем главного QML файла
    MAIN_QML_FILE = "ru.KOBzone.qml"
    
    def __init__(self):
        self.app = QApplication(sys.argv)
        self.engine = QQmlApplicationEngine()
        
        # Создаем компоненты
        self.analyzer = TextAnalyzer()
        self.file_manager = None
        
        # Настраиваем QML движок
        self.setup_qml()
        
    def setup_qml(self):
        """Настройка QML и связей с Python"""
        
        # Добавляем путь к кастомным компонентам DCButtons
        project_dir = Path(__file__).parent
        dcbuttons_path = project_dir / "DCButtons"
        
        # Добавляем путь импорта для QML модулей
        self.engine.addImportPath(str(project_dir))
        
        print(f"Добавлен путь импорта: {project_dir}")
        print(f"Путь к DCButtons: {dcbuttons_path}")
        
        # Проверка существования qmldir
        qmldir_file = dcbuttons_path / "qmldir"
        if qmldir_file.exists():
            print(f"✓ Файл qmldir найден: {qmldir_file}")
        else:
            print(f"✗ ОШИБКА: Файл qmldir не найден: {qmldir_file}")
        
        # Регистрируем analyzer в QML контексте
        self.engine.rootContext().setContextProperty("analyzer", self.analyzer)
        
        # Загружаем главный QML файл
        qml_file = project_dir / self.MAIN_QML_FILE
        
        # Проверяем существование файла
        if not qml_file.exists():
            print(f"✗ ОШИБКА: QML файл не найден: {qml_file}")
            print(f"Текущая директория: {project_dir}")
            print(f"Файлы в директории:")
            for f in project_dir.glob("*.qml"):
                print(f"  - {f.name}")
            sys.exit(-1)
        
        print(f"✓ Загрузка QML файла: {qml_file}")
        
        self.engine.load(QUrl.fromLocalFile(str(qml_file)))
        
        if not self.engine.rootObjects():
            print("✗ Ошибка: не удалось загрузить QML файл")
            sys.exit(-1)
        
        print("✓ QML файл успешно загружен")
        
        # Получаем корневой объект
        root = self.engine.rootObjects()[0]
        
        # Создаем file_manager с callback для обновления contentArea
        def update_content(text):
            content_area = root.findChild(QObject, "contentArea")
            if content_area:
                content_area.setProperty("text", text)
        
        self.file_manager = FileManager(update_content)
        
        # Регистрируем file_manager как window в QML
        self.engine.rootContext().setContextProperty("window", self.file_manager)
    
    def run(self):
        """Запуск приложения"""
        return self.app.exec()


def main():
    """Точка входа в приложение"""
    app = MainApp()
    sys.exit(app.run())


if __name__ == '__main__':
    main()
