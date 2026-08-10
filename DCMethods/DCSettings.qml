import QtQuick

import QtCore//Qt.labs.settings 1.0
import Qt.labs.platform as Platform

QtObject {
    id: root
    
    // Свойства с привязкой к настройкам
    property string audioPath: ""
    property string textPath: ""
    
    // Объект настроек (автоматическое сохранение)
    property Settings settings: Settings {
        category: "Transcribe"
        
        property alias audioPath: root.audioPath
        property alias textPath: root.textPath
    }
    
    // Метод для получения домашней директории
    function getHomeDir() {
        return Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation)
    }
    
    // Инициализация значений по умолчанию
    Component.onCompleted: {
        if (audioPath === "") {
            audioPath = getHomeDir() + "/Музыка"
        }
        
        if (textPath === "") {
            textPath = getHomeDir() + "/Документы"
        }
        console.log("Домашняя директория", getHomeDir())
        console.log("✓ Настройки загружены:")
        console.log("  Аудио:", audioPath)
        console.log("  Текст:", textPath)
    }
}
