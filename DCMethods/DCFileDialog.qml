import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import DCButtons 1.0//Импортируем кнопки
//DCFileDialog - Панель выбора пускового файла. В отличии от FileDialog показывает СКРЫТЫЕ папки и файлы.
//Открывается функцией fnOtkrit(strZag, strPutFil), выбранный путь приходит сигналом vybran(vrPut),
//закрытие панели сигналом zakrit(). Цвета настраиваются свойствами clrTexta/clrFona/clrFonaZatem.
Item {
	id: root
	visible: false
	z: 1000//Поверх всех слоёв
	anchors.fill: parent//Перекрываем всю зону родителя
	focus: visible//Фокус для клавиши Escape
	property bool zabanitKLAVISHI: true//Пока панель открыта, перехватывать ВСЕ клавиатуры (в т.ч. стрелки/Enter для списка), чтобы горячие клавиши вызывающего окна не срабатывали. Если нужен чужой хендлер — выставить в false и повесить его на lvFaylovik через id виджета.
	readonly property bool klaviaturaVPaneli: lvFaylovik.activeFocus//Публичное свойство: клавиатура сейчас внутри панели (для отладки и логики вызывающей стороны).
	//Свойства.
	property string strZagolovok: ""//Заголовок панели
	property string strPapka: ""//Текущая папка выбора
	property string strVibranniy: ""//Выбранный пусковой файл
	property var fllModel: []//Модель списка файлов из Python (fnSpisokPapki)
	property var fnSpisokPapki: null//Функция.backend списков папки(papka)->JSON, если не задана то pyLM.polSpisokPapki
	property int ntWidth: 2//Толщина элементов (как в других виджетах DCMethods), вместе с ntCoff задаёт высоту кнопки «наверх» и размер шрифта всех текстов.
	property int ntCoff: 8//Коэффициент размеров и отступов.
	property color clrTexta: "orange"//Цвет текста, рамки и выделения.
	property color clrFona: "SlateGray"//Цвет фона окна панели.
	property color clrFonaZatem: "#80000000"//Цвет затемнения фона за панелью.
	property real pctTexta: 1//Прозрачность текста и рамки (1 непрозрачный).
	property real pctFona: 1//Прозрачность фона окна панели (1 непрозрачный).
	property real pctPanelWidth: 0.85//Ширина окна панели от ширины родителя.
	property real pctPanelHeight: 0.8//Высота окна панели от высоты родителя.
	//Сигналы.
	signal vybran(string vrPut);//Выбран пусковой файл, vrPut путь к нему.
	signal zakrit();//Панель закрыта.
	//Функции.
	Keys.onPressed: (event) => {//Это запись для Qt6, для Qt5 нужно удалить event =>
		if (event.key === Qt.Key_Escape) {//Escape закрывает панель
			root.fnZakrit()
			event.accepted = true
		} else if (event.key === Qt.Key_Left && (event.modifiers & Qt.AltModifier)) {//Alt+стрелка влево — подняться в родительскую папку, как по кнопке «назад»
			root.fnNaVerh()
			event.accepted = true
		} else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {//Enter: вход в папку под курсором, или выбор выделенного файла
			let el = (lvFaylovik.currentIndex >= 0 && lvFaylovik.currentIndex < root.fllModel.length) ? root.fllModel[lvFaylovik.currentIndex] : null
			if (el && el.isFolder) {
				root.strPapka = el.path
				root.strVibranniy = ""
				root.fnObnovit()
			} else root.fnVybrat()
			event.accepted = true
		} else if (root.zabanitKLAVISHI) event.accepted = true//ВАЖНО!!! Проглатываем все прочие клавиши (стрелки съедает сам ListView раньше), чтобы горячие клавиши вызывающего окна при открытой панели не срабатывали.
	}
	function fnUrlToLocalPath(url) {//Функция кроссплатформенного преобразования URL в путь
		let path = url.toString()
		if (path.startsWith("file:///")) path = path.substring(7)
		path = decodeURIComponent(path)//Декодируем URL-кодирование (%20 пробел, %3F ?)
		if (Qt.platform.os === "windows") {//Windows: если путь начинается с /C:/, убираем первый /
			if (path.length > 2 && path[0] === '/' && path[2] === ':') path = path.substring(1)
		}
		if (Qt.platform.os !== "windows" && path.startsWith("//")) path = path.substring(1)//Linux убираем двойной слеш если появился
		return path
	}
	function fnNachalniyPapka(localPath) {//Функция возвращает папку начала выбора, или домашнюю если путь не задан
		if (localPath !== "" && localPath !== undefined) {
			let ntPos = localPath.lastIndexOf("/")
			if (ntPos > 0) return localPath.substring(0, ntPos)
		}
		return root.fnUrlToLocalPath(StandardPaths.writableLocation(StandardPaths.HomeLocation))
	}
	function fnObnovit() {//Функция обновления списка папки, включая скрытые файлы
		if (root.fnSpisokPapki !== null) root.fllModel = JSON.parse(root.fnSpisokPapki(root.strPapka))
		else root.fllModel = JSON.parse(pyLM.polSpisokPapki(root.strPapka))
	}
	function fnOtkrit(strZag, strPutFil) {//Функция открытия панели, strPutFil сохранённый путь к файлу (может быть пустым)
		root.strZagolovok = strZag
		root.strVibranniy = ""
		root.strPapka = root.fnNachalniyPapka(strPutFil)
		root.fnObnovit()
		root.visible = true
		lvFaylovik.forceActiveFocus()//ВАЖНО!!! Забираем фокус в панель сами (универсально для любого вызывающего окна), иначе клавиатура остаётся у него и горячие клавиши стреляют сквозь панель.
	}
	function fnZakrit() {//Функция закрытия панели
		root.visible = false
		lvFaylovik.focus = false//Снимаем фокус с внутренностей панели, чтобы не «держала» его в скрытом виде (activeFocus read-only, снимается через focus). Вызывающая сторона в onZakrit возвращает фокус своему корню.
		root.zakrit()//Сигнал вызывающей стороне, вернуть фокус своему окну. ВАЖНО!!!
	}
	function fnNaVerh() {//Функция подняться в родительскую папку (кнопка «назад» и Alt+стрелка влево)
		let ntPos = root.strPapka.lastIndexOf("/")
		if (ntPos > 0) { root.strPapka = root.strPapka.substring(0, ntPos); root.strVibranniy = ""; root.fnObnovit() }
	}
	function fnVybrat() {//Функция выбора выбранного файла
		if (root.strVibranniy === "") return
		root.vybran(root.strVibranniy)//Сигнал с выбранным путём
		root.fnZakrit()
	}
	Rectangle {//Затемняющий фон панели
		anchors.fill: parent
		color: root.clrFonaZatem
		MouseArea { anchors.fill: parent}//Блокируем клики от приложения за панелью
		Rectangle {//Окно самой панели
			anchors.centerIn: parent
			width: parent.width * root.pctPanelWidth; height: parent.height * root.pctPanelHeight
			color: Qt.alpha(Qt.darker(root.clrFona, 1.5), root.pctFona); border.color: Qt.alpha(root.clrTexta, root.pctTexta); radius: root.ntCoff
			ColumnLayout {
				anchors.fill: parent
				anchors.margins: root.ntCoff * 2
				spacing: root.ntCoff
				Text {//Заголовок панели
					text: root.strZagolovok; color: Qt.alpha(root.clrTexta, root.pctTexta)
					font.pixelSize: root.ntWidth*root.ntCoff+root.ntCoff//Крупнее строк панели на отступ, как в других виджетах.
				}
				RowLayout {//Строка: кнопка подняться в родительскую папку + текущий путь
					spacing: root.ntCoff
					DCKnopkaNazad {//Кнопка подняться в родительскую папку (как в DCPages/DCSettings), размер по умолчанию из ntWidth/ntCoff этой панели.
						ntWidth: root.ntWidth
						ntCoff: root.ntCoff
						tapHeight: root.ntWidth*root.ntCoff+root.ntCoff; tapWidth: tapHeight
						clrKnopki: Qt.alpha(root.clrTexta, root.pctTexta)
						clrFona: Qt.alpha(Qt.darker(root.clrFona, 1.5), root.pctFona)
						onClicked: root.fnNaVerh()//Подняться в родительскую папку (общий обработчик с Alt+стрелка влево).
					}
					Text {//Строка текущего пути
						text: "Путь: " + root.strPapka; color: Qt.alpha(root.clrTexta, root.pctTexta)
						font.pixelSize: root.ntWidth*root.ntCoff//Размер шрифта по ntWidth/ntCoff, чтобы быть одинаковой высоты с кнопкой.
						Layout.fillWidth: true; elide: Text.ElideMiddle
						Layout.alignment: Qt.AlignVCenter
					}
				}
				ListView {//Список папок и файлов (включая скрытые, с точкой в начале)
					id: lvFaylovik
					Layout.fillWidth: true; Layout.fillHeight: true
					clip: true
					ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }
					model: root.fllModel
					onCurrentIndexChanged: {//Клавиатурная навигация стрелками: файл под курсором становится выбранным, папка остаётся просто под курсором (Enter по ней = вход)
						if (currentIndex >= 0 && currentIndex < root.fllModel.length && !root.fllModel[currentIndex].isFolder)
							root.strVibranniy = root.fllModel[currentIndex].path
					}
					delegate: Rectangle {//Одна строка списка
						width: lvFaylovik.width; height: root.ntWidth*root.ntCoff+root.ntCoff//Высота строки как у кнопки «наверх» и строки пути.
						color: (modelData.path === root.strVibranniy) ? Qt.alpha(root.clrTexta, 0.3) : (ListView.isCurrent ? Qt.alpha(root.clrTexta, 0.12) : "transparent")//Выделение выбранного, тусклое — клавиатурного курсора
						MouseArea {
							anchors.fill: parent
							onClicked: {//Клик по папке входит в неё, клик по файлу выделяет
								if (modelData.isFolder) {
									root.strPapka = modelData.path
									root.strVibranniy = ""
									root.fnObnovit()
								} else root.strVibranniy = modelData.path
							}
							onDoubleClicked: if (!modelData.isFolder) root.fnVybrat()//Двойной клик по файлу = Выбрать
						}
						Text {//Название файла или папки
							x: root.ntCoff; anchors.verticalCenter: parent.verticalCenter
							font.pixelSize: root.ntWidth*root.ntCoff//Размер шрифта по ntWidth/ntCoff.
							color: Qt.alpha(root.clrTexta, root.pctTexta)
							text: modelData.isFolder ? modelData.name + "/" : modelData.name
						}
					}
				}
				Item {//Строка кнопок управления панели. Обычный Item вместо RowLayout: Layout считает ширину по implicitWidth (у DCKnopkaOriginal он 0) и обнуляет ширину, которую кнопка вычисляет сама в Component.onCompleted.
					Layout.fillWidth: true
					Layout.preferredHeight: root.ntWidth*root.ntCoff+root.ntCoff
					DCKnopkaOriginal {//Кнопка выбора выбранного файла (из DCButtons, как во всём проекте)
						id: knopkaVybrat
						text: qsTr("Выбрать")
						ntHeight: root.ntWidth; ntCoff: root.ntCoff//Размеры параметрами панели; шрифт и длина кнопки считаются внутри самой кнопки.
						clrTexta: Qt.alpha(root.clrTexta, root.pctTexta)//Цвет текста в тон панеле.
						clrKnopki: Qt.alpha(Qt.darker(root.clrFona, 2.0), root.pctFona)//Фон кнопки темнее фона окна панели.
						enabled: root.strVibranniy !== ""
						anchors.right: knopkaOtmena.left; anchors.rightMargin: root.ntCoff//Ставим слева от «Отмены» впритык с отступом.
						anchors.verticalCenter: parent.verticalCenter
						onClicked: root.fnVybrat()
					}
					DCKnopkaOriginal {//Кнопка отмены выбора и закрытия панели
						id: knopkaOtmena
						text: qsTr("Отмена")
						ntHeight: root.ntWidth; ntCoff: root.ntCoff
						clrTexta: Qt.alpha(root.clrTexta, root.pctTexta)
						clrKnopki: Qt.alpha(Qt.darker(root.clrFona, 2.0), root.pctFona)
						anchors.right: parent.right//Прижимаем к правому краю строки.
						anchors.verticalCenter: parent.verticalCenter
						onClicked: root.fnZakrit()
					}
				}
			}
		}
	}
}
