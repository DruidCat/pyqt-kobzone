import os
import requests
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QThread
from PyQt6.QtWidgets import QFileDialog

TIMEOUT_ANALYSIS = 550 #Увеличим с 120 до 300 секунд для чанков
TIMEOUT_FINAL = 1100 #Увеличим с 180 до 600 секунд для финального анализа

class DCAnalyzerWorker(QThread):
    # Сигналы. Рабочий поток для анализа текста
    sigFinished = pyqtSignal(str)
    sigChunkStarted = pyqtSignal(int, int)
    sigChunkFinished = pyqtSignal(int, int)
    sigChunkResult = pyqtSignal(int, int, str) #Сигнал (номер, всего, текст результата)
    sigAnalizFinalStart = pyqtSignal() #начало финального анализа
    
    def __init__(self, text_content, prompt, analyzer):
        super().__init__()
        self.text_content = text_content
        self.prompt = prompt
        self.analyzer = analyzer
    
    def run(self):
        """Выполняется в отдельном потоке"""
        try:
            result = self.analyzer.process_text(
                self.text_content, 
                self.prompt,
                chunk_start_callback=self.sigChunkStarted.emit,
                chunk_finish_callback=self.sigChunkFinished.emit,
                chunk_result_callback=self.sigChunkResult.emit, 
                final_analysis_callback=self.sigAnalizFinalStart.emit
            )
            self.sigFinished.emit(result)
        except Exception as e:
            self.sigFinished.emit(f"[Критическая ошибка: {str(e)}]")


class DCAnalyzer(QObject):
    #Сигналы
    sigResultReady = pyqtSignal(str) #Сигнал готовности Полного результата анализа в конце.
    sigAnalizSohranit = pyqtSignal(str) #Сигнал о том, что сохранился анализ в файл.
    sigChunkStarted = pyqtSignal(int, int) #Сигнал начала обработки Чанка.
    sigChunkFinished = pyqtSignal(int, int) #Сигнал окончания обработки Чанка.
    sigChunkResult = pyqtSignal(int, int, str) #Сигнал (номер, всего, текст результата)
    sigAnalizFinalStart = pyqtSignal() #Сигнал начала финального анализа
    sigAnalizStart = pyqtSignal() #Сигнал Начала анализа.
    sigAnalizFinish = pyqtSignal() #Сигнал Анализ завершён. 
    sigAnalizOstanovlen = pyqtSignal() #Сигнал остановки Анализа
    sigDocumentsLoaded = pyqtSignal(str, int) #Сигнал загрузки документов (текст, количество)
    
    def __init__(self):
        super().__init__()
        self.text_content = ""
        self.current_result = ""
        self.current_filename = ""
        self.current_prompt = "" #хранение промта
        self.final_prompt = "" #финальный промпт, который задаётся в _perform_final_analysis
        self.model_name = "qwen3-coder-30b-a3b-instruct" #Имя модели ИИ добавляем
        self.max_context = 8000 #значение из LM Studio в настройках для языковой модели.
        self.temperature = 0.5 #Температура ИИ модели.
        self.overlap_percent = 20 #Процент перекрытия по умолчанию
        self.worker = None
        self._server_url = "http://localhost:1234/v1"
        self._stop_requested = False #Запрос на остановку Анализа
        self.rag_module = None#Ссылка на DCAnalizerRAG (устанавливается в main.py)
        self.rag_enabled = False#Флаг включения RAG

    @pyqtSlot(str)
    def ustServerURL(self, server_url):
        """Устанавливает URL сервера для анализа"""
        server_url = server_url.strip().rstrip('/')
        if not server_url.endswith('/v1'):
            server_url += '/v1'
        
        self._server_url = server_url
        print(f"✓ PyAnalyzer: URL сервера → {server_url}")

    @pyqtSlot(str, int)
    def ustParametri(self, model_name, max_context):
        if model_name == "" or model_name == "(отсутствует)":
            self.model_name = None
        else:
            self.model_name = model_name

        self.max_context = max_context

    @pyqtSlot(int)
    def ustPerekritie(self, overlap_percent):
        self.overlap_percent = overlap_percent
    
    @pyqtSlot(float)#Слот задающий температуру языковой модели.
    def ustTemperature(self, temperature):
        self.temperature = temperature

    @pyqtSlot(bool)
    def ustRagEnabled(self, enabled: bool):
        """Включает или выключает использование RAG контекста"""
        self.rag_enabled = enabled
        if enabled:
            print("✓ RAG контекст включен для анализа")
        else:
            print("✓ RAG контекст выключен")

    @pyqtSlot(str, str)
    def startAnaliza(self, text_content, prompt):
        """Запускает анализ в отдельном потоке"""
        if not text_content.strip():
            self.sigResultReady.emit("Ошибка: текст пустой")
            return
        
        if not prompt.strip():
            prompt = "Проанализируй этот текст"
        
        # Теперь RAG загружается ДО вызова startAnaliza из QML
        # Останавливаем предыдущий поток если он есть
        if self.worker and self.worker.isRunning():
            self.worker.quit()
            self.worker.wait()
        
        # Излучаем сигнал о начале анализа
        self.sigAnalizStart.emit()
        
        # Создаем новый поток
        self.worker = DCAnalyzerWorker(text_content, prompt, self)
        self.worker.sigFinished.connect(self._on_analysis_finished)
        self.worker.sigChunkStarted.connect(self.sigChunkStarted.emit)
        self.worker.sigChunkFinished.connect(self.sigChunkFinished.emit)
        self.worker.sigChunkResult.connect(self.sigChunkResult.emit)
        self.worker.sigAnalizFinalStart.connect(self.sigAnalizFinalStart.emit)
        self.worker.start()
        
        self.sigResultReady.emit("Анализируется...") 

    @pyqtSlot()
    def stopAnaliz(self):
        """Принудительно останавливает анализ документов"""
        if self.worker and self.worker.isRunning():
            self._stop_requested = True
            
            # Останавливаем поток
            self.worker.quit()
            
            # Ждём завершения потока (максимум 3 секунды)
            if not self.worker.wait(3000):
                # Если не завершился — принудительно
                self.worker.terminate()
                self.worker.wait()
            
            print("⚠ Анализ остановлен пользователем")
            self.sigAnalizOstanovlen.emit()
            self.sigResultReady.emit("[Анализ остановлен пользователем]")
            self.sigAnalizFinish.emit()
            
            self._stop_requested = False
        else:
            print("⚠ Нет активного анализа для остановки")

    def _on_analysis_finished(self, result):
        """Обработчик завершения анализа"""
        self.current_result = result
        self.sigResultReady.emit(result)
        self.sigAnalizFinish.emit() #Излучаем сигнал о том, что анализ завершён

    @pyqtSlot(str)
    def ustPrompt(self, prompt): #Сохраняет текущий промпт (вызывается из QML)
        self.current_prompt = prompt

    @pyqtSlot(str)
    def ustFinalPrompt(self, _final_prompt):#Сохраняем финальный промт
        self.final_prompt = _final_prompt

    @pyqtSlot(list)
    def ustMultipleDocuments(self, file_paths): #Загружает несколько текстовых файлов и объединяет их содержим
        from PyQt6.QtCore import QUrl #импорт QUrl
        
        try:
            if not file_paths:
                print("✗ Список файлов пуст")
                return
            
            combined_content = []
            filenames = []
            successfully_loaded = 0
            
            for file_path in file_paths:
                try:
                    #Используем QUrl для кроссплатформенного преобразования
                    url = QUrl(file_path)
                    local_path = url.toLocalFile() #Автоматически обрабатывает file:/// и платформенные пути
                    
                    #Если toLocalFile() вернул пустую строку, используем исходный путь
                    if not local_path:
                        local_path = file_path
                    
                    file = Path(local_path)
                    
                    if not file.exists() or not file.is_file():
                        print(f"✗ Файл не найден: {file_path}")
                        combined_content.append(f"=== Файл: {file.name if file.name else Path(file_path).name} ===\n[Ошибка: файл не найден]\n")
                        continue
                    
                    with open(file, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    combined_content.append(f"=== Файл: {file.name} ===\n{content}\n")
                    filenames.append(file.stem)
                    successfully_loaded += 1
                    
                    print(f"✓ Загружен файл: {file.name} ({len(content)} символов)")
                    
                except Exception as e:
                    print(f"✗ Ошибка при загрузке файла {file_path}: {e}")
                    combined_content.append(f"=== Файл: {Path(file_path).name} ===\n[Ошибка загрузки: {str(e)}]\n")
            
            #Объединяем весь текст
            full_text = "\n".join(combined_content)
            
            #Сохраняем в переменную класса
            self.text_content = full_text
            
            #Формируем имя для сохранения результата
            if len(filenames) == 1:
                self.current_filename = filenames[0]
            elif len(filenames) > 1:
                self.current_filename = f"анализ_{len(filenames)}_файлов"
            else:
                self.current_filename = "анализ"
            
            print(f"✓ Всего загружено файлов: {successfully_loaded}/{len(file_paths)}")
            print(f"✓ Общий размер текста: {len(full_text)} символов")
            
            #Излучаем сигнал для обновления QML
            self.sigDocumentsLoaded.emit(full_text, successfully_loaded)
            
        except Exception as e:
            print(f"✗ Критическая ошибка при загрузке файлов: {e}")
            self.sigDocumentsLoaded.emit(f"[Ошибка: {str(e)}]", 0)

    def process_text(self, text_content, prompt, chunk_start_callback=None, 
                    chunk_finish_callback=None, chunk_result_callback=None,
                    final_analysis_callback=None):
        """
        Разбиваем текст на части и отправляем каждую часть в модель.
        После обработки всех чанков делаем финальный анализ.
        """
        # Проверка остановки в начале
        if self._stop_requested:
            return "[Анализ остановлен пользователем]"
        
        available_context = max(0, self.max_context - 5000)
        max_tokens = max(1000, available_context)
        
        if self.max_context < 8000:
            print(f"⚠ Предупреждение: контекст {self.max_context} слишком мал, рекомендуется минимум 8000")
        
        chunks = self.split_text_into_chunks(text_content, max_tokens, overlap_percent=self.overlap_percent)
        total_chunks = len(chunks)

        # === ЛОГИКА RAG: ПОЛУЧЕНИЕ КОНТЕКСТА ===
        rag_context = ""
        if self.rag_enabled and self.rag_module is not None:
            try:
                search_query = self._extract_search_query(prompt, text_content)

                self.sigResultReady.emit("🔄 Поиск релевантного контекста в RAG базе...")

                # Вычисляем оптимальное количество фрагментов
                top_k = self.vichislitTopK(prompt)
                db_size = self.rag_module.polRazmerBazi()

                print(f"✓ RAG база: {db_size} фрагментов, запрашиваем top_k={top_k}")
                rag_context = self.rag_module.poluchitKontekst(search_query, top_k=top_k)

                if rag_context:
                    # Проверяем, влезает ли RAG контекст в контекст LLM
                    rag_tokeni = self._tokeniOcenka(rag_context)
                    prompt_tokeni = self._tokeniOcenka(prompt)
                    zapas_na_otvet = int(self.max_context * 0.30)
                    dostupno_dlya_rag = max(
                        self.max_context - zapas_na_otvet - 500 - prompt_tokeni - 1000,
                        int(self.max_context * 0.15)  # хотя бы 15% контекста
                    )

                    if rag_tokeni > dostupno_dlya_rag:
                        print(f"⚠ RAG контекст: {rag_tokeni} токенов > доступно: {dostupno_dlya_rag}. Сжимаем...")
                        rag_context = self._szhatRagKontekst(rag_context, search_query)
                    else:
                        print(f"✓ RAG контекст: {rag_tokeni} токенов (влезает)")

                    print("✓ RAG контекст готов")
                else:
                    print("⚠ RAG не вернул результатов по запросу")

            except Exception as e:
                import traceback
                print(f"⚠ Ошибка получения RAG контекста: {e}")
                print(traceback.format_exc())

        # Модифицируем промпт, добавляя найденный контекст
        if rag_context:
            enhanced_prompt = f"""ВНИМАНИЕ: Ниже приведена дополнительная информация из базы знаний (RAG), которая может быть полезна для выполнения задачи. Используй её как приоритетный источник фактов. Проигнорируй дубликаты и нерелевантные фрагменты. Если информация повторяется — укажи это кратко, не дублируй.

ДАННЫЕ ИЗ RAG:
{rag_context}

---
ОСНОВНАЯ ЗАДАЧА:
{prompt}"""

            # Подсчёт элементов из возвращённой строки
            num_fragments = rag_context.count("[Источник") + rag_context.count("[RAG часть")

            # Превью (первые 500 символов)
            preview = rag_context[:500].replace("\n", " ").strip()

            self.sigResultReady.emit(
                f"✅ RAG: {num_fragments} элементов контекста\n\n"
                f"Превью:\n{preview}...\n\n"
                f"🔄 Начинается анализ..."
            )
        else:
            enhanced_prompt = prompt

            if self.rag_enabled:
                self.sigResultReady.emit(
                    "⚠️ RAG база не вернула результатов\n"
                    "Анализ продолжается без дополнительного контекста"
                )
        # === КОНЕЦ ЛОГИКИ RAG ===

        # Если чанк один — сразу финальный анализ
        if total_chunks == 1:
            if self._stop_requested:
                return "[Анализ остановлен пользователем]"
            
            if final_analysis_callback:
                final_analysis_callback()
            
            full_prompt = f"{enhanced_prompt}\n\nТекст для анализа:\n{chunks[0]}"

            try:
                headers = {"Content-Type": "application/json"}
                data = {
                    "messages": [
                        {"role": "user", "content": full_prompt}
                    ],
                    "temperature": self.temperature,
                    "max_tokens": max_tokens - 1000
                }
                if self.model_name:
                    data["model"] = self.model_name
                
                response = requests.post(
                    f"{self._server_url}/chat/completions",
                    headers=headers,
                    json=data,
                    timeout=TIMEOUT_ANALYSIS
                )
                
                if self._stop_requested:
                    return "[Анализ остановлен пользователем]"
                
                if response.status_code == 200:
                    result = response.json().get("choices", [{}])[0].get("message", {}).get("content", "Ошибка")
                else:
                    result = f"[Ошибка {response.status_code}: {response.text}]"
                
                # ОТПРАВЛЯЕМ РЕЗУЛЬТАТ ЕДИНСТВЕННОГО ЧАНКА
                if chunk_result_callback:
                    chunk_result_callback(1, 1, result)
                
                return result
            
            except requests.exceptions.Timeout:
                return "[Ошибка: таймаут при анализе]"
            except requests.exceptions.ConnectionError:
                return f"[Ошибка: не удалось подключиться к LM Studio. Проверьте, что сервер запущен на {self._server_url}]"
            except Exception as e:
                return f"[Ошибка при анализе: {str(e)}]"
        
        # Если чанков больше одного — стандартная логика
        # ШАГ 1: Анализ каждого чанка
        chunk_results = []
        for i, chunk in enumerate(chunks):
            if self._stop_requested:
                return "[Анализ остановлен пользователем]"
            
            current_chunk = i + 1
            
            if chunk_start_callback:
                chunk_start_callback(current_chunk, total_chunks)
            
            full_prompt = f"{enhanced_prompt}\n\nТекст (часть {current_chunk} из {total_chunks}):\n{chunk}"           

            try:
                headers = {"Content-Type": "application/json"}
                data = {
                    "messages": [
                        {"role": "user", "content": full_prompt}
                    ],
                    "temperature": self.temperature,
                    "max_tokens": max_tokens - 1000
                }
                if self.model_name:
                    data["model"] = self.model_name
                
                response = requests.post(
                    f"{self._server_url}/chat/completions",
                    headers=headers,
                    json=data,
                    timeout=TIMEOUT_ANALYSIS
                )
                
                if self._stop_requested:
                    return "[Анализ остановлен пользователем]"
                
                if response.status_code == 200:
                    result = response.json().get("choices", [{}])[0].get("message", {}).get("content", "Ошибка")
                else:
                    result = f"[Ошибка {response.status_code}: {response.text}]"
                
                chunk_results.append(result)
                
                # ОТПРАВЛЯЕМ РЕЗУЛЬТАТ ЧАНКА СРАЗУ
                if chunk_result_callback:
                    chunk_result_callback(current_chunk, total_chunks, result)
            
            except requests.exceptions.Timeout:
                result = f"[Ошибка: таймаут при обработке части {current_chunk}]"
                chunk_results.append(result)
                if chunk_result_callback:
                    chunk_result_callback(current_chunk, total_chunks, result)
            
            except requests.exceptions.ConnectionError:
                result = f"[Ошибка: не удалось подключиться к LM Studio]"
                chunk_results.append(result)
                if chunk_result_callback:
                    chunk_result_callback(current_chunk, total_chunks, result)
            
            except Exception as e:
                result = f"[Ошибка при обработке части {current_chunk}: {str(e)}]"
                chunk_results.append(result)
                if chunk_result_callback:
                    chunk_result_callback(current_chunk, total_chunks, result)
            
            if chunk_finish_callback:
                chunk_finish_callback(current_chunk, total_chunks)
        
        if self._stop_requested:
            return "[Анализ остановлен пользователем]"
        
        # ШАГ 2: Финальный анализ всех результатов
        if final_analysis_callback:
            final_analysis_callback()
        
        final_result = self._perform_final_analysis(chunk_results, prompt, total_chunks)
        
        if self._stop_requested:
            return "[Анализ остановлен пользователем]"
        
        # ШАГ 3: Формируем итоговый текст (markdown для красивого HTML)
        output_parts = []

        for i, result in enumerate(chunk_results):
            if i > 0:
                output_parts.append("\n---\n")  # Разделитель между чанками
            output_parts.append(f"### Часть {i+1}/{total_chunks}\n\n{result}\n")

        # Разделитель и заголовок перед финальным анализом
        output_parts.append("\n---\n")
        output_parts.append(f"### ИТОГОВЫЙ РЕЗУЛЬТАТ\n\n{final_result}")

        return "\n".join(output_parts) 


    def _extract_search_query(self, prompt, text_content):
        """
        Извлекает ключевые слова из промпта и текста для поиска в RAG
        """
        # Стоп-слова (игнорируем)
        stopwords = {
            'проанализируй', 'этот', 'текст', 'выдели', 'основные', 'темы',
            'сделай', 'анализ', 'дай', 'расскажи', 'объясни', 'опиши',
            'документ', 'файл', 'содержимое', 'следующий', 'приведённый'
        }
        
        # 1. Берём слова из промпта
        prompt_words = [
            w.lower().strip('.,!?:;') 
            for w in prompt.split() 
            if len(w) > 3 and w.lower() not in stopwords
        ]
        
        # 2. Если промпт короткий - берём первые 200 символов текста
        if len(prompt_words) < 3:
            text_words = [
                w.lower().strip('.,!?:;') 
                for w in text_content[:500].split() 
                if len(w) > 3 and w.lower() not in stopwords
            ]
            prompt_words.extend(text_words[:10])
        
        # 3. Формируем поисковый запрос (макс 500 символов)
        search_query = ' '.join(prompt_words[:50])  # 50 ключевых слов
        
        print(f"✓ Поисковый запрос для RAG: {search_query[:200]}...")
        return search_query



    def _summarize_chunk_result(self, result, max_length=1000):#Сокращаем результаты чанков, оставляя только суть
        """Сокращает результат чанка до основных тезисов"""
        if len(result) <= max_length:
            return result
        
        # Обрезаем до max_length символов, но завершаем на точке
        truncated = result[:max_length]
        last_period = truncated.rfind('.')
        
        if last_period > max_length // 2:  # Если точка найдена во второй половине
            return truncated[:last_period + 1] + "\n[...сокращено...]"
        else:
            return truncated + "...\n[...сокращено...]"

    def _perform_final_analysis(self, chunk_results, original_prompt, total_chunks):
        """
        Выполняет финальный анализ на основе результатов всех чанков
        """
        # ПРОВЕРКА ОСТАНОВКИ
        if self._stop_requested:
            return "[Анализ остановлен пользователем]"
        
        # Сокращаем каждый результат чанка
        summarized_results = []
        for i, result in enumerate(chunk_results):
            summarized = self._summarize_chunk_result(result, max_length=1500)
            summarized_results.append(f"Часть {i+1}: {summarized}")
        
        combined_results = "\n\n".join(summarized_results)

        if not self.final_prompt.strip(): #Если промпт задан пользователем пустой, то...
            self.final_prompt = f"""На основе всех этих частичных анализов составь единый, связный итоговый анализ документа. Объедини ключевые моменты, устрани дублирование, выдели главное. Ответ должен быть структурированным и понятным."""
        # Формируем промт для финального анализа
        _final_prompt = f"""Ты получил анализ документа, разбитого на {total_chunks} частей.

    Исходный запрос был: "{original_prompt}"

    Результаты анализа по частям:

    {combined_results}

    Задача: {self.final_prompt}"""

        max_response_tokens = int(self.max_context * 0.7)
        estimated_prompt_tokens = len(_final_prompt) // 2.5
        
        if estimated_prompt_tokens > (self.max_context * 0.3):
            print(f"⚠ Промт слишком длинный ({estimated_prompt_tokens} токенов), сокращаем резюме...")
            summarized_results = []
            for i, result in enumerate(chunk_results):
                summarized = self._summarize_chunk_result(result, max_length=800)
                summarized_results.append(f"Часть {i+1}: {summarized}")
            
            combined_results = "\n\n".join(summarized_results)
            _final_prompt = f"""Ты получил анализ документа, разбитого на {total_chunks} частей.

    Исходный запрос был: "{original_prompt}"

    Результаты анализа по частям:

    {combined_results}

    Задача: {self.final_prompt}"""
        
        try:
            headers = {"Content-Type": "application/json"}
            data = {
                "messages": [
                    {"role": "user", "content": _final_prompt}
                ],
                "temperature": self.temperature,
                "max_tokens": max_response_tokens,
                "n_ctx": self.max_context
            }
            if self.model_name:
                data["model"] = self.model_name

            print(f"✓ Финальный анализ:")
            print(f"  - Промт: ~{int(len(_final_prompt) / 2.5)} токенов")
            print(f"  - Максимум ответа: {max_response_tokens} токенов")
            print(f"  - Контекст: {self.max_context} токенов")

            response = requests.post(
                f"{self._server_url}/chat/completions",
                headers=headers,
                json=data,
                timeout=TIMEOUT_FINAL
            )
            
            # ПРОВЕРКА ОСТАНОВКИ ПОСЛЕ ЗАПРОСА
            if self._stop_requested:
                return "[Анализ остановлен пользователем]"
            
            if response.status_code == 200:
                return response.json().get("choices", [{}])[0].get("message", {}).get("content", "Ошибка финального анализа")
            else:
                return f"[Ошибка финального анализа {response.status_code}: {response.text}]"
        
        except requests.exceptions.Timeout:
            return "[Ошибка: таймаут при выполнении финального анализа]"
        except requests.exceptions.ConnectionError:
            return f"[Ошибка: не удалось подключиться к LM Studio для финального анализа]"
        except Exception as e:
            return f"[Ошибка при финальном анализе: {str(e)}]"
    
    def split_text_into_chunks(self, text, max_tokens, overlap_percent=None):
        """
        Разбивает текст на части с перекрытием для сохранения контекста
        
        Args:
            text: Исходный текст
            max_tokens: Максимальное количество токенов в чанке
            overlap_percent: Процент перекрытия между чанками (по умолчанию 20%)
        
        Returns:
            list: Список чанков текста
        """ 
        #Если overlap_percent не передан, то..
        if overlap_percent is None:
            overlap_percent = self.overlap_percent #используем значение из self

        chars_per_token = 2.5  # Для русского текста (кириллица)
        chunk_size = int(max_tokens * chars_per_token * 0.85)#0.85 = 15% запас для промта "Текст (часть X из Y):\n"
        overlap_size = int(chunk_size * (overlap_percent / 100))
        
        chunks = []
        start = 0
        text_length = len(text)
        
        while start < text_length:
            # Определяем конец текущего чанка
            end = min(start + chunk_size, text_length)
            
            # Ищем конец предложения для естественного разрыва
            if end < text_length:
                # Ищем ближайшую точку, восклицательный знак или вопросительный знак
                best_split = end
                for delimiter in [". ", ".\n", "! ", "!\n", "? ", "?\n"]:
                    pos = text.rfind(delimiter, start + chunk_size // 2, end)
                    if pos != -1:
                        best_split = pos + len(delimiter)
                        break
                end = best_split
            
            # Добавляем чанк
            chunk_text = text[start:end].strip()
            if chunk_text:
                chunks.append(chunk_text)
            
            # Следующий чанк начинается с перекрытием
            # Но не перемещаемся назад, если достигли конца
            if end >= text_length:
                break
            
            # Ищем начало нового чанка (с учётом перекрытия)
            start = end - overlap_size
            
            # Ищем начало предложения для перекрытия
            # Чтобы не разрывать предложение посередине
            for delimiter in [". ", ".\n", "! ", "!\n", "? ", "?\n"]:
                pos = text.find(delimiter, start, start + overlap_size // 2)
                if pos != -1:
                    start = pos + len(delimiter)
                    break
        
        print(f"✓ Текст разбит на {len(chunks)} чанков с перекрытием {overlap_percent}%")
        for i, chunk in enumerate(chunks):
            print(f"  Чанк {i+1}: {len(chunk)} символов (~{int(len(chunk)/chars_per_token)} токенов)")
        
        return chunks

    @pyqtSlot(str)
    def ustContentText(self, content): #Устанавливаем текст контента (вызывается из QML)
        self.text_content = content

    @pyqtSlot(str)
    def sohranitAnaliz(self, open_path): #Сохранение результата Анализа в файл 
        if not self.current_result or self.current_result == "Анализируется...":
            print("Нечего сохранять")
            return
        
        if self.current_filename:
            base_name = f"Анализ {self.current_filename}"
        else:
            base_name = "Анализ"
        
        save_dir = QFileDialog.getExistingDirectory(
            None,
            "Выберите папку для сохранения результата",
            str(open_path)#Открыть Диалог в папке (путь open_path)
        )
        if not save_dir:
            print("Сохранение отменено")
            return
        
        counter = 1
        while True:
            filename = f"{base_name} {counter:02d}.txt"
            full_path = Path(save_dir) / filename
            
            if not full_path.exists():
                break
            
            counter += 1
            
            if counter > 999:
                print("Слишком много файлов анализа")
                return
        
        try:
            # Формируем содержимое с промтом
            file_content = ""
            
            # Добавляем промт, если он есть
            if self.current_prompt:
                file_content += f"ПРОМТ: {self.current_prompt}\n"
                file_content += f"\n---\n"
            
            # Добавляем результат анализа
            file_content += self.current_result
            
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(file_content)
            
            print(f"✓ Результат сохранён: {full_path}")
            self.sigAnalizSohranit.emit(str(full_path))
        except Exception as e:
            print(f"✗ Ошибка сохранения: {e}")
            self.sigAnalizSohranit.emit(f"[Ошибка: {str(e)}]")

    def vichislitTopK(self, prompt_text=""):
        """
        Вычисляет оптимальное количество RAG фрагментов.
        Основывается на: max_context, длине промпта, запасе на ответ.
        Запрашивает МАКСИМАЛЬНО — реальная проверка влезания происходит после получения.
        """
        # 30% контекста — на ответ LLM
        zapas_na_otvet = int(self.max_context * 0.30)
        # Служебные токены (системные инструкции, форматирование)
        sluzhebnie = 500
        # Оценка токенов промпта (русский: ~2.5 символа на токен)
        prompt_tokeni = max(1, int(len(prompt_text) / 2.5))

        # Доступно для RAG
        dostupno = self.max_context - zapas_na_otvet - sluzhebnie - prompt_tokeni

        if dostupno <= 0:
            return 3

        # Минимальная оценка размера фрагмента (~200 токенов),
        # чтобы запросить больше фрагментов.
        # Реальная проверка — после получения фрагментов.
        min_fragment_tokeni = 200

        top_k = dostupno // min_fragment_tokeni
        return max(3, min(top_k, 50))

    def _tokeniOcenka(self, text):
        """Грубая оценка количества токенов (русский: ~2.5 символа на токен)"""
        return max(1, int(len(text) / 2.5))

    def _otpravitZaprosLLM(self, full_prompt, max_otvet_tokeni=None):
        """
        Отправляет один запрос к LLM и возвращает текст ответа.
        Выделяет HTTP-логику в одно место, чтобы не дублировать в разных частях кода.
        """
        if self._stop_requested:
            return "[Остановлено]"

        if max_otvet_tokeni is None:
            max_otvet_tokeni = int(self.max_context * 0.3)

        headers = {"Content-Type": "application/json"}
        data = {
            "messages": [{"role": "user", "content": full_prompt}],
            "temperature": self.temperature,
            "max_tokens": max_otvet_tokeni
        }
        if self.model_name:
            data["model"] = self.model_name

        try:
            response = requests.post(
                f"{self._server_url}/chat/completions",
                headers=headers,
                json=data,
                timeout=TIMEOUT_ANALYSIS
            )

            if self._stop_requested:
                return "[Остановлено]"

            if response.status_code == 200:
                return response.json().get("choices", [{}])[0].get("message", {}).get("content", "Ошибка")
            else:
                return f"[Ошибка {response.status_code}: {response.text}]"

        except requests.exceptions.Timeout:
            return "[Ошибка: таймаут]"
        except requests.exceptions.ConnectionError:
            return "[Ошибка: не удалось подключиться к LM Studio]"
        except Exception as e:
            return f"[Ошибка: {str(e)}]"

    def _szhatRagKontekst(self, rag_context, search_query):
        """
        Если RAG контекст слишком большой для одного вызова LLM —
        обрабатывает его по частям и возвращает сжатый (компрессированный) контекст.
        Работает по аналогии с обработкой чанков документов.
        """
        if not rag_context:
            return ""

        # Разделяем на отдельные фрагменты
        fragmenti = [f.strip() for f in rag_context.split("\n---\n") if f.strip()]

        if not fragmenti:
            return rag_context

        # Сколько фрагментов влезет в один batch
        zapas_na_otvet = int(self.max_context * 0.30)
        sluzhebnie = 500
        prompt_ochenka = self._tokeniOcenka(
            f"Проанализируй данные из базы знаний. Запрос: {search_query}"
        )
        dostupno = self.max_context - zapas_na_otvet - sluzhebnie - prompt_ochenka

        # Измеряем средний размер фрагмента
        if fragmenti:
            avg_frag = sum(self._tokeniOcenka(f) for f in fragmenti) / len(fragmenti)
        else:
            avg_frag = 300

        frag_per_batch = max(1, int(dostupno / max(1, avg_frag)))

        # Если всё влезает в один batch — возвращаем как есть
        if len(fragmenti) <= frag_per_batch:
            return rag_context

        # Разбиваем на batch-и
        batchi = []
        for i in range(0, len(fragmenti), frag_per_batch):
            batch = "\n---\n".join(fragmenti[i:i + frag_per_batch])
            batchi.append(batch)

        self.sigResultReady.emit(
            f"🔄 RAG контекст: {len(fragmenti)} фрагментов не влезает. "
            f"Обработка в {len(batchi)} этапах..."
        )

        rezultati = []
        for i, batch in enumerate(batchi):
            if self._stop_requested:
                return "[Остановлено]"

            self.sigChunkStarted.emit(i + 1, len(batchi))

            zapros = f"""Проанализируй следующие данные из базы знаний.
    Выдели ключевую информацию, факты и выводы, релевантные запросу.

    ДАННЫЕ ИЗ RAG (часть {i + 1} из {len(batchi)}):
    {batch}

    ЗАПРОС: {search_query}

    Сформулируй краткий и информативный вывод (максимум 500 слов)."""

            result = self._otpravitZaprosLLM(zapros)
            rezultati.append(result)

            self.sigChunkFinished.emit(i + 1, len(batchi))

        # Объединяем результаты всех batch-ей
        szhatii = "\n\n".join(
            [f"[RAG часть {i + 1}/{len(rezultati)}]: {r}" for i, r in enumerate(rezultati)]
        )

        self.sigResultReady.emit(
            f"✅ RAG обработан: {len(fragmenti)} фрагментов → {len(rezultati)} частей"
        )

        return szhatii
