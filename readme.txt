# Полный гайд: Расшифровка совещаний по ролям (M4A → текст)

## Шаг 1: Подготовка системы

```bash
# Обновляем систему
sudo apt update && sudo apt upgrade -y

# Устанавливаем необходимые пакеты
sudo apt install -y python3 python3-pip python3-venv ffmpeg git libavutil58 libavcodec60 libavformat60 libavdevice60 libavfilter9 libswscale7 libswresample4
# Проверяем ffmpeg (нужен для конвертации M4A)
ffmpeg -version

# Качаем проект с github.
git clone -b main git@github.com:DruidCat/pyqt-kobzona.git
```

### Проверка CUDA:
```bash
nvidia-smi
```
Должна отобразиться ваша видеокарта и версия CUDA (12.x).

Установка Python3.11 в виртуальном окружении pyenv, на котором работает WhisperX
pyenv необходим, чтоб в проекте не конфликтовали версии Python на одном компьютере.
# Устанавливаем пакеты для того, чтоб установить pynve:
sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libffi-dev python3-openssl

# Скачиваем pyenv в домашний каталог .pyenv
curl https://pyenv.run | bash

# Редактируем .bashrc, добавляем скрипт, запускающий pyenv:

# pyenv инструмент для запуска различных версий pyton
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Перезапускаем консоль, чтоб обновился .bashrc
source ~/.bashrc

# Запускаем в виртуальном пространстве Python 3.11 на котром написана WhisperX на момент написания статьи.
pyenv shell 3.11

# Проверить, что сделали всё правильно, должна отобразится версия 3.11
python3 --version

# Сделать версию по умолчанию для всех сессий, я так сделал
pyenv global 3.11

---

## Шаг 2: Создание проекта и окружения

```bash
# Создаём папку проекта, в эту папку установится проект вместе с нейронкой WhisperX в виртуальном пространстве venv
mkdir ~/git/kobzona && cd ~/git/kobzona

# Виртуальное окружение
python3 -m venv venv
source venv/bin/activate

# когда ты попадёшь в виртуальное пространство venv, из него можно будет выйти командой
deactivate
```

## Шаг 3: Установка полная всех библиотек в автоматическом режиме.
pip install --upgrade pip
pip install -r pipinstall.txt
```

---

## Шаг 4: Токен Hugging Face (для диаризации)

```bash
# 1. Зайдите на https://huggingface.co — зарегистрируйтесь
# 2. Примите лицензию pyannote, обязательно вводим название фирмы Dryads и сайт фирмы vc.com/DruidCat:
#	https://huggingface.co/pyannote/speaker-diarization
# 	https://huggingface.co/pyannote/speaker-diarization-3.1
#	https://huggingface.co/pyannote/speaker-diarization-community-1 
#	https://huggingface.co/pyannote/segmentation-3.0
#
# 3. Создайте токен: Settings → Access Tokens → New Token (Read)
# 4. Залогиньтесь:
hf auth login
# Вставьте токен когда попросит, при печатании токена не видно будет букв
```

---

## Шаг 5: Основной скрипт

Создайте файл `transcribe.py`:
Сам скрипт находится в этой же папке.

## Шаг 6: Запуск нейросети WhisperX

cd ~/git/kobzana
source venv/bin/activate
python transcribe.py

## Результат

В папке `~/Документы/КОБ зона протокол` для каждого файла появятся **2 файла**:

| Формат | Назначение |
|--------|-----------|
| `.txt` | Текстовый протокол для чтения |
| `.json` | Структурированные данные для обработки |

### Пример вывода `.txt`:
```
============================================================
ПРОТОКОЛ БЕСЕДЫ
Файл: совещание_15января
Дата расшифровки: 17.01.2025 14:30
============================================================

[SPEAKER_00]: Добрый день, коллеги. Начинаем планёрку.
[SPEAKER_01]: Здравствуйте.
[SPEAKER_00]: Алексей, доложи по продажам за декабрь.
[SPEAKER_01]: Итого за декабрь выручка составила сорок два миллиона.
[SPEAKER_02]: Могу сразу по маркетингу, если не против.
[SPEAKER_00]: Давай, Ольга.
[SPEAKER_02]: Конверсия выросла на двенадцать процентов после новогодней акции.
```

---

## ⚡ Оптимизации под вашу систему

```python
# Если файлы длинные (2+ часа), можно ускорить:
BATCH_SIZE = 24          # больше = быстрее (у вас RAM хватит)
COMPUTE_TYPE = "float16" # оптимально для RTX 50 series
WHISPER_MODEL = "large-v3"  # лучшее качество

```

## Запуск из коммандной строки

Редактируем .bashrc

