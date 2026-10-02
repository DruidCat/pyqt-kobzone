import os
import re
import pickle
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSlot, pyqtSignal, QThread

class RAGLoaderWorker(QThread):
    """Рабочий поток для загрузки RAG базы"""
    sigProgress = pyqtSignal(int, str)  # Прогресс загрузки: номер прогресса, наименование прогресса.
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
            self.sigProgress.emit(1, "Проверка зависимостей...")
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
            self.sigProgress.emit(2, "Проверка файлов базы...")
            index_file = os.path.join(self.rag_path, "index.faiss")
            docs_file = os.path.join(self.rag_path, "documents.pkl")
            meta_file = os.path.join(self.rag_path, "metadatas.pkl")
            
            if not os.path.exists(index_file):
                self.sigFinished.emit(False, f"Файл index.faiss отсутствует в {self.rag_path}")
                return
            
            if not os.path.exists(docs_file):
                self.sigFinished.emit(False, f"Файл documents.pkl отсутствует в {self.rag_path}")
                return

            metadatas = []
            if os.path.exists(meta_file):
                with open(meta_file, "rb") as f:
                    metadatas = pickle.load(f)
            else:
                self.sigProgress.emit(3, "Файл metadatas.pkl не найден (страницы/источники могут не отображаться)")

            # 3. Загрузка модели эмбеддингов
            self.sigProgress.emit(4, f"Загрузка модели эмбеддингов: {self.model_name}...")
            
            device = "cpu"  # Принудительно CPU
            embedder = SentenceTransformer(self.model_name, device=device)
            embedder.rag_model_name = self.model_name
            
            self.sigProgress.emit(5, f"Модель загружена на CPU")
            
            # 4. Загрузка FAISS индекса
            self.sigProgress.emit(6, "Загрузка FAISS индекса...")
            index = faiss.read_index(index_file)
            self.sigProgress.emit(7, f"FAISS индекс загружен ({index.ntotal} векторов)")
            
            # 5. Загрузка документов
            self.sigProgress.emit(8, "Загрузка документов...")
            with open(docs_file, "rb") as f:
                documents = pickle.load(f)
            
            # 6. Валидация
            if metadatas and len(metadatas) != len(documents):
                self.sigProgress.emit(9, f"Несоответствие: metadatas={len(metadatas)} != documents={len(documents)}")

            if len(documents) != index.ntotal:
                self.sigProgress.emit(10, f"Несоответствие: {len(documents)} документов != {index.ntotal} векторов")
            
            # 7. Сохраняем в родительский объект
            self.parent_rag._embedder = embedder
            self.parent_rag._index = index
            self.parent_rag._documents = documents
            self.parent_rag._model_name = self.model_name
            self.parent_rag._is_loaded = True
            self.parent_rag._metadatas = metadatas
            
            self.sigProgress.emit(11, f"RAG база успешно загружена: {len(documents)} фрагментов")
            self.sigFinished.emit(True, "")
            
        except Exception as e:
            import traceback
            error_details = traceback.format_exc()
            self.sigFinished.emit(False, f"Ошибка: {str(e)}\n{error_details}")


class DCAnalizerRAG(QObject):
    """Управление загрузкой и поиском по RAG базе данных"""
    sigLog = pyqtSignal(str)  # Логи для toolbar/txdOtvet
    sigBazaLoaded = pyqtSignal(bool)  # True - загружена, False - ошибка
    sigProgress = pyqtSignal(int, str)  #Прогресс загрузки (для txdOtvet)
    
    def __init__(self):
        super().__init__()
        self._index = None
        self._documents = []
        self._embedder = None
        self._current_rag_path = ""
        self._is_loaded = False
        self._model_name = ""
        self._loader_thread = None
        self._metadatas = []
        self._documents_lower = None  # кэш документов в нижнем регистре (для лексического поиска)

    @pyqtSlot(str)
    def ustRagPath(self, rag_path: str):
        """Устанавливает путь к RAG базе"""
        self._metadatas = [] #сброс
        self._documents_lower = None
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
        self.sigProgress.emit(0, "Начинается загрузка RAG базы...")
        
        self._loader_thread = RAGLoaderWorker(self._current_rag_path, model_name, self)
        self._loader_thread.sigProgress.connect(self._on_progress)
        self._loader_thread.sigFinished.connect(self._on_loading_finished)
        self._loader_thread.start()

    def _on_progress(self, ntProgress, message): #Получает сообщения от sigProgress sigFinished из потока
        """Обработчик прогресса загрузки"""
        self.sigLog.emit(message)
        self.sigProgress.emit(ntProgress, message) #Для txdOtvet

    def _on_loading_finished(self, success, error_message):
        """Обработчик завершения загрузки"""
        if success:
            self.sigBazaLoaded.emit(True)
        else:
            self.sigLog.emit(f"✗ {error_message}")
            self.sigProgress.emit(11, f"✗ Ошибка загрузки RAG базы:\n{error_message}")
            self.sigBazaLoaded.emit(False)

    def _obnovitCacheNizRegistr(self):
        """Кэшируем документы в нижнем регистре, чтобы не делать lower() каждый запрос"""
        if self._documents_lower is None or len(self._documents_lower) != len(self._documents):
            self._documents_lower = [str(d).lower() for d in self._documents]

    def _vydelitTochnieMarkeri(self, query: str) -> list[str]:
        """
        Достаём из query "точные маркеры": H150, A-123, 12-345, 150мм и т.п.
        Берём то, где есть цифры (часто это артикулы/обозначения).
        """
        if not query:
            return []

        query = query.strip()

        # 1) Слова, где есть и буквы и цифры: h150, ab12, н150 и т.д.
        markeri = re.findall(r"[A-Za-zА-Яа-я]{1,10}[\s\-–—_]*\d{1,10}[A-Za-zА-Яа-я]{0,10}", query)

        # 2) Чистые числа длиной >= 3 (опционально, полезно для 150/220/380 и т.п.)
        chisla = re.findall(r"\b\d{3,}\b", query)

        # Убираем дубли
        itog = []
        for x in markeri + chisla:
            x = x.strip()
            if x and x not in itog:
                itog.append(x)

        return itog[:10]  # ограничим

    def _zamenaLatCyrPolnostyu(self, slovo: str) -> str:
        """
        Грубая замена похожих латинских букв на кириллические и наоборот.
        Делается 'полностью по строке', без комбинаторики.
        """
        mapa = str.maketrans({
            # лат -> кир
            "a": "а", "e": "е", "k": "к", "m": "м", "h": "н", "o": "о", "p": "р", "c": "с", "t": "т", "x": "х", "y": "у",
            "A": "А", "E": "Е", "K": "К", "M": "М", "H": "Н", "O": "О", "P": "Р", "C": "С", "T": "Т", "X": "Х", "Y": "У",
            # кир -> лат
            "а": "a", "е": "e", "к": "k", "м": "m", "н": "h", "о": "o", "р": "p", "с": "c", "т": "t", "х": "x", "у": "y",
            "А": "A", "Е": "E", "К": "K", "М": "M", "Н": "H", "О": "O", "Р": "P", "С": "C", "Т": "T", "Х": "X", "У": "Y",
        })
        return slovo.translate(mapa)

    def _sdelatRegexIzMarkera(self, marker: str) -> re.Pattern:
        """
        Превращаем маркер (H150, H-150, 'H 150') в regex, который допускает пробелы/дефисы/переносы.
        """
        marker = marker.strip()
        marker = marker.replace(" ", "")

        # Разрешаем между символами пробелы/дефисы/подчёркивания/переносы
        razdel = r"[\s\-–—_]*"

        # Экранируем каждый символ
        chast = []
        for ch in marker:
            chast.append(re.escape(ch))
        pattern = razdel.join(chast)

        return re.compile(pattern, flags=re.IGNORECASE)

    def _poiskLex(self, query: str, top_k: int = 3) -> list[dict]:
        """
        Точный поиск по строке в documents.
        Возвращает список словарей: idx, similarity, marker, pos
        """
        self._obnovitCacheNizRegistr()

        markeri = self._vydelitTochnieMarkeri(query)
        if not markeri:
            return []

        # Собираем regex-паттерны с вариантами лат/кир
        spisok_patternov: list[tuple[str, re.Pattern]] = []
        for marker in markeri:
            marker2 = self._zamenaLatCyrPolnostyu(marker)
            # два варианта достаточно: оригинал и "перекодированный"
            for m in [marker, marker2]:
                m = m.strip()
                if not m:
                    continue
                try:
                    spisok_patternov.append((marker, self._sdelatRegexIzMarkera(m)))
                except re.error:
                    continue

        najdeno = []
        for idx, doc_low in enumerate(self._documents_lower):
            if not doc_low:
                continue

            for marker_original, rgx in spisok_patternov:
                mt = rgx.search(doc_low)
                if mt:
                    # similarity для лексического совпадения считаем максимальной
                    najdeno.append({
                        "idx": idx,
                        "similarity": 1.0,
                        "marker": marker_original,
                        "pos": mt.start(),
                    })
                    break  # один маркер на документ достаточно

        # Уникализируем по idx
        uniq = {}
        for item in najdeno:
            uniq[item["idx"]] = item

        rezultati = list(uniq.values())
        rezultati.sort(key=lambda x: (x["similarity"], -x["pos"]), reverse=True)

        return rezultati[:max(1, top_k)]

    @pyqtSlot(str, int, result=str)
    def poluchitKontekst(self, query: str, top_k: int = 3) -> str:
        """Ищет наиболее релевантные фрагменты"""
        
        if not self._is_loaded or self._index is None or self._embedder is None:
            self.sigLog.emit("⚠ RAG база не загружена")
            return ""

        try:
            import numpy as np
            # 1) СНАЧАЛА пробуем точный (лексический) поиск по артикулам/числам типа H150
            lex_rezultati = self._poiskLex(query, top_k=top_k)

            if lex_rezultati:
                self.sigLog.emit(f"🔎 Точный поиск: найдено {len(lex_rezultati)} совпадений")
                context_parts = []

                for item in lex_rezultati:
                    idx = item["idx"]
                    similarity = item["similarity"]
                    marker = item.get("marker", "")

                    doc = self._documents[idx]

                    meta = None
                    if self._metadatas and idx < len(self._metadatas):
                        meta = self._metadatas[idx]

                    file_name = ""
                    page = 0
                    if isinstance(meta, dict):
                        file_name = str(meta.get("filename", ""))
                        page = int(meta.get("page", 0) or 0)

                    dop_info = ""
                    if marker:
                        dop_info += f", точное совпадение: {marker}"
                    if file_name:
                        dop_info += f", файл: {file_name}"
                    if page > 0:
                        dop_info += f", стр.: {page}"

                    # Обрезаем как раньше
                    max_fragment_length = 1000
                    if len(doc) > max_fragment_length:
                        doc = doc[:max_fragment_length] + "..."

                    context_parts.append(
                        f"[Источник {len(context_parts)+1}, релевантность: {similarity:.2%}{dop_info}]:\n{doc}\n"
                    )

                    if len(context_parts) >= top_k:
                        break

                result = "\n---\n".join(context_parts)
                self.sigLog.emit(f"✓ Возвращено {len(context_parts)} фрагментов (точный поиск)")
                return result

            # Если точный поиск ничего не нашёл — продолжаем семантическим
            self.sigLog.emit("ℹ Точный поиск совпадений не дал, пробуем семантический поиск")

            # Кодируем запрос в вектор
            query_embedding = self._embedder.encode(
                [query], 
                convert_to_tensor=False,
                show_progress_bar=False
            )

            query_embedding = np.asarray(query_embedding, dtype="float32")

            # Нормализуем запрос так же, как документы в DCRAGMake.py
            norm = np.linalg.norm(query_embedding, axis=1, keepdims=True)
            query_embedding = query_embedding / (norm + 1e-12)
            
            # Ищем больше кандидатов (top_k * 3)
            search_multiplier = 3
            distances, indices = self._index.search(query_embedding, top_k * search_multiplier)
            
            # Адаптивный порог в зависимости от размера базы
            db_size = len(self._documents)
            
            # Реальные пороги для cosine similarity (иначе почти всё отбрасывается)
            if db_size > 10000:
                MIN_SIMILARITY = 0.30
            elif db_size > 5000:
                MIN_SIMILARITY = 0.25
            else:
                MIN_SIMILARITY = 0.20  # Малые базы - мягче
            
            self.sigLog.emit(f"🔍 База: {db_size} фрагментов, порог: {MIN_SIMILARITY:.0%}")
            
            context_parts = []
            for i, idx in enumerate(indices[0]):
                if idx == -1 or idx >= len(self._documents):
                    continue

                doc = self._documents[idx]
                dist = float(distances[0][i])

                # FAISS IndexFlatL2 возвращает L2^2.
                # Для нормализованных векторов: dist = 2 - 2*cos => cos = 1 - dist/2
                similarity = 1.0 - (dist / 2.0)

                # Подстрахуем диапазон
                if similarity < 0:
                    similarity = 0.0
                elif similarity > 1:
                    similarity = 1.0

                if similarity < MIN_SIMILARITY:
                    self.sigLog.emit(f"⚠ Фрагмент отброшен: релевантность {similarity:.2%} < {MIN_SIMILARITY:.0%}")
                    continue

                # Метаданные (файл/страница)
                meta = None
                if hasattr(self, "_metadatas") and self._metadatas and idx < len(self._metadatas):
                    meta = self._metadatas[idx]

                file_name = ""
                page = 0
                if isinstance(meta, dict):
                    file_name = str(meta.get("filename", ""))
                    page = int(meta.get("page", 0) or 0)

                # Обрезка фрагмента
                if db_size > 10000:
                    max_fragment_length = 2000
                elif db_size > 5000:
                    max_fragment_length = 1500
                else:
                    max_fragment_length = 1000

                if len(doc) > max_fragment_length:
                    doc = doc[:max_fragment_length] + "..."

                # Строка источника (чтобы DCAnalyzer.count("[Источник") работал как раньше)
                dop_info = ""
                if file_name:
                    dop_info += f", файл: {file_name}"
                if page > 0:
                    dop_info += f", стр.: {page}"

                context_parts.append(
                    f"[Источник {len(context_parts)+1}, релевантность: {similarity:.2%}{dop_info}]:\n{doc}\n"
                )

                self.sigLog.emit(f"✓ Найден фрагмент {len(context_parts)}: релевантность {similarity:.2%}{dop_info}")

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
