#!/usr/bin/env python3
"""
Транскрибер v5.6 (интеграция с PyQt6)
"""

# ============================================================
# ПОДАВЛЕНИЕ ВСЕХ ПРЕДУПРЕЖДЕНИЙ И ЛОГОВ
# ============================================================
import warnings
import logging
import os
import sys

warnings.filterwarnings("ignore")
os.environ['PYTHONWARNINGS'] = 'ignore'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

logging.basicConfig(level=logging.ERROR, format='%(message)s')

loggers_to_silence = [
    "lightning", "lightning.pytorch", "lightning.pytorch.utilities",
    "lightning.pytorch.utilities.upgrade_checkpoint", "pytorch_lightning",
    "whisperx", "whisperx.vads", "whisperx.vads.pyannote", "whisperx.asr",
    "pyannote", "pyannote.audio", "pyannote.audio.core.io",
    "pyannote.audio.utils.reproducibility", "transformers", "torch",
]

for logger_name in loggers_to_silence:
    logger = logging.getLogger(logger_name)
    logger.setLevel(logging.ERROR)
    logger.propagate = False

# ============================================================
# ИМПОРТЫ
# ============================================================

import whisperx
import torch
import json
import gc
import time
import threading
from datetime import datetime, timedelta
from pathlib import Path

# ============================================================
# ОПРЕДЕЛЕНИЕ РЕЖИМА ЗАПУСКА
# ============================================================

# ← НОВОЕ: Проверяем, запущен ли скрипт через GUI
IS_GUI_MODE = os.environ.get('TRANSCRIBE_GUI_MODE', '0') == '1'

# ============================================================
# КЛАСС АНИМАЦИИ ПРОГРЕССА (только для терминала)
# ============================================================

class Spinner:
    """Анимированный спиннер для индикации процесса"""
    
    def __init__(self, message="Обработка"):
        self.spinner_chars = ['|', '/', '-', '\\']
        self.idx = 0
        self.message = message
        self.running = False
        self.thread = None
        self.enabled = not IS_GUI_MODE
    
    def _spin(self):
        """Внутренний метод для вращения"""
        while self.running:
            char = self.spinner_chars[self.idx % len(self.spinner_chars)]
            sys.stdout.write(f'\r  {char} {self.message}')
            sys.stdout.flush()
            self.idx += 1
            time.sleep(0.1)
    
    def start(self):
        """Запуск анимации"""
        if not self.enabled:
            print(f"  {self.message}", flush=True)
            return
        
        self.running = True
        self.thread = threading.Thread(target=self._spin, daemon=True)
        self.thread.start()
    
    def stop(self, final_message=None):
        """Остановка анимации"""
        if not self.enabled:
            if final_message:
                print(f"  ✓ {final_message}", flush=True)
            return
        
        self.running = False
        if self.thread:
            self.thread.join()
        
        if final_message:
            sys.stdout.write(f'\r  ✓ {final_message}\n')
        else:
            sys.stdout.write(f'\r  ✓ {self.message}\n')
        sys.stdout.flush()

# ============================================================
# НАСТРОЙКИ (с поддержкой переменных окружения)
# ============================================================

DEVICE = "cuda"
COMPUTE_TYPE = "int8"
WHISPER_MODEL = "large-v2"
BATCH_SIZE = 16

MIN_SPEAKERS = 2
MAX_SPEAKERS = 5

INPUT_DIR = os.environ.get(
    'TRANSCRIBE_INPUT_DIR',
    str(Path.home() / "Музыка" / "КОБ зона протокол")
)

OUTPUT_DIR = os.environ.get(
    'TRANSCRIBE_OUTPUT_DIR',
    str(Path.home() / "Документы" / "КОБ зона протокол")
)

SUPPORTED_FORMATS = [
    '.m4a', '.M4A', '.arm', '.ARM', '.mp3', '.MP3',
    '.matroska', '.MATROSKA', '.mka', '.MKA', '.mkv', '.MKV',
    '.mks', '.MKS', '.webm', '.WEBM', '.weba', '.WEBA',
    '.wav', '.WAV', '.ogg', '.OGG', '.oga', '.OGA', '.ogv', '.OGV',
    '.flac', '.FLAC', '.aac', '.AAC', '.m4b', '.M4B',
    '.wma', '.WMA', '.wmv', '.WMV', '.opus', '.OPUS',
    '.mp4', '.MP4', '.mov', '.MOV', '.avi', '.AVI',
    '.3gp', '.3GP', '.amr', '.AMR',
]

# ============================================================
# ФУНКЦИИ
# ============================================================

def get_hf_token():
    """Получение токена HuggingFace"""
    for var in ["HF_TOKEN", "HUGGING_FACE_HUB_TOKEN", "HF_AUTH_TOKEN"]:
        token = os.environ.get(var)
        if token:
            return token
    
    for token_path in [
        Path.home() / ".cache" / "huggingface" / "token",
        Path.home() / ".huggingface" / "token"
    ]:
        if token_path.exists():
            try:
                return token_path.read_text().strip()
            except:
                pass
    
    return None


def convert_audio_to_wav(input_path: str, wav_path: str, file_ext: str):
    """Конвертация с анимацией"""
    import subprocess
    
    spinner = Spinner(f"🔄 Конвертация {file_ext.upper()} → WAV...")
    spinner.start()
    
    result = subprocess.run([
        "ffmpeg", "-y", "-i", input_path,
        "-ar", "16000", "-ac", "1",
        "-c:a", "pcm_s16le",
        "-loglevel", "error",
        wav_path
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        spinner.stop(f"🔄 Конвертация {file_ext.upper()} → WAV завершена")
    else:
        spinner.stop(f"🔄 Ошибка конвертации: {result.stderr[:50]}")
        return False
    
    return True


def is_already_processed(filename: str, output_dir: str) -> bool:
    """Проверка обработанных файлов"""
    txt_exists = os.path.exists(os.path.join(output_dir, f"{filename}.txt"))
    json_exists = os.path.exists(os.path.join(output_dir, f"{filename}.json"))
    return txt_exists and json_exists


def get_audio_files(directory: Path, output_dir: str):
    """Сканирование файлов"""
    all_files = []
    for ext in SUPPORTED_FORMATS:
        all_files.extend(directory.glob(f"*{ext}"))
    all_files = sorted(set(all_files))
    
    new_files = [f for f in all_files if not is_already_processed(f.stem, output_dir)]
    return all_files, new_files


def transcribe_with_diarization(audio_path: str, language: str = "ru"):
    """Полный пайплайн с анимацией"""
    gc.collect()
    torch.cuda.empty_cache()
    
    # 1. Транскрипция
    spinner = Spinner(f"📥 Загрузка модели Whisper ({WHISPER_MODEL})...")
    spinner.start()
    
    model = whisperx.load_model(
        WHISPER_MODEL,
        device=DEVICE,
        compute_type=COMPUTE_TYPE,
        language=language
    )
    spinner.stop(f"📥 Модель Whisper загружена")

    spinner = Spinner("🎙️ Транскрипция аудио...")
    spinner.start()
    
    audio = whisperx.load_audio(audio_path)

    # Нормализация громкости
    import numpy as np
    audio_max = np.abs(audio).max()
    if audio_max > 0:
        audio = audio / audio_max * 0.95
    
    try:
        result = model.transcribe(audio, batch_size=BATCH_SIZE, language=language)
    except RuntimeError as e:
        if "out of memory" in str(e).lower():
            spinner.stop("🎙️ Недостаточно памяти, уменьшаем batch...")
            torch.cuda.empty_cache()
            
            spinner = Spinner("🎙️ Транскрипция (batch=1)...")
            spinner.start()
            result = model.transcribe(audio, batch_size=1, language=language)
            spinner.stop(f"🎙️ Транскрипция завершена ({len(result['segments'])} сегментов)")
        else:
            raise
    else:
        spinner.stop(f"🎙️ Транскрипция завершена ({len(result['segments'])} сегментов)")
    
    del model
    gc.collect()
    torch.cuda.empty_cache()

    # 2. Выравнивание
    spinner = Spinner("📐 Выравнивание таймкодов...")
    spinner.start()
    
    model_a, metadata = whisperx.load_align_model(
        language_code=result["language"],
        device=DEVICE
    )
    result = whisperx.align(
        result["segments"], model_a, metadata, audio, DEVICE,
        return_char_alignments=False
    )
    
    spinner.stop("📐 Выравнивание завершено")
    
    del model_a
    gc.collect()
    torch.cuda.empty_cache()

    # 3. Диаризация
    spinner = Spinner("👥 Загрузка модели диаризации...")
    spinner.start()
    
    auth_token = get_hf_token()
    if not auth_token:
        spinner.stop("👥 Ошибка: токен HF не найден")
        sys.exit(1)
    
    from pyannote.audio import Pipeline
    import pandas as pd
    import numpy as np
    
    diarize_pipeline = None
    
    for model_name in [
        "pyannote/speaker-diarization-3.1",
        "pyannote/speaker-diarization"
    ]:
        for token_arg in [
            {"token": auth_token},
            {"use_auth_token": auth_token},
            {}
        ]:
            try:
                diarize_pipeline = Pipeline.from_pretrained(model_name, **token_arg)
                spinner.stop(f"👥 Модель загружена: {model_name}")
                break
            except:
                continue
        if diarize_pipeline:
            break
    
    if not diarize_pipeline:
        spinner.stop("👥 Ошибка загрузки модели")
        sys.exit(1)
    
    diarize_pipeline.to(torch.device(DEVICE))
    
    spinner = Spinner("👥 Определение спикеров...")
    spinner.start()
    
    audio_dict = {
        "waveform": torch.from_numpy(audio[np.newaxis, :]).float(),
        "sample_rate": 16000
    }
    
    diarize_output = diarize_pipeline(
        audio_dict,
        min_speakers=MIN_SPEAKERS,
        max_speakers=MAX_SPEAKERS
    )
    
    # 4. Извлечение сегментов
    diarization_segments = []
    annotation = diarize_output.speaker_diarization
    
    for segment, track, label in annotation.itertracks(yield_label=True):
        diarization_segments.append({
            'start': segment.start,
            'end': segment.end,
            'speaker': label
        })
    
    if not diarization_segments:
        spinner.stop("👥 Ошибка: не удалось извлечь сегменты")
        sys.exit(1)
    
    diarize_df = pd.DataFrame(diarization_segments)
    num_speakers = len(diarize_df['speaker'].unique())
    
    spinner.stop(f"👥 Определено спикеров: {num_speakers}")

    # 5. Привязка спикеров
    spinner = Spinner("🔗 Привязка спикеров к тексту...")
    spinner.start()
    
    result = whisperx.assign_word_speakers(diarize_df, result)
    
    spinner.stop("🔗 Привязка завершена")

    return result


def format_time(seconds: float) -> str:
    """Форматирование времени"""
    if seconds is None:
        return "00:00"
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    return f"{h:02d}:{m:02d}:{s:02d}" if h > 0 else f"{m:02d}:{s:02d}"


def format_duration(seconds: float) -> str:
    """Форматирование длительности"""
    td = timedelta(seconds=int(seconds))
    hours, remainder = divmod(td.seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    
    if td.days > 0:
        return f"{td.days}д {hours}ч {minutes}м {seconds}с"
    elif hours > 0:
        return f"{hours}ч {minutes}м {seconds}с"
    elif minutes > 0:
        return f"{minutes}м {seconds}с"
    else:
        return f"{seconds}с"


def calculate_speaker_stats(result: dict):
    """Расчет статистики"""
    speakers_stats = {}
    
    for seg in result["segments"]:
        speaker = seg.get("speaker", "НЕИЗВЕСТНО")
        
        if speaker not in speakers_stats:
            speakers_stats[speaker] = {
                "segments": 0,
                "words": 0,
                "time": 0.0
            }
        
        speakers_stats[speaker]["segments"] += 1
        speakers_stats[speaker]["words"] += len(seg.get("text", "").split())
        speakers_stats[speaker]["time"] += seg.get("end", 0) - seg.get("start", 0)
    
    return speakers_stats


def save_results(result: dict, filename: str, processing_time: float):
    """Сохранение результатов"""
    
    speakers_stats = calculate_speaker_stats(result)
    
    # TXT
    txt_path = os.path.join(OUTPUT_DIR, f"{filename}.txt")
    with open(txt_path, "w", encoding="utf-8") as f:
        f.write(f"{'='*70}\n")
        f.write(f"ПРОТОКОЛ: {filename}\n")
        f.write(f"Дата: {datetime.now().strftime('%d.%m.%Y %H:%M')}\n")
        f.write(f"{'='*70}\n\n")
        
        f.write(f"📊 СТАТИСТИКА ПО УЧАСТНИКАМ:\n")
        f.write(f"{'─'*70}\n")
        f.write(f"Всего участников: {len(speakers_stats)}\n\n")
        
        for speaker in sorted(speakers_stats.keys()):
            stats = speakers_stats[speaker]
            f.write(f"{speaker}:\n")
            f.write(f"  • Реплик: {stats['segments']}\n")
            f.write(f"  • Слов: {stats['words']}\n")
            f.write(f"  • Время речи: {format_time(stats['time'])}\n\n")
        
        f.write(f"{'='*70}\n\n")
        f.write(f"ТРАНСКРИПЦИЯ:\n")
        f.write(f"{'='*70}\n\n")
        
        current_speaker = None
        for seg in result["segments"]:
            speaker = seg.get("speaker", "НЕИЗВЕСТНО")
            text = seg.get("text", "").strip()
            start = format_time(seg.get("start", 0))

            if not text:
                continue

            if speaker != current_speaker:
                f.write(f"\n{'─'*70}\n{speaker}:\n{'─'*70}\n")
                current_speaker = speaker

            f.write(f"[{start}] {text}\n")
    
    print(f"  💾 TXT: {txt_path}", flush=True)
    
    # JSON
    json_path = os.path.join(OUTPUT_DIR, f"{filename}.json")
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump({
            "file": filename,
            "date": datetime.now().isoformat(),
            "processing_time_seconds": round(processing_time, 2),
            "processing_time_formatted": format_duration(processing_time),
            "statistics": {
                speaker: {
                    "segments": stats["segments"],
                    "words": stats["words"],
                    "speech_time_seconds": round(stats["time"], 2),
                    "speech_time_formatted": format_time(stats["time"])
                }
                for speaker, stats in speakers_stats.items()
            },
            "segments": [
                {
                    "start": round(s.get("start", 0), 2),
                    "end": round(s.get("end", 0), 2),
                    "speaker": s.get("speaker", "UNKNOWN"),
                    "text": s.get("text", "").strip()
                }
                for s in result["segments"]
            ]
        }, f, ensure_ascii=False, indent=2)
    
    print(f"  💾 JSON: {json_path}", flush=True)

def process_file(audio_path: Path, index: int, total: int):
    """Обработка одного файла"""
    filename = audio_path.stem
    file_ext = audio_path.suffix
    
    print(f"\n{'='*70}", flush=True)
    print(f"📂 ({index}/{total}) {filename}{file_ext}", flush=True)
    print(f"{'='*70}", flush=True)

    file_start_time = time.time()

    wav_path = os.path.join(OUTPUT_DIR, f"{filename}_temp.wav")
    
    if not convert_audio_to_wav(str(audio_path), wav_path, file_ext):
        print(f"  ❌ Ошибка конвертации", flush=True)
        return

    try:
        result = transcribe_with_diarization(wav_path)
        processing_time = time.time() - file_start_time
        
        print(f"\n  💾 Сохранение результатов...", flush=True)
        save_results(result, filename, processing_time)
        
        speakers_stats = calculate_speaker_stats(result)
        print(f"\n  📊 Статистика:", flush=True)
        for speaker in sorted(speakers_stats.keys()):
            stats = speakers_stats[speaker]
            print(f"     {speaker}: {stats['segments']} реплик, {stats['words']} слов, {format_time(stats['time'])}", flush=True)
        
        print(f"\n  ⏱️  Обработано за: {format_duration(processing_time)}", flush=True)
        print(f"  ✅ Готово!", flush=True)

    except Exception as e:
        print(f"\n  ❌ Ошибка: {e}", flush=True)
        import traceback
        traceback.print_exc()
    finally:
        if os.path.exists(wav_path):
            os.remove(wav_path)

def main():
    print(f"\n{'='*70}", flush=True)
    print(f"🎙️  КОБ зона протокол", flush=True)
    print(f"{'='*70}\n", flush=True)

    script_start_time = time.time()

    os.makedirs(INPUT_DIR, exist_ok=True)
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    print(f"📁 Папка с аудио: {INPUT_DIR}", flush=True)
    print(f"💾 Папка результатов: {OUTPUT_DIR}\n", flush=True)

    all_files, new_files = get_audio_files(Path(INPUT_DIR), OUTPUT_DIR)
    
    if not all_files:
        print(f"⚠️  Аудиофайлы не найдены в {INPUT_DIR}/", flush=True)
        return

    already_processed = len(all_files) - len(new_files)
    
    print(f"📁 Всего файлов: {len(all_files)}", flush=True)
    if already_processed > 0:
        print(f"   ✓ Уже обработано: {already_processed}", flush=True)
        print(f"   🆕 Новых файлов: {len(new_files)}", flush=True)
    
    if not new_files:
        print(f"\n✅ Все файлы уже обработаны!", flush=True)
        print(f"   Результаты в: {os.path.abspath(OUTPUT_DIR)}", flush=True)
        return
    
    by_format = {}
    for f in new_files:
        ext = f.suffix.lower()
        by_format.setdefault(ext, []).append(f)
    
    print(f"\nФайлы к обработке ({len(new_files)}):", flush=True)
    for ext in sorted(by_format.keys()):
        files = by_format[ext]
        total_size = sum(f.stat().st_size for f in files) / (1024**2)
        print(f"   {ext.upper()}: {len(files)} файл(ов), {total_size:.1f} МБ", flush=True)
    
    print(flush=True)
    for f in new_files:
        print(f"   • {f.name} ({f.stat().st_size/1024**2:.1f} МБ)", flush=True)

    if torch.cuda.is_available():
        print(f"\n🖥️  {torch.cuda.get_device_name(0)}", flush=True)

    print(f"\n🔑 Токен HuggingFace...", flush=True)
    if get_hf_token():
        print(f"   ✓", flush=True)
    else:
        print(f"   ❌ Выполните: huggingface-cli login", flush=True)
        return

    total_files = len(new_files)

    for i, audio_file in enumerate(new_files, start=1):
        process_file(audio_file, i, total_files)

    total_time = time.time() - script_start_time

    print(f"\n{'='*70}", flush=True)
    print(f"🎉 ВСЕ ФАЙЛЫ ОБРАБОТАНЫ ЗА: {format_duration(total_time)}", flush=True)
    print(f"{'='*70}", flush=True)
    print(f"Результаты: {os.path.abspath(OUTPUT_DIR)}", flush=True)
    print(f"{'='*70}\n", flush=True)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n⚠️ Прервано пользователем", flush=True)
