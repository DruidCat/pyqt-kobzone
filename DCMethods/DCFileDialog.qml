import QtQuick
import QtQuick.Layouts
import QtCore
import DCButtons 1.0//Импортируем кнопки
//DCFileDialog - Панель выбора файла. Может показывать СКРЫТЫЕ папки и файлы.
//Открывается функцией fnOtkrit(strZag, strPutFil), выбранный путь приходит сигналом vybran(vrPut),
//закрытие панели сигналом zakrit(). Цвета настраиваются свойствами clrTexta/clrFona/clrFonaZatem.
Item {
	id: root
	visible: false
	z: 1000//Поверх всех слоёв
	anchors.fill: parent//Перекрываем всю зону родителя
	focus: visible//Фокус для клавиши Escape
	//Публичное свойство: клавиатура сейчас внутри панели (для отладки и логики вызывающей стороны).
	readonly property bool klaviaturaVPaneli: lvFaylovik.activeFocus
	//Свойство потерялось при переносе комментариев под лимит 110 символов — без него
	//стрелки на краю списка уходят в окно позади панели и листают уже его меню
	property bool zabanitKLAVISHI: true//Пока панель открыта, проглатывать все прочие клавиши,
	//чтобы горячие клавиши вызвавшего панель окна при открытой панели не срабатывали
	//Свойства.
	property int ntShirinaPolzunka: 11//Толщина самодельной полосы прокрутки (настраивается)
	property bool isMobile: false//true - это мобильное устройсктво
	property string strZagolovok: ""//Заголовок панели
	property string strPapka: ""//Текущая папка выбора
	property string strVibranniy: ""//Выбранный пусковой файл
	property var fllModel: []//Модель списка файлов из Python (fnSpisokPapki)
	property var fnSpisokPapki: null//Функция.backend списков папки(papka)->JSON
	property int ntWidth: 2
	property int ntCoff: 8
	property color clrTexta: "orange"//Цвет текста, рамки.
	property color clrFona: "black"//Цвет фона окна панели.
	property color clrFonaZatem: "SlateGray"//Цвет затемнения фона за панелью.
	property real rlPanelWidth: isMobile ? 1 : 0.85//Ширина окна панели от ширины родителя.
	property real rlPanelHeight: isMobile ? 1 : 0.8//Высота окна панели от высоты родителя.
	//Масштаб шрифта заголовка и пути при изменении ширины панели: при уменьшении ширины
	//шрифт уменьшается, при увеличении растёт только до стандартного размера и не выше,
	//для этого коэффициент ограничен сверху единицей, а снизу минимальной читаемостью.
	property real rlShirinaEtalon: 520//Ширина панели, при которой шрифт равен стандарту.
	readonly property real rlFontCoff: Math.min(1, rctFileDialog.width / rlShirinaEtalon)
	//Сигналы.
	signal vybran(string vrPut);//Выбран пусковой файл, vrPut путь к нему.
	signal zakrit();//Панель закрыта.
	//Функции.
	Keys.onPressed: (event) => {//Это запись для Qt6, для Qt5 нужно удалить event =>
		if (event.key === Qt.Key_Escape) {//Escape закрывает панель
			root.fnZakrit()
			event.accepted = true
		//Alt+стрелка влево — подняться в родительскую папку, как по кнопке «назад»
		} else if (event.key === Qt.Key_Left && (event.modifiers & Qt.AltModifier)) {
			root.fnNaVerh()
			event.accepted = true
		//Enter: вход в папку под курсором, или выбор выделенного файла
		} else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
			let idx = lvFaylovik.currentIndex
			let el = (idx >= 0 && idx < root.fllModel.length) ? root.fllModel[idx] : null
			if (el && el.isFolder) {
				root.strPapka = el.path
				root.strVibranniy = ""
				root.fnObnovit()
			} else root.fnVybrat()
			event.accepted = true
		//ВАЖНО!!! Проглатываем все прочие клавиши (стрелки съедает сам ListView раньше),
		//чтобы горячие клавиши вызывающего окна при открытой панели не срабатывали.
		} else if (root.zabanitKLAVISHI) event.accepted = true
	}
	function fnUrlToLocalPath(url) {//Функция кроссплатформенного преобразования URL в путь
		let path = url.toString()
		if (path.startsWith("file:///")) path = path.substring(7)
		path = decodeURIComponent(path)//Декодируем URL-кодирование (%20 пробел, %3F ?)
		if (Qt.platform.os === "windows") {//Windows: если путь начинается с /C:/, убираем первый /
			if (path.length > 2 && path[0] === '/' && path[2] === ':') path = path.substring(1)
		}
		//Linux убираем двойной слеш если появился
		if (Qt.platform.os !== "windows" && path.startsWith("//")) path = path.substring(1)
		return path
	}
	//Функция возвращает папку начала выбора, или домашнюю если путь не задан
	function fnNachalniyPapka(localPath) {
		//Страховка: старый сохранённый путь на Windows мог быть с обратными слешами.
		let strPut = (localPath || "").replace(/\\/g, "/")
		if (strPut !== "") {
			let ntPos = strPut.lastIndexOf("/")
			if (ntPos > 0) return strPut.substring(0, ntPos)
		}
		return root.fnUrlToLocalPath(StandardPaths.writableLocation(StandardPaths.HomeLocation))
	}
	function fnObnovit() {//Функция обновления списка папки, включая скрытые файлы
		if (root.fnSpisokPapki !== null) root.fllModel = JSON.parse(root.fnSpisokPapki(root.strPapka))
		else root.fllModel = JSON.parse(pyLM.polSpisokPapki(root.strPapka))
	}	
	function fnOtkrit(strZag, strPutFil) {//Функция открытия панели, strPutFil сохранённый путь к файлу
		root.strZagolovok = strZag
		root.strVibranniy = ""
		root.strPapka = root.fnNachalniyPapka(strPutFil)
		root.fnObnovit()
		root.visible = true
		lvFaylovik.forceActiveFocus()//ВАЖНО!!! Забираем фокус в панель сами
	}
	function fnZakrit() {//Функция закрытия панели
		root.visible = false
		lvFaylovik.focus = false//Снимаем фокус с внутренностей панели, чтобы не «держала» его в скрытом виде
		root.zakrit()//Сигнал вызывающей стороне, вернуть фокус своему окну. ВАЖНО!!!
	}
	function fnNaVerh() {//Функция подняться в родительскую папку (кнопка «назад» и Alt+стрелка влево)
		//Страховка: старые сохранённые пути на Windows могли прийти с обратными слешами,
		//нормализуем их к прямым, иначе lastIndexOf("/") не находит границу папок.
		let strPut = root.strPapka.replace(/\\/g, "/")
		let ntPos = strPut.lastIndexOf("/")
		if (ntPos > 0) {
			let strRod = strPut.substring(0, ntPos)
			if (/^[a-zA-Z]:$/.test(strRod)) strRod += "/"//Корень диска не отрезаем целиком.
			if (strRod !== strPut) {//Уже на корне — ничего не делаем, иначе поднимаемся.
				root.strPapka = strRod
				root.strVibranniy = ""
				root.fnObnovit()
			}
		}
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
			id: rctFileDialog
			anchors.centerIn: parent
			width: parent.width * root.rlPanelWidth; height: parent.height * root.rlPanelHeight
			color: root.clrFonaZatem
			radius: root.ntCoff
			clip: true
			ColumnLayout {
				anchors.fill: parent
				spacing: root.ntCoff
				Rectangle {
					id: rctZagolovok
					Layout.fillWidth: true//Занимает всю доступную ширину с учётом margins ColumnLayout
					Layout.preferredHeight: root.ntWidth * root.ntCoff + root.ntCoff * 2
					color: root.clrFona
					border.color: root.clrTexta
					radius: root.ntCoff
					Text {//Заголовок панели
						anchors.centerIn: parent//По центру прямоугольника рисуем текст.
						text: root.strZagolovok;
						color: root.clrTexta
						//Шрифт масштабируется с шириной панели, но не больше стандартного.
						font.pixelSize: Math.max(root.ntCoff,
							(root.ntWidth*root.ntCoff+root.ntCoff) * root.rlFontCoff)
					}
				}
				Rectangle {
					id: rctPut
					Layout.fillWidth: true//Занимает всю доступную ширину с учётом margins ColumnLayout
					Layout.preferredHeight: root.ntWidth * root.ntCoff + root.ntCoff
					color: root.clrFona
					border.color: root.clrTexta
					radius: root.ntCoff
					RowLayout {//Строка: кнопка подняться в родительскую папку + текущий путь
						spacing: root.ntCoff
						anchors.verticalCenter: parent.verticalCenter//По вертикали по центру.
						DCKnopkaNazad {//Кнопка подняться в родительскую папку (как в DCPages/DCSettings),
							ntWidth: root.ntWidth; ntCoff: root.ntCoff
							tapHeight: root.ntWidth*root.ntCoff+root.ntCoff; tapWidth: tapHeight
							clrKnopki: root.clrTexta; clrFona: root.clrFona
							onClicked: root.fnNaVerh()//Подняться в родительскую папку
						}
						Text {//Строка текущего пути
							text: "Путь: " + root.strPapka
							color: root.clrTexta
							//Шрифт пути масштабируется с шириной панели, но не больше стандартного.
							font.pixelSize: Math.max(root.ntCoff,
								root.ntWidth*root.ntCoff * root.rlFontCoff)
							Layout.fillWidth: true; elide: Text.ElideMiddle
							Layout.alignment: Qt.AlignVCenter
						}
					}
				}
				Rectangle {
					id: rctZona
					Layout.fillWidth: true//Занимает всю доступную ширину с учётом margins ColumnLayout
					Layout.fillHeight: true
					color: root.clrFona
					border.color: root.clrTexta
					radius: root.ntCoff
					ListView {//Список папок и файлов (включая скрытые, с точкой в начале)
						id: lvFaylovik
						height: rctZona.height
						width: rctZona.width
						clip: true
						model: root.fllModel
						//Клавиатурная навигация стрелками: файл под курсором становится выбранным,
						//папка подсвечивается курсором, но не выбирается (Enter по папке = вход)
						onCurrentIndexChanged: {
							if (currentIndex >= 0 	&& currentIndex < root.fllModel.length
													&& !root.fllModel[currentIndex].isFolder)
								root.strVibranniy = root.fllModel[currentIndex].path
						}
						delegate: Rectangle {//Одна строка списка
							//Высота строки как у кнопки «наверх» и строки пути.
							width: lvFaylovik.width; height: root.ntWidth*root.ntCoff+root.ntCoff
							//Выделение курсором/выбором одинаково яркое — подсвечиваются и папки, и файлы
							color: (modelData.path === root.strVibranniy || ListView.isCurrent) ?
								Qt.alpha(root.clrTexta, 0.3) : "transparent"
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
								color: root.clrTexta
								text: modelData.isFolder ? modelData.name + "/" : modelData.name
							}
						}
					}
					DCScrollbar {//Самодельная полоса прокрутки вместо стандартной, цвета по гамме панели
						id: polzunka
						flick: lvFaylovik//Следим за прокруткой списка файлов
						width: root.ntShirinaPolzunka//Толщина настраивается свойством корня
						radius: root.ntCoff / 2
						clrTrack: Qt.alpha(root.clrTexta, 0.15)//Дорожка в цвете панели
						clrPolzunokOff: Qt.alpha(root.clrTexta, 0.5)//Ползунок в покое
						clrPolzunokOn: root.clrTexta//Ползунок активный
						anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
					}
				}
				Item {
					Layout.fillWidth: true
					Layout.preferredHeight: root.ntWidth*root.ntCoff+root.ntCoff
					DCKnopkaOriginal {//Кнопка выбора выбранного файла
						id: knopkaVybrat
						text: qsTr("Выбрать")
						ntHeight: root.ntWidth; ntCoff: root.ntCoff
						clrTexta: root.clrTexta; clrKnopki: root.clrFona
						enabled: root.strVibranniy !== ""
						anchors.right: knopkaOtmena.left; anchors.rightMargin: root.ntCoff
						anchors.verticalCenter: parent.verticalCenter
						onClicked: root.fnVybrat()
					}
					DCKnopkaOriginal {//Кнопка отмены выбора и закрытия панели
						id: knopkaOtmena
						text: qsTr("Отмена")
						ntHeight: root.ntWidth; ntCoff: root.ntCoff
						clrTexta: root.clrTexta; clrKnopki: root.clrFona
						anchors.right: parent.right//Прижимаем к правому краю строки.
						anchors.verticalCenter: parent.verticalCenter
						onClicked: root.fnZakrit()
					}
				}
			}
		}
	}
}
