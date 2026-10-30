import QtQuick
import QtQuick.Controls
import DCButtons 1.0
import DCMethods 1.0
import DCSettings 1.0

Item {
	id: root
	//Свойства
	property int ntWidth: 2
	property int ntCoff: 8
	property color clrTexta: "indigo"
	property color clrFona: "white"
	property color clrMenuText: "indigo"
	property color clrMenuFon: "#f5f5f5"
	property color clrVnimanie: "red"
	
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
	//Настройки страницы (значения из реестра DCSettings)
	property real rlTemperatura: DCSettings.orfograf_temperatura//Температура ИИ
	property int ntPerekritie: DCSettings.orfograf_perekritie//Перекрытие фрагментов в %
	property int ntKontekst: DCSettings.orfograf_kontekst//Размер фрагмента в символах
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
	function fnFocus(){//Фокус на странице, чтоб горячие клавиши работали.
		root.forceActiveFocus()
	}
	Component.onCompleted: {
        knopkiMassiv = [knopkaTemperatura, knopkaPerekritie, knopkaKontekst]//Сюда добавляем id кнопок
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
				root.currentIndex--
                if (root.currentIndex < 0)
                    root.currentIndex = knopkiMassiv.length - 1
                
                fnScrollKnopok(false)
			}
			event.accepted = true
		} else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === 1054) {
			if (!menuMenu.visible) {
				root.currentIndex++
                if (root.currentIndex >= knopkiMassiv.length)
                    root.currentIndex = 0
                
                fnScrollKnopok(true)
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
		} else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (!menuMenu.visible) {//Enter работает только если меню закрыто
                fnClickedEnter()
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
		} 
		if (pvTemperatura.visible) {
			pvTemperatura.visible = false
		}
		if (pvPerekritie.visible) {
			pvPerekritie.visible = false
		}
		if (pvKontekst.visible) {
			pvKontekst.visible = false
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
				DCKnopkaOriginal {//Кнопка выбора температуры ИИ модели
					id: knopkaTemperatura
					text: {
						let ltText = qsTr("температура ИИ: ");//Подпись значения
						ltText += root.rlTemperatura//Добавляем температуру из настроек
						for (let i = 0; i < modelTemperatura.count; i++) {//Ищем сохранённое значение в списке
							if (modelTemperatura.get(i).spisok === root.rlTemperatura) {
								pvTemperatura.currentIndex = i//Выставляем в карусели нужное значение
								break
							}
						}
						return ltText;
					}
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrTexta
					clrKnopki: (root.currentIndex === 0) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
					opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 0
						if(pvTemperatura.visible){//Если видимый виджет, то...
							Qt.callLater(function(){//пауза, иначе не сработает фокус. ВАЖНО!!!
								pvTemperatura.visible = false//Делаем невидимым виджет
								fnFocus()//фокус страницы, чтоб hotkey работали.
							})
						}
						else{//Если невидимый виджет, то...
							Qt.callLater(function(){//пауза, иначе не сработает фокус. ВАЖНО!!!
								pvTemperatura.visible = true//Делаем видимым виджет
								pvTemperatura.karusel.forceActiveFocus()//фокус PathView, чтоб hotkey работали
							})
						}
					}
					onClicked: {
						if (pressed && !pvTemperatura.pressed
								&& !pvPerekritie.pressed
								&& !pvKontekst.pressed) fnPress()
					}
				}
				DCKnopkaOriginal {//Кнопка выбора процента перекрытия соседних фрагментов
					id: knopkaPerekritie
					text: {
						let ltText = qsTr("перекрытие фрагментов, %: ");//Подпись значения
						ltText += root.ntPerekritie//Добавляем перекрытие из настроек
						for (let i = 0; i < modelPerekritie.count; i++) {//Ищем сохранённое значение в списке
							if (modelPerekritie.get(i).spisok === root.ntPerekritie) {
								pvPerekritie.currentIndex = i//Выставляем в карусели нужное значение
								break
							}
						}
						return ltText;
					}
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrTexta
					clrKnopki: (root.currentIndex === 1) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
					opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 1
						if(pvPerekritie.visible){//Если видимый виджет, то...
							Qt.callLater(function(){//пауза, иначе не сработает фокус. ВАЖНО!!!
								pvPerekritie.visible = false//Делаем невидимым виджет
								fnFocus()//фокус страницы, чтоб hotkey работали.
							})
						}
						else{//Если невидимый виджет, то...
							Qt.callLater(function(){//пауза, иначе не сработает фокус. ВАЖНО!!!
								pvPerekritie.visible = true//Делаем видимым виджет
								pvPerekritie.karusel.forceActiveFocus()//фокус PathView, чтоб hotkey работали
							})
						}
					}
					onClicked: {
						if (pressed && !pvTemperatura.pressed
								&& !pvPerekritie.pressed
								&& !pvKontekst.pressed) fnPress()
					}
				}
				DCKnopkaOriginal {//Кнопка выбора размера фрагмента документа в символах
					id: knopkaKontekst
					text: {
						let ltText = qsTr("размер фрагмента, символов: ");//Подпись значения
						ltText += root.ntKontekst//Добавляем размер из настроек
						for (let i = 0; i < modelKontekst.count; i++) {//Ищем сохранённое значение в списке
							if (modelKontekst.get(i).spisok === root.ntKontekst) {
								pvKontekst.currentIndex = i//Выставляем в карусели нужное значение
								break
							}
						}
						return ltText;
					}
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrTexta
					clrKnopki: (root.currentIndex === 2) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
					opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 2
						if(pvKontekst.visible){//Если видимый виджет, то...
							Qt.callLater(function(){//пауза, иначе не сработает фокус. ВАЖНО!!!
								pvKontekst.visible = false//Делаем невидимым виджет
								fnFocus()//фокус страницы, чтоб hotkey работали.
							})
						}
						else{//Если невидимый виджет, то...
							Qt.callLater(function(){//пауза, иначе не сработает фокус. ВАЖНО!!!
								pvKontekst.visible = true//Делаем видимым виджет
								pvKontekst.karusel.forceActiveFocus()//фокус PathView, чтоб hotkey работали
							})
						}
					}
					onClicked: {
						if (pressed && !pvTemperatura.pressed
								&& !pvPerekritie.pressed
								&& !pvKontekst.pressed) fnPress()
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
		ListModel {//Список температур ИИ модели
			id: modelTemperatura
			ListElement { spisok: 0.0 }
			ListElement { spisok: 0.1 }
			ListElement { spisok: 0.2 }
			ListElement { spisok: 0.3 }
			ListElement { spisok: 0.4 }
			ListElement { spisok: 0.5 }
			ListElement { spisok: 0.7 }
			ListElement { spisok: 1.0 }
		}
		ListModel {//Список процентов перекрытия фрагментов
			id: modelPerekritie
			ListElement { spisok: 0 }
			ListElement { spisok: 5 }
			ListElement { spisok: 10 }
			ListElement { spisok: 15 }
			ListElement { spisok: 20 }
			ListElement { spisok: 25 }
			ListElement { spisok: 30 }
			ListElement { spisok: 40 }
		}
		ListModel {//Список размеров фрагмента в символах
			id: modelKontekst
			ListElement { spisok: 2000 }
			ListElement { spisok: 4000 }
			ListElement { spisok: 6000 }
			ListElement { spisok: 8000 }
			ListElement { spisok: 12000 }
			ListElement { spisok: 16000 }
		}
		DCPathView {//Карусель выбора температуры ИИ
			id: pvTemperatura
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrMenuFon; clrTexta: root.clrTexta; clrMenuFon: Qt.darker(root.clrMenuFon, 1.5)
			anchors.left: tmZona.left; anchors.right: tmZona.right; anchors.bottom: tmZona.bottom
			visible: false
			modelData: modelTemperatura
			onClicked: function (strTemperatura) {
				Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
					pvTemperatura.visible = false//Делаем невидимым виджет
					root.rlTemperatura = strTemperatura//Запоминаем выбор в настройках страницы
					DCSettings.orfograf_temperatura = root.rlTemperatura//Сохраняем в реестре
				})
			}
			onVisibleChanged: {//Если видимость поменялась, то...
				if(!visible) root.forceActiveFocus()//Если невидимый, то фокус на root, чтоб hotkey работали.
			}
		}
		DCPathView {//Карусель выбора процента перекрытия фрагментов
			id: pvPerekritie
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrMenuFon; clrTexta: root.clrTexta; clrMenuFon: Qt.darker(root.clrMenuFon, 1.5)
			anchors.left: tmZona.left; anchors.right: tmZona.right; anchors.bottom: tmZona.bottom
			visible: false
			modelData: modelPerekritie
			onClicked: function (strPerekritie){
				Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
					pvPerekritie.visible = false//Делаем невидимым виджет
					root.ntPerekritie = strPerekritie//Запоминаем выбор в настройках страницы
					DCSettings.orfograf_perekritie = root.ntPerekritie//Сохраняем в реестре
				})
			}
			onVisibleChanged: {//Если видимость поменялась, то...
				if(!visible) root.forceActiveFocus()//Если невидимый, то фокус на root, чтоб hotkey работали.
			}
		}
		DCPathView {//Карусель выбора размера фрагмента
			id: pvKontekst
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrMenuFon; clrTexta: root.clrTexta; clrMenuFon: Qt.darker(root.clrMenuFon, 1.5)
			anchors.left: tmZona.left; anchors.right: tmZona.right; anchors.bottom: tmZona.bottom
			visible: false
			modelData: modelKontekst
			onClicked: function(strKontekst) {
				Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
					pvKontekst.visible = false//Делаем невидимым виджет
					root.ntKontekst = strKontekst//Запоминаем выбор в настройках страницы
					DCSettings.orfograf_kontekst = root.ntKontekst//Сохраняем в реестре
				})
			}
			onVisibleChanged: {//Если видимость поменялась, то...
				if(!visible) root.forceActiveFocus()//Если невидимый, то фокус на root, чтоб hotkey работали.
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
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			anchors.verticalCenter: tmToolbar.verticalCenter; anchors.left: tmToolbar.left
			clrKnopki: root.clrTexta; clrFona: root.clrFona
			tapHeight: root.ntWidth * root.ntCoff + root.ntCoff; tapWidth: tapHeight * root.tapToolbarLevi
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

