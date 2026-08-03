import QtQuick
import QtQuick.Controls
import DCButtons 1.0

Item {
    id: root
    
    // Свойства
    property int ntWidth: 2
    property int ntCoff: 8
    property color clrTexta: "indigo"
    property color clrFona: "white"
    property color clrMenuText: "indigo"
    property color clrMenuFon: "#f5f5f5"
    
    property alias zagolovokX: tmZagolovok.x
    property alias zagolovokY: tmZagolovok.y
    property alias zagolovokWidth: tmZagolovok.width
    property alias zagolovokHeight: tmZagolovok.height
    property alias zonaX: tmZona.x
    property alias zonaY: tmZona.y
    property alias zonaWidth: tmZona.width
    property alias zonaHeight: tmZona.height
    property alias toolbarX: tmToolbar.x
    property alias toolbarY: tmToolbar.y
    property alias toolbarWidth: tmToolbar.width
    property alias toolbarHeight: tmToolbar.height
    
    property real tapZagolovokLevi: 1.3
    property real tapZagolovokPravi: 1.3
    property real tapToolbarLevi: 1.3
    property real tapToolbarPravi: 1.3
    
    // Сигналы
    signal clickedNazad()
    signal signalToolbar(var strToolbar)
    
    // Настройки
    anchors.fill: parent
    
    // Заголовок
    Item {
        id: tmZagolovok
        
        DCKnopkaNazad {
            id: knopkaNazad
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.verticalCenter: tmZagolovok.verticalCenter
            anchors.left: tmZagolovok.left
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff
            tapWidth: tapHeight * root.tapZagolovokLevi
            
            onClicked: root.clickedNazad()
        }
    }
    
    // Рабочая зона
    Item {
        id: tmZona
        
        Column {
            anchors.fill: parent
            anchors.margins: root.ntCoff * 2
            spacing: root.ntCoff * 2
            
            // Кнопка загрузки файла
            DCKnopkaOriginal {
                id: btnLoadFile
                text: "📁 Загрузить файл"
                ntHeight: root.ntWidth
                ntCoff: root.ntCoff
                clrKnopki: "#4CAF50"
                clrTexta: "white"
                anchors.horizontalCenter: parent.horizontalCenter
                
                onClicked: {
                    window.load_file()
                }
            }
            
            // Содержимое файла
            Text {
                text: "Содержимое файла:"
                font.pixelSize: root.ntWidth * root.ntCoff
                color: root.clrTexta
            }
            
            ScrollView {
                width: parent.width
                height: 180
                
                TextArea {
                    id: contentArea
                    objectName: "contentArea"
                    placeholderText: "Загрузите файл или вставьте текст..."
                    wrapMode: TextArea.Wrap
                    selectByMouse: true
                    color: root.clrTexta
                    
                    background: Rectangle {
                        color: "white"
                        border.color: root.clrTexta
                        border.width: 1
                        radius: root.ntCoff / 2
                    }
                    
                    onTextChanged: analyzer.setTextContent(text)
                }
            }
            
            // Промт для модели
            Text {
                text: "Промт для модели:"
                font.pixelSize: root.ntWidth * root.ntCoff
                color: root.clrTexta
            }
            
            TextField {
                id: promptField
                width: parent.width
                placeholderText: "Проанализируй этот текст и выдели основные темы"
                selectByMouse: true
                color: root.clrTexta
                
                background: Rectangle {
                    color: "white"
                    border.color: root.clrTexta
                    border.width: 1
                    radius: root.ntCoff / 2
                }
                
                Keys.onReturnPressed: {
                    if (contentArea.text.trim() !== "") {
                        analyzer.analyze(contentArea.text, promptField.text)
                    }
                }
            }
            
            // Кнопка анализа
            DCKnopkaOriginal {
                id: btnAnalyze
                text: "🚀 Анализировать"
                ntHeight: root.ntWidth
                ntCoff: root.ntCoff
                clrKnopki: "#2196F3"
                clrTexta: "white"
                enabled: contentArea.text.trim() !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                
                onClicked: {
                    analyzer.analyze(contentArea.text, promptField.text)
                }
            }
            
            // Результат
            Text {
                text: "Результат:"
                font.pixelSize: root.ntWidth * root.ntCoff
                color: root.clrTexta
            }
            
            ScrollView {
                width: parent.width
                height: 180
                
                TextArea {
                    id: resultArea
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    selectByMouse: true
                    placeholderText: "Результат анализа появится здесь..."
                    color: root.clrTexta
                    
                    background: Rectangle {
                        color: "#f9f9f9"
                        border.color: root.clrTexta
                        border.width: 1
                        radius: root.ntCoff / 2
                    }
                    
                    Connections {
                        target: analyzer
                        function onResultReady(result) {
                            resultArea.text = result
                        }
                    }
                }
            }
        }
    }
    
    // Тулбар
    Item {
        id: tmToolbar
    }
}
