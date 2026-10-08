import warnings
warnings.filterwarnings("ignore", category=FutureWarning)

import os
import sys
import re # Работа с регулярными выражениями.
import tempfile #Работа с temp файлами и папками
import platform #Работа с Операционными Системами
from pathlib import Path #Для Path

# Чтобы импорты работали даже если python запущен в safe-path режиме
sys.path.insert(0, str(Path(__file__).resolve().parent))
# ============================================================
# ОПРЕДЕЛЕНИЕ ОПЕРАЦИОННОЙ СИСТЕМЫ
# ============================================================
IS_WINDOWS = platform.system() == "Windows"
IS_LINUX = platform.system() == "Linux"
IS_MACOS = platform.system() == "Darwin"

if IS_WINDOWS:
    print("🪟 Windows: используется временная папка для FAISS.", flush=True)
elif IS_LINUX:
    print("🐧 Linux: прямая запись FAISS в финальную папку.", flush=True)
elif IS_MACOS:
    print("🍎 macOS: прямая запись FAISS в финальную папку.", flush=True)
# ============================================================
# ОПТИМИЗАЦИЯ ПАМЯТИ PYTORCH
# ============================================================
os.environ['PYTORCH_CUDA_ALLOC_CONF'] = 'expandable_segments:True,max_split_size_mb:128'
os.environ['TRANSFORMERS_VERBOSITY'] = 'error'
os.environ['HF_HUB_DISABLE_SYMLINKS_WARNING'] = '1'

# ============================================================
# ОТКЛЮЧЕНИЕ ИЗБЫТОЧНОГО ВЫВОДА TRANSFORMERS
# ============================================================
os.environ['TRANSFORMERS_VERBOSITY'] = 'error'
os.environ['HF_HUB_DISABLE_SYMLINKS_WARNING'] = '1'

import shutil
import pickle
from transformers import AutoTokenizer, AutoModel
import torch
import time
import threading
from datetime import datetime
import zipfile
from DCPDF import izvlech_text_iz_pdf_po_stranicam

# ============================================================
# ОПРЕДЕЛЕНИЕ РЕЖИМА ЗАПУСКА
# ============================================================

IS_GUI_MODE = os.environ.get('RAG_GUI_MODE', '0') == '1'
USE_GPU = os.environ.get('RAG_USE_GPU', '0') == '1'
MODEL_INDEX = int(os.environ.get('RAG_MODEL_INDEX', '0'))

# ============================================================
# РЕЖИМ ЧАНКИНГА
# 0 = All (Абзац + мусор)
# 1 = Paragraph-based Chunking (абзацы)
# 2 = Sliding Window Chunking (окна по токенам + overlap 20%)
# ============================================================
REJIM_CHANKING = int(os.environ.get("RAG_REJIM_CHANKING", "1"))
if REJIM_CHANKING not in (1, 2):
    REJIM_CHANKING = 1

PEREKRITIE_PROC = 0.20  # 20%

# Получаем batch_size из окружения
BATCH_GPU_OVERRIDE = os.environ.get('RAG_BATCH_GPU')
BATCH_CPU_OVERRIDE = os.environ.get('RAG_BATCH_CPU')

# Словарь моделей эмбеддингов
EMBEDDING_MODELS = {
    0: {
        'name': 'sentence-transformers/all-MiniLM-L6-v2',
        'dimension': 384,
        'description': '384D, быстрая',
        'batch_size_cpu': 32,
        'batch_size_gpu': 128
    },
    1: {
        'name': 'sentence-transformers/all-MiniLM-L12-v2',
        'dimension': 384,
        'description': '384D, точная',
        'batch_size_cpu': 32,
        'batch_size_gpu': 128
    },
    2: {
        'name': 'sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2',
        'dimension': 384,
        'description': '384D, многоязычная',
        'batch_size_cpu': 32,
        'batch_size_gpu': 128
    },
    3: {
        'name': 'sentence-transformers/all-mpnet-base-v2',
        'dimension': 768,
        'description': '768D, максимальное качество',
        'batch_size_cpu': 16,
        'batch_size_gpu': 64
    },
    4: {
        'name': 'sentence-transformers/LaBSE',
        'dimension': 768,
        'description': '768D, 100+ языков',
        'batch_size_cpu': 16,
        'batch_size_gpu': 64
    },
    5: {
        'name': 'BAAI/bge-m3',
        'dimension': 1024,
        'description': '1024D, мультиязычная 8K',
        'batch_size_cpu': 4,
        'batch_size_gpu': 16,
        'max_length': 8192
    },
    6: {
        'name': 'intfloat/multilingual-e5-large',
        'dimension': 1024,
        'description': '1024D, использует GPU',
        'batch_size_cpu': 8,
        'batch_size_gpu': 32
    }
}

# Проверка корректности индекса модели
if MODEL_INDEX not in EMBEDDING_MODELS:
    print(f"❌ Ошибка: неверный индекс модели {MODEL_INDEX}", flush=True)
    print(f"   Доступные индексы: 0-{len(EMBEDDING_MODELS)-1}", flush=True)
    sys.exit(1)

# Получение выбранной модели
SELECTED_MODEL = EMBEDDING_MODELS[MODEL_INDEX]
MODEL_NAME = SELECTED_MODEL['name']
EXPECTED_DIMENSION = SELECTED_MODEL['dimension']

# ============================================================
# ПЕРЕОПРЕДЕЛЕНИЕ BATCH_SIZE ИЗ GUI (если передано)
# ============================================================
if BATCH_GPU_OVERRIDE:
    try:
        batch_gpu_value = int(BATCH_GPU_OVERRIDE)
        if 1 <= batch_gpu_value <= 256:
            SELECTED_MODEL['batch_size_gpu'] = batch_gpu_value
        else:
            print(f"⚠️ Некорректный batch_gpu: {batch_gpu_value} (1-256), используется значение по умолчанию", flush=True)
    except ValueError:
        print(f"⚠️ Ошибка парсинга batch_gpu: {BATCH_GPU_OVERRIDE}", flush=True)

if BATCH_CPU_OVERRIDE:
    try:
        batch_cpu_value = int(BATCH_CPU_OVERRIDE)
        if 1 <= batch_cpu_value <= 64:
            SELECTED_MODEL['batch_size_cpu'] = batch_cpu_value
        else:
            print(f"⚠️ Некорректный batch_cpu: {batch_cpu_value} (1-64), используется значение по умолчанию", flush=True)
    except ValueError:
        print(f"⚠️ Ошибка парсинга batch_cpu: {BATCH_CPU_OVERRIDE}", flush=True)

# Определение доступности GPU
GPU_AVAILABLE = torch.cuda.is_available()

# Проверка faiss-gpu
try:
    if USE_GPU:
        import faiss.contrib.torch_utils
        FAISS_GPU_AVAILABLE = True
    else:
        import faiss
        FAISS_GPU_AVAILABLE = False
except ImportError:
    import faiss
    FAISS_GPU_AVAILABLE = False
    if USE_GPU:
        print("⚠️  FAISS-GPU не установлен, используется CPU версия", flush=True)
        USE_GPU = False

# Получение путей из переменных окружения
BASE_DIR = os.environ.get(
    'RAG_DB_DIR',
    "/mnt/Yandex.Disk/Мои Документы/БД/A.I. СССР"
)

DATA_DIR = os.environ.get(
    'RAG_DOC_DIR',
    os.path.join(BASE_DIR, "base")
)

# Пути к папкам
base_dir = BASE_DIR
data_dir = DATA_DIR
add_dir = os.path.join(base_dir, "add")
arch_dir = os.path.join(base_dir, "arch")
index_dir = os.path.join(base_dir, "faiss_index")

# Время старта скрипта
start_time = time.time()

# ============================================================
# ВЫВОД ЗАГОЛОВКА ДО ЗАГРУЗКИ МОДЕЛИ
# ============================================================
print("="*70, flush=True)
print("🚀 СОЗДАНИЕ ВЕКТОРНОЙ БАЗЫ ДАННЫХ RAG", flush=True)
print("="*70, flush=True)
print(f"📦 Модель: {MODEL_NAME}", flush=True)
print(f"   {SELECTED_MODEL['description']}", flush=True)

if USE_GPU and GPU_AVAILABLE and FAISS_GPU_AVAILABLE:
    print("🎮 Режим: GPU (CUDA)", flush=True)
    print(f"   Устройство: {torch.cuda.get_device_name(0)}", flush=True)
    print(f"   VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB", flush=True)
    print(f"   Batch size: {SELECTED_MODEL['batch_size_gpu']}", flush=True)
elif USE_GPU and not GPU_AVAILABLE:
    print("⚠️  GPU запрошен, но CUDA недоступна", flush=True)
    print("💻 Режим: CPU (fallback)", flush=True)
    print(f"   Batch size: {SELECTED_MODEL['batch_size_cpu']}", flush=True)
    USE_GPU = False
elif USE_GPU and not FAISS_GPU_AVAILABLE:
    print("⚠️  GPU запрошен, но faiss-gpu не установлен", flush=True)
    print("💻 Режим: CPU (fallback)", flush=True)
    print(f"   Batch size: {SELECTED_MODEL['batch_size_cpu']}", flush=True)
    USE_GPU = False
else:
    print("💻 Режим: CPU", flush=True)
    print(f"   Batch size: {SELECTED_MODEL['batch_size_cpu']}", flush=True)

print(f"🧩 Режим чанкинга: {REJIM_CHANKING} ({'Parent Document' if REJIM_CHANKING==1 else 'Перекрытие 20%'})", flush=True)

print("="*70, flush=True)

def create_backup_archive():
    """Создание архива папки base и перемещение в arch"""
    if not os.path.exists(data_dir):
        print("⚠️  Папка base не найдена, архивация пропущена", flush=True)
        return False
    
    # Создание папки arch если её нет
    os.makedirs(arch_dir, exist_ok=True)
    
    # Генерация имени архива
    current_date = datetime.now().strftime("%Y-%m-%d")
    archive_name = f"{current_date}.zip"
    archive_path = os.path.join(arch_dir, archive_name)
    
    # Проверка на существование архива с таким же именем
    if os.path.exists(archive_path):
        counter = 1
        while os.path.exists(archive_path):
            archive_name = f"{current_date}_{counter}.zip"
            archive_path = os.path.join(arch_dir, archive_name)
            counter += 1
    
    print(f"\n📦 Создание резервной копии базы данных...", flush=True)
    print(f"   Архив: {archive_name}", flush=True)
    
    try:
        # Создание zip архива
        with zipfile.ZipFile(archive_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            # Подсчёт файлов для прогресса
            total_files = sum([len(files) for _, _, files in os.walk(data_dir)])
            processed = 0
            
            for root, dirs, files in os.walk(data_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, data_dir)
                    zipf.write(file_path, arcname)
                    processed += 1
                    
                    # Показываем прогресс каждые 10 файлов
                    if processed % 10 == 0 or processed == total_files:
                        percent = (processed / total_files) * 100
                        sys.stdout.write(f'\r   📄 Архивировано файлов: {processed}/{total_files} ({percent:.1f}%)')
                        sys.stdout.flush()
            
            print(flush=True)  # Новая строка после прогресса
        
        # Получение размера архива
        archive_size = os.path.getsize(archive_path)
        size_mb = archive_size / (1024 * 1024)
        
        print(f"   ✓ Архив создан: {archive_name} ({size_mb:.1f} MB)", flush=True)
        print(f"   📁 Местоположение: {arch_dir}", flush=True)
        return True
    
    except Exception as e:
        print(f"\n   ✗ Ошибка при создании архива: {e}", flush=True)
        return False

def format_time(seconds):
    """Форматирование времени в читаемый вид"""
    if seconds < 60:
        return f"{seconds:.1f} сек"
    elif seconds < 3600:
        minutes = seconds / 60
        return f"{minutes:.1f} мин"
    else:
        hours = seconds / 3600
        return f"{hours:.1f} час"

# ==================== ПЕРВЫЙ МОДУЛЬ: ПРОВЕРКА НА ПЕРЕСОЗДАНИЕ RAG ====================

if os.path.exists(index_dir) and os.path.isdir(index_dir):
    # print("="*70, flush=True)
    print("⚠️  Обнаружена существующая векторная база данных RAG", flush=True)
    print("="*70, flush=True)

    if IS_GUI_MODE:
        # В GUI режиме всегда пересоздаём
        print("\n🗑️  Удаление старой базы данных...", flush=True)
        shutil.rmtree(index_dir)
        print("✓ Старая база удалена\n", flush=True)
    else:
        response = input("\n🔄 Пересоздать векторную базу данных RAG? (Д/Н): ")
        
        if response in ['Д', 'д', 'Y', 'y']:
            print("\n🗑️  Удаление старой базы данных...", flush=True)
            shutil.rmtree(index_dir)
            print("✓ Старая база удалена\n", flush=True)
        else:
            print("\n❌ Операция отменена. Выход из программы.", flush=True)
            sys.exit(0)

# ==================== ВТОРОЙ МОДУЛЬ: ПРОВЕРКА НОВЫХ ФАЙЛОВ В ADD ====================

def check_and_move_new_files():
    """Проверка и перенос новых файлов из папки add в base"""
    if not os.path.exists(add_dir):
        return
    
    # Поиск txt файлов в папке add
    new_files = []
    for root, _, files in os.walk(add_dir):
        for file in files:
            if file.lower().endswith(".txt") or file.lower().endswith(".pdf"):
                new_files.append(os.path.join(root, file))
    
    if not new_files:
        return
    
    # ==================== GUI РЕЖИМ ====================
    if IS_GUI_MODE:
        print("="*70, flush=True)
        print("📥 ОБНАРУЖЕНЫ НОВЫЕ ФАЙЛЫ В ПАПКЕ ДЛЯ ДОБАВЛЕНИЯ", flush=True)
        print("="*70, flush=True)
        print(f"\nПапка: {add_dir}\n", flush=True)
        
        for idx, file_path in enumerate(new_files, 1):
            relative_path = os.path.relpath(file_path, add_dir)
            file_size = os.path.getsize(file_path)
            size_kb = file_size / 1024
            print(f"  [{idx}] {relative_path} ({size_kb:.1f} KB)", flush=True)
        
        print(f"\n📊 Всего файлов: {len(new_files)}", flush=True)
        print("="*70, flush=True)
        
        # Автоматически переносим файлы в GUI режиме
        print("\n🔄 Автоматический перенос файлов в base...", flush=True)
        
        # Создание резервной копии базы перед добавлением
        if not create_backup_archive():
            print("\n❌ Ошибка создания архива. Операция отменена.", flush=True)
            sys.exit(1)
        
        # Создание подпапки с текущей датой
        current_date = datetime.now().strftime("%Y-%m-%d")
        target_dir = os.path.join(data_dir, current_date)
        
        os.makedirs(target_dir, exist_ok=True)
        
        print(f"\n📁 Создана папка: {current_date}/", flush=True)
        print("🔄 Перенос файлов...\n", flush=True)
        
        moved_count = 0
        for idx, file_path in enumerate(new_files, 1):
            try:
                file_name = os.path.basename(file_path)
                target_path = os.path.join(target_dir, file_name)
                
                # Проверка на существование файла с таким же именем
                if os.path.exists(target_path):
                    base_name, ext = os.path.splitext(file_name)
                    counter = 1
                    while os.path.exists(target_path):
                        file_name = f"{base_name}_{counter}{ext}"
                        target_path = os.path.join(target_dir, file_name)
                        counter += 1
                
                shutil.move(file_path, target_path)
                print(f"  [{idx}/{len(new_files)}] ✓ {os.path.basename(file_path)} → {current_date}/{file_name}", flush=True)
                moved_count += 1
            except Exception as e:
                print(f"  [{idx}/{len(new_files)}] ✗ Ошибка при переносе {os.path.basename(file_path)}: {e}", flush=True)
        
        print(f"\n✓ Перенесено файлов: {moved_count}/{len(new_files)}\n", flush=True)
        
        # Удаление пустых папок в add
        try:
            for root, dirs, files in os.walk(add_dir, topdown=False):
                for dir_name in dirs:
                    dir_path = os.path.join(root, dir_name)
                    if not os.listdir(dir_path):
                        os.rmdir(dir_path)
                        print(f"  🗑️  Удалена пустая папка: {os.path.relpath(dir_path, add_dir)}", flush=True)
        except Exception as e:
            print(f"  ⚠️  Ошибка при удалении пустых папок: {e}", flush=True)
        
        return
    
    # ==================== ТЕРМИНАЛЬНЫЙ РЕЖИМ ====================
    
    # Показываем найденные файлы
    print("="*70, flush=True)
    print("📥 ОБНАРУЖЕНЫ НОВЫЕ ФАЙЛЫ В ПАПКЕ ДЛЯ ДОБАВЛЕНИЯ", flush=True)
    print("="*70, flush=True)
    print(f"\nПапка: {add_dir}\n", flush=True)
    
    for idx, file_path in enumerate(new_files, 1):
        relative_path = os.path.relpath(file_path, add_dir)
        file_size = os.path.getsize(file_path)
        size_kb = file_size / 1024
        print(f"  [{idx}] {relative_path} ({size_kb:.1f} KB)", flush=True)
    
    print(f"\n📊 Всего файлов: {len(new_files)}", flush=True)
    print("="*70, flush=True)
    
    response = input("\n🔄 Перенести файл(ы) в папку base? (Д/Н): ")
    
    if response in ['Д', 'д', 'Y', 'y']:
        # Создание резервной копии базы перед добавлением новых файлов
        if not create_backup_archive():
            print("\n❌ Ошибка создания архива. Операция отменена.", flush=True)
            sys.exit(1)
        
        # Создание подпапки с текущей датой
        current_date = datetime.now().strftime("%Y-%m-%d")
        target_dir = os.path.join(data_dir, current_date)
        
        os.makedirs(target_dir, exist_ok=True)
        
        print(f"\n📁 Создана папка: {current_date}/", flush=True)
        print("🔄 Перенос файлов...\n", flush=True)
        
        moved_count = 0
        for file_path in new_files:
            try:
                file_name = os.path.basename(file_path)
                target_path = os.path.join(target_dir, file_name)
                
                # Проверка на существование файла с таким же именем
                if os.path.exists(target_path):
                    base_name, ext = os.path.splitext(file_name)
                    counter = 1
                    while os.path.exists(target_path):
                        file_name = f"{base_name}_{counter}{ext}"
                        target_path = os.path.join(target_dir, file_name)
                        counter += 1
                
                shutil.move(file_path, target_path)
                print(f"  ✓ {os.path.basename(file_path)} → {current_date}/{file_name}", flush=True)
                moved_count += 1
            except Exception as e:
                print(f"  ✗ Ошибка при переносе {os.path.basename(file_path)}: {e}", flush=True)
        
        print(f"\n✓ Перенесено файлов: {moved_count}/{len(new_files)}\n", flush=True)
        
        # Удаление пустых папок в add
        try:
            for root, dirs, files in os.walk(add_dir, topdown=False):
                for dir_name in dirs:
                    dir_path = os.path.join(root, dir_name)
                    if not os.listdir(dir_path):
                        os.rmdir(dir_path)
        except:
            pass
    else:
        print("\n❌ Файлы не перенесены. Продолжение работы с текущей базой.\n", flush=True)

# Вызываем проверку новых файлов ТОЛЬКО после подтверждения пересоздания RAG
check_and_move_new_files()

# ============================================================
# ЗАГРУЗКА МОДЕЛИ
# ============================================================

print("\n📥 Загрузка модели...", flush=True)
sys.stdout.flush()

device = torch.device('cuda' if USE_GPU and GPU_AVAILABLE else 'cpu')

# ============================================================
# АГРЕССИВНАЯ ОЧИСТКА VRAM ДЛЯ bge-m3
# ============================================================
if USE_GPU and GPU_AVAILABLE:
    
    # Агрессивная очистка
    import gc
    gc.collect()  # Python garbage collector
    torch.cuda.empty_cache()  # PyTorch cache
    torch.cuda.synchronize()  # Синхронизация
    torch.cuda.reset_peak_memory_stats()  # Сброс статистики
    
    # Проверка доступной памяти
    mem_info = torch.cuda.mem_get_info(0)
    free_memory = mem_info[0] / (1024**3)  # В ГБ
    total_memory = mem_info[1] / (1024**3)
    used_memory = total_memory - free_memory
    
    if free_memory < 6.0:
        print(f"\n⚠️  КРИТИЧНО: Недостаточно VRAM!", flush=True)
        print(f"   Требуется: 6+ GB для bge-m3", flush=True)
        print(f"   Доступно:  {free_memory:.2f} GB", flush=True)
        print(f"\n💡 Рекомендации:", flush=True)
        print(f"   1. Закройте браузеры и другие программы", flush=True)
        print(f"   2. Перезапустите приложение", flush=True)
        print(f"   3. Используйте модель с меньшими требованиями", flush=True)
        
        if IS_GUI_MODE:
            # В GUI режиме автоматически переключаемся на CPU
            print(f"\n💻 Автоматическое переключение на CPU режим...", flush=True)
            USE_GPU = False
            device = torch.device('cpu')
        else:
            # В терминале спрашиваем пользователя
            response = input("\nПродолжить на CPU? (Д/Н): ")
            if response in ['Д', 'д', 'Y', 'y']:
                USE_GPU = False
                device = torch.device('cpu')
            else:
                print("\n❌ Операция отменена.", flush=True)
                sys.exit(0)

try:
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    model = AutoModel.from_pretrained(MODEL_NAME)
    
    # Перемещаем модель на GPU если нужно
    if USE_GPU and GPU_AVAILABLE:
        model = model.to(device)
        print(f"✓ Модель загружена на GPU: {torch.cuda.get_device_name(0)}", flush=True)
    else:
        print("✓ Модель загружена на CPU", flush=True)
    
    print(f"   Ожидаемая размерность: {EXPECTED_DIMENSION}D", flush=True)

except Exception as e:
    print(f"❌ Ошибка загрузки модели: {e}", flush=True)
    sys.exit(1)

def mean_pooling(model_output, attention_mask):
    """Mean Pooling - учитываем attention mask для корректного усреднения"""
    token_embeddings = model_output[0]
    input_mask_expanded = attention_mask.unsqueeze(-1).expand(token_embeddings.size()).float()
    return torch.sum(token_embeddings * input_mask_expanded, 1) / torch.clamp(input_mask_expanded.sum(1), min=1e-9)

class SpinnerThread(threading.Thread):
    """Поток для плавной анимации спиннера"""
    def __init__(self):
        super().__init__()
        self.spinner = ['/', '-', '\\', '|']
        self.idx = 0
        self.running = True
        self.message = ""
        self.daemon = True
        self.enabled = not IS_GUI_MODE
    
    def run(self):
        while self.running:
            if self.message and self.enabled:
                sys.stdout.write(f'\r  {self.spinner[self.idx]} {self.message}')
                sys.stdout.flush()
                self.idx = (self.idx + 1) % 4
            time.sleep(0.1)
    
    def update_message(self, msg):
        self.message = msg
        if not self.enabled:
            print(f"  {msg}", flush=True)
    
    def stop(self):
        self.running = False
        if self.enabled:
            sys.stdout.write('\r')
            sys.stdout.flush()

def encode_texts(texts, batch_size=None):
    """Кодирование текстов в эмбеддинги"""
    all_embeddings = []
    total = len(texts)
    
    # Автоматический выбор batch_size
    if batch_size is None:
        if USE_GPU and GPU_AVAILABLE:
            batch_size = SELECTED_MODEL['batch_size_gpu']
            
            # Динамическая корректировка для bge-m3
            if MODEL_NAME == 'BAAI/bge-m3':
                free_memory = torch.cuda.mem_get_info(0)[0] / (1024**3)
                if free_memory < 8.0:
                    batch_size = 4
                    print(f"   ⚠️  Уменьшен batch_size до 4 (доступно VRAM: {free_memory:.2f} GB)", flush=True)
                elif free_memory < 10.0:
                    batch_size = 8
        else:
            batch_size = SELECTED_MODEL['batch_size_cpu']
    
    # Получаем max_length из модели
    max_length = SELECTED_MODEL.get('max_length', 512)
    
    # Вычисляем шаг для обновления (1% от общего количества)
    one_percent = max(1, total // 100)
    next_report = one_percent
    last_reported_percent = 0
    
    # Запуск спиннера
    spinner = SpinnerThread()
    spinner.start()
    
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]
        
        # Для e5 моделей нужен префикс
        if MODEL_NAME.startswith('intfloat/e5'):
            batch = [f"passage: {text}" for text in batch]
        
        encoded = tokenizer(
            batch, 
            padding=True, 
            truncation=True, 
            max_length=max_length,
            return_tensors='pt'
        )
        
        # Перемещаем данные на GPU если нужно
        if USE_GPU and GPU_AVAILABLE:
            encoded = {key: val.to(device) for key, val in encoded.items()}
        
        try:
            with torch.no_grad():
                model_output = model(**encoded)
                batch_embeddings = mean_pooling(model_output, encoded['attention_mask'])
                batch_embeddings = torch.nn.functional.normalize(batch_embeddings, p=2, dim=1)
                all_embeddings.append(batch_embeddings.cpu())
            
            # Очистка памяти после батча (для bge-m3)
            if USE_GPU and GPU_AVAILABLE and MODEL_NAME == 'BAAI/bge-m3':
                del encoded, model_output, batch_embeddings
                torch.cuda.empty_cache()
        
        except RuntimeError as e:
            if "out of memory" in str(e):
                print(f"\n❌ CUDA out of memory на батче {i//batch_size + 1}", flush=True)
                print(f"   Попытка уменьшить batch_size и продолжить...", flush=True)
                
                # Очистка памяти
                torch.cuda.empty_cache()
                
                # Уменьшаем batch_size вдвое
                batch_size = max(1, batch_size // 2)
                print(f"   Новый batch_size: {batch_size}", flush=True)
                
                # Возвращаемся назад и пробуем снова
                continue
            else:
                raise
        
        # Обновление прогресса
        processed = i + len(batch)
        
        if processed >= next_report or processed == total:
            percent = int((processed / total) * 100)
            
            if percent > last_reported_percent or processed == total:
                spinner.update_message(f'Обработано {processed}/{total} фрагментов ({percent}%)')
                last_reported_percent = percent
                next_report += one_percent
    
    spinner.stop()
    spinner.join()
    print(f'  ✓ Обработано {total}/{total} фрагментов (100%)', flush=True)
    
    return torch.vstack(all_embeddings)

def razbit_na_abzaci(text: str) -> list[str]:
    # Устойчивее, чем split("\n\n")
    abzaci = [x.strip() for x in re.split(r"\n\s*\n", text) if x.strip()]
    return abzaci

def _tokenov_v_tekste(tokenizer, text: str) -> int:
    ids = tokenizer(
        text,
        add_special_tokens=False,
        truncation=False,
        return_attention_mask=False
    )["input_ids"]
    return len(ids)

def _razbit_tokeni_oknami(tokenizer, tokeni: list[int], max_tokenov: int, overlap_tokenov: int) -> list[str]:
    if max_tokenov <= 0:
        return []
    if overlap_tokenov < 0:
        overlap_tokenov = 0
    if overlap_tokenov >= max_tokenov:
        overlap_tokenov = max(0, max_tokenov // 5)

    step = max(1, max_tokenov - overlap_tokenov)

    chanki = []
    for start in range(0, len(tokeni), step):
        okno = tokeni[start:start + max_tokenov]
        if not okno:
            break
        text_okna = tokenizer.decode(okno, skip_special_tokens=True).strip()
        if text_okna:
            chanki.append(text_okna)
        if start + max_tokenov >= len(tokeni):
            break
    return chanki

def razbit_text_sliding(text: str, tokenizer, max_tokenov: int, perekritie_proc: float = 0.20) -> list[str]:
    """
    Sliding Window Chunking c перекрытием.
    Стараемся сохранять границы абзацев. Если абзац > max_tokenov — режем его окнами токенов.
    """
    abzaci = razbit_na_abzaci(text)
    if not abzaci:
        return []

    overlap_tokenov = int(max_tokenov * perekritie_proc)
    chanki: list[str] = []

    tek_abzaci: list[str] = []
    tek_tokenov = 0
    overlap_abzaci: list[str] = []

    def sobrat_overlap(spisok_abzacev: list[str]) -> list[str]:
        if overlap_tokenov <= 0:
            return []
        result = []
        s = 0
        for a in reversed(spisok_abzacev):
            t = _tokenov_v_tekste(tokenizer, a)
            result.append(a)
            s += t
            if s >= overlap_tokenov:
                break
        result.reverse()
        return result

    def sbrosit_chank():
        nonlocal tek_abzaci, tek_tokenov, overlap_abzaci
        if tek_abzaci:
            chanki.append("\n\n".join(tek_abzaci).strip())
            overlap_abzaci = sobrat_overlap(tek_abzaci)
        tek_abzaci = []
        tek_tokenov = 0

    for abzac in abzaci:
        if not abzac:
            continue

        t = _tokenov_v_tekste(tokenizer, abzac)

        # Абзац-гигант режем окнами
        if t > max_tokenov:
            sbrosit_chank()
            tokeni = tokenizer(
                abzac,
                add_special_tokens=False,
                truncation=False,
                return_attention_mask=False
            )["input_ids"]
            okna = _razbit_tokeni_oknami(tokenizer, tokeni, max_tokenov, overlap_tokenov)
            chanki.extend(okna)
            overlap_abzaci = []  # overlap уже есть окнами
            continue

        # При старте нового чанка добавляем overlap-абзацы
        if not tek_abzaci and overlap_abzaci:
            for oa in overlap_abzaci:
                ot = _tokenov_v_tekste(tokenizer, oa)
                if tek_tokenov + ot <= max_tokenov:
                    tek_abzaci.append(oa)
                    tek_tokenov += ot
                else:
                    break

        # Влезает — добавляем
        if tek_tokenov + t <= max_tokenov:
            tek_abzaci.append(abzac)
            tek_tokenov += t
        else:
            # Закрываем чанк и начинаем новый
            sbrosit_chank()

            # Новый чанк снова: overlap + текущий абзац
            if overlap_abzaci:
                for oa in overlap_abzaci:
                    ot = _tokenov_v_tekste(tokenizer, oa)
                    if tek_tokenov + ot <= max_tokenov:
                        tek_abzaci.append(oa)
                        tek_tokenov += ot
                    else:
                        break

            tek_abzaci.append(abzac)
            tek_tokenov += t

    sbrosit_chank()
    return chanki

# Список всех документов .txt + .pdf
print("\n📂 Поиск документов...", flush=True)
doc_files = []
for root, _, files in os.walk(data_dir):
    for file in files:
        file_lower = file.lower()
        if file_lower.endswith(".txt") or file_lower.endswith(".pdf"):
            doc_files.append(os.path.join(root, file))

print(f"✓ Найдено {len(doc_files)} файлов (.txt/.pdf)\n", flush=True)
print("="*70, flush=True)
print("📖 ОБРАБОТКА ФАЙЛОВ", flush=True)
print("="*70, flush=True)

# Чтение и разбиение текста
documents = []
metadatas = []

for idx, file_path in enumerate(doc_files, 1):
    try:
        chunk_count = 0
        file_lower = file_path.lower()

        if file_lower.endswith(".txt"):
            with open(file_path, "r", encoding="utf-8") as f:
                text = f.read()

            max_length = SELECTED_MODEL.get('max_length', 512)

            if REJIM_CHANKING == 1:
                chunks = razbit_na_abzaci(text)
            else:
                chunks = razbit_text_sliding(text, tokenizer, max_length, perekritie_proc=PEREKRITIE_PROC)

            for nomer_chanka, chunk in enumerate(chunks, 1):
                if len(chunk) > 50:
                    documents.append(chunk)
                    metadatas.append({
                        "source": file_path,
                        "filename": os.path.basename(file_path),
                        "page": 0,              # txt
                        "rejim": REJIM_CHANKING,
                        "chunk_no": nomer_chanka
                    })
                    chunk_count += 1

        elif file_lower.endswith(".pdf"):
            spisok_stranic = izvlech_text_iz_pdf_po_stranicam(file_path)

            # ---- ОТЛАДКА (по запросу) ----
            # print(f"\nPDF распознан: {os.path.basename(file_path)}", flush=True)
            # print(f"Страниц: {len(spisok_stranic)}", flush=True)

            for nomer_stranicy, text_stranicy in enumerate(spisok_stranic, 1):
                if not text_stranicy:
                    continue

                max_length = SELECTED_MODEL.get('max_length', 512)

                if REJIM_CHANKING == 1:
                    chunks = razbit_na_abzaci(text_stranicy)
                else:
                    chunks = razbit_text_sliding(text_stranicy, tokenizer, max_length, perekritie_proc=PEREKRITIE_PROC)

                for nomer_chanka, chunk in enumerate(chunks, 1):
                    if len(chunk) > 50:
                        documents.append(chunk)
                        metadatas.append({
                            "source": file_path,
                            "filename": os.path.basename(file_path),
                            "page": nomer_stranicy,  # pdf page
                            "rejim": REJIM_CHANKING,
                            "chunk_no": nomer_chanka
                        })
                        chunk_count += 1

            if chunk_count == 0:
                print(f"⚠️  PDF без текста (возможно скан без текстового слоя): {os.path.basename(file_path)}", flush=True)

        relative_path = os.path.relpath(file_path, data_dir)
        print(f"[{idx}/{len(doc_files)}] ✓ {relative_path:50s} ({chunk_count:4d} фрагментов)", flush=True)

    except Exception as e:
        print(f"[{idx:2d}/{len(doc_files)}] ✗ Ошибка {os.path.basename(file_path)}: {e}", flush=True)

print("="*70, flush=True)
print(f"📊 Всего фрагментов: {len(documents)}", flush=True)
print("="*70, flush=True)

# Генерация эмбеддингов
print("\n⚙️  Генерация эмбеддингов...", flush=True)
embeddings_tensor = encode_texts(documents)

print(f"\n✓ Размерность эмбеддингов: {embeddings_tensor.shape}", flush=True)

# Создание FAISS индекса
print("\n🔨 Создание FAISS индекса...", flush=True)
dimension = embeddings_tensor.shape[1]

if USE_GPU and FAISS_GPU_AVAILABLE:
    # GPU версия
    import faiss
    
    # Создаём CPU индекс
    cpu_index = faiss.IndexFlatL2(dimension)
    
    # Переносим на GPU
    res = faiss.StandardGpuResources()
    gpu_index = faiss.index_cpu_to_gpu(res, 0, cpu_index)
    
    # Добавляем векторы
    gpu_index.add(embeddings_tensor.detach().numpy().astype('float32'))
    
    # Копируем обратно на CPU для сохранения
    index = faiss.index_gpu_to_cpu(gpu_index)
    
    print(f"✓ Индекс создан на GPU 0: {torch.cuda.get_device_name(0)}", flush=True)
else:
    # CPU версия
    import faiss
    
    index = faiss.IndexFlatL2(dimension)
    index.add(embeddings_tensor.detach().numpy().astype('float32'))
    
    print("✓ Индекс создан на CPU", flush=True)

# ============================================================
# СОХРАНЕНИЕ БАЗЫ ДАННЫХ (КРОССПЛАТФОРМЕННОЕ)
# ============================================================
print("\n💾 Сохранение базы данных...", flush=True)

if IS_WINDOWS:
    # ============================================================
    # WINDOWS: Сохранение через временную папку (обход проблемы с кириллицей)
    # ============================================================
    
    # Создаем временную папку (без кириллицы, в системном temp)
    TEMP_BASE_DIR = tempfile.mkdtemp(prefix="rag_temp_")
    TEMP_INDEX_DIR = os.path.join(TEMP_BASE_DIR, "faiss_index")
    os.makedirs(TEMP_INDEX_DIR, exist_ok=True)
    
    print(f"   📁 Временная папка: {TEMP_BASE_DIR}", flush=True)
    print(f"   📁 Финальная папка: {index_dir}", flush=True)
    
    # Пути к временным файлам
    temp_faiss_path = os.path.join(TEMP_INDEX_DIR, "index.faiss")
    temp_docs_path = os.path.join(TEMP_INDEX_DIR, "documents.pkl")
    temp_meta_path = os.path.join(TEMP_INDEX_DIR, "metadatas.pkl")
    temp_config_path = os.path.join(TEMP_INDEX_DIR, "model_config.txt")
    
    # Сохраняем ВСЕ файлы во ВРЕМЕННУЮ папку
    print("   🔨 Создание FAISS индекса...", flush=True)
    faiss.write_index(index, temp_faiss_path)
    
    print("   📝 Сохранение документов...", flush=True)
    with open(temp_docs_path, "wb") as f:
        pickle.dump(documents, f)
    
    print("   📝 Сохранение метаданных...", flush=True)
    with open(temp_meta_path, "wb") as f:
        pickle.dump(metadatas, f)
    
    print("   ⚙️  Сохранение конфигурации модели...", flush=True)
    with open(temp_config_path, "w", encoding="utf-8") as f:
        f.write(MODEL_NAME)
    
    print("✓ База создана во временной папке", flush=True)
    
    # Копирование в финальную папку
    print("\n📦 Копирование в финальную папку...", flush=True)
    
    try:
        # Удаляем старую базу, если она есть
        if os.path.exists(index_dir):
            print(f"   🗑️  Удаление старой базы...", flush=True)
            shutil.rmtree(index_dir)
        
        # Копируем новую базу
        print(f"   📋 Копирование файлов...", flush=True)
        shutil.copytree(TEMP_INDEX_DIR, index_dir)
        
        # Проверка целостности
        print("   🔍 Проверка целостности...", flush=True)
        required_files = ["index.faiss", "documents.pkl", "metadatas.pkl", "model_config.txt"]
        for file in required_files:
            file_path = os.path.join(index_dir, file)
            if not os.path.exists(file_path):
                raise FileNotFoundError(f"Файл {file} не скопировался!")
            if os.path.getsize(file_path) == 0:
                raise ValueError(f"Файл {file} пустой после копирования!")
        
        print("✓ База успешно скопирована и проверена", flush=True)
        
        # Очистка временной папки
        print(f"   🧹 Очистка временной папки...", flush=True)
        shutil.rmtree(TEMP_BASE_DIR)
        print("✓ Временная папка удалена", flush=True)
        
    except Exception as e:
        print(f"\n❌ Ошибка при копировании: {e}", flush=True)
        print(f"⚠️  Временная папка сохранена: {TEMP_BASE_DIR}", flush=True)
        print(f"💡 Вы можете вручную скопировать файлы из неё в {index_dir}", flush=True)
        sys.exit(1)

else:
    # ============================================================
    # LINUX / MACOS: Прямая запись в финальную папку (кириллица работает нормально)
    # ============================================================
    
    # Создаем папку, если её нет
    os.makedirs(index_dir, exist_ok=True)
    
    # Сохраняем напрямую
    print("   🔨 Создание FAISS индекса...", flush=True)
    faiss.write_index(index, os.path.join(index_dir, "index.faiss"))
    
    print("   📝 Сохранение документов...", flush=True)
    with open(os.path.join(index_dir, "documents.pkl"), "wb") as f:
        pickle.dump(documents, f)
    
    print("   📝 Сохранение метаданных...", flush=True)
    with open(os.path.join(index_dir, "metadatas.pkl"), "wb") as f:
        pickle.dump(metadatas, f)
    
    print("   ⚙️  Сохранение конфигурации модели...", flush=True)
    with open(os.path.join(index_dir, "model_config.txt"), "w", encoding="utf-8") as f:
        f.write(MODEL_NAME)
    
    print("✓ База данных сохранена напрямую", flush=True)

print("\n✅ Все файлы базы данных успешно сохранены!", flush=True)

# Подсчёт времени работы
end_time = time.time()
elapsed_time = end_time - start_time

print("\n" + "="*70, flush=True)
print("🎉 УСПЕШНО!", flush=True)
print("="*70, flush=True)
print(f"  📁 Местоположение: {index_dir}", flush=True)
print(f"  📚 Файлов обработано: {len(doc_files)}", flush=True)
print(f"  📄 Фрагментов создано: {len(documents)}", flush=True)
print(f"  📦 Модель: {MODEL_NAME}", flush=True)
print(f"  🔢 Размерность векторов: {dimension}", flush=True)
print(f"  {'🎮' if USE_GPU and GPU_AVAILABLE else '💻'} Устройство: {'GPU' if USE_GPU and GPU_AVAILABLE else 'CPU'}", flush=True)
print(f"  ⏱️  Время работы: {format_time(elapsed_time)}", flush=True)
print("="*70, flush=True)
