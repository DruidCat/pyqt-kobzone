import QtQuick
import QtCore
//DCSettings - виджет сохранения настроек в реестр.
QtObject {
    id: root
	//Свойства с привязкой к настройкам
    property string audio_put: ""
    property string text_put: ""
	//Объект настроек (автоматическое сохранение)
    property Settings settings: Settings {
        category: "Transcribe"
        property alias audio_put: root.audio_put
        property alias text_put: root.text_put
    }
    Component.onCompleted: {//Инициализация значений по умолчанию
        //Получаем стандартные пути через QtCore.StandardPaths
        const cnDomPut = StandardPaths.writableLocation(StandardPaths.HomeLocation)
        let musicPut = StandardPaths.writableLocation(StandardPaths.MusicLocation)
        let docPut = StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        //Возвращаемся на домашнюю директорию, если стандартные пути не найдены
        musicPut = musicPut !== "" ? musicPut : cnDomPut
        docPut = docPut !== "" ? docPut : cnDomPut
        if (audio_put === "") {//Если настройки ёще были записаны, то...
            audio_put = musicPut
        }
        if (text_put === "") {//Если настройки ёще были записаны, то...
            text_put = docPut
        }
    }
}
