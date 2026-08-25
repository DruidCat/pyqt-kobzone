import QtQuick
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
    
    property real tapZagolovokLevi: 1
    property real tapZagolovokPravi: 1
    property real tapToolbarLevi: 1
    property real tapToolbarPravi: 1
	property int logoRazmer: 22//Размер Логотипа
    property string logoImya: "kobzone"//Имя логотипа в DCLogo
    //Массив кнопок для навигации
    property var knopkiMassiv: []
    property int currentIndex: 0//Выбранная кнопка.
    //Настройки
    anchors.fill: parent
    //Сигналы
    signal clickedAnalizator()
    signal clickedOrfograf()
    signal clickedTranskribaciya()
	signal clickedSettings()
	signal clickedInfo()//Сигнал нажатия кнопки Информация
	signal toolbar(var strToolbar)
    signal log(var strLog)
	//Методы
    Component.onCompleted: {
        knopkiMassiv = [knopkaAnalizator, knopkaRedaktor, knopkaTranskribaciya]
    }
    Keys.onPressed: (event) => {//Обработка клавиш на уровне root
		if (event.modifiers & Qt.AltModifier) {
            if (event.key === Qt.Key_F || event.key === 1040) {
                fnClickedMenu()//Функция Настройки
                event.accepted = true
                return
            }
        }
        if (event.key === Qt.Key_Escape) {
			fnClickedEscape()//Функция нажатия на клавишу Escape
			event.accepted = true
		} else if (event.key === Qt.Key_F1){
			fnClickedInfo()	
            event.accepted = true
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K || event.key === 1051) {
            if (!menuMenu.visible) {//Навигация работает только если меню закрыто
                root.currentIndex--
                if (root.currentIndex < 0)
                    root.currentIndex = knopkiMassiv.length - 1
                
                fnScrollKnopok(false)
            }
            event.accepted = true 
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === 1054) {
            if (!menuMenu.visible) {//Навигация работает только если меню закрыто
                root.currentIndex++
                if (root.currentIndex >= knopkiMassiv.length)
                    root.currentIndex = 0
                
                fnScrollKnopok(true)
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (!menuMenu.visible) {//Enter работает только если меню закрыто
                fnClickedEnter()
            }
            event.accepted = true
        }
    }
    function fnClickedEnter() {//Функция обработки нажатия клавиши Enter
        if (root.currentIndex >= 0 && root.currentIndex < knopkiMassiv.length) {
            var vrKnopkaID = knopkiMassiv[root.currentIndex]
            
            if (vrKnopkaID && typeof vrKnopkaID.fnPress === "function" && 
                vrKnopkaID.visible && vrKnopkaID.enabled) {
                vrKnopkaID.fnPress()
            }
        }
    }
    function fnScrollKnopok(isPlus) {//Функция скроллина кнопок
        var knopkaID = knopkiMassiv[root.currentIndex]
        if (!knopkaID) {
            return
        }
        if (knopkaID.visible) {
            var knopkaTop = knopkaID.y
            var knopkaBottom = knopkaTop + knopkaID.height + root.ntWidth
            var visibleTop = flcMenu.contentY
            var visibleBottom = visibleTop + flcMenu.height
            
            if (knopkaTop < visibleTop)
                flcMenu.contentY = knopkaTop
            else if (knopkaBottom > visibleBottom)
                flcMenu.contentY = knopkaBottom - flcMenu.height
        }
    }
    function fnClickedEscape() {//Функция нажатия на клавишу Escape
		if (menuMenu.visible) {
			menuMenu.visible = false
		} else {
			//Если меню закрыто, ничего не делаем (можно добавить другую логику)
		}
    }
    function fnClickedMenu() {
		fnClickedEscape()//Функция нажатия на клавишу Escape
		root.clickedSettings()//Сигнал излучает открытие настроек.
    }
	function fnClickedInfo() {//Функция нажатия на кнопку Помощь
		fnClickedEscape()//Функция нажатия на клавишу Escape
        root.clickedInfo();//Сигнал излучаем, что нажата кнопка Описание.
    }
    function fnToggleMenu() {//Переключение видимости меню
        if (menuMenu.visible) {
            menuMenu.visible = false
        } else {
            menuMenu.visible = true
        }
    }
    function fnCloseMenuIfOpen() {//Закрыть меню если оно открыто
		if (menuMenu.visible) {
			menuMenu.visible = false
			return true//Возвращаем true если меню было открыто
		}
		return false//Возвращаем false если меню было закрыто
    }
    Item {//Заголовок
        id: tmZagolovok
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
				if (!fnCloseMenuIfOpen()) {//Если меню открыто, закрываем его
					fnClickedMenu()
				}
			}
        }
    }
    Item {//Рабочая зона
        id: tmZona
        clip: true
        
        Rectangle {
            id: rctZona
            anchors.fill: parent
            anchors.margins: root.ntCoff / 2
            color: "transparent"
            Rectangle {//Левый логотип
                id: rctLogo_1
                width: parent.width * 0.25
                height: parent.height
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: "transparent"
                border.color: root.clrTexta
                border.width: root.ntCoff / 4
                radius: root.ntCoff / 2
                
                Image {
                    id: imgLogo1
                    anchors.fill: parent
                    anchors.margins: root.ntCoff
                    source: "qrc:/resources/images/high_priestess.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: 0.8
                }
            }
            Rectangle {//Центральное меню
                id: rctMenu
                anchors.left: rctLogo_1.right
                anchors.right: rctLogo_2.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: root.ntCoff
                anchors.rightMargin: root.ntCoff
                color: "transparent"
                Flickable {
                    id: flcMenu
                    property int kolichestvoKnopok: clmnKnopki.children.length
                    anchors.fill: parent
                    contentWidth: rctMenu.width
                    contentHeight: clmnKnopki.height
                    clip: true
                    interactive: true
					TapHandler {//Нажимаем на всю область виджета.
						onTapped: fnCloseMenuIfOpen()//Закрыть меню если оно открыто	
					}
                    Column {
                        id: clmnKnopki
                        width: flcMenu.width - scbScrollbar.width - root.ntWidth * root.ntCoff
                        anchors.left: parent.left
                        anchors.leftMargin: root.ntWidth * root.ntCoff
                        spacing: root.ntWidth
                        DCKnopkaOriginal {//Кнопка "Нейро анализ документа"
                            id: knopkaAnalizator
                            ntHeight: root.ntWidth * 1.1
                            ntCoff: root.ntCoff
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.topMargin: root.ntWidth
                            clrTexta: root.clrMenuText
                            clrKnopki: (root.currentIndex === 0) ?
														Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                            text: "НЕЙРО АНАЛИЗ ДОКУМЕНТОВ"
                            opacityKnopki: 0.9
                            function fnPress() {
                                root.currentIndex = 0
                                root.clickedAnalizator()
                            }
                            onPressedChanged: {
                                if (pressed) {
                                    if (!fnCloseMenuIfOpen()) {//Сначала закрываем меню если открыто
                                        fnPress()//Если меню было закрыто, выполняем действие
                                    }
                                }
                            }
                        }
                        DCKnopkaOriginal {//Кнопка "Исправление текста"
                            id: knopkaRedaktor
                            ntHeight: root.ntWidth * 1.1
                            ntCoff: root.ntCoff
                            anchors.left: parent.left
                            anchors.right: parent.right
                            clrTexta: root.clrMenuText
                            clrKnopki: (root.currentIndex === 1) ?
                                Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                            text: "ИСПРАВЛЕНИЕ ТЕКСТА"
                            opacityKnopki: 0.9
                            enabled: true
                            function fnPress() {
                                root.currentIndex = 1
                                root.clickedOrfograf()
                            }
                            onPressedChanged: {
                                if (pressed) {
                                    if (!fnCloseMenuIfOpen()) {//Сначала закрываем меню если открыто
                                        fnPress()//Если меню было закрыто, выполняем действие
                                    }
                                }
                            }
                        }
                        DCKnopkaOriginal {//Кнопка "Транскрибация"
                            id: knopkaTranskribaciya
                            ntHeight: root.ntWidth * 1.1
                            ntCoff: root.ntCoff
                            anchors.left: parent.left
                            anchors.right: parent.right
                            clrTexta: root.clrMenuText
                            clrKnopki: (root.currentIndex === 2) ?
                                Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                            text: "ТРАНСКРИБАЦИЯ"
                            opacityKnopki: 0.9
                            enabled: true
                            function fnPress() {
                                root.currentIndex = 2
                                root.clickedTranskribaciya()
                            }
                            onPressedChanged: {
                                if (pressed) {
                                    if (!fnCloseMenuIfOpen()) {//Сначала закрываем меню если открыто
                                        fnPress()//Если меню было закрыто, выполняем действие
                                    }
                                }
                            }
                        }
                    }
                }
                DCScrollbar {//Скроллбар
                    id: scbScrollbar
                    flick: flcMenu
                    anchors.right: rctMenu.right
                    anchors.top: rctMenu.top
                    anchors.bottom: rctMenu.bottom
                    clrPolzunokOff: Qt.lighter(root.clrMenuFon, 1.3)
                    clrPolzunokOn: root.clrTexta
                    width: root.ntWidth * root.ntCoff
                    radius: 1
                }
            }
            Rectangle {//Правый логотип
                id: rctLogo_2
                width: parent.width * 0.25
                height: parent.height
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: "transparent"
                border.color: root.clrTexta
                border.width: root.ntCoff / 4
                radius: root.ntCoff / 2
                Image {
                    id: imgLogo2
                    anchors.fill: parent
                    anchors.margins: root.ntCoff
                    source: "qrc:/resources/images/logo.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: 0.8
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
            anchors.rightMargin: scbScrollbar.width
            pctFona: 0.90
            clrTexta: root.clrMenuText
            clrFona: root.clrMenuFon
            imyaMenu: "kobzone"
            onClicked: function(ntNomer, strMenu) {
                menuMenu.visible = false//Закрываем меню после выбора
                if (ntNomer === 1) {
                    fnClickedMenu()
                } else if (ntNomer === 2) {
                    fnClickedInfo()
                } else if (ntNomer === 3) {
                    Qt.quit()//Выход
                }
            }
			onVisibleChanged: {
				if(!visible){//Если закрылось меню, то форсируем основное окно для горчих клавиш.
					root.forceActiveFocus();//Напрямую форсируем фокус
				}
			}
        }
    }
    Item {//Тулбар
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
                if (!fnCloseMenuIfOpen()) {//Если меню открыто, закрываем его
                    fnClickedInfo()//Если меню было закрыто, показываем информацию
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
                fnToggleMenu()//Переключаем видимость меню
            }
        }
    }
    MouseArea {//MouseArea для возврата фокуса при клике
        anchors.fill: parent
        z: -1
        propagateComposedEvents: true
        onClicked: (mouse) => {
            mouse.accepted = false
            if (menuMenu.visible) {// Закрываем меню при клике на пустую область
                menuMenu.visible = false
            } else {
                root.forceActiveFocus()
            }
        }
    }
}
