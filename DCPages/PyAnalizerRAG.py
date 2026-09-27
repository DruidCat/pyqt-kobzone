import os
import pickle
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSlot, pyqtSignal, QThread

class RAGLoaderWorker(QThread):
    """Рабочий поток для загрузки RAG базы"""
    sigProgress = pyqtSignal(str)  # Прогресс загрузки
    sigFinished = pyqtSignal(bool, str)  # (success, error_message)
    
    def __init__(self, rag_path, model_name, parent_rag):
        super().__init__()
        self.rag_path = rag_path
        self.model_name = model_name
        self.parent_rag = parent_rag
    
    def run(self):
        """Выполняется в отдельном потоке"""
        try:
            # 1. Проверка библиотек
            self.sigProgress.emit("🔄 Проверка зависимостей...")
            try:
                import faiss
            except ImportError:
                self.sigFinished.emit(False, "FAISS не установлен. Выполните: pip install faiss-cpu")
                return
            
            try:
                from sentence_transformers import SentenceTransformer
            except ImportError:
                self.sigFinished.emit(False, "sentence-transformers не установлен. Выполните: pip install sentence-transformers")
                return
            
            # 2. Проверка файлов
            self.sigProgress.emit("🔄 Проверка файлов базы...")
            index_file = os.path.join(self.rag_path, "index.faiss")
            docs_file = os.path.join(self.rag_path, "documents.pkl")
            
            if not os.path.exists(index_file):
                self.sigFinished.emit(False, f"Файл index.faiss отсутствует в {self.rag_path}")
                return
            
            if not os.path.exists(docs_file):
                self.sigFinished.emit(False, f"Файл documents.pkl отсутствует в {self.rag_path}")
                return
            
            # 3. Загрузка модели эмбеддингов
            self.sigProgress.emit(f"🔄 Загрузка модели эмбеддингов: {self.model_name}...")
            
            device = "cpu"  # Принудительно CPU
            embedder = SentenceTransformer(self.model_name, device=device)
            embedder.rag_model_name = self.model_name
            
            self.sigProgress.emit(f"✓ Модель загружена на CPU")
            
            # 4. Загрузка FAISS индекса
            self.sigProgress.emit("🔄 Загрузка FAISS индекса...")
            index = faiss.read_index(index_file)
            self.sigProgress.emit(f"✓ FAISS индекс загружен ({index.ntotal} векторов)")
            
            # 5. Загрузка документов
            self.sigProgress.emit("🔄 Загрузка документов...")
            with open(docs_file, "rb") as f:
                documents = pickle.load(f)
            
            # 6. Валидация
            if len(documents) != index.ntotal:
                self.sigProgress.emit(f"⚠ Несоответствие: {len(documents)} документов != {index.ntotal} векторов")
            
            # 7. Сохраняем в родительский объект
            self.parent_rag._embedder = embedder
            self.parent_rag._index = index
            self.parent_rag._documents = documents
            self.parent_rag._model_name = self.model_name
            self.parent_rag._is_loaded = True
            
            self.sigProgress.emit(f"✓ RAG база успешно загружена: {len(documents)} фрагментов")
            self.sigFinished.emit(True, "")
            
        except Exception as e:
            import traceback
            error_details = traceback.format_exc()
            self.sigFinished.emit(False, f"Ошибка: {str(e)}\n{error_details}")


class DCAnalizerRAG(QObject):
    """Управление загрузкой и поиском по RAG базе данных"""
    sigLog = pyqtSignal(str)  # Логи для toolbar/resultArea
    sigBazaLoaded = pyqtSignal(bool)  # True - загружена, False - ошибка
    sigProgress = pyqtSignal(str)  # Прогресс загрузки (для resultArea)
    
    def __init__(self):
        super().__init__()
        self._index = None
        self._documents = []
        self._embedder = None
        self._current_rag_path = ""
        self._is_loaded = False
        self._model_name = ""
        self._loader_thread = None

    @pyqtSlot(str)
    def ustRagPath(self, rag_path: str):
        """Устанавливает путь к RAG базе"""
        # Убираем префикс file://
        if rag_path.startswith("file://"):
            rag_path = rag_path.replace("file://", "").replace("file:", "")
        
        # Убираем двойной слеш на Windows
        if rag_path.startswith("/") and len(rag_path) > 2 and rag_path[2] == ":":
            rag_path = rag_path[1:]
            
        self._current_rag_path = rag_path
        self._is_loaded = False  # Сбрасываем для перезагрузки
        self._index = None
        self._documents = []
        
        if rag_path:
            self.sigLog.emit(f"✓ Путь к RAG базе установлен: {rag_path}")
        else:
            self.sigLog.emit("⚠ RAG отключен: путь очищен")
            self.sigBazaLoaded.emit(False)

    @pyqtSlot(result=int)
    def polRazmerBazi(self) -> int:
        """Возвращает количество фрагментов в загруженной базе"""
        if self._is_loaded and self._documents:
            return len(self._documents)
        return 0

    @pyqtSlot()
    def zapustitLoadingRAG(self):
        """Запускает загрузку RAG базы в отдельном потоке"""
        
        # Если уже загружено - ничего не делаем
        if self._is_loaded and self._index is not None:
            self.sigBazaLoaded.emit(True)
            return
        
        # Проверка пути
        if not self._current_rag_path:
            self.sigLog.emit("⚠ Путь к RAG базе не задан")
            self.sigBazaLoaded.emit(False)
            return
        
        if not os.path.exists(self._current_rag_path):
            self.sigLog.emit(f"✗ Путь не существует: {self._current_rag_path}")
            self.sigBazaLoaded.emit(False)
            return
        
        # Читаем имя модели из конфига
        config_file = os.path.join(self._current_rag_path, "model_config.txt")
        
        if os.path.exists(config_file):
            with open(config_file, "r", encoding="utf-8") as f:
                model_name = f.read().strip()
            self.sigLog.emit(f"📖 Модель из config: {model_name}")
        else:
            model_name = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
            self.sigLog.emit(f"⚠ model_config.txt не найден, используется: {model_name}")
        
        # Останавливаем предыдущий поток если он есть
        if self._loader_thread and self._loader_thread.isRunning():
            self._loader_thread.quit()
            self._loader_thread.wait()
        
        # Создаем новый поток загрузки
        self.sigProgress.emit("🔄 Начинается загрузка RAG базы...")
        
        self._loader_thread = RAGLoaderWorker(self._current_rag_path, model_name, self)
        self._loader_thread.sigProgress.connect(self._on_progress)
        self._loader_thread.sigFinished.connect(self._on_loading_finished)
        self._loader_thread.start()

    def _on_progress(self, message):
        """Обработчик прогресса загрузки"""
        self.sigLog.emit(message)
        self.sigProgress.emit(message)  # Для resultArea

    def _on_loading_finished(self, success, error_message):
        """Обработчик завершения загрузки"""
        if success:
            self.sigBazaLoaded.emit(True)
        else:
            self.sigLog.emit(f"✗ {error_message}")
            self.sigProgress.emit(f"✗ Ошибка загрузки RAG базы:\n{error_message}")
            self.sigBazaLoaded.emit(False)

    @pyqtSlot(str, int, result=str)
    def poluchitKontekst(self, query: str, top_k: int = 3) -> str:
        """Ищет наиболее релевантные фрагменты"""
        
        if not self._is_loaded or self._index is None or self._embedder is None:
            self.sigLog.emit("⚠ RAG база не загружена")
            return ""

        try:
            # Кодируем запрос в вектор
            query_embedding = self._embedder.encode(
                [query], 
                convert_to_tensor=False,
                show_progress_bar=False
            )
            
            # ✅ НОВОЕ: Ищем больше кандидатов (top_k * 3)
            search_multiplier = 3
            distances, indices = self._index.search(query_embedding, top_k * search_multiplier)
            
            # ✅ НОВОЕ: Адаптивный порог в зависимости от размера базы
            db_size = len(self._documents)
            
            if db_size > 10000:
                MIN_SIMILARITY = 0.70  # Большие базы - выше требования
            elif db_size > 5000:
                MIN_SIMILARITY = 0.65
            else:
                MIN_SIMILARITY = 0.60  # Малые базы - мягче
            
            self.sigLog.emit(f"🔍 База: {db_size} фрагментов, порог: {MIN_SIMILARITY:.0%}")
            
            context_parts = []
            for i, idx in enumerate(indices[0]):
                if idx != -1 and idx < len(self._documents):
                    doc = self._documents[idx]
                    dist = distances[0][i]
                    similarity = 1 - dist
                    
                    # Пропускаем низкокачественные результаты
                    if similarity < MIN_SIMILARITY:
                        self.sigLog.emit(f"⚠ Фрагмент отброшен: релевантность {similarity:.2%} < {MIN_SIMILARITY:.0%}")
                        continue
                    
                    # ✅ Адаптивная длина фрагмента
                    if db_size > 10000:
                        max_fragment_length = 2000  # Большие базы - длиннее фрагменты
                    elif db_size > 5000:
                        max_fragment_length = 1500
                    else:
                        max_fragment_length = 1000

                    if len(doc) > max_fragment_length:
                        doc = doc[:max_fragment_length] + "..." 
                    
                    context_parts.append(
                        f"[Источник {len(context_parts)+1}, релевантность: {similarity:.2%}]:\n{doc}\n"
                    )
                    
                    self.sigLog.emit(f"✓ Найден фрагмент {len(context_parts)}: релевантность {similarity:.2%}")
                    
                    # Ограничиваем количество фрагментов
                    if len(context_parts) >= top_k:
                        break
            
            if not context_parts:
                self.sigLog.emit(f"⚠ Поиск не вернул результатов (все < {MIN_SIMILARITY:.0%} релевантности)")
                return ""
            
            result = "\n---\n".join(context_parts)
            self.sigLog.emit(f"✓ Возвращено {len(context_parts)} качественных фрагментов")
            return result
        
        except Exception as e:
            import traceback
            self.sigLog.emit(f"✗ Ошибка поиска в RAG: {str(e)}")
            self.sigLog.emit(f"Детали:\n{traceback.format_exc()}")
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
