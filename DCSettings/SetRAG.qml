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
	//Массив кнопок для навигации
    property var knopkiMassiv: []//Массив кнопок, между которыми нужно листать.
    property int currentIndex: 0//Выбранная кнопка.
	
	property bool isGPU: DCSettings.rag_gpu//true - анализ через GPU, false - анализ через CPU
	property int ntModel: DCSettings.rag_model//модель от 0 простой до сложной 6	
	property int ntBatchGPU: DCSettings.rag_batch_gpu//Максимум 256
	property int ntBatchCPU: DCSettings.rag_batch_cpu//Максимум 64
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
        knopkiMassiv = [knopkaGPU, knopkaModeli, knopkaBatchGPU, knopkaBatchCPU]//Сюда добавляем id кнопок
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
		} else {
			//Если меню закрыто, ничего не делаем (можно добавить другую логику)
		}
		if (pvModeli.visible) {
			pvModeli.visible = false
		}
		txnZagolovok.visible = false//Делаем невидимым ввот чисел
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
		else {
			if (pvModeli.visible) pvModeli.visible = false
			if (vprGPUStart.visible) vprGPUStart.visible = false
			if (txnZagolovok.visible) txnZagolovok.visible = false
			menuMenu.visible = true
		}
	}
	function fnCloseMenuIfOpen() {
		if (menuMenu.visible) {
			menuMenu.visible = false
			return true
		}
		return false
	}
	function fnCloseBatchIfOpen() {
		if (txnZagolovok.visible) {
			txnZagolovok.visible = false
			return true
		}
		return false
	}
	function fnCloseModeliIfOpen() {
		if (pvModeli.visible) {
			pvModeli.visible = false
			return true
		}
		return false
	}
	function fnCloseGPUStartIfOpen() {
		if (vprGPUStart.visible) {
			vprGPUStart.visible = false
			return true
		}
		return false
	}
	function fnClickedModeli(){//Функция выбора модели
		if(pvModeli.visible){//Если видимый виджет, то...
			Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModeli. ВАЖНО!!!
				pvModeli.visible = false//Делаем невидимым виджет
			})
		}
		else{//Если невидимый виджет, то...
			pvModeli.currentIndex = root.ntModel//Выставляем центральной модель из настроек
			Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModeli. ВАЖНО!!!
				pvModeli.visible = true//Делаем видимым виджет
			})
		}
	}
	function fnClickedOk(){//Функция сохранения данных.
		let ltContext = Number(txnZagolovok.text)//Явно приобразовываем в число.
		let ltResult = Math.round(ltContext / 2) * 2;//Получаем число кратное 2.
		if (txnZagolovok.isBatchGPU){
			if (ltResult>256) ltResult = 256
			DCSettings.rag_batch_gpu = ltResult//Сохраняем в реестре значение.
		} else {
			if (ltResult>64) ltResult = 64 
			DCSettings.rag_batch_cpu = ltResult//Сохраняем в реестре значение.
		}
		txnZagolovok.visible = false//Делаем невидимым ввот чисел
	}
	function fnClickedZakrit(){//Функция закрытия виджета
		txnZagolovok.visible = false//Делаем невидимым ввот чисел
	}
	function fnClickedBatch(blBatchGPU){//Функция выбора batch size
		txnZagolovok.isBatchGPU = blBatchGPU
		txnZagolovok.visible = !txnZagolovok.visible
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
		DCKnopkaZakrit {
            id: knopkaZakrit
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            visible: false
            anchors.verticalCenter: tmZagolovok.verticalCenter
            anchors.left: tmZagolovok.left
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff
            tapWidth: tapHeight*root.tapZagolovokLevi
            onClicked: fnClickedZakrit();//Функция обрабатывающая кнопку Закрыть.
        }
		DCKnopkaOk {
            id: knopkaOk
			ntWidth: root.ntWidth
			ntCoff: root.ntCoff
			visible: false
			anchors.verticalCenter: tmZagolovok.verticalCenter
			anchors.right: tmZagolovok.right
			clrKnopki: root.clrTexta
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff
            tapWidth: tapHeight*root.tapZagolovokLevi
            onClicked: fnClickedOk();//Нажимаем на Ок(Сохранить)	
		}
		Item {
            id: tmTextInput
			anchors.top: tmZagolovok.top
			anchors.bottom: tmZagolovok.bottom
			anchors.left: knopkaZakrit.right
			anchors.right: knopkaOk.left
            anchors.topMargin: root.ntCoff/4
            anchors.bottomMargin: root.ntCoff/4
            anchors.leftMargin: root.ntCoff/2
            anchors.rightMargin: root.ntCoff/2
			DCTextInput {
				id: txnZagolovok
				ntWidth: root.ntWidth; ntCoff: root.ntCoff
				anchors.fill: tmTextInput
				clrTexta: root.clrTexta; clrFona: root.clrMenuFon
				radius: root.ntCoff/2
				visible: false
				isNumber: true//Вводим только цифры
				textInput.maximumLength: 3//Ограницение по вводу максимальны токенов для локальной модели
				property bool isBatchGPU: false//true - открываем настройки batch_size_gpu, false - cpu
				onSgnDebug: function (strDebug) { root.toolbar(strDebug) }//Ошибка из виджета в программу.
				onVisibleChanged: {//Если видимость DCTextInput изменился, то...
					if(txnZagolovok.visible){//Если DCTextInput видим, то...
						knopkaNazad.visible = false;//Конопка Назад Невидимая.
						knopkaZakrit.visible = true;//Кнопка закрыть Видимая
						knopkaOk.visible = true;//Кнопка Ок Видимая.
						if (isBatchGPU) text = DCSettings.rag_batch_gpu//Показываем значение batch_size_gpu
						else text = DCSettings.rag_batch_cpu//Показываем значение batch_size_cpu
					}
					else{//Если DCTextInput не видим, то...
						knopkaNazad.visible = true;//Конопка Информация Видимая.
						knopkaZakrit.visible = false;//Кнопка закрыть Невидимая
						knopkaOk.visible = false;//Кнопка Ок Невидимая.
						txnZagolovok.text = "";//Текст обнуляем вводимый.
						root.forceActiveFocus()//Фокус на главной странице, чтоб горячие клавиши работали.
					}
				}
				onClickedEnter: {//слот нажатия кнопки Enter.
					if(knopkaOk.visible) fnClickedOk();//Функция сохранения данных.
				}
				onClickedEscape: {
					if(knopkaZakrit.visible) fnClickedZakrit()//Функция закрытия виджета
				}
			}
		}
		DCVopros {
			id: vprGPUStart
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			anchors.top: tmZagolovok.top; anchors.bottom: tmZagolovok.bottom
			anchors.left: tmZagolovok.left; anchors.right: tmZagolovok.right
			clrFona: root.clrVnimanie; clrTexta: root.clrFona
			clrKnopki: root.clrFona; clrBorder: root.clrFona
			tapKnopkaZakrit: root.tapZagolovokLevi; tapKnopkaOk: root.tapZagolovokPravi
			visible: false
			text: qsTr("ВКЛЮЧИТЬ GPU?")
			onVisibleChanged: {
				if(visible) {
					pvModeli.visible = false//Делаем невидимым виджет
					knopkaNazad.visible = false
					knopkaModeli.enabled = false
				} else {
					knopkaNazad.visible = true
					knopkaModeli.enabled = true
        			root.forceActiveFocus()//Переводим фокус на основное окно, чтоб работали горячие кнопки.
				}
			}
			onClickedOk: {
				DCSettings.rag_gpu = root.isGPU = true
				DCSettings.rag_model = root.ntModel = pvModeli.currentIndex;//Приравниваем значение
				vprGPUStart.visible = false//Делаем невидимый диалог
				pvModeli.visible = false
			}
			onClickedOtmena: {
				vprGPUStart.visible = false//Делаем невидимый диалог.
			}
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
				onTapped: {
					fnCloseMenuIfOpen()//Закрыть меню если оно открыто	
					if(!knopkaBatchGPU.pressedTmr550 && !knopkaBatchCPU.pressedTmr550) fnCloseBatchIfOpen()
					fnCloseGPUStartIfOpen()//Закрываем попрос по GPU
					if(!pvModeli.jdi && !pvModeli.pressed) fnCloseModeliIfOpen()//Закрываем меню выбора модели
				}
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
				DCKnopkaOriginal {//Кнопка использования GPU/CPU при создании RAG базы данных
					id: knopkaGPU
					text: root.isGPU ? qsTr("gpu вкл") : qsTr("gpu выкл")
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
						root.isGPU = !root.isGPU
						DCSettings.rag_gpu = root.isGPU
						if(root.isGPU) root.toolbar("Используется GPU для создания RAG базы данных.")
						else root.toolbar("Используется CPU для создания RAG базы данных.")
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseGPUStartIfOpen() && !fnCloseBatchIfOpen()){
								if (pressed && !pvModeli.pressed) fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {//Кнопка выбора модели
                    id: knopkaModeli
                    text: {
                        let ltModel = qsTr("модель ");//
						ltModel += modelModeli.get(root.ntModel).spisok
                        pvModeli.currentIndex = root.ntModel
                        return ltModel;
                    }
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
					anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 1) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 1
						fnClickedModeli()//Функция выбора модели
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseGPUStartIfOpen() && !fnCloseBatchIfOpen()) {
								if (pressed && !pvModeli.pressed) fnPress()
							}
						}
					}
                }
				DCKnopkaOriginal {//Кнопка параллельный прогонов через GPU
					id: knopkaBatchGPU
					text: {
						let ltText = qsTr("batch GPU ");//
						ltText += DCSettings.rag_batch_gpu
                        return ltText;
					}
					ntHeight: root.ntWidth
					ntCoff: root.ntCoff
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2
					anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 2) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						fnClickedBatch(true)//Запускаем настройку batch_size_gpu
						root.toolbar("Выберите количество фрагментов документа за один проход GPU.")
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseGPUStartIfOpen() && !fnCloseBatchIfOpen()){
								if (pressed && !pvModeli.pressed) fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {//Кнопка параллельный прогонов через CPU
					id: knopkaBatchCPU
					text: {
						let ltText = qsTr("batch CPU ");//
						ltText += DCSettings.rag_batch_cpu
                        return ltText;
					}
					ntHeight: root.ntWidth
					ntCoff: root.ntCoff
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2
					anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 3) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						fnClickedBatch(false)//Запускаем настройку batch_size_cpu
						root.toolbar("Выберите количество фрагментов документа за один проход для CPU.")
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseGPUStartIfOpen() && !fnCloseBatchIfOpen()){
								if (pressed && !pvModeli.pressed) fnPress()
							}
						}
					}
				}
			}
		}
		ListModel {//Модель с Моделями движков RAG
            id: modelModeli
            ListElement { spisok: "all-MiniLM-L6-v2 (384D, быстрая)" }
            ListElement { spisok: "all-MiniLM-L12-v2 (384D, точная)" }
            ListElement { spisok: "paraphrase-multilingual (384D, многоязычная)" }
            ListElement { spisok: "all-mpnet-base-v2 (768D, максимальное качество)" }
            ListElement { spisok: "LaBSE (768D, 100+ языков)" }
            ListElement { spisok: "BAAI/bge-m3 (1024D, мультиязычная 8K)" }
            ListElement { spisok: "e5-multilingual-large (1024D, использует GPU)" }
        }
        DCPathView {
            id: pvModeli
            visible: false
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            anchors.left: tmZona.left; anchors.right: tmZona.right; anchors.bottom: tmZona.bottom
            anchors.leftMargin: dcScrollbar.width; anchors.rightMargin: dcScrollbar.width
            clrFona: root.clrFona; clrTexta: root.clrMenuText; clrMenuFon: root.clrMenuFon
            modelData: modelModeli
            onClicked: function(strModel) {
				Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModeli. ВАЖНО!!!
					if(pvModeli.currentIndex === 6 && !root.isGPU){//Для этой модели нужен GPU
						vprGPUStart.visible = true
					}
					else{
						pvModeli.visible = false//Делаем невидимым виджет
						root.ntModel = pvModeli.currentIndex;//Приравниваем значение к переменной.
						DCSettings.rag_model = root.ntModel//Сохраняем в реестре.
					}
				})
            }
			onVisibleChanged: {//Если видимость поменялась, то...
				if(visible) Qt.callLater(function(){ pvModeli.karusel.forceActiveFocus() })//фокус PathView
				else root.forceActiveFocus()//Если невидимый, то фокус на root, чтоб hotkey работали.
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
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			anchors.verticalCenter: tmToolbar.verticalCenter
			anchors.left: tmToolbar.left
			clrKnopki: root.clrTexta; clrFona: root.clrFona
			visible: true
			tapHeight: root.ntWidth * root.ntCoff + root.ntCoff
			tapWidth: tapHeight * root.tapToolbarLevi
			onClicked: {
				if (!fnCloseMenuIfOpen() && !fnCloseGPUStartIfOpen() && !fnCloseBatchIfOpen()) {
					fnClickedInfo()
				}
			}
		}
		DCKnopkaNastroiki {
			id: knopkaNastroiki
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			anchors.verticalCenter: tmToolbar.verticalCenter
			anchors.right: tmToolbar.right
			clrKnopki: root.clrTexta; clrFona: root.clrFona
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
			if (menuMenu.visible || pvModeli.visible || txnZagolovok.visible || vprGPUStart.visible){
				menuMenu.visible = false
				pvModeli.visible = false
				txnZagolovok.visible = false
				//vprGPUStart.visible = false
			}
			else 
				root.forceActiveFocus()
			root.forceActiveFocus()
		}
	}
}

