#!/usr/bin/env python3
import subprocess
import os
import sys
import shutil
import platform
from PyQt6.QtCore import QLibraryInfo

def get_rcc_path():
    """Автоматически находит путь к утилите rcc для любой ОС"""
    is_windows = platform.system() == "Windows"
    rcc_name = "rcc.exe" if is_windows else "rcc"

    # 1. Ищем в системном PATH
    rcc_path = shutil.which(rcc_name)
    if rcc_path:
        return rcc_path

    # 2. Спрашиваем у PyQt6 (самый надежный вариант)
    paths_to_check = [
        QLibraryInfo.path(QLibraryInfo.LibraryPath.BinariesPath),
        QLibraryInfo.path(QLibraryInfo.LibraryPath.LibraryExecutablesPath)
    ]
    for qt_path in paths_to_check:
        if qt_path:
            candidate = os.path.join(qt_path, rcc_name)
            if os.path.isfile(candidate):
                return candidate

    # 3. Ищем в папке Scripts виртуального окружения
    venv_path = os.path.dirname(sys.executable)
    venv_candidate = os.path.join(venv_path, rcc_name)
    if os.path.isfile(venv_candidate):
        return venv_candidate

    return None

def compile_with_binary():
    """Компиляция с использованием бинарного формата"""
    
    if os.path.exists('resources_rc.py'):
        os.remove('resources_rc.py')
    if os.path.exists('resources.rcc'):
        os.remove('resources.rcc')
    
    rcc = get_rcc_path()
    if not rcc:
        print("❌ Критическая ошибка: утилита rcc не найдена в системе!")
        print("   Убедитесь, что PyQt6/PySide6 установлены корректно.")
        return False
        
    print(f"ℹ️  Найден rcc: {rcc}")
    
    # Используем бинарный формат. 
    # ВАЖНО: --compress-algo zlib гарантирует, что PyQt6 на Windows сможет прочитать файл
    cmd = [
        rcc,
        '-binary',
        '--compress-algo', 'zlib', 
        '-o', 'resources.rcc',
        'resources.qrc'
    ]
    
    try:
        subprocess.run(cmd, check=True)
        
        if os.path.exists('resources.rcc'):
            # Создаем Python обертку с ИСПРАВЛЕННЫМИ СЛЕШАМИ для Windows
            with open('resources_rc.py', 'w', encoding='utf-8') as f:
                f.write('''
from PyQt6 import QtCore
import os

def qInitResources():
    """Загружает бинарные ресурсы"""
    resource_path = os.path.join(os.path.dirname(__file__), 'resources.rcc')
    
    # КРИТИЧНО ДЛЯ WINDOWS: Заменяем обратные слеши на прямые
    resource_path = resource_path.replace("\\\\", "/")
    
    if os.path.exists(resource_path):
        # Обязательно проверяем, что Qt действительно загрузил ресурсы
        success = QtCore.QResource.registerResource(resource_path)
        if success:
            print(f"✅ Ресурсы успешно загружены из: {resource_path}")
            return True
        else:
            print(f"❌ ОШИБКА: Qt не смог зарегистрировать ресурсы! (возможно поврежден алгоритм сжатия)")
            return False
    else:
        print(f"❌ Ресурсы не найдены на диске: {resource_path}")
        return False

def qCleanupResources():
    """Очищает ресурсы"""
    pass

# Автоматически загружаем ресурсы
qInitResources()
''')
            
            print("✅ Скомпилировано в бинарный формат")
            print("   Файл: resources.rcc")
            return True
            
    except subprocess.CalledProcessError as e:
        print(f"❌ Ошибка компиляции rcc: {e}")
        return False
    except Exception as e:
        print(f"❌ Непредвиденная ошибка: {e}")
        return False

if __name__ == '__main__':
    if compile_with_binary():
        print("\n✅ Готово! Запустите main.py")
        sys.exit(0)
    else:
        sys.exit(1)
