#!/usr/bin/env python3
import subprocess
import os
import sys

def compile_with_binary():
    """Компиляция с использованием бинарного формата"""
    
    if os.path.exists('resources_rc.py'):
        os.remove('resources_rc.py')
    
    rcc = '/usr/lib/qt6/libexec/rcc'
    
    # Используем бинарный формат вместо Python
    cmd = [
        rcc,
        '-binary',
        '-o', 'resources.rcc',
        'resources.qrc'
    ]
    
    try:
        subprocess.run(cmd, check=True)
        
        if os.path.exists('resources.rcc'):
            # Создаем Python обертку для загрузки бинарного ресурса
            with open('resources_rc.py', 'w') as f:
                f.write('''
from PyQt6 import QtCore
import os

def qInitResources():
    """Загружает бинарные ресурсы"""
    resource_path = os.path.join(os.path.dirname(__file__), 'resources.rcc')
    if os.path.exists(resource_path):
        QtCore.QResource.registerResource(resource_path)
        print(f"✅ Ресурсы загружены из: {resource_path}")
        return True
    else:
        print(f"❌ Ресурсы не найдены: {resource_path}")
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
            
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        return False

if __name__ == '__main__':
    if compile_with_binary():
        print("✅ Готово! Запустите main.py")
        sys.exit(0)
    else:
        sys.exit(1)
