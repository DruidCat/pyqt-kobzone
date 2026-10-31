import QtQuick //2.15
import QtQuick.Controls//Drawer
import DCButtons 1.0//Импортируем кнопки написанные мной.
import DCMethods 1.0//Импортируем методы написанные мной.
import DCSettings 1.0//Импортируем настройки
//SetAnalizer - Боковая панель с настройками нейро анализа документов.
Drawer {
	id: root
	//Свойства
    property int ntWidth: 1
    property int ntCoff: 8
    property color clrTexta: "Orange"
    property color clrFona: "Black"
    property color clrMenuFon: "SlateGray"
	property bool readOnly: false//true - запрещено редактировать текст
	property real tapZagolovokLevi: 1.3
	property real tapZagolovokPravi: 1.3
	property string strPrompt: DCSettings.orfograf_prompt
	property real rlTemperatura: DCSettings.orfograf_temperatura//Температура ИИ
	property int ntPerekritie: DCSettings.orfograf_perekritie
	property bool isMobile: false//true - мобильное устройство
	property bool isEnabled: true//false - не активная страница
	//Массив кнопок для навигации
    property var knopkiMassiv: []//Массив кнопок, между которыми нужно листать.
    property int currentIndex: 0//Выбранная кнопка.
	property bool __isClickedInfo: false//true - нажата кнока Информация.
	property int __parentWidth: parent.width//Ширина родителя, ширина основного окна приложения.
	property int __minSidebarWidth: __parentWidth * 0.2//Минимум ширины боковой панели
	property int __maxSidebarWidth: root.__parentWidth * 0.5//Максимум ширины боковой панели
	property int __sidebarWidth: root.isMobile ? root.__parentWidth//Если мобила, то ширина всего экрана
						: Math.max(__minSidebarWidth,root.__parentWidth * DCSettings.orfograf_sidebar_shirina)
	//Настройки
	edge: Qt.RightEdge
	modal: false
	dim: false
	closePolicy: Drawer.CloseOnEscape//Закрываем боковую панель только при нажати Escape, другие политики выкл
	clip: true//Обрезать всё лишнее.
	width: __sidebarWidth//ВАЖНО! ширина боковой панели зависит только от __sidebarWidth.
	height: parent.height//Высота боковой панели по высоте родителя.
	y: root.ntWidth * root.ntCoff + 3 * root.ntCoff//координату по Y брал из расчёта Stranica.qml
	interactive: true//false -  панель не реагирует на свайпы.
	//Сигналы
	signal clickedInfo()//Сигнал открытия информации
	//Методы
	Component.onCompleted: {
		txdPrompt.text = DCSettings.orfograf_prompt
        knopkiMassiv=[knopkaTemperatura, knopkaPerekritie]
	}
	on__ParentWidthChanged: {//Если родительская ширина экрана меняется, то ...
		root.__sidebarWidth = root.__parentWidth * DCSettings.orfograf_sidebar_shirina//Пересчит.ширину панели
	}
	onPositionChanged: {//Если позиция изменяется у боковой панели, то...
		if(position) root.readOnly = false//Если панель открыта, то режим редактирования
		else {
			fnCloseTemperaturaIfOpen()
			fnClosePerekritieIfOpen()
			root.readOnly = true//Если панель закрыта, то режим только чтения.
			if(__isClickedInfo){//Если нажата кнопка открытия инструкции, то...
				__isClickedInfo = false//Обнуляем флаг
				root.clickedInfo()//Сигнал нажатия на кнопку информации когда панель закрылась
			}
		}
	}
	onStrPromptChanged: {//Если промт изменился, то...
		pyOrfograf.ustPrompt(root.strPrompt)
	}
	function fnCloseTemperaturaIfOpen(){
		if (pvTemperatura.visible) {
			pvTemperatura.visible = false
			fnFocus()//фокус root, чтоб hotkey работали.
			return true
		}
		return false
	}
	function fnClosePerekritieIfOpen(){
		if (pvPerekritie.visible) {
			pvPerekritie.visible = false
			fnFocus()//фокус root, чтоб hotkey работали.
			return true
		}
		return false
	}
	function fnFocus(){//Фокус на странице, чтоб горячие клавиши работали.
		rctRoot.forceActiveFocus()
	}
	Rectangle {
		id: rctRoot
		anchors.fill: parent
		Keys.onPressed: (event) => {//Это запись для Qt6, для Qt5 нужно удалить event =>
			if(event.modifiers & Qt.AltModifier){//Если нажат "Alt"
				if (event.key === Qt.Key_S || event.key === 1067){//Если нажата клавиша стрелка влево, то...
					root.close();//Метод обрабатывающий кнопку Закрыть боковую панель.
					event.accepted = true;//Завершаем обработку эвента.
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
					vrKnopkaID.visible && vrKnopkaID.enabled) {
					vrKnopkaID.fnClicked()
				}
			}
		}
		function fnScrollKnopok(isPlus) {//Функция скроллина кнопок
			var knopkaID = knopkiMassiv[root.currentIndex]
			if (!knopkaID) {
				return
			}
			/*
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
			*/
		}
		Rectangle {//Прямоугольник узкой полоски интерфейса справа
			id: rctBorder
			anchors.top: root.top
			x: root.width-root.ntCoff
			width: root.ntCoff
			height: root.height
			color: root.clrMenuFon
		}
		Rectangle {//Прямоугольник заголовка, для надписи и кнопки закрыть.
			id: rctZagolovok
			anchors.top: root.top
			anchors.right: rctBorder.left
			width: root.width - rctBorder.width - rctRuchka.width
			height: root.ntCoff*(root.ntWidth-1)+root.ntCoff
			color: root.clrFona
			border.color: root.clrTexta
			border.width: root.ntCoff/4
			DCKnopkaInfo {
				id: knopkaInfo
				ntWidth: (root.ntWidth-1); ntCoff: root.ntCoff
				anchors.verticalCenter: rctZagolovok.verticalCenter; anchors.left: rctZagolovok.left
				clrKnopki: root.clrTexta; clrFona: root.clrFona
				tapHeight: (root.ntWidth-1)*root.ntCoff+root.ntCoff; tapWidth: tapHeight * root.tapZagolovokLevi
				function fnClicked(){
					root.__isClickedInfo = true//Взводим флаг, ждём, когда закроется панели и откроем Инструкц
					root.close()//Закрываем панель, сворачиваем температуру
				}
				onClicked: fnClicked()//Функция нажатия информации.
			}
			DCKnopkaZakrit {
				id: knopkaZakrit
				ntWidth: (root.ntWidth-1); ntCoff: root.ntCoff
				anchors.verticalCenter: rctZagolovok.verticalCenter; anchors.right: rctZagolovok.right
				clrKnopki: root.clrTexta; clrFona: root.clrFona
				tapHeight: (root.ntWidth-1)*root.ntCoff+root.ntCoff; tapWidth: tapHeight * root.tapZagolovokPravi
				onClicked: root.close();//Метод обрабатывающий кнопку Закрыть боковую панель.
			}
			Label {//Текст вписанный в границы, отображает имя заголовка.
				id: lblZagolovok
				anchors.top: rctZagolovok.top
				anchors.right: knopkaZakrit.left
				width: root.width - rctBorder.width - rctRuchka.width - knopkaZakrit.width - knopkaInfo.width
				height: rctZagolovok.height
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter
				color: root.clrTexta
				font.bold: true//Жирный текст.
				font.pixelSize: root.ntCoff*(root.ntWidth-1)
				elide: Text.ElideRight//Обрезаем текст по правой стороне точками (...)
				text: qsTr("НАСТРОЙКА НЕЙРО ОРФОГРАФИИ")
			}
		}
		Rectangle {//Прямоугольник всей оставшейся боковой панели.
			id: rctSidebar
			anchors.top: rctZagolovok.bottom
			anchors.right: rctBorder.left
			width: root.width - rctBorder.width - rctRuchka.width
			height: root.height-rctZagolovok.height
			color: root.clrFona
			clip: true//Обязательно обрезать всё, что не помещается в этот прямоугольник.
			opacity: 0.9//ГЛАВНАЯ ПРОЗРАЧНОСТЬ!!!	
			TapHandler {//Нажимаем на всю область
				onTapped: {
					if(!pvTemperatura.jdi && !pvTemperatura.pressed) fnCloseTemperaturaIfOpen()//Закрываем
					if(!pvPerekritie.jdi && !pvPerekritie.pressed) fnClosePerekritieIfOpen()//Закрываем
				}
			}
			Behavior on opacity {
				NumberAnimation {
					duration: 300
					easing.type: Easing.InOutQuad
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
						let ltText = qsTr("температура ");//
						ltText += root.rlTemperatura//Добавляем в строчку температуру из параметра
						pvTemperatura.currentIndex = root.rlTemperatura*10//Выставляем в карусели нужную Темп.
						return ltText;
					}
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrTexta
                    clrKnopki: (root.currentIndex === 0) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
					enabled: root.isEnabled
					opacityKnopki: 0.9
					function fnClicked() {
						root.currentIndex = 0
						if(pvTemperatura.visible){//Если видимый виджет, то...
							Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
								pvTemperatura.visible = false//Делаем невидимым виджет
								fnFocus()//фокус PathView, чтоб hotkey работали.
							})
						}
						else{//Если невидимый виджет, то...
							Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
								pvTemperatura.visible = true//Делаем видимым виджет
								pvTemperatura.karusel.forceActiveFocus()//фокус PathView, чтоб hotkey работали.
							})
						}
					}
					onClicked: {
						if (pressed && !pvTemperatura.pressed
									&& !pvPerekritie.pressed) fnClicked()
					}
				}
				DCKnopkaOriginal {//Кнопка выбора Перекрытия ИИ
					id: knopkaPerekritie
					text: {
						let ltText = qsTr("перекрытие ");//
						ltText += root.ntPerekritie//Добавляем в строчку перекрытие из настроек
						ltText += "%"
						for (let i = 0; i < modelPerekritie.count; i++) {//Ищем сохранённую модель в списке
							if (modelPerekritie.get(i).spisok === root.ntPerekritie) {
								pvPerekritie.currentIndex = i//Выставляем в карусели нужный процент Перекрытия
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
					enabled: root.isEnabled
					opacityKnopki: 0.9
					function fnClicked() {
						root.currentIndex = 1
						if(pvPerekritie.visible){//Если видимый виджет, то...
							Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
								pvPerekritie.visible = false//Делаем невидимым виджет
								fnFocus()//фокус PathView, чтоб hotkey работали.
							})
						}
						else{//Если невидимый виджет, то...	
							Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
								pvPerekritie.visible = true//Делаем видимым виджет
								pvPerekritie.karusel.forceActiveFocus()//фокус PathView, чтоб hotkey работали.
							})
						}
					}
					onClicked: {
						if (pressed && !pvTemperatura.pressed
									&& !pvPerekritie.pressed) fnClicked()
					}
				}
				Text {//Содержимое файла
					id: txtPrompt
					text: "Промт:"
					font.pixelSize: root.ntWidth/2 * root.ntCoff
					color: root.clrTexta
					font.bold: true//Жирный текст.
					width: parent.width - parent.leftPadding - parent.rightPadding
				}
				DCTextEdit {
					id: txdPrompt
					width: parent.width - parent.leftPadding - parent.rightPadding
					height: {
						let ltHeight = 0//Высота рабочей области редактирования.
						if (pvTemperatura.visible || pvPerekritie.visible){
							ltHeight = rctSidebar.height - txtPrompt.height
													- knopkaTemperatura.height
													- knopkaPerekritie.height
													- root.ntCoff * 5
													- pvTemperatura.height
						}else {
							ltHeight = rctSidebar.height - txtPrompt.height
													- knopkaTemperatura.height
													- knopkaPerekritie.height
													- root.ntCoff * 5
						}
						return ltHeight
					}
					ntWidth: root.ntWidth/2//Для уменьшения размера текста и ширины скролбара
					ntCoff: root.ntCoff
					readOnly: root.readOnly
					enabled: root.isEnabled
					scrollAuto: false//Ручное управление скроллом
					clrFona: "transparent"; clrTexta: root.clrTexta
					clrPolzunka: Qt.lighter(root.clrMenuFon, 1.3); clrBorder: root.clrTexta
					radius: root.ntCoff / 2
					isBorder: true//Показываем бордюр области текста.
					textEdit.textFormat: TextEdit.RichText//HTML поддержка
					placeholderText:"Введите финальный промпт, чтоб языковая модель могла подвести итог анализа..."
					onTextChanged: {
						root.strPrompt = text
						DCSettings.orfograf_prompt = text
					}
					onPressed: {
						fnCloseTemperaturaIfOpen()//Закрываем карусель температуры
						fnClosePerekritieIfOpen()//Закрываем карусель перекрытия
					}
				}	
			}
		}
		Rectangle {//Прямоугольник ручки,за которую можно тянуть размер боковой панели,для изменения её размер
			id: rctRuchka
			anchors.top: root.top
			anchors.right: rctSidebar.left
			width: (root.ntWidth < 3) ? 3 : root.ntWidth//В зависимости от параметра, изменяется толщина ручки.
			height: root.height
			color: Qt.darker(root.clrTexta, 1.3)
			border.color: root.clrTexta
			border.width: (root.ntWidth < 5) ? 1 : root.ntCoff/4//Чтоб была видна оконтовка ручки.
			MouseArea {
				id: maRuchka
				//Свойства
				property bool isDrag: false//Свойство перетаскивания. true - началось перетаскивание.
				property real lastX//Переменная хранящаа предыдущее положение мыши
				//Настройки
				anchors.fill: rctRuchka
				hoverEnabled: true//При наведении изменение
				cursorShape: Qt.SizeHorCursor//Курсор в виде изменения горизонтального размера.
				//Функции
				onPressed: (mouse) => {//Если нажали на ручку
					if (root.isMobile) return//Если мобильное устройство, то выходим
					root.interactive = false;//Отключаем свайп Drawer. ВАЖНО!
					isDrag = true//Взводим флаг при нажатии на ручку, идёт изменение размеров.
					lastX = mouse.x//Запоминаем первоначальное положение боковой панели по координатам мыши.
					mouse.accepted = true//Завершаем обработку эвента.
				}
				onReleased: {//Если отпустили кнопку мышки
					root.interactive = true;//Включаем свайп Drawer. ВАЖНО!
					isDrag = false//При отпускании мыши Окончание перетаскивания
					DCSettings.orfograf_sidebar_shirina = root.__sidebarWidth / root.__parentWidth//Запись в реест
				}
				onCanceled: {
					root.interactive = true;//Включаем свайп Drawer. ВАЖНО!
					isDrag = false//Окончание перетаскивания
					DCSettings.orfograf_sidebar_shirina = root.__sidebarWidth / root.__parentWidth//Запись в реест
				}
				onPositionChanged: (mouse) => {//Если позиция меняется, то...
					if (!isDrag || root.isMobile) return//Если не перетаск. ручку или мобильное устройство,вых
					const dX = mouse.x - lastX//Дельта Х относительно предыдущей точки Х
					lastX = mouse.x//Запоминаем положение мыши по Х.
					if (dX === 0) return//Если дельта не изменилась, ничего не делаем
					let ltWidth = root.__sidebarWidth - dX//Новые размеры ширины боковой панели.
					ltWidth=Math.max(root.__minSidebarWidth,Math.min(root.__maxSidebarWidth, ltWidth))
					root.__sidebarWidth = ltWidth//Изменяем ширину боковой панели на новую ширину
				}
			}
		}
		Rectangle {//Оконтовка поверх всех прямоугольников
			id: rctOkontovka
			anchors.top: root.top
			anchors.right: rctSidebar.right
			height: root.height
			width: rctSidebar.width
			color: "transparent"
			border.color: root.clrTexta
			border.width: root.ntCoff/4
		}
		ListModel {//Модель с температурами для ИИ
			id: modelTemperatura
			ListElement { spisok: 0 }
			ListElement { spisok: 0.1 }
			ListElement { spisok: 0.2 }
			ListElement { spisok: 0.3 }
			ListElement { spisok: 0.4 }
			ListElement { spisok: 0.5 }
			ListElement { spisok: 0.6 }
			ListElement { spisok: 0.7 }
			ListElement { spisok: 0.8 }
			ListElement { spisok: 0.9 }
			ListElement { spisok: 1 }
		}
		DCPathView {
			id: pvTemperatura
			visible: false
			z: 100
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			anchors.left: rctSidebar.left; anchors.right: rctSidebar.right; anchors.bottom: rctSidebar.bottom
			anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
			anchors.bottomMargin: rctOkontovka.border.width
			clrFona: root.clrFona; clrTexta: root.clrTexta; clrMenuFon: root.clrMenuFon
			modelData: modelTemperatura
			onClicked: function(strTemperatura) {
				Qt.callLater(function(){//пауза, иначе не сработает фокус и pvTemperatura. ВАЖНО!!!
					pvTemperatura.visible = false//Делаем невидимым виджет
					root.rlTemperatura = strTemperatura//Приравнываем значение полученное
					DCSettings.orfograf_temperatura = root.rlTemperatura//Сохраняем в реестре температуру ИИ.
				})
			}
			onVisibleChanged: {//Если видимость поменялась, то...
				if(!visible) fnFocus()//Если невидимый, то фокус на root, чтоб hotkey работали.
			}
		}
		ListModel {//Модель с % перекрытия для анализа
			id: modelPerekritie
			ListElement { spisok: 0 }
			ListElement { spisok: 5 }
			ListElement { spisok: 10 }
			ListElement { spisok: 15 }
			ListElement { spisok: 20 }
			ListElement { spisok: 25 }
		}
		DCPathView {
			id: pvPerekritie
			z: 100
			visible: false
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			anchors.left: rctSidebar.left; anchors.right: rctSidebar.right; anchors.bottom: rctSidebar.bottom
			anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
			anchors.bottomMargin: rctOkontovka.border.width
			clrFona: root.clrFona; clrTexta: root.clrTexta; clrMenuFon: root.clrMenuFon
			modelData: modelPerekritie
			onClicked: function(strPerekritie) {
				Qt.callLater(function(){//пауза, иначе не сработает фокус и pvPerekritie. ВАЖНО!!!
					pvPerekritie.visible = false//Делаем невидимым виджет
					root.ntPerekritie = strPerekritie//Приравнываем значение полученное
					DCSettings.orfograf_perekritie = root.ntPerekritie//Сохраняем в реестре перекрытие в %.
				})
			}
			onVisibleChanged: {//Если видимость поменялась, то...
				if(!visible) fnFocus()//Если невидимый, то фокус на root, чтоб hotkey работали.
			}
		}
	}	
}
