# Любимая КОБзона

Desktop-приложение с графическим интерфейсом для работы с локальными языковыми моделями
через LM Studio или Bionic. Приложение использует AI для обработки информации.

## Описание

- СОЗДАНИЕ RAG БД — документы загружаются в базу данных, на которую опирается языковая модель.
- ТРАНСКРИБАЦИЯ — распознавание аудиозаписей разговоров, встреч, лекций, выступлений с
  переводом в текст.
- ИСПРАВЛЕНИЕ ТЕКСТА — исправление текста, неверно распознанного нейросетью.
- НЕЙРО АНАЛИЗ ДОКУМЕНТОВ — анализ текстов с подключением RAG баз данных и постановкой
  конкретных вопросов нейросети; ответ формируется по документам и данным из RAG базы.

## Требования

- Python 3.13 (64-битный)
- PyQt6 (Qt 6 устанавливается автоматически вместе с ним — см. «Про Qt 6»)
- LM Studio или Bionic (для работы с языковыми моделями)

## Про Qt 6

Приложение написано на QML, поэтому для запуска нужен не только Python, но и сам Qt 6.
PyQt6 — обёртка над библиотеками Qt; при установке через pip вместе с ним автоматически
устанавливается комплект Qt 6, отдельная установка Qt обычно НЕ нужна:

```bash
# PyQt6==6.10.2 из requirements.txt тянет за собой PyQt6-Qt6 (комплект Qt 6.10) и sip
pip install -r requirements.txt
```

Проверка версии Qt, фактически установленного в виртуальном окружении:

```bash
# В venv — вывод версии Qt и версии PyQt (команда в одну строку, короче не сделать):
python - <<'PYEOF'
from PyQt6.QtCore import QT_VERSION_STR, PYQT_VERSION_STR
print('Qt', QT_VERSION_STR, '| PyQt', PYQT_VERSION_STR)
PYEOF
```

Правило совместимости: PyQt6-колёса с PyPI собраны под конкретный компилятор, на Windows —
под MSVC. Смешивать Qt из установщика Qt (комплекты MinGW, llvm-mingw) и PyQt6 из pip
нельзя: их DLL ABI-несовместимы, QML выдаёт ошибку «Cannot load library».
Системные требования и особенности по операционным системам — в соответствующих
подразделах главы «Установка».

Отдельный Qt (Qt Creator, C++-проекты, утилиты rcc, qmllint) устанавливается только при
необходимости: официальный онлайн-установщик https://www.qt.io/download-qt-installer или
встроенный Maintenance Tool. Для работы КОБзоны это не требуется, достаточно pip.

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
# Выйти из виртуального окружения venv можно командой
deactivate
```

4. **Установите зависимости:**

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

5. **Создание ресурсов:**

```bash
python3.13 DCScripts/DCCompileRCC.py
```

6. **Установите LM Studio:**

```bash
# Установите libfuse2, чтоб запускать *.AppImage
sudo apt install libfuse2
# Скачайте LM Studio с официального сайта
wget https://lmstudio.ai/download/linux -O lmstudio.AppImage
chmod +x lmstudio.AppImage
./lmstudio.AppImage --no-sandbox
# или в песочнице
./lmstudio.AppImage
```

7. **Настройте LM Studio или Bionic:**
   - Запустите LM Studio или Bionic
   - Скачайте нужную языковую модель
   - Перейдите во вкладку "Developer" -> "Status: Running"
   - Запустите локальный сервер "Running" (по умолчанию Base URL http://localhost:1234)

8. **Запустите приложение:**

```bash
python3.13 main.py
```

9. **Установите sandbox firejail:**

```bash
# Установите firejail, чтоб запускать LM Studio или Bionic в защищённой песочнице (sandbox).
sudo apt install firejail
```

Qt 6 из pip-колеса самодостаточен, но ему нужны системные библиотеки X11/xcb.
Если приложение запускается, но окно пустое или падает с ошибкой xcb, установить:

```bash
sudo apt install -y libxcb-xinerama0 libxcb-cursor0 libxkbcommon-x11-0 libxcb-icccm4 \
    libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0
```

На Wayland (по умолчанию в Ubuntu 26.04) дополнительно нужны платформенные плагины Qt,
обычно они уже есть в системе. Если QML-модули не находятся, проверьте, что приложение
не запускается из чужого окружения с переменными QT_PLUGIN_PATH / QML2_PATH от другой
сборки Qt.

### Windows 10, 11

1. **Установите Python 3.13:**
   - Скачайте Python 3.13 с официального сайта: https://www.python.org/downloads/release/python-31315/
   - При установке обязательно отметьте "Add Python 3.13 to PATH"
   - Выберите "Custom installation" и убедитесь, что установлены pip и IDLE

2. **Установите Git (опционально):**
   - Скачайте с https://git-scm.com/download/win
   - Или скачайте проект напрямую как ZIP-архив с GitHub

3. **Клонируйте репозиторий:**

Через консоль Git Bash:
```cmd
git clone https://github.com/DruidCat/pyqt-kobzone.git
cd pyqt-kobzone
```

Или распакуйте скачанный ZIP-архив и откройте папку в командной строке.

4. **Создайте виртуальное окружение:**
Через консоль Git Bash:
```cmd
python -m venv venv
source venv\Scripts\activate
```

```bash
# Выйти из виртуального окружения venv можно командой
deactivate
```

5. **Установите зависимости:**

```cmd
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Qt 6 устанавливать отдельно НЕ нужно и вредно: PyQt6 из pip приносит собственный
MSVC-комплект Qt 6. Условия корректной работы:
   - Python 3.13 обязан быть 64-битным (win_amd64-колесо PyQt6 на 32-битный Python
     не установится);
   - если ранее устанавливался Qt для Qt Creator, папки комплектов MinGW/llvm-mingw
     не должны стоять в PATH выше папок Python и venv, иначе DLL подмешиваются из
     чужой сборки и QML выдаёт «Cannot load library»;
   - антивирус и SmartScreen иногда блокируют DLL из venv — при странных ошибках
     импорта добавьте папку проекта в исключения.

6. **Создание ресурсов:**

```bash
python DCScripts/DCCompileRCC.py
```

7. **Установите LM Studio или Bionic:**
   - Скачайте LM Studio или Bionic для Windows: https://lmstudio.ai/download
   - Запустите установщик и следуйте инструкциям
   - После установки запустите LM Studio или Bionic

8. **Настройте LM Studio или Bionic:**
   - Запустите LM Studio или Bionic
   - Скачайте нужную языковую модель (рекомендуются модели до 7B параметров)
   - Перейдите во вкладку "Developer" -> "Status: Running"
   - Запустите локальный сервер "Running" (по умолчанию Base URL http://localhost:1234)

9. **Запустите приложение:**

```cmd
python main.py
```

10. **Установите sandbox Sandboxie или Sandboxie Plus:**
   - Установите Sandboxie или Sandboxie Plus, чтоб запускать LM Studio или Bionic
     в защищённой песочнице (sandbox).
   - Скачайте с официального сайта: https://sandboxie-plus.com/downloads/

### macOS

1. **Установите Python 3.13:**
   - Скачайте Python 3.13 с официального сайта: https://www.python.org/downloads/macos/
   - Запустите скачанный `.pkg` установщик и следуйте инструкциям
     (в macOS Python автоматически добавляется в PATH)
   - Убедитесь, что установка прошла успешно, открыв Терминал и введя команду `python3 --version`

2. **Установите Git (опционально):**
   - Скачайте с https://git-scm.com/download/mac
   - Или скачайте проект напрямую как ZIP-архив с GitHub

3. **Клонируйте репозиторий:**

Через стандартный Терминал (Terminal):
```bash
git clone https://github.com/DruidCat/pyqt-kobzone.git
cd pyqt-kobzone
```

Или распакуйте скачанный ZIP-архив и откройте эту папку в Терминале (через правый клик
по папке -> «Новый терминал по адресу папки» или командой `cd` после перетаскивания
папки в окно терминала).

4. **Создайте виртуальное окружение:**
Через Терминал:
```bash
python3 -m venv venv
source venv/bin/activate
```

```bash
# Выйти из виртуального окружения venv можно командой
deactivate
```

5. **Установите зависимости:**

```bash
python3 -m pip install --upgrade pip
pip install -r requirements.txt
```

Отдельная установка Qt не нужна: pip-колесо PyQt6 (universal2 — подходит для Apple
Silicon и для Intel) содержит весь комплект Qt 6. Если отдельный Qt необходим
(Qt Creator, C++-проекты, утилиты rcc, qmllint), используется один из способов:

```bash
# Способ 1 — официальный онлайн-установщик Qt (графический, даёт Qt Creator + комплекты Qt):
# https://www.qt.io/download-qt-installer  (выбрать Qt 6.x для macOS)

# Способ 2 — Homebrew (быстро, без Qt Creator):
brew install qt
```

Проверка отдельного Qt: `qmake6 -query QT_VERSION` (Homebrew) или через Maintenance Tool
установщика Qt. Правило то же, что и на других платформах: системный Qt
(Homebrew/установщик) и Qt из PyQt6-колеса pip — разные сборки, подмешивание их
библиотек через DYLD_LIBRARY_PATH / QT_PLUGIN_PATH ломает запуск QML. Для запуска
КОБзоны используется только Qt из виртуального окружения.

6. **Создание ресурсов:**

```bash
python3 DCScripts/DCCompileRCC.py
```

7. **Установите LM Studio или Bionic:**
   - Скачайте LM Studio или Bionic для macOS (версию Universal, Apple Silicon или Intel
     в зависимости от Mac): https://lmstudio.ai/download
   - Откройте скачанный `.dmg` образ и перетащите приложение в папку «Программы» (Applications)
   - После установки запустите LM Studio или Bionic (при первом запуске macOS может
     потребовать подтвердить открытие приложения в Системных настройках)

8. **Настройте LM Studio или Bionic:**
   - Запустите LM Studio или Bionic
   - Скачайте нужную языковую модель (рекомендуются модели до 7B параметров)
   - Перейдите во вкладку "Developer" -> "Status: Running"
   - Запустите локальный сервер "Running" (по умолчанию Base URL http://localhost:1234)

9. **Запустите приложение:**

```bash
python3 main.py
```

10. **Работа в sandbox:**
   - Запуск LM Studio или Bionic в sandbox не поддерживается.
   - Для безопасности данных создайте отдельную учётную запись и в ней запускайте
     LM Studio или Bionic.

## Структура проекта

```
pyqt-kobzone/
├── DCButtons/		# Кнопки приложения
├── DCMethods/		# Виджеты приложения
├── DCPages/		# Страницы приложения
├── DCScripts/		# Python скрипты приложения
├── DCSettings/		# Настройки приложения
├── resources/		# Ресурсы проекта
├── main.py			# Главный файл приложения
├── README.md		# Документация
├── requirements.txt	# Зависимости проекта
├── resources.qrc		# Таблица ресурсов проекта
└── ru.KOBzone.qml		# Главный qml файл
```

## Конфигурация

### Настройка подключения к LM Studio или Bionic

По умолчанию приложение подключается к LM Studio или к Bionic по адресу
`http://localhost:1234`. Если порт занят, его можно изменить как в LM Studio или
Bionic, так и в настройках приложения Любимая КОБзона.

## Использование

После запуска приложения открывается графическое окно с интерфейсом для работы
с AI-моделями.

Основные функции:
- Нейро анализ документов
- Редактирование текста
- Транскрибация
- Создание RAG баз данных

## Решение проблем

**Ошибка подключения к LM Studio или Bionic:**
- Убедитесь, что LM Studio или Bionic запущен
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

**«Cannot load library» / QML не запускается на Windows:**
- Смешение DLL разных сборок Qt. Порядок PATH и комплектов — в подразделе
  «Windows 10, 11» главы «Установка».

**LM Studio или Bionic не подключается:**
- Проверьте, что LM Studio или Bionic запущен
- Убедитесь, что во вкладке Developer LM Studio или в Bionic включен локальный сервер
- Проверьте брандмауэр Windows - разрешите подключения для LM Studio или для Bionic
- Попробуйте открыть http://localhost:1234 в браузере для проверки

**Медленная работа с моделями:**
- Используйте модели меньшего размера (3B-7B параметров)
- Убедитесь, что в LM Studio включено GPU ускорение (если доступно)
- Выделите больше RAM для приложения в настройках LM Studio

## Рекомендуемые модели для LM Studio и для Bionic

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
- LM Studio и Bionic: https://lmstudio.ai/
- Python 3.13: https://www.python.org/downloads/release/python-31314/

---

**Примечание:**
- Перед использованием убедитесь, что у вас установлены все необходимые зависимости
- LM Studio или Bionic должен быть запущен и настроен для работы приложения с AI-функциями
- Для работы с языковыми моделями требуется достаточно оперативной памяти (минимум 8 GB)
- Первый запуск может быть медленным из-за загрузки модели в LM Studio

## Гайд по расшифровке совещаний по ролям (M4A -> текст)
```bash
# Устанавливаем необходимые пакеты кодеков
sudo apt install -y ffmpeg libavutil58 libavcodec60 libavformat60 libavdevice60 \
    libavfilter9 libswscale7 libswresample4
# Проверяем ffmpeg (нужен для конвертации M4A)
ffmpeg --version
```
**Проверка CUDA:**
```bash
nvidia-smi
```
Должна отобразиться ваша видеокарта и версия CUDA (12.x).

## Установка Python 3.13 в виртуальном окружении pyenv, на котором работает WhisperX
- pyenv необходим, чтоб в проекте не конфликтовали версии Python на одном компьютере.
- ВНИМАНИЕ: данный способ установки версии Python является альтернативным тому, что
  указан выше в инструкции, а именно использованию `python -m venv venv`. Выберите
  подходящий.

```bash
# Устанавливаем пакеты для установки pyenv, если через apt не получилось:
sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libffi-dev python3-openssl
# Скачиваем pyenv в домашний каталог .pyenv
curl https://pyenv.run | bash
```

Редактируем .bashrc, добавляем скрипт, запускающий pyenv:

```code
# pyenv инструмент для запуска различных версий python
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
```

```bash
# Перезапускаем консоль, чтоб обновился .bashrc
source ~/.bashrc

# Скачать python 3.13 через pyenv
pyenv install 3.13.14

# Запускаем в виртуальном пространстве Python 3.13, на котором написана WhisperX
# на момент написания инструкции.
pyenv shell 3.13

# Проверить, что сделали всё правильно, должна отобразиться версия 3.13
python3 --version

# Сделать версию по умолчанию для всех сессий
pyenv global 3.13
```

## Токен Hugging Face (для диаризации)
- Зайдите на https://huggingface.co — зарегистрируйтесь
- Примите лицензию pyannote, обязательно вводим название фирмы и сайт фирмы:
```http
https://huggingface.co/pyannote/speaker-diarization
https://huggingface.co/pyannote/speaker-diarization-3.1
https://huggingface.co/pyannote/speaker-diarization-community-1
https://huggingface.co/pyannote/segmentation-3.0
```
- Создайте токен: Settings -> Access Tokens -> New Token (Read)
- Залогиньтесь:
```bash
hf auth login
```

**Вставьте токен когда попросит, при печатании токена видно не будет букв.**
