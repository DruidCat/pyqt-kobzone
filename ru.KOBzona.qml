import QtQuick 2.15
import QtQuick.Controls 2.15
import DCButtons 1.0  // Импортируем кастомные кнопки

ApplicationWindow {
    id: root
    visible: true
    width: 900
    height: 700
    title: "Любимая КОБзона"
    
    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Text {
            text: "Анализ текста"
            font.pixelSize: 24
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Используем кастомную кнопку DCKnopkaOriginal
        DCKnopkaOriginal {
            id: btnLoadFile
            text: "📁 Загрузить файл"
            ntHeight: 3
            clrKnopki: "#4CAF50"  // Зеленый цвет
            clrTexta: "white"
            anchors.horizontalCenter: parent.horizontalCenter
            
            onClicked: {
                window.load_file()
            }
        }

        Text {
            text: "Содержимое файла:"
            font.pixelSize: 16
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
                
                onTextChanged: analyzer.setTextContent(text)
            }
        }

        Text {
            text: "Промт для модели:"
            font.pixelSize: 16
        }

        TextField {
            id: promptField
            width: parent.width
            placeholderText: "Проанализируй этот текст и выдели основные темы"
            selectByMouse: true
            
            Keys.onReturnPressed: {
                if (contentArea.text.trim() !== "") {
                    analyzer.analyze(contentArea.text, promptField.text)
                }
            }
        }

        // Используем кастомную кнопку для анализа
        DCKnopkaOriginal {
            id: btnAnalyze
            text: "🚀 Анализировать"
            ntHeight: 3
            clrKnopki: "#2196F3"  // Синий цвет
            clrTexta: "white"
            enabled: contentArea.text.trim() !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            
            onClicked: {
                analyzer.analyze(contentArea.text, promptField.text)
            }
        }

        Text {
            text: "Результат:"
            font.pixelSize: 16
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
