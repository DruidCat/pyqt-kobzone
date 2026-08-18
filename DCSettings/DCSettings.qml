import QtQuick
import QtCore
//DCSettings - виджет сохранения настроек в реестр.
QtObject {
    id: root
	//Свойства с привязкой к настройкам, значения по умолчанию при первом пуске приложения.
    property string analizer_put_text: ""
    property string transcribe_put_audio: ""
    property string transcribe_put_text: ""
	property int instrukcii_shirina: 220
	//Объект настроек (автоматическое сохранение)
    property Settings settings: Settings {
        category: "KOBzone"
		//Нейро Анализ
        property alias analizer_put_text: root.analizer_put_text
		//Транскрибация
        property alias transcribe_put_audio: root.transcribe_put_audio
        property alias transcribe_put_text: root.transcribe_put_text
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
        if (transcribe_put_audio === "") {//Если настройки ёще были записаны, то...
			musicPut = musicPut.toString()//В текст переводим, чтоб replace работал
			musicPut = musicPut.replace(/^file:\/\//, "")//Удаляем file://
            transcribe_put_audio = musicPut//Записываем в реестр
        }
        if (transcribe_put_text === "") {//Если настройки ёще были записаны, то...
            transcribe_put_text = docPut//Записываем в реестр
        }
    }
}
