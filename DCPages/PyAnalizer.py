import os
import requests
from pathlib import Path
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QThread
from PyQt6.QtWidgets import QFileDialog

LM_STUDIO_URL = "http://localhost:1234/v1"


class AnalyzerWorker(QThread):
    """Рабочий поток для анализа текста"""
    finished = pyqtSignal(str)
    chunkStarted = pyqtSignal(int, int)
    chunkFinished = pyqtSignal(int, int)
    finalAnalysisStarted = pyqtSignal() #начало финального анализа
    
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
                chunk_start_callback=self.chunkStarted.emit,
                chunk_finish_callback=self.chunkFinished.emit,
                final_analysis_callback=self.finalAnalysisStarted.emit
            )
            self.finished.emit(result)
        except Exception as e:
            self.finished.emit(f"[Критическая ошибка: {str(e)}]")


class DCAnalyzer(QObject):
    resultReady = pyqtSignal(str)
    fileSaved = pyqtSignal(str)
    chunkStarted = pyqtSignal(int, int)
    chunkFinished = pyqtSignal(int, int)
    finalAnalysisStarted = pyqtSignal() #начало финального анализа
    analysisStarted = pyqtSignal()
    analysisFinished = pyqtSignal()
    documentsLoaded = pyqtSignal(str, int) #сигнал загрузки документов (текст, количество)
    
    def __init__(self):
        super().__init__()
        self.text_content = ""
        self.current_result = ""
        self.current_filename = ""
        self.current_prompt = ""  #хранение промта
        self.worker = None
        self.model_name = "qwen3-coder-30b-a3b-instruct"  #Имя модели ИИ добавляем
        self.max_context = 22016  #Укажите ваше значение из LM Studio
        self.temperature = 0.5 #Температура ИИ модели.

    @pyqtSlot(str, int, float)
    def setModelSettings(self, model_name, max_context, temperature):
        """Устанавливает параметры модели из настроек QML"""
        self.model_name = model_name
        self.max_context = max_context
        self.temperature = temperature
        
        print(f"✓ Настройки модели обновлены:")
        print(f"  - Модель: {self.model_name}")
        print(f"  - Контекст: {self.max_context} токенов")
        print(f"  - Temperature: {self.temperature}")

    @pyqtSlot(str, str)
    def analyze(self, text_content, prompt):
        """Запускает анализ в отдельном потоке"""
        if not text_content.strip():
            self.resultReady.emit("Ошибка: текст пустой")
            return
        
        if not prompt.strip():
            prompt = "Проанализируй этот текст"
        
        # Останавливаем предыдущий поток если он есть
        if self.worker and self.worker.isRunning():
            self.worker.quit()
            self.worker.wait()
        
        # Излучаем сигнал о начале анализа
        self.analysisStarted.emit()
        
        # Создаем новый поток
        self.worker = AnalyzerWorker(text_content, prompt, self)
        self.worker.finished.connect(self._on_analysis_finished)
        self.worker.chunkStarted.connect(self.chunkStarted.emit)
        self.worker.chunkFinished.connect(self.chunkFinished.emit)
        self.worker.finalAnalysisStarted.connect(self.finalAnalysisStarted.emit)
        self.worker.start()
        
        self.resultReady.emit("Анализируется...")

    def _on_analysis_finished(self, result):
        """Обработчик завершения анализа"""
        self.current_result = result
        self.resultReady.emit(result)
        self.analysisFinished.emit()

    @pyqtSlot(str)
    def setCurrentPrompt(self, prompt):
        """Сохраняет текущий промт (вызывается из QML)"""
        self.current_prompt = prompt

    @pyqtSlot(list)
    def loadMultipleDocuments(self, file_paths):
        """Загружает несколько текстовых файлов и объединяет их содержимое"""
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
                    # ← ИЗМЕНЕНО: Используем QUrl для кроссплатформенного преобразования
                    url = QUrl(file_path)
                    local_path = url.toLocalFile()  # Автоматически обрабатывает file:/// и платформенные пути
                    
                    # Если toLocalFile() вернул пустую строку, используем исходный путь
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
            
            # Объединяем весь текст
            full_text = "\n".join(combined_content)
            
            # Сохраняем в переменную класса
            self.text_content = full_text
            
            # Формируем имя для сохранения результата
            if len(filenames) == 1:
                self.current_filename = filenames[0]
            elif len(filenames) > 1:
                self.current_filename = f"анализ_{len(filenames)}_файлов"
            else:
                self.current_filename = "анализ"
            
            print(f"✓ Всего загружено файлов: {successfully_loaded}/{len(file_paths)}")
            print(f"✓ Общий размер текста: {len(full_text)} символов")
            
            # Излучаем сигнал для обновления QML
            self.documentsLoaded.emit(full_text, successfully_loaded)
            
        except Exception as e:
            print(f"✗ Критическая ошибка при загрузке файлов: {e}")
            self.documentsLoaded.emit(f"[Ошибка: {str(e)}]", 0)

    def process_text(self, text_content, prompt, chunk_start_callback=None, 
                    chunk_finish_callback=None, final_analysis_callback=None):
        """
        Разбиваем текст на части и отправляем каждую часть в модель.
        После обработки всех чанков делаем финальный анализ.
        """
        max_tokens = 8000
        chunks = self.split_text_into_chunks(text_content, max_tokens)
        total_chunks = len(chunks)
        
        #Если чанк один — сразу финальный анализ
        if total_chunks == 1:
            if final_analysis_callback:
                final_analysis_callback()
            
            # Обрабатываем единственный чанк как финальный анализ
            full_prompt = f"{prompt}\n\nТекст:\n{chunks[0]}"
            
            try:
                headers = {"Content-Type": "application/json"}
                data = {
                    "model": self.model_name, #Используем переменную имении ИИ модели
                    "messages": [
                        {"role": "user", "content": full_prompt}
                    ],
                    "temperature": self.temperature,
                    "max_tokens": max_tokens - 1000
                }
                
                response = requests.post(
                    f"{LM_STUDIO_URL}/chat/completions",
                    headers=headers,
                    json=data,
                    timeout=120
                )
                
                if response.status_code == 200:
                    result = response.json().get("choices", [{}])[0].get("message", {}).get("content", "Ошибка")
                else:
                    result = f"[Ошибка {response.status_code}: {response.text}]"
                
                return result
            
            except requests.exceptions.Timeout:
                return "[Ошибка: таймаут при анализе]"
            except requests.exceptions.ConnectionError:
                return f"[Ошибка: не удалось подключиться к LM Studio. Проверьте, что сервер запущен на {LM_STUDIO_URL}]"
            except Exception as e:
                return f"[Ошибка при анализе: {str(e)}]"
        
        #Если чанков больше одного — стандартная логика
        # ШАГ 1: Анализ каждого чанка
        chunk_results = []
        for i, chunk in enumerate(chunks):
            current_chunk = i + 1
            
            # Сигнал: чанк начал обрабатываться
            if chunk_start_callback:
                chunk_start_callback(current_chunk, total_chunks) 
                
            full_prompt = f"{prompt}\n\nТекст (часть {current_chunk} из {total_chunks}):\n{chunk}"
            
            try:
                headers = {"Content-Type": "application/json"}
                data = {
                    "model": self.model_name, #Используем переменную имении ИИ модели
                    "messages": [
                        {"role": "user", "content": full_prompt}
                    ],
                    "temperature": self.temperature,
                    "max_tokens": max_tokens - 1000
                }
                
                response = requests.post(
                    f"{LM_STUDIO_URL}/chat/completions",
                    headers=headers,
                    json=data,
                    timeout=120
                )
                
                if response.status_code == 200:
                    result = response.json().get("choices", [{}])[0].get("message", {}).get("content", "Ошибка")
                else:
                    result = f"[Ошибка {response.status_code}: {response.text}]"
                
                chunk_results.append(result)
            except requests.exceptions.Timeout:
                chunk_results.append(f"[Ошибка: таймаут при обработке части {current_chunk}]")
            except requests.exceptions.ConnectionError:
                chunk_results.append(f"[Ошибка: не удалось подключиться к LM Studio. Проверьте, что сервер запущен на {LM_STUDIO_URL}]")
            except Exception as e:
                chunk_results.append(f"[Ошибка при обработке части {current_chunk}: {str(e)}]")
            
            # Сигнал: чанк завершён
            if chunk_finish_callback:
                chunk_finish_callback(current_chunk, total_chunks)
        
        # ← ШАГ 2: Финальный анализ всех результатов
        if final_analysis_callback:
            final_analysis_callback()
        
        final_result = self._perform_final_analysis(chunk_results, prompt, total_chunks)
        
        # ← ШАГ 3: Формируем итоговый текст
        output_parts = []
        
        for i, result in enumerate(chunk_results):
            output_parts.append(f"=== Часть {i+1}/{total_chunks} ===\n{result}\n")
        
        output_parts.append("\n**ИТОГОВЫЙ РЕЗУЛЬТАТ:**\n\n" + final_result)
        
        return "\n".join(output_parts)

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
        # ← ИЗМЕНЕНО: Сокращаем каждый результат чанка
        summarized_results = []
        for i, result in enumerate(chunk_results):
            summarized = self._summarize_chunk_result(result, max_length=1500)
            summarized_results.append(f"Часть {i+1}: {summarized}")
        
        combined_results = "\n\n".join(summarized_results)
        
        # Формируем промт для финального анализа
        final_prompt = f"""Ты получил анализ документа, разбитого на {total_chunks} частей.

    Исходный запрос был: "{original_prompt}"

    Результаты анализа по частям:

    {combined_results}

    Задача: На основе всех этих частичных анализов составь единый, связный итоговый анализ документа. 
    Объедини ключевые моменты, устрани дублирование, выдели главное. Ответ должен быть структурированным и понятным."""

        try:
            headers = {"Content-Type": "application/json"}
            data = {
                "model": self.model_name, #Используем переменную имении ИИ модели
                "messages": [
                    {"role": "user", "content": final_prompt}
                ],
                "temperature": self.temperature,
                "max_tokens": 8000,
                "n_ctx": self.max_context #Указываем размер контекста через переменную.
            }

            response = requests.post(
                f"{LM_STUDIO_URL}/chat/completions",
                headers=headers,
                json=data,
                timeout=180  # Увеличиваем таймаут для финального анализа
            )
            
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

    def split_text_into_chunks(self, text, max_tokens):
        """Разбиваем текст на части, каждая не превышает max_tokens"""
        chars_per_token = 4
        chunk_size = (max_tokens * chars_per_token) // 2
        
        chunks = []
        while text:
            if len(text) <= chunk_size:
                chunks.append(text.strip())
                break
            
            split_point = min(chunk_size, len(text))
            
            for delimiter in [". ", ".\n", "! ", "?\n"]:
                pos = text.rfind(delimiter, 0, split_point)
                if pos != -1:
                    split_point = pos + len(delimiter)
                    break
            
            chunks.append(text[:split_point].strip())
            text = text[split_point:].strip()
        
        return chunks

    @pyqtSlot(str)
    def setTextContent(self, content):
        """Сохраняет текст (вызывается из QML)"""
        self.text_content = content

    @pyqtSlot(str)
    def setCurrentFilename(self, filename):
        """Сохраняет имя загруженного файла"""
        self.current_filename = Path(filename).stem if filename else ""

    @pyqtSlot()
    def saveResult(self):
        """Сохранение результата в файл"""
        if not self.current_result or self.current_result == "Анализируется...":
            print("Нечего сохранять")
            return
        
        if self.current_filename:
            base_name = f"{self.current_filename} анализ"
        else:
            base_name = "анализ"
        
        save_dir = QFileDialog.getExistingDirectory(
            None,
            "Выберите папку для сохранения результата",
            str(Path.home())
        )
        
        if not save_dir:
            print("Сохранение отменено")
            return
        
        counter = 1
        while True:
            filename = f"{base_name}_{counter:02d}.txt"
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
                file_content += f"ПРОМТ: {self.current_prompt}\n\n"
                file_content += "=" * 80 + "\n\n"
            
            # Добавляем результат анализа
            file_content += self.current_result
            
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(file_content)
            
            print(f"✓ Результат сохранён: {full_path}")
            self.fileSaved.emit(str(full_path))
        except Exception as e:
            print(f"✗ Ошибка сохранения: {e}")
            self.fileSaved.emit(f"[Ошибка: {str(e)}]")
