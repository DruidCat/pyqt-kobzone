//DCSidebarAnalizer.qml
import QtQuick //2.15
import QtQuick.Controls//Drawer
import DCButtons 1.0//Импортируем кнопки написанные мной.
import DCMethods 1.0//Импортируем методы написанные мной.
import DCSettings 1.0//Импортируем настройки
//Боковая панель в нейроанализе документов.
Drawer {
	id: root
	//Свойства
	property bool isMobile: false//true - мобильное устройство
    property int ntWidth: 1
    property int ntCoff: 8
    property color clrTexta: "Orange"
    property color clrFona: "Black"
    property color clrMenuFon: "SlateGray"
	property bool readOnly: false//true - запрещено редактировать текст
	property int __parentWidth: parent.width//Ширина родителя, ширина основного окна приложения.
	property int minSidebarWidth: __parentWidth * 0.2//Минимум ширины боковой панели
	property int maxSidebarWidth: root.__parentWidth * 0.5//Максимум ширины боковой панели
	property int sidebarWidth: root.isMobile ? root.__parentWidth//Если мобила, то ширина всего экрана
						: Math.max(minSidebarWidth, root.__parentWidth * DCSettings.analizer_sidebar_shirina)
	property string strPromptFinal: DCSettings.analizer_prompt_final
	//Настройки
	edge: Qt.RightEdge
	modal: false
	dim: false
	closePolicy: Drawer.CloseOnEscape//Закрываем боковую панель только при нажати Escape, другие политики выкл
	clip: true//Обрезать всё лишнее.
	width: sidebarWidth//ВАЖНО! ширина боковой панели зависит только от sidebarWidth.
	height: parent.height//Высота боковой панели по высоте родителя.
	y: root.ntWidth * root.ntCoff + 3 * root.ntCoff//координату по Y брал из расчёта Stranica.qml
	interactive: true//false -  панель не реагирует на свайпы.
	//Функции
	Component.onCompleted: {
		txaPromptFinal.text = DCSettings.analizer_prompt_final
	}
	on__ParentWidthChanged: {//Если родительская ширина экрана меняется, то ...
		root.sidebarWidth = root.__parentWidth * DCSettings.analizer_sidebar_shirina//Пересчит. ширину панели.
	}
	onPositionChanged: {//Если позиция изменяется у боковой панели, то...
		
	}
	onOpened: {//Если боковая панель открылась, то...
	}
	onStrPromptFinalChanged: {
		pyAnalyzer.ustFinalPrompt(root.strPromptFinal)
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
		DCKnopkaZakrit {
			id: knopkaZakrit
			ntWidth: (root.ntWidth-1)
			ntCoff: root.ntCoff
			visible: true
			anchors.verticalCenter: rctZagolovok.verticalCenter
			anchors.right: rctZagolovok.right
			clrKnopki: root.clrTexta
			clrFona: root.clrFona
			tapHeight: (root.ntWidth-1)*root.ntCoff+root.ntCoff
			tapWidth: tapHeight
			onClicked: root.close();//Метод обрабатывающий кнопку Закрыть боковую панель.
		}
		Label {//Текст вписанный в границы, отображает имя заголовка.
			id: lblZagolovok
			anchors.top: rctZagolovok.top
			anchors.right: knopkaZakrit.left
			width: root.width - rctBorder.width - rctRuchka.width - knopkaZakrit.width
			height: rctZagolovok.height
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignVCenter
			color: root.clrTexta
			//font.capitalization: Font.AllUppercase//СЛОВА ЗАГЛАВНЫМИ БУКВАМИ
			font.bold: true//Жирный текст.
			font.pixelSize: root.ntCoff*(root.ntWidth-1)
			elide: Text.ElideRight//Обрезаем текст по правой стороне точками (...)
			text: qsTr("Настройки")
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
			Text {//Содержимое файла
				id: txtPromptFinal
				text: "Финальный промт:"
				font.pixelSize: root.ntWidth/2 * root.ntCoff
				color: root.clrTexta
				font.bold: true//Жирный текст.
				width: parent.width - parent.leftPadding - parent.rightPadding
			}
			DCTextEdit {
				id: txaPromptFinal
				width: parent.width - parent.leftPadding - parent.rightPadding
				height: rctSidebar.height - txtPromptFinal.height - root.ntCoff * 4
				ntWidth: root.ntWidth/2//Для уменьшения размера текста и ширины скролбара
				ntCoff: root.ntCoff
				readOnly: root.readOnly
				scrollAuto: false//Ручное управление скроллом
				clrFona: "transparent"; clrTexta: root.clrTexta
				clrPolzunka: Qt.lighter(root.clrMenuFon, 1.3); clrBorder: root.clrTexta
				radius: root.ntCoff / 2
				isBorder: true//Показываем бордюр области текста.
				textEdit.textFormat: TextEdit.RichText//HTML поддержка
				placeholderText:"Введите финальный промпт, чтоб языковая модель могла подвести итог анализа..."
				onTextChanged: {
					root.strPromptFinal = text
					DCSettings.analizer_prompt_final = text
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
				DCSettings.analizer_sidebar_shirina = root.sidebarWidth / root.__parentWidth//Запись в реестр
			}
			onCanceled: {
				root.interactive = true;//Включаем свайп Drawer. ВАЖНО!
				isDrag = false//Окончание перетаскивания
				DCSettings.analizer_sidebar_shirina = root.sidebarWidth / root.__parentWidth//Запись в реестр
			}
			onPositionChanged: (mouse) => {//Если позиция меняется, то...
				if (!isDrag || root.isMobile) return//Если не перетаск. ручку или мобильное устройство,вых
				const dX = mouse.x - lastX//Дельта Х относительно предыдущей точки Х
				lastX = mouse.x//Запоминаем положение мыши по Х.
				if (dX === 0) return//Если дельта не изменилась, ничего не делаем
				let ltWidth = root.sidebarWidth - dX//Новые размеры ширины боковой панели.
				ltWidth=Math.max(root.minSidebarWidth,Math.min(root.maxSidebarWidth, ltWidth))
				root.sidebarWidth = ltWidth//Изменяем ширину боковой панели на новую ширину
			}
		}
	}
	Rectangle {//Оконтовка поверх всех прямоугольников
		anchors.top: root.top
		anchors.right: rctSidebar.right
		height: root.height
		width: rctSidebar.width
		color: "transparent"
		border.color: root.clrTexta
		border.width: root.ntCoff/4
	}
}
