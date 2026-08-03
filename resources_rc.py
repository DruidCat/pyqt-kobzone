
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
