import QtQuick
import QtQuick.Controls
import DCButtons 1.0
import DCMethods 1.0

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
	signal clickedInfo()//Сигнал нажатия кнопки Информация
    
    // Настройки
    anchors.fill: parent
    focus: true
    
    // Обработка горячих клавиш для скролла
    Keys.onPressed: (event) => {
        // ← ДОБАВЛЕНО: Alt+Left для возврата назад
        if (event.modifiers & Qt.AltModifier) {
            if (event.key === Qt.Key_Left) {
                console.log("Alt+Left: возврат назад")
                root.clickedNazad()
                event.accepted = true
                return
            }
        }
		if (event.key === Qt.Key_Escape) {
            // ВАЖНО: Сначала проверяем меню
            if (menuMenu.visible) {
                menuMenu.visible = false
                event.accepted = true
            } else {
                // Если меню закрыто, ничего не делаем (можно добавить другую логику)
                event.accepted = true
            }
        }        
		if (event.key === Qt.Key_F1){
			if (!menuMenu.visible) {
			   fnClickedInfo()	
            }
            event.accepted = true
		}
        if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            // Скролл вверх
            if (!menuMenu.visible) {// Навигация работает только если меню закрыто
				var ltNoviY = flcZona.contentY - 50
				if (ltNoviY < 0)
					ltNoviY = 0
				flcZona.contentY = ltNoviY
			}
			event.accepted = true
            
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            // Скролл вниз
			if (!menuMenu.visible) {// Навигация работает только если меню закрыто
				var ltMaxY = flcZona.contentHeight - flcZona.height
				var ltNoviY = flcZona.contentY + 50
				if (ltNoviY > ltMaxY)
					ltNoviY = ltMaxY
				flcZona.contentY = ltNoviY
			}	
			event.accepted = true
            
        } else if (event.key === Qt.Key_PageUp) {
            // Скролл на страницу вверх
			if (!menuMenu.visible) {// Навигация работает только если меню закрыто
				var ltNoviY = flcZona.contentY - flcZona.height
				if (ltNoviY < 0)
					ltNoviY = 0
				flcZona.contentY = ltNoviY
			}
			event.accepted = true
        } else if (event.key === Qt.Key_PageDown) {
            // Скролл на страницу вниз
			if (!menuMenu.visible) {// Навигация работает только если меню закрыто
				var ltMaxY = flcZona.contentHeight - flcZona.height
				var ltNoviY = flcZona.contentY + flcZona.height
				if (ltNoviY > ltMaxY)
					ltNoviY = ltMaxY
				flcZona.contentY = ltNoviY
			}
			event.accepted = true
        } else if (event.key === Qt.Key_Home) {
            // В начало
			if (!menuMenu.visible) {// Навигация работает только если меню закрыто
				flcZona.contentY = 0
			}
			event.accepted = true
            
        } else if (event.key === Qt.Key_End) {
            // В конец
			if (!menuMenu.visible) {// Навигация работает только если меню закрыто
				flcZona.contentY = flcZona.contentHeight - flcZona.height
			}
			event.accepted = true
        }
    }
    function fnClickedMenu() {
        // Функция нажатия на кнопку Меню настройки
        // Пока ничего не делает
		console.log("НАСТРОЙКИ")
    }
	function fnClickedInfo() {
        // Функция нажатия на кнопку Помощь
        // Пока ничего не делает
        root.clickedInfo();//Сигнал излучаем, что нажата кнопка Описание.
    }
	function fnClickedLoad() {
		window.load_file()
	}
	function fnClickedAnalizer() {
		analyzer.analyze(contentArea.text, promptField.text)
	}
	function fnToggleMenu() {
        // Переключение видимости меню
        if (menuMenu.visible) {
            menuMenu.visible = false
        } else {
            menuMenu.visible = true
        }
    }
    function fnCloseMenuIfOpen() {
        // Закрыть меню если оно открыто
        if (menuMenu.visible) {
            menuMenu.visible = false
            return true  // Возвращаем true если меню было открыто
        }
        return false  // Возвращаем false если меню было закрыто
    }
    Component.onCompleted: {
        root.forceActiveFocus()
    }
    
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
                // Если меню открыто, закрываем его
                if (!fnCloseMenuIfOpen()) {
                    // Если меню было закрыто, вызываем функцию
                    fnClickedMenu()
                }
            }
        }
    }
    
    // Рабочая зона
    Item {
        id: tmZona
        clip: true
        
        Flickable {
            id: flcZona
            anchors.fill: parent
            contentWidth: tmZona.width
            contentHeight: clmnContent.height
            clip: true
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            
            Column {
                id: clmnContent
                width: flcZona.width - scbScrollbar.width
                spacing: root.ntCoff * 2
                topPadding: root.ntCoff * 2
                bottomPadding: root.ntCoff * 2
                leftPadding: root.ntCoff * 2
                rightPadding: root.ntCoff * 2
                
                // Кнопка загрузки файла
                DCKnopkaOriginal {
                    id: btnLoadFile
                    text: "📁 Загрузить документы"
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
                    //clrKnopki: "#4CAF50"
					clrKnopki: root.clrTexta	
                    clrTexta: root.clrFona
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    onClicked: {
						if (!fnCloseMenuIfOpen()) {
							fnClickedLoad()
						}
                    }
                }
                
                // Содержимое файла
                Text {
                    text: "Содержимое файла:"
                    font.pixelSize: root.ntWidth * root.ntCoff
                    color: root.clrTexta
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                
                Rectangle {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    height: 180
                    color: "white"
                    border.color: root.clrTexta
                    border.width: 1
                    radius: root.ntCoff / 2
                    
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 5
                        
                        TextArea {
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
                }
                
                // Промт для модели
                Text {
                    text: "Промт для модели:"
                    font.pixelSize: root.ntWidth * root.ntCoff
                    color: root.clrTexta
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                
                TextField {
                    id: promptField
                    width: parent.width - parent.leftPadding - parent.rightPadding
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
                    clrTexta: root.clrFona
                    enabled: contentArea.text.trim() !== ""
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    onClicked: {
						if (!fnCloseMenuIfOpen()) {
							fnClickedAnalizer()
						}
                    }
                }
                
                // Результат
                Text {
                    text: "Результат:"
                    font.pixelSize: root.ntWidth * root.ntCoff
                    color: root.clrTexta
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                
                Rectangle {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    height: 300
                    color: "#f9f9f9"
                    border.color: root.clrTexta
                    border.width: 1
                    radius: root.ntCoff / 2
                    
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 5
                        
                        TextArea {
                            id: resultArea
                            readOnly: true
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            placeholderText: "Результат анализа появится здесь..."
                            color: root.clrTexta
                            background: null
                            
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
        }
        
        // Скроллбар
        DCScrollbar {
            id: scbScrollbar
            flick: flcZona
            anchors.right: tmZona.right
            anchors.top: tmZona.top
            anchors.bottom: tmZona.bottom
            clrPolzunokOff: Qt.lighter(root.clrMenuFon, 1.3)
            clrPolzunokOn: root.clrTexta
            width: root.ntWidth * root.ntCoff
            radius: 1
        }
		// Всплывающее меню DCMenu
        DCMenu {
            id: menuMenu
            visible: false
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.left: tmZona.left
            anchors.right: tmZona.right
            anchors.bottom: tmZona.bottom
            anchors.bottomMargin: root.ntWidth
            anchors.rightMargin: scbScrollbar.width
            pctFona: 0.90
            clrTexta: root.clrMenuText
            clrFona: root.clrMenuFon
            imyaMenu: "analizer"
            
            onClicked: function(ntNomer, strMenu) {
                menuMenu.visible = false  // Закрываем меню после выбора
                
                if (ntNomer === 1) {
                    fnClickedLoad()
                }
				if (ntNomer === 2) {
                    fnClickedAnalizer()
                }
				if (ntNomer === 3) {
                    fnClickedMenu()
                }
				if (ntNomer === 4) {
                    fnClickedInfo()
                }
				if (ntNomer === 5) {  // Выход
                    Qt.quit()
                }
            }
			onVisibleChanged: {
				if(!visible){//Если закрылось меню, то форсируем основное окно для горчих клавиш.
					root.forceActiveFocus();//Напрямую форсируем фокус
				}
			}
        }
    }
    
    // Тулбар
    Item {
        id: tmToolbar
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
                // Если меню открыто, закрываем его
                if (!fnCloseMenuIfOpen()) {
                    // Если меню было закрыто, показываем информацию
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
                // Переключаем видимость меню
                fnToggleMenu()
            }
        }
    }
    
    // MouseArea для возврата фокуса
    MouseArea {
        anchors.fill: parent
        z: -1
        propagateComposedEvents: true
        onClicked: (mouse) => {
            mouse.accepted = false
			// Закрываем меню при клике на пустую область
            if (menuMenu.visible) {
                menuMenu.visible = false
            } else {
                root.forceActiveFocus()
            }
            root.forceActiveFocus()
        }
    }
}
