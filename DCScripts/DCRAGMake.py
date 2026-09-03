import warnings
warnings.filterwarnings("ignore", category=FutureWarning)

import os
import sys
import shutil
import pickle
from transformers import AutoTokenizer, AutoModel
import torch
import time
import threading
from datetime import datetime
import zipfile

# ============================================================
# ОПРЕДЕЛЕНИЕ РЕЖИМА ЗАПУСКА
# ============================================================

IS_GUI_MODE = os.environ.get('RAG_GUI_MODE', '0') == '1'
USE_GPU = os.environ.get('RAG_USE_GPU', '0') == '1'  # ← Новый флаг

# Определение доступности GPU
GPU_AVAILABLE = torch.cuda.is_available()

# Проверка faiss-gpu
try:
    if USE_GPU:
        import faiss.contrib.torch_utils  # Проверка faiss-gpu
        FAISS_GPU_AVAILABLE = True
    else:
        import faiss
        FAISS_GPU_AVAILABLE = False
except ImportError:
    import faiss
    FAISS_GPU_AVAILABLE = False
    if USE_GPU:
        print("⚠️  FAISS-GPU не установлен, используется CPU версия")
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

# Вывод информации о режиме работы
print("="*70)
print("🚀 СОЗДАНИЕ ВЕКТОРНОЙ БАЗЫ ДАННЫХ RAG")
print("="*70)
if USE_GPU and GPU_AVAILABLE and FAISS_GPU_AVAILABLE:
    print("🎮 Режим: GPU (CUDA)")
    print(f"   Устройство: {torch.cuda.get_device_name(0)}")
    print(f"   VRAM: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
elif USE_GPU and not GPU_AVAILABLE:
    print("⚠️  GPU запрошен, но CUDA недоступна")
    print("💻 Режим: CPU (fallback)")
    USE_GPU = False
elif USE_GPU and not FAISS_GPU_AVAILABLE:
    print("⚠️  GPU запрошен, но faiss-gpu не установлен")
    print("💻 Режим: CPU (fallback)")
    USE_GPU = False
else:
    print("💻 Режим: CPU")
print("="*70)

def create_backup_archive():
    """Создание архива папки base и перемещение в arch"""
    if not os.path.exists(data_dir):
        print("⚠️  Папка base не найдена, архивация пропущена")
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
    
    print(f"\n📦 Создание резервной копии базы данных...")
    print(f"   Архив: {archive_name}")
    
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
            
            print()  # Новая строка после прогресса
        
        # Получение размера архива
        archive_size = os.path.getsize(archive_path)
        size_mb = archive_size / (1024 * 1024)
        
        print(f"   ✓ Архив создан: {archive_name} ({size_mb:.1f} MB)")
        print(f"   📁 Местоположение: {arch_dir}")
        return True
    
    except Exception as e:
        print(f"\n   ✗ Ошибка при создании архива: {e}")
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
    print("="*70)
    print("⚠️  Обнаружена существующая векторная база данных RAG")
    print("="*70)

    if IS_GUI_MODE:
        # В GUI режиме всегда пересоздаём
        print("\n🗑️  Удаление старой базы данных...")
        shutil.rmtree(index_dir)
        print("✓ Старая база удалена\n", flush=True)
    else:
        response = input("\n🔄 Пересоздать векторную базу данных RAG? (Д/Н): ")
        
        if response in ['Д', 'д', 'Y', 'y']:
            print("\n🗑️  Удаление старой базы данных...")
            shutil.rmtree(index_dir)
            print("✓ Старая база удалена\n")
        else:
            print("\n❌ Операция отменена. Выход из программы.")
            sys.exit(0)

print("="*70)
print("🚀 СОЗДАНИЕ ВЕКТОРНОЙ БАЗЫ ДАННЫХ RAG")
print("="*70)

# ==================== ВТОРОЙ МОДУЛЬ: ПРОВЕРКА НОВЫХ ФАЙЛОВ В ADD ====================

# Проверка новых файлов в папке add
def check_and_move_new_files():
    """Проверка и перенос новых файлов из папки add в base"""
    if not os.path.exists(add_dir):
        return
    
    # Поиск txt файлов в папке add
    new_files = []
    for root, _, files in os.walk(add_dir):
        for file in files:
            if file.endswith(".txt"):
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
    print("="*70)
    print("📥 ОБНАРУЖЕНЫ НОВЫЕ ФАЙЛЫ В ПАПКЕ ДЛЯ ДОБАВЛЕНИЯ")
    print("="*70)
    print(f"\nПапка: {add_dir}\n")
    
    for idx, file_path in enumerate(new_files, 1):
        relative_path = os.path.relpath(file_path, add_dir)
        file_size = os.path.getsize(file_path)
        size_kb = file_size / 1024
        print(f"  [{idx}] {relative_path} ({size_kb:.1f} KB)")
    
    print(f"\n📊 Всего файлов: {len(new_files)}")
    print("="*70)
    
    response = input("\n🔄 Перенести файл(ы) в папку base? (Д/Н): ")
    
    if response in ['Д', 'д', 'Y', 'y']:
        # Создание резервной копии базы перед добавлением новых файлов
        if not create_backup_archive():
            print("\n❌ Ошибка создания архива. Операция отменена.")
            sys.exit(1)
        
        # Создание подпапки с текущей датой
        current_date = datetime.now().strftime("%Y-%m-%d")
        target_dir = os.path.join(data_dir, current_date)
        
        os.makedirs(target_dir, exist_ok=True)
        
        print(f"\n📁 Создана папка: {current_date}/")
        print("🔄 Перенос файлов...\n")
        
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
                print(f"  ✓ {os.path.basename(file_path)} → {current_date}/{file_name}")
                moved_count += 1
            except Exception as e:
                print(f"  ✗ Ошибка при переносе {os.path.basename(file_path)}: {e}")
        
        print(f"\n✓ Перенесено файлов: {moved_count}/{len(new_files)}\n")
        
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
        print("\n❌ Файлы не перенесены. Продолжение работы с текущей базой.\n")

# Вызываем проверку новых файлов ТОЛЬКО после подтверждения пересоздания RAG
check_and_move_new_files()

print("\n📥 Загрузка модели...")

# Определение устройства
device = torch.device('cuda' if USE_GPU and GPU_AVAILABLE else 'cpu')

tokenizer = AutoTokenizer.from_pretrained('sentence-transformers/all-MiniLM-L6-v2')
model = AutoModel.from_pretrained('sentence-transformers/all-MiniLM-L6-v2')

# Перемещаем модель на GPU если нужно
if USE_GPU and GPU_AVAILABLE:
    model = model.to(device)
    print(f"✓ Модель загружена на GPU: {torch.cuda.get_device_name(0)}")
else:
    print("✓ Модель загружена на CPU")

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
        self.enabled = not IS_GUI_MODE #Отключается в GUI режиме
    
    def run(self):
        while self.running:
            if self.message and self.enabled: #Проверка enabled
                sys.stdout.write(f'\r  {self.spinner[self.idx]} {self.message}')
                sys.stdout.flush()
                self.idx = (self.idx + 1) % 4
            time.sleep(0.1)
    
    def update_message(self, msg):
        self.message = msg
        if not self.enabled: #Если GUI, выводим сразу
            print(f"  {msg}", flush=True)
    
    def stop(self):
        self.running = False
        if self.enabled:
            sys.stdout.write('\r')
            sys.stdout.flush()

def encode_texts(texts, batch_size=32):
    """Кодирование текстов в эмбеддинги"""
    all_embeddings = []
    total = len(texts)
    
    # Увеличиваем batch_size для GPU
    if USE_GPU and GPU_AVAILABLE:
        batch_size = 128  # GPU может обработать больше
    
    # Вычисляем шаг для обновления (1% от общего количества)
    one_percent = max(1, total // 100)
    next_report = one_percent
    last_reported_percent = 0
    
    # Запуск спиннера в отдельном потоке
    spinner = SpinnerThread()
    spinner.start()
    
    # Определение устройства
    device = torch.device('cuda' if USE_GPU and GPU_AVAILABLE else 'cpu')
    
    for i in range(0, len(texts), batch_size):
        batch = texts[i:i+batch_size]
        encoded = tokenizer(batch, padding=True, truncation=True, 
                          max_length=512, return_tensors='pt')
        
        # Перемещаем данные на GPU если нужно
        if USE_GPU and GPU_AVAILABLE:
            encoded = {key: val.to(device) for key, val in encoded.items()}
        
        with torch.no_grad():
            model_output = model(**encoded)
            batch_embeddings = mean_pooling(model_output, encoded['attention_mask'])
            # Нормализация
            batch_embeddings = torch.nn.functional.normalize(batch_embeddings, p=2, dim=1)
            # Возвращаем на CPU для сохранения
            all_embeddings.append(batch_embeddings.cpu())
        
        # Обновление прогресса ТОЛЬКО при достижении следующего процента
        processed = i + len(batch)
        
        if processed >= next_report or processed == total:
            percent = int((processed / total) * 100)
            
            if percent > last_reported_percent or processed == total:
                spinner.update_message(f'Обработано {processed}/{total} фрагментов ({percent}%)')
                last_reported_percent = percent
                next_report += one_percent
    
    # Остановка спиннера
    spinner.stop()
    spinner.join()
    print(f'  ✓ Обработано {total}/{total} фрагментов (100%)')
    
    return torch.vstack(all_embeddings)

# Список всех текстовых файлов
print("\n📂 Поиск текстовых файлов...")
txt_files = []
for root, _, files in os.walk(data_dir):
    for file in files:
        if file.endswith(".txt"):
            txt_files.append(os.path.join(root, file))

print(f"✓ Найдено {len(txt_files)} текстовых файлов\n")
print("="*70)
print("📖 ОБРАБОТКА ФАЙЛОВ")
print("="*70)

# Чтение и разбиение текста
documents = []
metadatas = []

for idx, file_path in enumerate(txt_files, 1):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            text = f.read()
            # Разбиение по абзацам
            chunks = [chunk.strip() for chunk in text.split('\n\n') if chunk.strip()]
            
            chunk_count = 0
            for chunk in chunks:
                if len(chunk) > 50:
                    documents.append(chunk)
                    metadatas.append({
                        "source": file_path,
                        "filename": os.path.basename(file_path)
                    })
                    chunk_count += 1
        
        # Показываем относительный путь от data_dir
        relative_path = os.path.relpath(file_path, data_dir)
        print(f"[{idx}/{len(txt_files)}] ✓ {relative_path:50s} ({chunk_count:4d} фрагментов)", flush=True)
    except Exception as e:
        print(f"[{idx:2d}/{len(txt_files)}] ✗ Ошибка {os.path.basename(file_path)}: {e}")

print("="*70)
print(f"📊 Всего фрагментов: {len(documents)}")
print("="*70)

# Генерация эмбеддингов
print("\n⚙️  Генерация эмбеддингов...")
embeddings_tensor = encode_texts(documents)

print(f"\n✓ Размерность эмбеддингов: {embeddings_tensor.shape}")

# Создание FAISS индекса
print("\n🔨 Создание FAISS индекса...")
dimension = embeddings_tensor.shape[1]

if USE_GPU and FAISS_GPU_AVAILABLE:
    # GPU версия
    import faiss
    
    # Создаём CPU индекс
    cpu_index = faiss.IndexFlatL2(dimension)
    
    # Переносим на GPU
    res = faiss.StandardGpuResources()  # Инициализация GPU ресурсов
    gpu_index = faiss.index_cpu_to_gpu(res, 0, cpu_index)  # 0 = первая GPU
    
    # Добавляем векторы
    gpu_index.add(embeddings_tensor.detach().numpy().astype('float32'))
    
    # Копируем обратно на CPU для сохранения
    index = faiss.index_gpu_to_cpu(gpu_index)

    print(f"✓ Индекс создан на GPU 0: {torch.cuda.get_device_name(0)}") 
else:
    # CPU версия
    import faiss
    
    index = faiss.IndexFlatL2(dimension)
    index.add(embeddings_tensor.detach().numpy().astype('float32'))
    
    print("✓ Индекс создан на CPU")

# Сохранение
print("\n💾 Сохранение базы данных...")
os.makedirs(index_dir, exist_ok=True)
faiss.write_index(index, f"{index_dir}/index.faiss")

with open(f"{index_dir}/index.faiss", "rb") as f_check:
    pass

with open(f"{index_dir}/documents.pkl", "wb") as f:
    pickle.dump(documents, f)

with open(f"{index_dir}/metadatas.pkl", "wb") as f:
    pickle.dump(metadatas, f)

print("✓ База данных сохранена")

# Подсчёт времени работы
end_time = time.time()
elapsed_time = end_time - start_time

print("\n" + "="*70)
print("🎉 УСПЕШНО!")
print("="*70)
print(f"  📁 Местоположение: {index_dir}")
print(f"  📚 Файлов обработано: {len(txt_files)}")
print(f"  📄 Фрагментов создано: {len(documents)}")
print(f"  🔢 Размерность векторов: {dimension}")
print(f"  {'🎮' if USE_GPU and GPU_AVAILABLE else '💻'} Устройство: {'GPU' if USE_GPU and GPU_AVAILABLE else 'CPU'}")
print(f"  ⏱️  Время работы: {format_time(elapsed_time)}")
print("="*70)
