import sys
from pathlib import Path
from PyQt6.QtWidgets import QApplication
from PyQt6.QtQml import QQmlApplicationEngine
from PyQt6.QtCore import QObject, pyqtSlot, QUrl, pyqtProperty, pyqtSignal
from PyQt6.QtGui import QFontDatabase, QFont

from DCPages.PyAnalizer import DCAnalyzer
from DCPages.PyTranscribe import DCTranscribe
from DCPages.PyJurnal import DCJurnal
from DCScripts.DCFileOpener import DCFileOpener
import resources_rc


class PythonInfo(QObject):
    """Предоставляет информацию о версии Python"""
    
    pythonVersionChanged = pyqtSignal()
    pythonImplementationChanged = pyqtSignal()
    pythonExecutableChanged = pyqtSignal()
    
    def __init__(self):
        super().__init__()
    
    @pyqtProperty(str, notify=pythonVersionChanged)
    def pythonVersion(self):
        return sys.version
    
    @pyqtProperty(str, notify=pythonImplementationChanged)
    def pythonImplementation(self):
        return sys.implementation.name

    @pyqtProperty(str, notify=pythonExecutableChanged)
    def pythonExecutable(self):
        return sys.executable


class QtInfo(QObject):
    """Предоставляет информацию о версии Qt"""
    
    qtVersionChanged = pyqtSignal()
    qtMajorVersionChanged = pyqtSignal()
    qtMinorVersionChanged = pyqtSignal()
    
    def __init__(self):
        super().__init__()
    
    @pyqtProperty(str, notify=qtVersionChanged)
    def qtVersion(self):
        from PyQt6.QtCore import QT_VERSION_STR
        return QT_VERSION_STR
    
    @pyqtProperty(str, notify=qtMajorVersionChanged)
    def qtMajorVersion(self):
        from PyQt6.QtCore import QT_VERSION_MAJOR
        return str(QT_VERSION_MAJOR)
    
    @pyqtProperty(str, notify=qtMinorVersionChanged)
    def qtMinorVersion(self):
        from PyQt6.QtCore import QT_VERSION_MINOR
        return str(QT_VERSION_MINOR)

def _get_git_version():
    """Получает версию из git"""
    try:
        import subprocess
        result = subprocess.run(
            ['git', 'describe', '--tags', '--always'],
            capture_output=True,
            text=True,
            timeout=1,
            cwd=Path(__file__).parent
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except:
        pass
    return "1.0.0-dev"


class MainApp:
    """Главный класс приложения"""
    
    MAIN_QML_FILE = "ru.KOBzone.qml"
    APP_NAME = "KOBzone"
    APP_ORGANIZATION = "DruidCat"
    APP_VERSION = _get_git_version()
    
    def __init__(self):
        self.app = QApplication(sys.argv)
        
        # Устанавливаем метаданные приложения
        self.app.setApplicationName(self.APP_NAME)
        self.app.setOrganizationName(self.APP_ORGANIZATION)
        self.app.setApplicationVersion(self.APP_VERSION)
        
        self.engine = QQmlApplicationEngine()
        
        self.analyzer = DCAnalyzer()#Иннициализация DCAnalizer
        self.transcriber = DCTranscribe()#Инициализация DCTranscribe
        self.jurnal = DCJurnal()# Инициализация DCJurnal
        self.file_opener = DCFileOpener()#Открытие файлов и папок
        self.python_info = None
        self.qt_info = None
        
        # Загружаем шрифт
        self.load_custom_font()
        
        self.setup_qml()
    
    def load_custom_font(self):
        """Загрузка кастомного шрифта из ресурсов"""
        font_id = QFontDatabase.addApplicationFont(":/resources/fonts/MesloLGSRegular.ttf")
        
        if font_id != -1:
            font_families = QFontDatabase.applicationFontFamilies(font_id)
            if font_families:
                font_family = font_families[0]
                print(f"✓ Шрифт загружен: {font_family}")
                self.app.setFont(QFont(font_family))
                return font_family
            else:
                print("✗ Ошибка: не удалось получить имя семейства шрифта")
        else:
            print("✗ Ошибка: не удалось загрузить шрифт")
        
        return None
        
    def setup_qml(self):
        """Настройка QML и связей с Python"""
        
        project_dir = Path(__file__).parent
        
        self.engine.addImportPath(str(project_dir))
        
        print(f"✓ Добавлен путь импорта: {project_dir}")
        
        # Проверка qmldir файлов
        for module_name in ["DCButtons", "DCMethods", "DCPages", "DCSettings"]:
            module_path = project_dir / module_name
            qmldir_file = module_path / "qmldir"
            
            if qmldir_file.exists():
                print(f"✓ Модуль {module_name}: {qmldir_file}")
            else:
                print(f"✗ ОШИБКА: qmldir не найден для {module_name}")
        
        print(f"✓ Qt ресурсы загружены (resources_rc.py)")
        
        # Создаём ВСЕ объекты ДО загрузки QML
        self.python_info = PythonInfo()
        self.qt_info = QtInfo()
        
        # РЕГИСТРИРУЕМ КОНТЕКСТНЫЕ СВОЙСТВА.
        self.engine.rootContext().setContextProperty("analyzer", self.analyzer)
        self.engine.rootContext().setContextProperty("transcriber", self.transcriber)
        self.engine.rootContext().setContextProperty("jurnal", self.jurnal)#доступен в QML как "jurnal"
        self.engine.rootContext().setContextProperty("fileOpener", self.file_opener)#доступен в QML fileOpener
        self.engine.rootContext().setContextProperty("pythonInfo", self.python_info)
        self.engine.rootContext().setContextProperty("qtInfo", self.qt_info)
        
        print(f"✓ Все контекстные свойства установлены (версия: {self.APP_VERSION})")
        
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
        
        # Обновляем callbacks после загрузки QML
        root = self.engine.rootObjects()[0]
        
        def update_content(text):
            content_area = root.findChild(QObject, "contentArea")
            if content_area:
                content_area.setProperty("text", text)
            else:
                print("✗ contentArea не найден")
        
        def update_filename(path):
            self.analyzer.setCurrentFilename(path)
            print(f"✓ Установлено имя файла: {Path(path).name}")
        
    def run(self):
        """Запуск приложения"""
        return self.app.exec()


def main():
    """Точка входа"""
    app = MainApp()
    sys.exit(app.run())


if __name__ == '__main__':
    main()
