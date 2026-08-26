import requests
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot

LM_STUDIO_URL = "http://localhost:1234/v1"


class DCModelManager(QObject):
    """Менеджер моделей LM Studio"""
    
    # Сигналы
    sigModelsLoaded = pyqtSignal(list)  # Список моделей загружен
    sigModelChanged = pyqtSignal(str)   # Модель изменена
    sigError = pyqtSignal(str)          # Ошибка
    
    def __init__(self):
        super().__init__()
        self._current_model = ""
        self._models_list = []
    
    @pyqtSlot()
    def zagruzitModeli(self):
        """Загружает список доступных моделей из LM Studio"""
        try:
            response = requests.get(
                f"{LM_STUDIO_URL}/models",
                timeout=5
            )
            
            if response.status_code == 200:
                data = response.json()
                
                # LM Studio возвращает: {"data": [{"id": "model-name"}, ...]}
                models = []
                
                # Добавляем опцию "Автовыбор"
                models.append("(автовыбор модели)")
                
                # Добавляем реальные модели
                for model_info in data.get("data", []):
                    model_id = model_info.get("id", "")
                    # Фильтруем embedding-модели
                    if model_id and "embed" not in model_id.lower():
                        models.append(model_id)                

                self._models_list = models
                self.sigModelsLoaded.emit(models)
                
                print(f"✓ Загружено моделей: {len(models) - 1}")  # -1 = без "автовыбора"
                
            else:
                error_msg = f"Ошибка {response.status_code}: {response.text}"
                print(f"✗ {error_msg}")
                self.sigError.emit(error_msg)
                
                # Возвращаем хотя бы "автовыбор"
                self.sigModelsLoaded.emit(["(автовыбор модели)"])
        
        except requests.exceptions.ConnectionError:
            error_msg = f"Не удалось подключиться к LM Studio ({LM_STUDIO_URL})"
            print(f"✗ {error_msg}")
            self.sigError.emit(error_msg)
            self.sigModelsLoaded.emit(["(автовыбор модели)"])
        
        except Exception as e:
            error_msg = f"Ошибка загрузки моделей: {str(e)}"
            print(f"✗ {error_msg}")
            self.sigError.emit(error_msg)
            self.sigModelsLoaded.emit(["(автовыбор модели)"])
    
    @pyqtSlot(str)
    def ustModel(self, model_name):
        """Устанавливает выбранную модель"""
        if model_name == "(автовыбор модели)":
            self._current_model = ""  # Пустая строка = автовыбор
        else:
            self._current_model = model_name
        
        self.sigModelChanged.emit(self._current_model)
        print(f"✓ Выбрана модель: {model_name}")
    
    @pyqtSlot(result=str)
    def poluchitModel(self):
        """Возвращает текущую модель"""
        return self._current_model
