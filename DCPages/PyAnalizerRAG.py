import os
import pickle
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSlot, pyqtSignal

class DCAnalizerRAG(QObject):
    """Управление загрузкой и поиском по RAG базе данных"""
    sigLog = pyqtSignal(str)
    
    def __init__(self):
        super().__init__()
        self._index = None
        self._documents = []
        self._embedder = None
        self._current_rag_path = ""
        self._is_loaded = False
        self._model_name = ""

    @pyqtSlot(str)
    def ustRagPath(self, rag_path: str):
        """Устанавливает путь к RAG базе и сбрасывает кэш для перезагрузки"""
        # Убираем префикс file:// если он вдруг попал сюда из QML
        if rag_path.startswith("file://"):
            rag_path = rag_path.replace("file://", "").replace("file:", "")
            
        self._current_rag_path = rag_path
        self._is_loaded = False # Сбрасываем, чтобы при следующем запросе данные обновились
        if rag_path:
            self.sigLog.emit(f"✓ Путь к RAG базе установлен: {rag_path}")
        else:
            self.sigLog.emit("⚠ RAG отключен: путь очищен")

    def _load_rag_data(self) -> bool:
        """Ленивая загрузка FAISS индекса и модели эмбеддингов"""
        if self._is_loaded and self._index is not None:
            return True

        if not self._current_rag_path or not os.path.exists(self._current_rag_path):
            self.sigLog.emit("⚠ Путь к RAG базе не задан или не существует")
            return False

        try:
            import faiss
            from sentence_transformers import SentenceTransformer

            index_dir = self._current_rag_path
            
            # 1. Читаем имя модели из конфигурации базы
            config_path = os.path.join(index_dir, "model_config.txt")
            if os.path.exists(config_path):
                with open(config_path, "r", encoding="utf-8") as f:
                    self._model_name = f.read().strip()
            else:
                self._model_name = "sentence-transformers/all-MiniLM-L6-v2" # Fallback
                self.sigLog.emit(f"⚠ model_config.txt не найден, используется модель по умолчанию: {self._model_name}")

            # 2. Загружаем модель эмбеддингов (только если она сменилась или не загружена)
            if self._embedder is None or getattr(self._embedder, 'rag_model_name', None) != self._model_name:
                self.sigLog.emit(f"🔄 Загрузка модели эмбеддингов для RAG: {self._model_name}...")
                self._embedder = SentenceTransformer(self._model_name)
                self._embedder.rag_model_name = self._model_name # Метка для проверки
                self.sigLog.emit("✓ Модель эмбеддингов RAG загружена в память")

            # 3. Загружаем FAISS индекс и документы
            self.sigLog.emit("🔄 Загрузка индекса FAISS и документов...")
            index_file = os.path.join(index_dir, "index.faiss")
            docs_file = os.path.join(index_dir, "documents.pkl")
            
            if not os.path.exists(index_file) or not os.path.exists(docs_file):
                raise FileNotFoundError("Файлы index.faiss или documents.pkl отсутствуют в папке RAG")

            self._index = faiss.read_index(index_file)
            
            with open(docs_file, "rb") as f:
                self._documents = pickle.load(f)
                
            self._is_loaded = True
            self.sigLog.emit(f"✓ RAG база успешно загружена: {len(self._documents)} фрагментов")
            return True

        except Exception as e:
            self.sigLog.emit(f"✗ Критическая ошибка загрузки RAG базы: {str(e)}")
            self._is_loaded = False
            return False

    @pyqtSlot(str, int, result=str)
    def poluchitKontekst(self, query: str, top_k: int = 3) -> str:
        """Ищет наиболее релевантные фрагменты по тексту запроса"""
        if not self._load_rag_data():
            return ""

        try:
            # Кодируем запрос пользователя в вектор
            query_embedding = self._embedder.encode([query], convert_to_tensor=False)
            
            # Ищем ближайшие векторы в FAISS
            distances, indices = self._index.search(query_embedding, top_k)
            
            # Собираем результаты в читаемый текст
            context_parts = []
            for i, idx in enumerate(indices[0]):
                if idx != -1 and idx < len(self._documents): # -1 означает, что FAISS не нашел ничего
                    doc = self._documents[idx]
                    dist = distances[0][i]
                    context_parts.append(f"[Источник {i+1}]:\n{doc}\n")
            
            if not context_parts:
                return ""
                
            return "\n---\n".join(context_parts)
        
        except Exception as e:
            self.sigLog.emit(f"✗ Ошибка поиска в RAG: {str(e)}")
            return ""

"""
Как это работает:
1. Пользователь выбирает папку через knopkaRAG -> путь сохраняется в DCSettings.analizer_put_rag.
2. Пользователь нажимает "Анализировать".
3. StrAnalizer.qml вызывает pyAnalizerRAG.ustRagPath, передавая путь.
4. PyAnalizer.py начинает работу, видит, что rag_enabled == True, и берет первые 300 символов промпта пользователя.
5. Он передает эти 300 символов в PyAnalizerRAG.py.
6. PyAnalizerRAG.py (если еще не загружена) загружает легкую модель SentenceTransformer и FAISS-индекс из указанной папки.
7. Она находит 3 самых похожих фрагмента текста в базе.
8. PyAnalizer.py берет эти 3 фрагмента, красиво оформляет их в блок ДАННЫЕ ИЗ RAG: и добавляет в начало промпта, который уходит в LM Studio.
.9 LM Studio генерирует ответ, опираясь как на загруженный пользователем текст, так и на найденные факты из RAG-базы.
"""
