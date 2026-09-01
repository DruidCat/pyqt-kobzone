# Любимая КОБзона

Приложение для управления локальными языковыми моделями с графическим интерфейсом на PyQt6 и интеграцией с LM Studio.

## Описание

Любимая КОБзона - это desktop-приложение с графическим интерфейсом для работы с локальными языковыми моделями и интеграцией с LM Studio. Проект включает в себя использование AI для обработки информации.

## Требования

- Python 3.13
- PyQt6
- LM Studio (для работы с языковыми моделями)

## Установка

### Ubuntu 26.04

1. **Обновите систему и установите необходимые зависимости:**

```bash
sudo apt update
sudo apt install -y python3.13 python3.13-venv python3-pip git curl ffmpeg
```

2. **Клонируйте репозиторий:**

```bash
git clone https://github.com/DruidCat/pyqt-kobzone.git
cd pyqt-kobzone
```

3. **Создайте виртуальное окружение:**

```bash
python3.13 -m venv venv
source venv/bin/activate
```

```bash
# Когда ты попадёшь в виртуальное пространство venv, из него можно будет выйти командой
deactivate
```

4. **Установите зависимости:**

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

5. **Установите LM Studio:**

```bash
# Скачайте LM Studio с официального сайта
wget https://lmstudio.ai/download/linux -O lmstudio.AppImage
chmod +x lmstudio.AppImage
./lmstudio.AppImage
```

6. **Настройте LM Studio:**
   - Запустите LM Studio
   - Скачайте нужную языковую модель
   - Запустите локальный сервер (обычно на порту 1234)

7. **Запустите приложение:**

```bash
python3.13 main.py
```

### Windows 10, 11

1. **Установите Python 3.13:**
   - Скачайте Python 3.13 с официального сайта: https://www.python.org/downloads/release/python-31314/
   - При установке обязательно отметьте "Add Python 3.13 to PATH"
   - Выберите "Custom installation" и убедитесь, что установлены pip и IDLE

2. **Установите Git (опционально):**
   - Скачайте с https://git-scm.com/download/win
   - Или скачайте проект напрямую как ZIP-архив с GitHub

3. **Клонируйте репозиторий:**

Через Git:
```cmd
git clone https://github.com/DruidCat/pyqt-kobzone.git
cd pyqt-kobzone
```

Или распакуйте скачанный ZIP-архив и откройте папку в командной строке.

4. **Создайте виртуальное окружение:**

```cmd
python -m venv venv
venv\Scripts\activate
```

```bash
# Когда ты попадёшь в виртуальное пространство venv, из него можно будет выйти командой
deactivate
```

5. **Установите зависимости:**

```cmd
python -m pip install --upgrade pip
pip install -r requirements.txt
```

6. **Установите LM Studio:**
   - Скачайте LM Studio для Windows: https://lmstudio.ai/
   - Запустите установщик и следуйте инструкциям
   - После установки запустите LM Studio

7. **Настройте LM Studio:**
   - Запустите LM Studio
   - Скачайте нужную языковую модель (рекомендуется начать с моделей до 7B параметров)
   - Перейдите во вкладку "Local Server"
   - Запустите сервер (по умолчанию на http://localhost:1234)

8. **Запустите приложение:**

```cmd
python main.py
```

## Структура проекта

```
pyqt-kobzone/
├── DCButtons/			# Кнопки приложения
├── DCMethods/			# Виджеты приложения
├── DCPages/			# Страницы приложения
├── DCScripts/			# Python скрипты приложения
├── DCSettings/			# Настройки приложения
├── resources/			# Ресурсы проекта
├── main.py				# Главный файл приложения
├── README.md			# Документация
├── requirements.txt	# Зависимости проекта
├── resources.qrc		# Таблица ресурсов проекта
└── ru.KOBzone.qml		# Главный qml файл
```

## Конфигурация

### Настройка подключения к LM Studio

По умолчанию приложение подключается к LM Studio по адресу `http://localhost:1234`. 

## Использование

После запуска приложения откроется графическое окно с интерфейсом для работы с AI-моделями.

Основные функции:
- Нейро анализ документов
- Редактирование текста
- Транскрибация

## Решение проблем

**Ошибка подключения к LM Studio:**
- Убедитесь, что LM Studio запущен
- Проверьте, что локальный сервер активен (вкладка "Local Server" в LM Studio)
- Проверьте порт подключения (по умолчанию 1234)

**Проблемы с GUI на Linux:**
```bash
sudo apt install libxcb-xinerama0 libxcb-cursor0
```

### Windows

**Ошибка: "python is not recognized"**
- Переустановите Python 3.13 с галочкой "Add Python to PATH"
- Или добавьте путь к Python в переменные среды вручную:
  - Обычно: `C:\Users\<Username>\AppData\Local\Programs\Python\Python313`

**Ошибка при установке PyQt6:**
- Убедитесь, что используете 64-битную версию Python 3.13
- Попробуйте обновить pip: `python -m pip install --upgrade pip`

**LM Studio не подключается:**
- Проверьте, что LM Studio запущен
- Убедитесь, что в настройках LM Studio включен локальный сервер
- Проверьте брандмауэр Windows - разрешите подключения для LM Studio
- Попробуйте открыть http://localhost:1234 в браузере для проверки

**Медленная работа с моделями:**
- Используйте модели меньшего размера (3B-7B параметров)
- Убедитесь, что в LM Studio включено GPU ускорение (если доступно)
- Выделите больше RAM для приложения в настройках LM Studio

## Рекомендуемые модели для LM Studio

Для начала работы рекомендуются следующие модели:

- **Для слабых ПК (4-8 GB RAM):**
  - Phi-3-mini (3.8B)
  - TinyLlama (1.1B)

- **Для средних ПК (8-16 GB RAM):**
  - Llama-3-8B
  - Mistral-7B
  - Gemma-7B

- **Для мощных ПК (16+ GB RAM):**
  - Llama-3-13B
  - Mixtral-8x7B

## Создание исполняемого файла (опционально)

### Для Windows:

```cmd
pip install pyinstaller
pyinstaller --onefile --windowed --name KobZone main.py
```

Исполняемый файл будет в папке `dist/`

### Для Ubuntu:

```bash
pip install pyinstaller
pyinstaller --onefile --windowed --name KobZone main.py
```

## Автор

DruidCat

## Лицензия

Информация о лицензии проекта уточняется в репозитории.

## Ссылки

- GitHub: https://github.com/DruidCat/pyqt-kobzone
- Документация PyQt6: https://www.riverbankcomputing.com/static/Docs/PyQt6/
- LM Studio: https://lmstudio.ai/
- Python 3.13: https://www.python.org/downloads/release/python-31314/

---

**Примечание:** 
- Перед использованием убедитесь, что у вас установлены все необходимые зависимости
- LM Studio должен быть запущен и настроен для работы приложения с AI-функциями
- Для работы с языковыми моделями требуется достаточно оперативной памяти (минимум 8 GB)
- Первый запуск может быть медленным из-за загрузки модели в LM Studio

**Полный гайд: Расшифровка совещаний по ролям (M4A → текст)**
```bash
# Устанавливаем необходимые пакеты кодеков
sudo apt install -y ffmpeg libavutil58 libavcodec60 libavformat60 libavdevice60 libavfilter9 libswscale7 libswresample4
# Проверяем ffmpeg (нужен для конвертации M4A)
ffmpeg --version
```
**Проверка CUDA:**
```bash
nvidia-smi
```
Должна отобразиться ваша видеокарта и версия CUDA (12.x).

**Установка Python3.13 в виртуальном окружении pyenv, на котором работает WhisperX**
pyenv необходим, чтоб в проекте не конфликтовали версии Python на одном компьютере.
```bash
# Устанавливаем пакеты для того, чтоб установить pynve если через apt не получилось:
sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libffi-dev python3-openssl
# Скачиваем pyenv в домашний каталог .pyenv
curl https://pyenv.run | bash
```

Редактируем .bashrc, добавляем скрипт, запускающий pyenv:

```code
# pyenv инструмент для запуска различных версий pyton
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```

```bash
# Перезапускаем консоль, чтоб обновился .bashrc
source ~/.bashrc

# Скачать python 3.13 через pyenv
pyenv install 3.13.14

# Запускаем в виртуальном пространстве Python 3.13 на котром написана WhisperX на момент написания статьи.
pyenv shell 3.13

# Проверить, что сделали всё правильно, должна отобразится версия 3.13
python3 --version

# Сделать версию по умолчанию для всех сессий, я так сделал
pyenv global 3.13
```

**Токен Hugging Face (для диаризации)**
    - 1. Зайдите на https://huggingface.co — зарегистрируйтесь
    - 2. Примите лицензию pyannote, обязательно вводим название фирмы и сайт фирмы:
        https://huggingface.co/pyannote/speaker-diarization
        https://huggingface.co/pyannote/speaker-diarization-3.1
        https://huggingface.co/pyannote/speaker-diarization-community-1 
        https://huggingface.co/pyannote/segmentation-3.0

    - 3. Создайте токен: Settings → Access Tokens → New Token (Read)
    - 4. Залогиньтесь:
```cmd
hf auth login
```

**Вставьте токен когда попросит, при печатании токена не видно будет букв**

