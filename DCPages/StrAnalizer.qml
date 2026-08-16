import QtQuick
import QtQuick.Controls
import DCButtons 1.0
import DCMethods 1.0

Item {
    id: root
    //Свойства
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
    
    property int logoRazmer: 22
    property real rlProgress: 0
    property real rlLoader: 1
	//Настройки
    anchors.fill: parent
    focus: true
    //Сигналы
    signal clickedNazad()
	signal clickedSettings()
    signal clickedInfo()
    signal signalToolbar(var strToolbar)
    //Методы
    Timer {//ТАЙМЕР анимации логотипа
        id: tmrLogo
        interval: 47
        running: false
        repeat: true
        property bool blLogo: false
        onTriggered: {
            if (blLogo) {
                imgLogo.scale += 0.02
                if (imgLogo.scale >= 1.3)
                    blLogo = false
            } else {
                imgLogo.scale -= 0.02
                if (imgLogo.scale <= 0.7)
                    blLogo = true
            }
        }
        onRunningChanged: {
            if (running) {
                ldrProgress.active = true
                
                knopkaInfo.visible = false
                knopkaNastroiki.visible = false
                knopkaMenu.enabled = false
                knopkaNazad.enabled = false
                
                knopkaZagruzit.enabled = false
                knopkaAnaliz.enabled = false
                knopkaSohranit.enabled = false
            } else {
                imgLogo.scale = 1.0
                ldrProgress.active = false
                
                knopkaInfo.visible = true
                knopkaNastroiki.visible = true
                knopkaMenu.enabled = true
                knopkaNazad.enabled = true
                
                knopkaZagruzit.enabled = true
                knopkaAnaliz.enabled = contentArea.text.trim() !== ""
            }
        }
    }
	Connections {//CONNECTIONS для прогресса
		target: analyzer
		
		function onAnalysisStarted() {
			console.log("✓ Анализ начался")
			root.rlProgress = 0
			tmrLogo.running = true
		}
		function onAnalysisFinished() {
			console.log("✓ Анализ завершён")
			
			if (ldrProgress.item) {
				ldrProgress.item.progress = 100
			}
			
			Qt.callLater(function() {
				tmrLogo.running = false
			})
		}
		function onChunkStarted(ntCurrent, ntTotal) {
			console.log(`Чанк ${ntCurrent}/${ntTotal} начал обрабатываться`)
			
			if (ldrProgress.item) {
				ldrProgress.item.text = `${ntCurrent}/${ntTotal + 1}`
			}
		}
		function onChunkFinished(ntCurrent, ntTotal) {
			console.log(`Чанк ${ntCurrent}/${ntTotal} завершён`)
			
			// Прогресс обновляется после завершения чанка
			// +1 резервируем для финального анализа
			root.rlLoader = 100 / (ntTotal + 1)
			root.rlProgress = ntCurrent * root.rlLoader
			
			if (ldrProgress.item) {
				ldrProgress.item.progress = root.rlProgress
				ldrProgress.item.text = `${ntCurrent}/${ntTotal + 1}`
			}
		}
		function onFinalAnalysisStarted() {//Обработчик финального анализа
			console.log("✓ Начался финальный анализ")
			
			if (ldrProgress.item) {
				ldrProgress.item.text = "Финальный анализ..."
			}
		}
	}	
    Keys.onPressed: (event) => {//Обработка горячих клавиш
        if (event.modifiers & Qt.AltModifier) {
            if (event.key === Qt.Key_Left) {
                fnClickedNazad()//Функция закрытия страницы.
                event.accepted = true
                return
            }
        }
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_S) {
                if (!menuMenu.visible && knopkaSohranit.enabled) {
                    fnClickedSave()
                }
                event.accepted = true
            }
        }
        if (event.key === Qt.Key_Escape) {
            if (menuMenu.visible) {
                menuMenu.visible = false
                event.accepted = true
            } else {
                event.accepted = true
            }
        } else if (event.key === Qt.Key_F1) {
            if (!menuMenu.visible) {
                fnClickedInfo()    
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            if (!menuMenu.visible) {
                var ltNoviY = flcZona.contentY - 50
                if (ltNoviY < 0)
                    ltNoviY = 0
                flcZona.contentY = ltNoviY
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            if (!menuMenu.visible) {
                var ltMaxY = flcZona.contentHeight - flcZona.height
                var ltNoviY = flcZona.contentY + 50
                if (ltNoviY > ltMaxY)
                    ltNoviY = ltMaxY
                flcZona.contentY = ltNoviY
            }    
            event.accepted = true
        } else if (event.key === Qt.Key_PageUp) {
            if (!menuMenu.visible) {
                var ltNoviY = flcZona.contentY - flcZona.height
                if (ltNoviY < 0)
                    ltNoviY = 0
                flcZona.contentY = ltNoviY
            }
            event.accepted = true
        } else if (event.key === Qt.Key_PageDown) {
            if (!menuMenu.visible) {
                var ltMaxY = flcZona.contentHeight - flcZona.height
                var ltNoviY = flcZona.contentY + flcZona.height
                if (ltNoviY > ltMaxY)
                    ltNoviY = ltMaxY
                flcZona.contentY = ltNoviY
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Home) {
            if (!menuMenu.visible) {
                flcZona.contentY = 0
            }
            event.accepted = true
        } else if (event.key === Qt.Key_End) {
            if (!menuMenu.visible) {
                flcZona.contentY = flcZona.contentHeight - flcZona.height
            }
            event.accepted = true
        }
    }
    function fnClickedNazad() {//Функция закрытия страницы.
		menuMenu.visible = false
		root.clickedNazad()
	}
    function fnClickedMenu() {
		root.clickedSettings()//Сигнал излучает открытие настроек.
    }
    function fnClickedInfo() {
        root.clickedInfo()
    }
    function fnClickedLoad() {
        window.load_file()
    }
    function fnClickedAnalizer() {
        analyzer.analyze(contentArea.text, promptField.text)
    }
    function fnClickedSave() {
        analyzer.saveResult()
    }
    function fnToggleMenu() {
        if (menuMenu.visible) menuMenu.visible = false
        else menuMenu.visible = true
    }
    function fnCloseMenuIfOpen() {
        if (menuMenu.visible) {
            menuMenu.visible = false
            return true
        }
        return false
    }
    function fnMarkdownToHtml(markdown) {//Функция конвертация Markdown в HTML
        if (!markdown) return ""
        
        let html = markdown
        //Заголовки: ### Заголовок → <h3>Заголовок</h3>
        html = html.replace(/^### (.+)$/gm, '<h3 style="color: #2d4288; margin-top: 16px; margin-bottom: 8px;">$1</h3>')
        html = html.replace(/^## (.+)$/gm, '<h2 style="color: #2d4288; margin-top: 20px; margin-bottom: 10px;">$1</h2>')
        html = html.replace(/^# (.+)$/gm, '<h1 style="color: #2d4288; margin-top: 24px; margin-bottom: 12px;">$1</h1>')
        //Жирный текст: **текст** → <b>текст</b>
        html = html.replace(/\*\*(.+?)\*\*/g, '<b style="color: #1a237e;">$1</b>')
        //Курсив: *текст* → <i>текст</i>
        html = html.replace(/\*(.+?)\*/g, '<i>$1</i>')
        //Зачёркнутый: ~~текст~~ → <s>текст</s>
        html = html.replace(/~~(.+?)~~/g, '<s>$1</s>')
        //Код: `код` → <code>код</code>
        html = html.replace(/`(.+?)`/g, '<code style="background-color: #f5f5f5; padding: 2px 4px; border-radius: 3px; color: #c7254e;">$1</code>')
        //Списки: - элемент → <ul><li>элемент</li></ul>
        html = html.replace(/^- (.+)$/gm, '<li>$1</li>')
        html = html.replace(/(<li>.*<\/li>\n?)+/g, '<ul style="margin-left: 20px;">$&</ul>')
        //Нумерованные списки: 1. элемент → <ol><li>элемент</li></ol>
        html = html.replace(/^\d+\. (.+)$/gm, '<li>$1</li>')
        html = html.replace(/(<li>.*<\/li>\n?)+/g, function(match) {
            if (match.includes('<ul>')) return match
            return '<ol style="margin-left: 20px;">' + match + '</ol>'
        })
        //Цитаты: > текст → <blockquote>текст</blockquote>
        html = html.replace(/^> (.+)$/gm, '<blockquote style="border-left: 4px solid #2d4288; padding-left: 12px; margin-left: 0; color: #666;">$1</blockquote>')
        //Горизонтальная линия: --- → <hr>
        html = html.replace(/^---$/gm, '<hr style="border: none; border-top: 2px solid #e0e0e0; margin: 16px 0;">')
        //Переносы строк: двойной перенос → <br><br>
        html = html.replace(/\n\n/g, '<br><br>')
        //Ссылки: [текст](url) → <a href="url">текст</a>
        html = html.replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2" style="color: #2196F3; text-decoration: underline;">$1</a>')
        
        return '<p style="margin: 0; line-height: 1.6;">' + html + '</p>'
    }
    Component.onCompleted: {
        root.forceActiveFocus()
    }
    Item {//Заголовок
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
            onClicked: fnClickedNazad()//Функция закрытия страницы.
        }
        DCKnopkaMenu {
            id: knopkaMenu
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            visible: true
            anchors.verticalCenter: tmZagolovok.verticalCenter
            anchors.right: tmZagolovok.right
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff
            tapWidth: tapHeight * root.tapZagolovokPravi
            onClicked: {
                if (!fnCloseMenuIfOpen()) {
                    fnClickedMenu()
                }
            }
        }
    }
    Item {//Рабочая зона
        id: tmZona
        clip: true
        Image {//ЛОГОТИП
            id: imgLogo
            anchors.centerIn: tmZona
            width: 200
            height: 200
            source: "qrc:/resources/images/logo.png"
            fillMode: Image.PreserveAspectFit
            opacity: 0.4
            visible: true
            z: -1
            scale: 1.0
			/*
            Behavior on scale {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.InOutQuad
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
			*/
        }
        Flickable {
            id: flcZona
            anchors.fill: parent
            contentWidth: tmZona.width
            contentHeight: clmnContent.height
            clip: true
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            opacity: 0.9//ГЛАВНАЯ ПРОЗРАЧНОСТЬ!!!
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
            
            Column {
                id: clmnContent
                width: flcZona.width - dcScrollbar.width
                spacing: root.ntCoff/2//Расстояние между элементами по вертикали.
                topPadding: root.ntCoff * 2
                bottomPadding: root.ntCoff * 2
                leftPadding: root.ntCoff * 2
                rightPadding: root.ntCoff * 2
                DCKnopkaOriginal {//Кнопка загрузки файла
                    id: knopkaZagruzit
                    text: "📁 Загрузить документы"
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
                    clrKnopki: root.clrTexta    
                    clrTexta: root.clrFona
					anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
                    onClicked: {
                        if (!fnCloseMenuIfOpen()) {
                            fnClickedLoad()
                        }
                    }
                }
                Text {//Содержимое файла
                    text: "Содержимое файла:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                Rectangle {
                    id: rctContentArea
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    height: 180
                    color: "transparent"
                    border.color: root.clrTexta
                    border.width: 1
                    radius: root.ntCoff / 2
                    clip: true
                    
                    Flickable {
                        id: flcContentArea
                        anchors.fill: parent
                        anchors.margins: 5
                        anchors.rightMargin: scbContentArea.width + 5
                        contentWidth: width
                        contentHeight: contentArea.contentHeight
                        clip: true
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
                        
                        TextArea.flickable: TextArea {
                            id: contentArea
                            objectName: "contentArea"
                            placeholderText: "Загрузите файл или вставьте текст..."
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            color: root.clrTexta
                            background: null
                            
                            onTextChanged: analyzer.setTextContent(text)
                        }
                    }
                    DCScrollbar {
                        id: scbContentArea
                        flick: flcContentArea
                        anchors.right: rctContentArea.right
                        anchors.top: rctContentArea.top
                        anchors.bottom: rctContentArea.bottom
                        anchors.margins: 5
                        clrPolzunokOff: Qt.lighter(root.clrMenuFon, 1.3)
                        clrPolzunokOn: root.clrTexta
                        width: root.ntWidth * root.ntCoff
                        radius: 1
                    }
                }
                Text {//Промт для модели
                    text: "Промт для модели:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                TextField {
                    id: promptField
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    placeholderText: "Проанализируй этот текст и выдели основные темы"
                    selectByMouse: true
                    color: root.clrTexta
                    background: Rectangle {
                        color: "transparent"
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
                DCKnopkaOriginal {//Кнопка анализа
                    id: knopkaAnaliz
                    text: "🚀 Анализировать"
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
                    clrKnopki: "#2196F3"
                    clrTexta: root.clrFona
                    enabled: contentArea.text.trim() !== ""
					anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
                    onClicked: {
                        if (!fnCloseMenuIfOpen()) {
                            fnClickedAnalizer()
                        }
                    }
                }
                Text {//Результат
                    text: "Результат:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                Rectangle {
                    id: rctResultArea
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    height: 300
                    color: "transparent"
                    border.color: root.clrTexta
                    border.width: 1
                    radius: root.ntCoff / 2
                    clip: true
                    Flickable {
                        id: flcResultArea
                        anchors.fill: parent
                        anchors.margins: 5
                        anchors.rightMargin: scbResultArea.width + 5
                        contentWidth: width
                        contentHeight: resultArea.contentHeight
                        clip: true
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
                        TextArea.flickable: TextArea {//TextArea.flickable на Text с HTML
                            id: resultArea
                            readOnly: true
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            placeholderText: "Результат анализа появится здесь..."
                            color: root.clrTexta
							background: null
							textFormat: TextEdit.RichText//ВКЛЮЧАЕМ HTML
                            Connections {
                                target: analyzer
                                function onResultReady(result) {
                                    //Конвертируем Markdown в HTML
                                    resultArea.text = root.fnMarkdownToHtml(result)
                                    
                                    knopkaSohranit.enabled = (result !== "" && 
                                                            result !== "Анализируется..." &&
                                                            !result.startsWith("Ошибка:"))
                                }
                            }
                        }
                    }
                    DCScrollbar {
                        id: scbResultArea
                        flick: flcResultArea
                        anchors.right: rctResultArea.right
                        anchors.top: rctResultArea.top
                        anchors.bottom: rctResultArea.bottom
                        anchors.margins: 5
                        clrPolzunokOff: Qt.lighter(root.clrMenuFon, 1.3)
                        clrPolzunokOn: root.clrTexta
                        width: root.ntWidth * root.ntCoff
                        radius: 1
                    }
                }
                DCKnopkaOriginal {//Кнопка сохранения результата
                    id: knopkaSohranit
                    text: "💾 Сохранить результат"
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
                    clrKnopki: "#4CAF50"
                    clrTexta: root.clrFona
                    enabled: false
					anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
                    onClicked: {
                        if (!fnCloseMenuIfOpen()) {
                            fnClickedSave()
                        }
                    }
                    Connections {
                        target: analyzer
                        function onFileSaved(path) {
                            if (path.startsWith("[Ошибка")) {
                                console.log("Ошибка сохранения:", path)
                            } else {
                                console.log("✓ Файл сохранён:", path)
                                root.signalToolbar("Сохранено: " + path.split('/').pop())
                            }
                        }
                    }
                }
            }
        }
        DCScrollbar {// Скроллбар основной области
            id: dcScrollbar
            flick: flcZona
            anchors.right: tmZona.right
            anchors.top: tmZona.top
            anchors.bottom: tmZona.bottom
            clrPolzunokOff: Qt.lighter(root.clrMenuFon, 1.3)
            clrPolzunokOn: root.clrTexta
            width: root.ntWidth * root.ntCoff
            radius: 1
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }
        }
        DCMenu {//Всплывающее меню DCMenu
            id: menuMenu
            visible: false
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.left: tmZona.left
            anchors.right: tmZona.right
            anchors.bottom: tmZona.bottom
            anchors.bottomMargin: root.ntWidth
            anchors.rightMargin: dcScrollbar.width
            pctFona: 0.90
            clrTexta: root.clrMenuText
            clrFona: root.clrMenuFon
            imyaMenu: "analizer"
            
            onClicked: function(ntNomer, strMenu) {
                menuMenu.visible = false
                
                if (ntNomer === 1) {
                    fnClickedLoad()
                } else if (ntNomer === 2) {
                    fnClickedAnalizer()
                } else if (ntNomer === 3) {
                    fnClickedSave()
                } else if (ntNomer === 4) {
                    fnClickedMenu()
                } else if (ntNomer === 5) {
                    fnClickedInfo()
                } else if (ntNomer === 6) {
                    Qt.quit()
                }
            }
            onVisibleChanged: {
                if (!visible) {
                    root.forceActiveFocus()
                }
            }
        }
    }
    Item {//Тулбар
        id: tmToolbar
        clip: true
        //LOADER для DCProgress
        Loader {
            id: ldrProgress
            anchors.fill: tmToolbar
            source: "qrc:/DCMethods/DCProgress.qml"
            active: false
            onLoaded: {
                ldrProgress.item.ntWidth = root.ntWidth
                ldrProgress.item.ntCoff = root.ntCoff
                ldrProgress.item.clrProgress = root.clrTexta
                ldrProgress.item.clrTexta = "grey"
                ldrProgress.item.radius = root.ntCoff / 4
				ldrProgress.item.msInterval = 2200
            }
        }
        DCKnopkaInfo {
            id: knopkaInfo
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.verticalCenter: tmToolbar.verticalCenter
            anchors.left: tmToolbar.left
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            visible: true
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff
            tapWidth: tapHeight * root.tapToolbarLevi
            onClicked: {
                if (!fnCloseMenuIfOpen()) {
                    fnClickedInfo()
                }
            }
        }
        DCKnopkaNastroiki {
            id: knopkaNastroiki
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.verticalCenter: tmToolbar.verticalCenter
            anchors.right: tmToolbar.right
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            blVert: true
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff
            tapWidth: tapHeight * root.tapToolbarPravi
            onClicked: {
                fnToggleMenu()
            }
        }
    }
    MouseArea {//MouseArea для возврата фокуса
        anchors.fill: parent
        z: -1
        propagateComposedEvents: true
        onClicked: (mouse) => {
            mouse.accepted = false
            if (menuMenu.visible) {
                menuMenu.visible = false
            } else {
                root.forceActiveFocus()
            }
            root.forceActiveFocus()
        }
    }
}
