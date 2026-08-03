import os
import requests
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QThread

LM_STUDIO_URL = "http://localhost:1234/v1"


class AnalyzerWorker(QThread):
    """Рабочий поток для анализа текста"""
    finished = pyqtSignal(str)
    
    def __init__(self, text_content, prompt):
        super().__init__()
        self.text_content = text_content
        self.prompt = prompt
    
    def run(self):
        """Выполняется в отдельном потоке"""
        try:
            analyzer = TextAnalyzer()
            result = analyzer.process_text(self.text_content, self.prompt)
            self.finished.emit(result)
        except Exception as e:
            self.finished.emit(f"[Критическая ошибка: {str(e)}]")


class TextAnalyzer(QObject):
    resultReady = pyqtSignal(str)
    
    def __init__(self):
        super().__init__()
        self.text_content = ""
        self.worker = None

    @pyqtSlot(str, str)
    def analyze(self, text_content, prompt):
        """
        Запускает анализ в отдельном потоке
        """
        if not text_content.strip():
            self.resultReady.emit("Ошибка: текст пустой")
            return
        
        if not prompt.strip():
            prompt = "Проанализируй этот текст"
        
        # Останавливаем предыдущий поток если он есть
        if self.worker and self.worker.isRunning():
            self.worker.quit()
            self.worker.wait()
        
        # Создаем новый поток
        self.worker = AnalyzerWorker(text_content, prompt)
        self.worker.finished.connect(self.resultReady.emit)
        self.worker.start()
        
        self.resultReady.emit("Анализируется...")

    def process_text(self, text_content, prompt):
        """
        Разбиваем текст на части и отправляем каждую часть в модель.
        Результат объединяется в один вывод (выполняется в потоке)
        """
        max_tokens = 8000
        chunks = self.split_text_into_chunks(text_content, max_tokens)
        
        results = []
        for i, chunk in enumerate(chunks):
            full_prompt = f"{prompt}\n\nТекст (часть {i+1} из {len(chunks)}):\n{chunk}"
            
            try:
                headers = {"Content-Type": "application/json"}
                data = {
                    "model": "",
                    "messages": [
                        {"role": "user", "content": full_prompt}
                    ],
                    "temperature": 0.5,
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
                
                results.append(f"=== Часть {i+1}/{len(chunks)} ===\n{result}\n")
            except requests.exceptions.Timeout:
                results.append(f"[Ошибка: таймаут при обработке части {i+1}]\n")
            except requests.exceptions.ConnectionError:
                results.append(f"[Ошибка: не удалось подключиться к LM Studio. Проверьте, что сервер запущен на {LM_STUDIO_URL}]\n")
            except Exception as e:
                results.append(f"[Ошибка при обработке части {i+1}: {str(e)}]\n")

        return "\n".join(results)

    def split_text_into_chunks(self, text, max_tokens):
        """Разбиваем текст на части, каждая не превышает max_tokens"""
        
        # Примерный расчет (1 токен ≈ 4 символа для русского текста)
        chars_per_token = 4
        chunk_size = (max_tokens * chars_per_token) // 2  # Запас 50%
        
        chunks = []
        while text:
            if len(text) <= chunk_size:
                chunks.append(text.strip())
                break
            
            split_point = min(chunk_size, len(text))
            
            # Ищем конец предложения
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
