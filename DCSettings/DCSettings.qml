pragma Singleton
import QtQuick
import QtCore
//DCSettings - виджет сохранения настроек в реестр.
QtObject {
    id: root
	//Свойства с привязкой к настройкам, значения по умолчанию при первом пуске приложения.
	//Любимая КОБзона
	property int kobzone_x: 0
	property int kobzone_y: 0
	property int kobzone_shirina: 1100
	property int kobzone_visota: 550
	property int kobzone_set_shrift: 1//0-мал, 1-сред, 2-большой.
	//Нейро Анализ
	property real analizer_sidebar_shirina: 0.3//Коэффициент от общей ширины окна, показ.ширину боковой панели
	property real analizer_temperatura: 0.5//Температура ИИ модели, чем выше, тем точнее ответ. 0-1
	property int analizer_perekritie: 20//Перекрытие чтения соседнего чанка в процентах: 20 это 20%
	property string analizer_prompt_final: "На основе всех этих частичных анализов составь единый, связный итоговый анализ документа. Объедини ключевые моменты, устрани дублирование, выдели главное. Ответ должен быть структурированным и понятным."
	property string analizer_put_text: ""
    property string analizer_put_sohranit: ""
	property string analizer_put_rag: ""
	//LM Studio 
	property string studio_model_imya: ""//По умолчанию отсутствует
	property int studio_max_context: 8000//Количество токенов
	property int studio_gpu_offload: 50//по умолчанию 50%	
	property string studio_lms_put: ""//По умолчанию путь не задан
	property string studio_cli_put: ""//По умолчанию путь не задан
	property string studio_server_url: "http://localhost:1234"
	//Транскрибация
    property string transcribe_put_audio: ""
    property string transcribe_put_text: ""
	//RAG
    property string rag_put_doc: ""
    property string rag_put_db: ""
	property bool rag_gpu: false//true - работает на gpu, false - работает на cpu.
	property int rag_model: 0//модели от 0 до 6
	property int rag_batch_gpu: 8//Количество параллельных проходов на GPU, но не больше 256
	property int rag_batch_cpu: 4//Количество параллельных проходов на GPU, но не больше 64
	//Инструкции
	property real instrukcii_shirina: 0.3//Коэффициент от общей ширины окна, показ.ширину боковой панели
	//Объект настроек (автоматическое сохранение)
    property Settings settings: Settings {
        category: "KOBzone"
		//Любимая КОБзона
		property alias kobzone_x: root.kobzone_x
		property alias kobzone_y: root.kobzone_y
		property alias kobzone_shirina: root.kobzone_shirina
		property alias kobzone_visota: root.kobzone_visota
		property alias kobzone_set_shrift: root.kobzone_set_shrift
		//Нейро Анализ
        property alias analizer_sidebar_shirina: root.analizer_sidebar_shirina
		property alias analizer_temperatura: root.analizer_temperatura
		property alias analizer_perekritie: root.analizer_perekritie
		property alias analizer_prompt_final: root.analizer_prompt_final
        property alias analizer_put_text: root.analizer_put_text
        property alias analizer_put_sohranit: root.analizer_put_sohranit
        property alias analizer_put_rag: root.analizer_put_rag
		//LM Studio
		property alias studio_model_imya: root.studio_model_imya
		property alias studio_max_context: root.studio_max_context
		property alias studio_gpu_offload: root.studio_gpu_offload
		property alias studio_lms_put: root.studio_lms_put
		property alias studio_cli_put: root.studio_cli_put
		property alias studio_server_url: root.studio_server_url
		//Транскрибация
        property alias transcribe_put_audio: root.transcribe_put_audio
        property alias transcribe_put_text: root.transcribe_put_text
		//RAG
		property alias rag_put_doc: root.rag_put_doc
		property alias rag_put_db: root.rag_put_db
		property alias rag_gpu: root.rag_gpu
		property alias rag_model: root.rag_model
		property alias rag_batch_gpu: root.rag_batch_gpu
		property alias rag_batch_cpu: root.rag_batch_cpu
		//Инструкции
		property alias instrukcii_shirina: root.instrukcii_shirina
    }
    Component.onCompleted: {//Инициализация значений по умолчанию
        //Получаем стандартные пути через QtCore.StandardPaths
        const cnDomPut = StandardPaths.writableLocation(StandardPaths.HomeLocation)
        var urlMusic = StandardPaths.writableLocation(StandardPaths.MusicLocation)
        var urlDocuments = StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        //Возвращаемся на домашнюю директорию, если стандартные пути не найдены
        urlMusic = urlMusic !== "" ? urlMusic : cnDomPut
        urlDocuments = urlDocuments !== "" ? urlDocuments : cnDomPut
		urlDocuments = fnUrlToLocalPath(urlDocuments)//Удаляем file:// с помощью кроссплатформенной функции
		if (studio_model_imya === "") studio_model_imya = pyLMStudio.polModelNoName()//имя ОТСУТСТВУЕТ.
		if (analizer_put_text === "") {//Если настройки ёще были записаны, то...
            analizer_put_text = urlDocuments//Записываем в реестр
        }
		if (analizer_put_sohranit === "") {//Если настройки ёще были записаны, то...
            analizer_put_sohranit = urlDocuments//Записываем в реестр
        }
        if (transcribe_put_audio === "") {//Если настройки ёще были записаны, то...
			urlMusic = fnUrlToLocalPath(urlMusic)//Удаляем file:// с помощью кроссплатформенной функции
            transcribe_put_audio = urlMusic//Записываем в реестр
        }
        if (transcribe_put_text === "") {//Если настройки ёще были записаны, то...
            transcribe_put_text = urlDocuments//Записываем в реестр
        }
		if (rag_put_doc === "") {//Если настройки ёще были записаны, то...
            rag_put_doc = urlDocuments//Записываем в реестр
        }
		if (rag_put_db === "") {//Если настройки ёще были записаны, то...
            rag_put_db = urlDocuments//Записываем в реестр
        }
    }
	function fnUrlToLocalPath(url) {//Функция кроссплатформенного преобразования URL в путь
		if (!url) return ""
		var path = url.toString()
		if (path.startsWith("file:///")) {//Если путь начинается с file:///
			path = path.substring(7)//Убираем "file://" чтоб осталось "/" /home, /mnt и тд
		} else if (path.startsWith("file://")) {//Если путь начинается с file://
			path = path.substring(7)//Убираем "file://"
		}
		path = decodeURIComponent(path)//Декодируем URL-кодирование (%20 → пробел, %3F → ?)
		if (Qt.platform.os === "windows") {//Windows: если путь начинается с /C:/, убираем первый /
			if (path.length > 2 && path[0] === '/' && path[2] === ':') {
				path = path.substring(1)
			}
		}
		if (Qt.platform.os !== "windows" && path.startsWith("//")) {//Linux-убираем двойной слеш,если появился
			path = path.substring(1)
		}
		return path
	}
}
