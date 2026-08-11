import QtQuick
import QtCore
//DCSettings - виджет сохранения настроек в реестр.
QtObject {
    id: root
	//Свойства с привязкой к настройкам
    property string audioPath: ""
    property string textPath: ""
	//Объект настроек (автоматическое сохранение)
    property Settings settings: Settings {
        category: "Transcribe"
        property alias audioPath: root.audioPath
        property alias textPath: root.textPath
    }

    Component.onCompleted: {//Инициализация значений по умолчанию
        //Получаем стандартные пути через QtCore.StandardPaths
        const cnDomPut = StandardPaths.writableLocation(StandardPaths.HomeLocation)
        let musicPut = StandardPaths.writableLocation(StandardPaths.MusicLocation)
        let docPut = StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        //Возвращаемся на домашнюю директорию, если стандартные пути не найдены
        musicPut = musicPut !== "" ? musicPut : cnDomPut
        docPut = docPut !== "" ? docPut : cnDomPut
        if (audioPath === "") {//Если настройки ёще были записаны, то...
            audioPath = musicPut
        }
        if (textPath === "") {//Если настройки ёще были записаны, то...
            textPath = docPut
        }
        console.log("✓ Настройки загружены:")
        console.log("  Аудио:", audioPath)
        console.log("  Текст:", textPath)
    }
}
