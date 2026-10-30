/*Настройка нейро орфографии документа*/
import QtQuick
import QtQuick.Controls
import DCButtons 1.0
import DCMethods 1.0
import DCSettings 1.0
Drawer {//Выезжающая боковая панель настроек орфографии, аналог SetAnalizer.
	id: root
	//Свойства
	property int ntWidth: 1//Размер шрифта заголовка для DCKnopkaX элементов.
	property int ntCoff: 8//Коэффициент масштабирования всех элементов.
	property color clrTexta: "white"//Цвет шрифта и обводки
	property color clrFona: "black"//Цвет фона страницы.
	property color clrMenuFon: "lightsteelblue"//Цвет фона кнопок и карусели.
	property bool readOnly: false//Запрет изменять текущие настройки орфографии.
	property real tapZagolovokLevi: 1//Коэффициент отступа слева заголовка.
	property real tapZagolovokPravi: 1//Коэффициент отступа справа заголовка.
	property real rlTemperatura: DCSettings.orfograf_temperatura//Температура ИИ.
	property int ntPerekritie: DCSettings.orfograf_perekritie//Перекрытие фрагментов, %.
	property int ntKontekst: DCSettings.orfograf_kontekst//Размер фрагмента контекста.
	property bool isMobile: false//true - мобильное устройство.
	property bool isEnabled: true//Разрешить изменять текущие настройки орфографии.
	property var knopkiMassiv //Массив кнопок для перебора клавишами стрелок.
	property int currentIndex: 0 //Текущая выбранная настройка (кнопка на панели).
	property bool __isClickedInfo: false//Флаг, нажата или нет кнопка информации.
	property int __parentWidth: (parent ? parent.width : 0)//Ширина родителя.
	property int __minSidebarWidth: parent.width * 0.2//Минимальная ширина боковой панели.
	property int __maxSidebarWidth: parent.width * 0.5//Максимальная ширина боковой панели.
	property int __sidebarWidth: DCSettings.orfograf_sidebar_shirina * __parentWidth//Ширина боковой панели.
	//Настройки
	edge: Qt.RightEdge//Панель выезжает с правого края.
	modal: false//Не блокируем страницу, hotkeys страницы работают.
	dim: false//Затемнение не нужно.
	closePolicy: Drawer.CloseOnEscape//Закрытие по Escape.
	clip: true
	width: __sidebarWidth
	height: parent.height
	y: root.ntWidth * root.ntCoff + 3 * root.ntCoff
	interactive: true//Потянуть за край можно, closePolicy тут же CloseOnRelease.
	//Методы
	signal clickedInfo()//Информация по настройкам орфографии.
	Component.onCompleted: {
		knopkiMassiv = [knopkaTemperatura, knopkaPerekritie, knopkaKontekst]
	}
	on__ParentWidthChanged: {
		__minSidebarWidth = __parentWidth * 0.2
		__maxSidebarWidth = __parentWidth * 0.5
		__sidebarWidth = DCSettings.orfograf_sidebar_shirina * __parentWidth
	}
	onPositionChanged: {//Если сдвигаем панель, прячем все открытые карусели настроек.
		if(pvTemperatura.visible){
			pvTemperatura.visible = false
			fnFocus()//фокус, чтоб hotkey работали. ВАЖНО!!!
		}
		if(pvPerekritie.visible){
			pvPerekritie.visible = false
			fnFocus()//фокус, чтоб hotkey работали. ВАЖНО!!!
		}
		if(pvKontekst.visible){
			pvKontekst.visible = false
			fnFocus()//фокус, чтоб hotkey работали. ВАЖНО!!!
		}
		if(opened){
			root.readOnly = false//Разрешаем изменять настройки, панель открыта.
			//Отправляем сигнал о нажатии кнопки Информация, если она нажата.
			if(__isClickedInfo){
				__isClickedInfo = false//Сбрасываем флаг нажания кнопки.
				root.clickedInfo()//Излучаем сигнал на страницу.
			}
		} else {
			root.readOnly = true//Запрещаем изменять настройки, панель закрыта.
		}
	}
	function fnCloseTemperaturaIfOpen() {//Закрыть pvTemperatura, если виден.
		if (pvTemperatura.visible) {
			pvTemperatura.visible = false
			Qt.callLater(function(){//пауза, иначе не сработает фокус. ВАЖНО!!!
				fnFocus()//фокус PathView, чтоб hotkey работали.
			})
		}
	}
	function fnClosePerekritieIfOpen() {//Закрыть pvPerekritie, если виден.
		if (pvPerekritie.visible) {
			pvPerekritie.visible = false
			Qt.callLater(function(){//пауза, иначе не сработает фокус. ВАЖНО!!!
				fnFocus()//фокус PathView, чтоб hotkey работали.
			})
		}
	}
	function fnCloseKontekstIfOpen() {//Закрыть pvKontekst, если виден.
		if (pvKontekst.visible) {
			pvKontekst.visible = false
			Qt.callLater(function(){//пауза, иначе не сработает фокус. ВАЖНО!!!
				fnFocus()//фокус PathView, чтоб hotkey работали.
			})
		}
	}
	function fnFocus(){//Фокус на странице, чтоб горячие клавиши работали.
		rctRoot.forceActiveFocus()
	}
	Rectangle {
		id: rctRoot
		anchors.fill: parent
		Keys.onPressed: (event) => {//Это запись для Qt6, для Qt5 нужно удалить event =>
			if(event.modifiers & Qt.AltModifier){//Если нажат "Alt"
				if (event.key === Qt.Key_S || event.key === 1067){//Клавиша S или С кириллица.
					root.close();//Закрыть боковую панель настроек.
					event.accepted = true//Завершаем обработку эвента.
				}
			} else if (event.key === Qt.Key_F1){//Если нажата F1, то...
				knopkaInfo.fnClicked()
				event.accepted = true
			} else if (event.key === Qt.Key_Up || event.key === Qt.Key_K || event.key === 1051) {
				root.currentIndex--
				if (root.currentIndex < 0) root.currentIndex = knopkiMassiv.length - 1
				//fnScrollKnopok(false)
				event.accepted = true
			} else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === 1054) {
				root.currentIndex++
				if (root.currentIndex >= knopkiMassiv.length) root.currentIndex = 0
				//fnScrollKnopok(true)
				event.accepted = true
			} else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
				fnClickedEnter()
				event.accepted = true
			}
		}
		function fnClickedEnter() {//Функция обработки нажатия клавиши Enter
			if (root.currentIndex >= 0 && root.currentIndex < knopkiMassiv.length) {
				var vrKnopkaID = knopkiMassiv[root.currentIndex]
				if (vrKnopkaID && typeof vrKnopkaID.fnClicked === "function" &&
					vrKnopkaID.enabled) {
					vrKnopkaID.fnClicked()
				}
			}
		}
		function fnScrollKnopok(vnizu) {//Функция прокрутки кнопок по горячим клавишам.
			// if (vnizu) tmrScroll.interval = 1000//Задержка в миллисекундах
			// else tmrScroll.interval = 1000
			// tmrScroll.triggered()
		}
		Rectangle {
			id: rctBorder
			anchors.fill: parent
			antialiasing: true
			color: "transparent"
			border.width: root.ntCoff / 2
			border.color: root.clrTexta
		}
		Rectangle {//Заголовок боковой панели.
			id: rctZagolovok
			width: parent.width
			height: root.ntWidth * root.ntCoff + 3 * root.ntCoff
			color: root.clrFona
			opacity: 0.9
			DCKnopkaInfo {//Кнопка информации по настройкам орфографии.
				id: knopkaInfo
				ntWidth: root.ntWidth; ntCoff: root.ntCoff
				anchors.left: parent.left
				anchors.leftMargin: root.ntCoff * root.tapZagolovokLevi
				anchors.verticalCenter: parent.verticalCenter
				clrKnopki: root.clrTexta
				function fnClicked() {
					root.__isClickedInfo = true
					root.close()//Закрытие панели, сигнал уйдёт в onPositionChanged.
				}
			}
			DCKnopkaZakrit {//Кнопка закрыть боковую панель.
				id: knopkaZakrit
				ntWidth: root.ntWidth; ntCoff: root.ntCoff
				anchors.right: parent.right
				anchors.rightMargin: root.ntCoff * root.tapZagolovokPravi
				anchors.verticalCenter: parent.verticalCenter
				clrKnopki: root.clrTexta
				onClicked: { root.close() }
			}
			Text {
				id: lblZagolovok
				anchors.left: knopkaInfo.right; anchors.right: knopkaZakrit.left
				anchors.leftMargin: 2*root.ntCoff; anchors.rightMargin: 2*root.ntCoff
				anchors.verticalCenter: knopkaInfo.verticalCenter
				elide: Text.ElideRight
				horizontalAlignment: Text.AlignHCenter
				text: "НАСТРОЙКА НЕЙРО ОРФОГРАФИИ"
				color: root.clrTexta
				font.pixelSize: root.ntWidth * root.ntCoff
			}
		}
		Rectangle {
			id: rctRuchka
			x: rctBorder.x
			y: rctBorder.y
			width: ntCoff * 2
			height: rctBorder.height
			color: root.clrTexta
			MouseArea {
				id: mshRuchka
				anchors.fill: parent
				acceptedButtons: Qt.LeftButton | Qt.RightButton
				function fnKonecDraga(){
					root.__sidebarWidth = rctBorder.x + rctBorder.width
					DCSettings.orfograf_sidebar_shirina = root.__sidebarWidth /
							root.__parentWidth
				}
				onCanceled: {
					fnKonecDraga()
				}
				onPositionChanged: (mouse) => {
					var ltNoviX = rctBorder.x + mouse.x - mshRuchka.previousX
					//Если меньше минимума или больше максимума, то не давим дальше.
					if (ltNoviX < rctRuchka.mapToItem(parent, 0, 0).x +
						root.__minSidebarWidth) return
					if (ltNoviX > rctRuchka.mapToItem(parent, 0, 0).x +
						root.__maxSidebarWidth) return
					//Ставим новый X у границы панели.
					rctBorder.x = ltNoviX
					//Ставим новый X у заголовка панели, чтоб не отставал.
					rctZagolovok.x = ltNoviX
					//Ставим новый X у основной области панели, чтоб не отставал.
					rctSidebar.x = ltNoviX + rctBorder.width + rctRuchka.width
					rctOkontovka.x = ltNoviX
				}
				onReleased: {
					fnKonecDraga()
				}
			}
		}
		Rectangle {//Основная область боковой панели настроек.
			id: rctSidebar
			anchors.top: rctZagolovok.bottom
			anchors.right: rctBorder.left
			width: root.width - rctBorder.width - rctRuchka.width
			height: root.height - rctZagolovok.height
			color: root.clrFona
			clip: true
			opacity: 0.9
			Behavior on opacity {
				NumberAnimation {
					duration: 300
					easing.type: Easing.InOutQuad
				}
			}
			TapHandler {//Клик мимо кнопок: закрываем открытые карусели.
				onSingleTapped: {
					if(pvTemperatura.visible) fnCloseTemperaturaIfOpen()
					else if(pvPerekritie.visible) fnClosePerekritieIfOpen()
					else if(pvKontekst.visible) fnCloseKontekstIfOpen()
				}
			}
			Column {
				id: clmnContent
				width: rctSidebar.width
				spacing: root.ntCoff/2//Расстояние между элементами по вертикали.
				topPadding: root.ntCoff * 2
				bottomPadding: root.ntCoff * 2
				leftPadding: root.ntCoff * 2
				rightPadding: root.ntCoff * 2
				DCKnopkaOriginal {//Кнопка выбора Температуры ИИ
					id: knopkaTemperatura
					text: {
						let ltText = qsTr("температура ИИ: ")//
						ltText += root.rlTemperatura//Добавляем в строчку температуру.
						//Ищем индекс текущего значения в модели карусели.
						pvTemperatura.currentIndex = 0//
						for(let i = 0; i < modelTemperatura.count; i++) {
							if(modelTemperatura.get(i).spisok ===
									root.rlTemperatura){
								pvTemperatura.currentIndex = i//Нашли, ставим индекс.
								break
							}
						}
						return ltText;
					}
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrTexta
					clrKnopki: (root.currentIndex === 0) ? Qt.darker(root.clrMenuFon, 1.2) :
						root.clrMenuFon
					enabled: root.isEnabled
					opacityKnopki: 0.9
					function fnClicked() {
						root.currentIndex = 0
						if(pvTemperatura.visible){//Если видимый виджет, то...
							Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
								pvTemperatura.visible = false//Делаем невидимым виджет
								fnFocus()//фокус PathView, чтоб hotkey работали.
							})
						} else {
							Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
								pvTemperatura.visible = true//Делаем видимым виджет
								fnFocus()//фокус PathView, чтоб hotkey работали.
							})
						}
					}
					onClicked: if (pressed && !pvTemperatura.pressed) fnClicked()
				}
				DCKnopkaOriginal {//Кнопка выбора Перекрытия фрагментов
					id: knopkaPerekritie
					text: {
						let ltText = qsTr("перекрытие фрагментов, %: ")//
						ltText += root.ntPerekritie//Добавляем в строчку перекрытие.
						pvPerekritie.currentIndex = root.ntPerekritie//Выставляем в карусели нужное перекрытие.
						return ltText;
					}
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrTexta
					clrKnopki: (root.currentIndex === 1) ? Qt.darker(root.clrMenuFon, 1.2) :
						root.clrMenuFon
					enabled: root.isEnabled
					opacityKnopki: 0.9
					function fnClicked() {
						root.currentIndex = 1
						if(pvPerekritie.visible){//Если видимый виджет, то...
							Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
								pvPerekritie.visible = false//Делаем невидимым виджет
								fnFocus()//фокус PathView, чтоб hotkey работали.
							})
						} else {
							Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
								pvPerekritie.visible = true//Делаем видимым виджет
								fnFocus()//фокус PathView, чтоб hotkey работали.
							})
						}
					}
					onClicked: if (pressed && !pvPerekritie.pressed) fnClicked()
				}
				DCKnopkaOriginal {//Кнопка выбора Размера фрагмента контекста
					id: knopkaKontekst
					text: {
						let ltText = qsTr("размер фрагмента, символов: ")//
						ltText += root.ntKontekst//Добавляем в строчку размер контекста.
						//Ищем индекс текущего значения в модели карусели.
						pvKontekst.currentIndex = 0//
						for(let i = 0; i < modelKontekst.count; i++) {
							if(modelKontekst.get(i).spisok === root.ntKontekst){
								pvKontekst.currentIndex = i//Нашли, ставим индекс.
								break
							}
						}
						return ltText;
					}
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrTexta
					clrKnopki: (root.currentIndex === 2) ? Qt.darker(root.clrMenuFon, 1.2) :
						root.clrMenuFon
					enabled: root.isEnabled
					opacityKnopki: 0.9
					function fnClicked() {
						root.currentIndex = 2
						if(pvKontekst.visible){//Если видимый виджет, то...
							Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
								pvKontekst.visible = false//Делаем невидимым виджет
								fnFocus()//фокус PathView, чтоб hotkey работали.
							})
						} else {
							Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
								pvKontekst.visible = true//Делаем видимым виджет
								fnFocus()//фокус PathView, чтоб hotkey работали.
							})
						}
					}
					onClicked: if (pressed && !pvKontekst.pressed) fnClicked()
				}
			}
		}
		Rectangle {//Область отрисовки снизу боковой панели.
			id: rctOkontovka
			x: rctBorder.x
			anchors.bottom: rctBorder.bottom
			width: rctRuchka.x - rctBorder.x + rctBorder.width +
				(rctBorder.width + rctRuchka.width) / 2 - ntCoff * 2
			visible: pvTemperatura.visible || pvPerekritie.visible || pvKontekst.visible
			height: parent.height / 2 + rctOkontovka.border.width +
				(rctBorder.width + rctRuchka.width) / 2 - ntCoff * 2
			color: "transparent"
			border.width: 3
			border.color: root.clrTexta
		}
		ListModel {
			id: modelTemperatura
			ListElement { spisok: 0.00 }
			ListElement { spisok: 0.05 }
			ListElement { spisok: 0.10 }
			ListElement { spisok: 0.15 }
			ListElement { spisok: 0.20 }
			ListElement { spisok: 0.25 }
			ListElement { spisok: 0.30 }
			ListElement { spisok: 0.35 }
			ListElement { spisok: 0.40 }
			ListElement { spisok: 0.45 }
			ListElement { spisok: 0.50 }
			ListElement { spisok: 0.55 }
			ListElement { spisok: 0.70 }
			ListElement { spisok: 0.75 }
			ListElement { spisok: 0.95 }
			ListElement { spisok: 0.98 }
			ListElement { spisok: 0.99 }
			ListElement { spisok: 0.995 }
			ListElement { spisok: 0.999 }
			ListElement { spisok: 1.00 }
		}
		DCPathView {//Карусель выбора температуры ИИ.
			//Свойства
			id: pvTemperatura
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			//Настройки
			z: 100
			visible: false
			anchors.left: rctSidebar.left; anchors.right: rctSidebar.right
			anchors.bottom: rctSidebar.bottom
			anchors.margins: root.ntCoff * 2
			anchors.bottomMargin: rctOkontovka.border.width
			clrFona: root.clrFona; clrTexta: root.clrTexta; clrMenuFon: root.clrMenuFon
			modelData: modelTemperatura
			//Методы
			onClicked: function(strTemperatura) {
				Qt.callLater(function(){//пауза, иначе не сработает visible и pvModel. ВАЖНО!!!
					pvTemperatura.visible = false//Делаем невидимым виджет
					//Меняем ширину боковой панели, она уменьшилась из за прокрутки карусели.
					root.x = Math.floor(root.x + (root.__parentWidth - root.width) / 2)
					root.rlTemperatura = Number(strTemperatura)//Меняем значение.
					DCSettings.orfograf_temperatura = Number(strTemperatura)//Запись в настройки.
				})
			}
			onVisibleChanged: {
				if(!visible) fnFocus()//Возвращаем фокус на панель, hotkey работали.
			}
		}
		ListModel {
			id: modelPerekritie
			ListElement { spisok: 0 }
			ListElement { spisok: 5 }
			ListElement { spisok: 10 }
			ListElement { spisok: 15 }
			ListElement { spisok: 20 }
			ListElement { spisok: 25 }
			ListElement { spisok: 30 }
			ListElement { spisok: 35 }
			ListElement { spisok: 40 }
			ListElement { spisok: 45 }
			ListElement { spisok: 50 }
			ListElement { spisok: 55 }
			ListElement { spisok: 60 }
			ListElement { spisok: 65 }
			ListElement { spisok: 70 }
			ListElement { spisok: 75 }
			ListElement { spisok: 80 }
			ListElement { spisok: 85 }
			ListElement { spisok: 90 }
		}
		DCPathView {//Карусель выбора перекрытия фрагментов.
			//Свойства
			id: pvPerekritie
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			//Настройки
			z: 100
			visible: false
			anchors.left: rctSidebar.left; anchors.right: rctSidebar.right
			anchors.bottom: rctSidebar.bottom
			anchors.margins: root.ntCoff * 2
			anchors.bottomMargin: rctOkontovka.border.width
			clrFona: root.clrFona; clrTexta: root.clrTexta; clrMenuFon: root.clrMenuFon
			modelData: modelPerekritie
			//Методы
			onClicked: function(strPerekritie) {
				Qt.callLater(function(){//пауза, иначе не сработает visible и pvModel. ВАЖНО!!!
					pvPerekritie.visible = false//Делаем невидимым виджет
					//Меняем ширину боковой панели, она уменьшилась из за прокрутки карусели.
					root.x = Math.floor(root.x + (root.__parentWidth - root.width) / 2)
					root.ntPerekritie = parseInt(strPerekritie)//Меняем значение.
					DCSettings.orfograf_perekritie = parseInt(strPerekritie)//Запись в настройки.
				})
			}
			onVisibleChanged: {
				if(!visible) fnFocus()//Возвращаем фокус на панель, hotkey работали.
			}
		}
		ListModel {
			id: modelKontekst
			ListElement { spisok: 100 }
			ListElement { spisok: 200 }
			ListElement { spisok: 400 }
			ListElement { spisok: 500 }
			ListElement { spisok: 600 }
			ListElement { spisok: 800 }
			ListElement { spisok: 900 }
			ListElement { spisok: 1000 }
			ListElement { spisok: 1200 }
			ListElement { spisok: 1500 }
			ListElement { spisok: 1800 }
			ListElement { spisok: 2000 }
			ListElement { spisok: 2500 }
			ListElement { spisok: 3000 }
		}
		DCPathView {//Карусель выбора размера фрагмента контекста.
			//Свойства
			id: pvKontekst
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			//Настройки
			z: 100
			visible: false
			anchors.left: rctSidebar.left; anchors.right: rctSidebar.right
			anchors.bottom: rctSidebar.bottom
			anchors.margins: root.ntCoff * 2
			anchors.bottomMargin: rctOkontovka.border.width
			clrFona: root.clrFona; clrTexta: root.clrTexta; clrMenuFon: root.clrMenuFon
			modelData: modelKontekst
			//Методы
			onClicked: function(strKontekst) {
				Qt.callLater(function(){//пауза, иначе не сработает visible и pvModel. ВАЖНО!!!
					pvKontekst.visible = false//Делаем невидимым виджет
					//Меняем ширину боковой панели, она уменьшилась из за прокрутки карусели.
					root.x = Math.floor(root.x + (root.__parentWidth - root.width) / 2)
					root.ntKontekst = parseInt(strKontekst)//Меняем значение.
					DCSettings.orfograf_kontekst = parseInt(strKontekst)//Запись в настройки.
				})
			}
			onVisibleChanged: {
				if(!visible) fnFocus()//Возвращаем фокус на панель, hotkey работали.
			}
		}
	}
}
