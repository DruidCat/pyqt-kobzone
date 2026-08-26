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
	//Модель
	property string strModel: dcReestr.analizer_model_imya//Имя модели ИИ
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
        knopkiMassiv = [knopkaModeli]//Сюда добавляем id кнопок, между которыми мы будим листать.
		root.forceActiveFocus()

        pyModelManager.zagruzitModeli()//Загружаем модели при открытии страницы
	}
	DCSettings {//Объект настроек
        id: dcReestr
    }
	onStrModelChanged: {//Если Модель изменится, то...
        dcReestr.analizer_model_imya = root.strModel//Сохраняем в реестре имя Модели.
        pyModelManager.ustModel(root.strModel)//Отправляем в Python
        //Обновляем настройки анализатора
        let contextVal = dcReestr.analizer_context
        let tempVal = dcReestr.analizer_temp
        let overlapVal = dcReestr.analizer_overlap
        pyAnalyzer.ustModelSettings(
            root.strModel, 
            contextVal, 
            tempVal, 
            overlapVal
        )
    }
    Connections {//Обработчик загрузки моделей из Python
        target: pyModelManager

        function onSigModelsLoaded(models) {
            modelModels.clear()//Очищаем старую модель
            for (let i = 0; i < models.length; i++) {//Заполняем новыми данными
                modelModels.append({ spisok: models[i] })
            }
            let savedModel = dcReestr.analizer_model_imya//Устанавливаем текущий индекс

            if (savedModel === "" || savedModel === "(автовыбор модели)") {
                pvModels.currentIndex = 0//Первый элемент = автовыбор
            } else {
                for (let i = 0; i < models.length; i++) {//Ищем сохранённую модель в списке
                    if (models[i] === savedModel) {
                        pvModels.currentIndex = i
                        break
                    }
                }
            }
            console.log("✓ Загружено моделей:", models.length)
        }
        function onSigError(errorMsg) {
            console.log("✗ Ошибка загрузки моделей:", errorMsg)
            root.log("Ошибка: " + errorMsg)
        }
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
	function fnClickedModel(){//Функция выбора Модели
		if(pvModels.visible){//Если видимый виджет, то...
			Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
				pvModels.visible = false//Делаем невидимым виджет
				root.forceActiveFocus()//фокус PathView, чтоб hotkey работали.
			})
		}
		else{//Если невидимый виджет, то...
			Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
				pvModels.visible = true//Делаем видимым виджет
				pvModels.karusel.forceActiveFocus()//фокус PathView, чтоб hotkey работали.
			})
		}
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
				DCKnopkaOriginal {//Кнопка выбора размера шрифта
                    id: knopkaModeli
                    text: {
                        let ltText = qsTr("модель ");//
						if (root.strModel === "" || root.strModel === "(автовыбор модели)") {
							ltText += qsTr("автовыбор")
						} else {
							// Показываем только последнюю часть имени (без пути)
							let parts = root.strModel.split("/")
							ltText += parts[parts.length - 1]
						}
						return ltText;
                    }
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
					anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 0) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 0
						fnClickedModel()//Функция выбора Модели.
					}
					onPressedChanged: {
						if (pressed) {
							if (!fnCloseMenuIfOpen()) {//Сначала закрываем меню если открыто
								if (pressed && !pvModels.pressed) fnPress()
							}
						}
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
		ListModel {//Модель с шриштами
            id: modelModels
			//Будет заполняться динамически из Python
        }
        DCPathView {
            id: pvModels
            visible: false
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            anchors.left: tmZona.left; anchors.right: tmZona.right; anchors.bottom: tmZona.bottom
            anchors.leftMargin: dcScrollbar.width; anchors.rightMargin: dcScrollbar.width
            clrFona: root.clrFona; clrTexta: root.clrMenuText; clrMenuFon: root.clrMenuFon
            modelData: modelModels
            onClicked: function(strModel) {
				Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
					pvModels.visible = false//Делаем невидимым виджет
					root.strModel = strModel//Сохраняем выбор
					root.forceActiveFocus()//фокус PathView, чтоб hotkey работали.
				})
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

