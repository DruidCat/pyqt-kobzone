
from PyQt6 import QtCore
import os

def qInitResources():
    """Загружает бинарные ресурсы"""
    resource_path = os.path.join(os.path.dirname(__file__), 'resources.rcc')
    
    # КРИТИЧНО ДЛЯ WINDOWS: Заменяем обратные слеши на прямые
    resource_path = resource_path.replace("\\", "/").replace("\\", "/")
    
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
