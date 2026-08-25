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
    
	property int logoRazmer: 22//Размер Логотипа
    property string logoImya: "kobzone"//Имя логотипа в DCLogo
	property real rlProgress: 0
	property real rlLoader: 1
	//Массив кнопок для навигации
    property var knopkiMassiv: []//Массив кнопок, между которыми нужно листать.
    property int currentIndex: 0//Выбранная кнопка.
	//Настройки
	anchors.fill: parent
	focus: true
	//Сигналы
	signal clickedNazad()
	signal clickedInfo()
	signal toolbar(var strToolbar)
    signal log(var strLog)
	//Методы
	Component.onCompleted: {
        knopkiMassiv = []//Сюда добавляем id кнопок, между которыми мы будим листать.
		root.forceActiveFocus()
	}
	Keys.onPressed: (event) => {
		if (event.modifiers & Qt.AltModifier) {
			if (event.key === Qt.Key_Left) {
				fnClickedNazad()
				event.accepted = true
				return
			}
		}
		if (event.key === Qt.Key_Escape) {
			fnClickedEscape()//Функция нажатия на клавишу Escape
			event.accepted = true
		} else if (event.key === Qt.Key_F1) {
			fnClickedInfo()    
			event.accepted = true
		} else if (event.key === Qt.Key_Up || event.key === Qt.Key_K || event.key === 1051) {
			if (!menuMenu.visible) {
				var ltNoviY = flcZona.contentY - 50
				if (ltNoviY < 0)
					ltNoviY = 0
				flcZona.contentY = ltNoviY
			}
			event.accepted = true
		} else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === 1054) {
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
            var visibleTop = flcZona.contentY
            var visibleBottom = visibleTop + flcZona.height
            
            if (knopkaTop < visibleTop)
                flcZona.contentY = knopkaTop
            else if (knopkaBottom > visibleBottom)
                flcZona.contentY = knopkaBottom - flcZona.height
        }
    }
	function fnClickedEscape() {//Функция нажатия на клавишу Escape
		if (menuMenu.visible) {
			menuMenu.visible = false
		} else {
			//Если меню закрыто, ничего не делаем (можно добавить другую логику)
		}
    }
	function fnClickedNazad() {
		fnClickedEscape()//Функция нажатия на клавишу Escape
		root.clickedNazad()
	}
	function fnClickedInfo() {
		fnClickedEscape()//Функция нажатия на клавишу Escape
		root.clickedInfo()
	}
	function fnToggleMenu() {
		if (menuMenu.visible) 
			menuMenu.visible = false
		else 
			menuMenu.visible = true
	}
	function fnCloseMenuIfOpen() {
		if (menuMenu.visible) {
			menuMenu.visible = false
			return true
		}
		return false
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
			onClicked: fnClickedNazad()
		}
	}
	Item {//Рабочая зона
		id: tmZona
		clip: true
		DCLogo {//Логотип
            id: lgLogo
            anchors.centerIn: tmZona
			ntCoff: root.logoRazmer
			logoImya: root.logoImya
			logoOpacity: 0.4
			z: -1
		}
		Flickable {
			id: flcZona
			anchors.fill: parent
			contentWidth: tmZona.width
			contentHeight: clmnContent.height
			clip: true
			interactive: true
			boundsBehavior: Flickable.StopAtBounds
			opacity: 0.9
			Behavior on opacity {
				NumberAnimation {
					duration: 300
					easing.type: Easing.InOutQuad
				}
			}
			TapHandler {//Нажимаем на всю область
				onTapped: fnCloseMenuIfOpen()//Закрыть меню если оно открыто	
			}
			Column {
				id: clmnContent
				width: flcZona.width - dcScrollbar.width
				spacing: root.ntCoff / 2
				topPadding: root.ntCoff * 2
				bottomPadding: root.ntCoff * 2
				leftPadding: root.ntCoff * 2
				rightPadding: root.ntCoff * 2
				//ТУТ КОНТЕНТ НАСТРОЕК
				Text {//Промт для модели
                    text: "Имя модели:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
				TextField {
					id: promptField
					width: parent.width - parent.leftPadding - parent.rightPadding
					placeholderText: "Напишите имя языковой модели"
					selectByMouse: true
					color: root.clrTexta
					background: Rectangle {
						color: "transparent"
						border.color: root.clrTexta
						border.width: 1
						radius: root.ntCoff / 2
					}
					Keys.onReturnPressed: {//Если нажат Enter
						
					}
					onTextChanged: {

					}
				}
			}
		}
		DCScrollbar {//Скроллбар
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
			imyaMenu: "settings"
			onClicked: function(ntNomer, strMenu) {
				menuMenu.visible = false
				if (ntNomer === 1) {
					fnClickedInfo()
				} else if (ntNomer === 2) {
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
			if (menuMenu.visible)
				menuMenu.visible = false
			else 
				root.forceActiveFocus()
			root.forceActiveFocus()
		}
	}
}

