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
    property string analizer_put_text: ""
    property string analizer_put_sohranit: ""
	property string analizer_model_imya: "(автовыбор модели)"//По умолчанию автовыбор
	property string analizer_lms_put: ""//По умолчанию путь не задан
	//property string analizer_model_imya: "qwen3-coder-30b-a3b-instruct"//Имя модели ИИ добавляем
	property int analizer_max_context: 22016//Количество токенов
	property real analizer_temperatura: 0.5//Температура ИИ модели, чем выше, тем точнее ответ. 0-1
	property int analizer_perekritie: 20//Перекрытие чтения соседнего чанка в процентах: 20 это 20%
	//Транскрибация
    property string transcribe_put_audio: ""
    property string transcribe_put_text: ""
	//RAG
    property string rag_put_doc: ""
    property string rag_put_db: ""
	//Инструкции
	property int instrukcii_shirina: 220
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
        property alias analizer_put_text: root.analizer_put_text
        property alias analizer_put_sohranit: root.analizer_put_sohranit
		property alias analizer_model_imya: root.analizer_model_imya
		property alias analizer_max_context: root.analizer_max_context
		property alias analizer_temperatura: root.analizer_temperatura
		property alias analizer_perekritie: root.analizer_perekritie
		property alias analizer_lms_put: root.analizer_lms_put
		//Транскрибация
        property alias transcribe_put_audio: root.transcribe_put_audio
        property alias transcribe_put_text: root.transcribe_put_text
		//RAG
		property alias rag_put_doc: root.rag_put_doc
		property alias rag_put_db: root.rag_put_db
		//Инструкции
		property alias instrukcii_shirina: root.instrukcii_shirina
    }
    Component.onCompleted: {//Инициализация значений по умолчанию
        //Получаем стандартные пути через QtCore.StandardPaths
        const cnDomPut = StandardPaths.writableLocation(StandardPaths.HomeLocation)
        var musicPut = StandardPaths.writableLocation(StandardPaths.MusicLocation)
        var docPut = StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        //Возвращаемся на домашнюю директорию, если стандартные пути не найдены
        musicPut = musicPut !== "" ? musicPut : cnDomPut
        docPut = docPut !== "" ? docPut : cnDomPut
		docPut = docPut.toString()//В текст переводим, чтоб replace работал
		docPut = docPut.replace(/^file:\/\//, "")//Удаляем file://
		if (analizer_put_text === "") {//Если настройки ёще были записаны, то...
            analizer_put_text = docPut//Записываем в реестр
        }
		if (analizer_put_sohranit === "") {//Если настройки ёще были записаны, то...
            analizer_put_sohranit = docPut//Записываем в реестр
        }
        if (transcribe_put_audio === "") {//Если настройки ёще были записаны, то...
			musicPut = musicPut.toString()//В текст переводим, чтоб replace работал
			musicPut = musicPut.replace(/^file:\/\//, "")//Удаляем file://
            transcribe_put_audio = musicPut//Записываем в реестр
        }
        if (transcribe_put_text === "") {//Если настройки ёще были записаны, то...
            transcribe_put_text = docPut//Записываем в реестр
        }
		if (rag_put_doc === "") {//Если настройки ёще были записаны, то...
            rag_put_doc = docPut//Записываем в реестр
        }
		if (rag_put_db === "") {//Если настройки ёще были записаны, то...
            rag_put_db = docPut//Записываем в реестр
        }
    }
}
