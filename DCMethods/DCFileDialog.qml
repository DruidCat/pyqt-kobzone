import QtQuick
import QtQuick.Layouts
import QtCore
import DCButtons 1.0//Импортируем кнопки
//DCFileDialog - Панель выбора файла. СКРЫТЫЕ папки и файлы показывает флаг hide:true.
//Открывается функцией fnOtkrit(strZag, strPutFil), выбранный путь приходит сигналом vybran(vrPut),
//закрытие панели сигналом zakrit(). Цвета настраиваются свойствами clrTexta/clrFona/clrFonaZatem.
Item {
	id: root
	visible: false
	z: 1000//Поверх всех слоёв
	anchors.fill: parent//Перекрываем всю зону родителя
	focus: visible//Фокус для клавиши Escape
	//Свойства.
	property int ntShirinaPolzunka: 11//Толщина самодельной полосы прокрутки (настраивается)
	property bool isMobile: false//true - это мобильное устройсктво
	property bool hide: false//true - показывать скрытые папки и файлы (имя начинается с точки).
	property string strZagolovok: ""//Заголовок панели
	property string strPapka: ""//Текущая папка выбора
	property string strVibranniy: ""//Выбранный пусковой файл
	property string strKursor: ""//Путь строки под курсором стрелок (папки тоже)
	property var fllModel: []//Модель списка файлов из Python (fnSpisokPapki)
	property var fnSpisokPapki: null//Функция.backend списков папки(papka)->JSON
	property int ntWidth: 2
	property int ntCoff: 8
	property color clrTexta: "orange"//Цвет текста, рамки.
	property color clrFona: "black"//Цвет фона окна панели.
	property color clrFonaZatem: "SlateGray"//Цвет затемнения фона за панелью.
	property real rlPanelWidth: isMobile ? 1 : 0.85//Ширина окна панели от ширины родителя.
	property real rlPanelHeight: isMobile ? 1 : 0.8//Высота окна панели от высоты родителя.
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
			if (el && el.isFolder) root.fnVojtiVPapku(el.path)
			else root.fnVybrat()
			event.accepted = true
		} else event.accepted = true//горячие клавиши вызывающего окна при открытой панели не срабатывали.
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
	function fnNachalniyPapka(localPath) {//Функция возвращает папку начала выбора,или домашнюю(путь не задан)
		//Страховка: старый сохранённый путь на Windows мог быть с обратными слешами.
		let strPut = (localPath || "").replace(/\\/g, "/")
		if (strPut !== "") {
			let ntPos = strPut.lastIndexOf("/")
			if (ntPos > 0) return strPut.substring(0, ntPos)
		}
		return root.fnUrlToLocalPath(StandardPaths.writableLocation(StandardPaths.HomeLocation))
	}
	function fnObnovit() {//Функция обновления списка папки
		let massiv = (root.fnSpisokPapki !== null) ?
			JSON.parse(root.fnSpisokPapki(root.strPapka)) : []
		//Скрытые (имя с точки в начале) оставляем в списке только при флаге hide:true.
		if (!root.hide) massiv = massiv.filter((el) => !el.name.startsWith("."))
		//Как в классических файловых диалогах: первой строкой "..." — вход
		//в родительскую папку. На вершине дерева (корень) такой строки нет.
		let strRod = root.fnRoditelnayaStr(root.strPapka)
		if (strRod !== "")
			massiv.unshift({name: "...", path: strRod, isFolder: true, isUp: true})
		root.fllModel = massiv
	}
	onHideChanged: if (root.visible) root.fnObnovit()//Смена флага на лету перечитывает список.
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
	//Функция возвращает путь родительской папки, "" если подниматься уже некуда.
	//Страховка: старые сохранённые пути на Windows могли прийти с обратными слешами,
	//нормализуем их к прямым, иначе lastIndexOf("/") не находит границу папок.
	function fnRoditelnayaStr(strPapka) {
		let strPut = strPapka.replace(/\\/g, "/")
		let ntPos = strPut.lastIndexOf("/")
		if (ntPos <= 0) return ""
		let strRod = strPut.substring(0, ntPos)
		if (/^[a-zA-Z]:$/.test(strRod)) strRod += "/"//Корень диска не отрезаем целиком.
		if (strRod === strPut) return ""
		return strRod
	}
	function fnVojtiVPapku(strPapka) {//Функция входа в папку: сменить текущую и обновить список.
		root.strPapka = strPapka
		root.strVibranniy = ""
		root.fnObnovit()
	}
	function fnNaVerh() {//Функция подняться в родительскую папку (кнопка «назад» и Alt+стрелка влево)
		let strRod = root.fnRoditelnayaStr(root.strPapka)
		if (strRod !== "") root.fnVojtiVPapku(strRod)
	}
	function fnVybrat() {//Функция выбора выбранного файла
		if (root.strVibranniy === "") return
		root.vybran(root.strVibranniy)//Сигнал с выбранным путём
		root.fnZakrit()
	}
	//Функция раздаёт ширину строки двум нижним кнопкам: когда панели не
	//хватает места, кнопки делят её пропорционально естественным ширинам
	//(символы*высота), а текст ужимает обработчик кнопки из DCButtons.
	function fnRasstavitKnopki() {
		let vys = root.ntWidth*root.ntCoff+root.ntCoff//Высота обеих кнопок
		let shirV = knopkaVybrat.text.length*vys//Естественная ширина «Выбрать»
		let shirO = knopkaOtmena.text.length*vys//Естественная ширина «Отмена»
		let dost = tmRjadKnopok.width - root.ntCoff//Место минус зазор между кнопками
		if (dost >= shirV + shirO) {//Места хватает — кнопки в естественный размер
			knopkaVybrat.width = shirV
			knopkaOtmena.width = shirO
		} else {//Узко — делим поровну пропорционально естественным ширинам
			knopkaOtmena.width = Math.max(1, Math.floor(dost*shirO/(shirV+shirO)))
			knopkaVybrat.width = Math.max(1, dost - knopkaOtmena.width)
		}
	}
	Rectangle {//Затемняющий фон панели
		anchors.fill: parent
		color: root.clrFonaZatem
		MouseArea { anchors.fill: parent}//Блокируем клики от приложения за панелью
		Rectangle {//Окно самой панели
			anchors.centerIn: parent
			width: parent.width * root.rlPanelWidth; height: parent.height * root.rlPanelHeight
			color: root.clrFonaZatem
			radius: root.ntCoff
			clip: true
			ColumnLayout {
				anchors.fill: parent
				spacing: root.ntCoff
				Rectangle {
					Layout.fillWidth: true//Занимает всю доступную ширину с учётом margins ColumnLayout
					Layout.preferredHeight: root.ntWidth * root.ntCoff + root.ntCoff * 2
					color: root.clrFona
					border.color: root.clrTexta
					radius: root.ntCoff
					Text {//Заголовок панели
						anchors.centerIn: parent//По центру прямоугольника рисуем текст.
						text: root.strZagolovok;
						color: root.clrTexta
						//Размер считает помощник shriftZagolovok (DCFontSize): заголовок
						//любой длины влезает в свою рамку с отступом ntCoff.
						font.pixelSize: shriftZagolovok.ntShrift
					}
					DCFontSize {//Счётчик размера шрифта заголовка (см. DCFontSize.qml).
						id: shriftZagolovok
						width: parent.width//Рамка, в которой рисуется заголовок.
						strTekst: root.strZagolovok
						ntBazovy: root.ntWidth*root.ntCoff+root.ntCoff
						ntMin: root.ntCoff
						ntOtstup: root.ntCoff
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
							id: knopkaNazad
							ntWidth: root.ntWidth; ntCoff: root.ntCoff
							tapHeight: root.ntWidth*root.ntCoff+root.ntCoff; tapWidth: tapHeight
							clrKnopki: root.clrTexta; clrFona: root.clrFona
							onClicked: root.fnNaVerh()//Подняться в родительскую папку
						}
						Text {//Строка текущего пути
							id: tekstPuti
							text: "Путь: " + root.strPapka
							color: root.clrTexta
							//Размер считает помощник shriftPuti (DCFontSize); если путь не
							//влезает даже в минимуме шрифта, elide дорезает его многоточием.
							font.pixelSize: shriftPuti.ntShrift
							Layout.fillWidth: true; elide: Text.ElideMiddle
							Layout.alignment: Qt.AlignVCenter
						}
					}
					DCFontSize {//Счётчик размера шрифта пути: доступная ширина — рамка
						//rctPut минус кнопка «назад» и отступы RowLayout.
						id: shriftPuti
						ntShirina: rctPut.width - knopkaNazad.width - root.ntCoff*3
						strTekst: tekstPuti.text
						ntBazovy: root.ntWidth*root.ntCoff
						ntMin: root.ntCoff
					}
				}
				Rectangle {
					id: rctZona
					Layout.fillWidth: true//Занимает всю доступную ширину с учётом margins ColumnLayout
					Layout.fillHeight: true
					color: root.clrFona
					border.color: root.clrTexta
					ListView {//Список папок и файлов (включая скрытые, с точкой в начале)
						id: lvFaylovik
						height: rctZona.height
						//Выделения строк не должны налаживаться на скроллбар: список
						//не заходит под дорожку, строки кончаются перед полосой прокрутки.
						//Зазор берём только когда полоса реально видна (flick меньше контента).
						width: rctZona.width - (polzunka.visible ? polzunka.width : 0)
						clip: true
						model: root.fllModel
						//Клавиатурная навигация стрелками: файл под курсором становится выбранным,
						//папка подсвечивается курсором, но не выбирается (Enter по папке = вход).
						//Курсор стрелок ведёт подсветку любой строки; на файле он
						//работает как клик — файл ещё и выбирается, на папке — нет.
						onCurrentIndexChanged: {
							let item = (currentIndex >= 0 && currentIndex < root.fllModel.length) ?
								root.fllModel[currentIndex] : null
							root.strKursor = item ? item.path : ""
							//Когда курсор ушёл с файла на папку, прежнее выделение файла снимаем:
							//иначе при движении вверх по папкам старый файл продолжает подсвечиваться.
							if (item === null || item.isFolder) root.strVibranniy = ""
							else root.strVibranniy = item.path
						}
						delegate: Rectangle {//Одна строка списка
							//Высота строки как у кнопки «наверх» и строки пути.
							width: lvFaylovik.width; height: root.ntWidth*root.ntCoff+root.ntCoff
							//Выделение курсором/выбором одинаково яркое — подсвечиваются и папки, и файлы.
							//ListView.isCurrent на модели-массиве из Python не срабатывает, сверяем путь.
							color: (modelData.path === root.strKursor ||
								modelData.path === root.strVibranniy) ?
								Qt.alpha(root.clrTexta, 0.3) : "transparent"
							MouseArea {
								anchors.fill: parent
								//Одиночный клик по папке входит в неё, клик по файлу сразу его выбирает.
								onClicked: {
									if (modelData.isFolder) root.fnVojtiVPapku(modelData.path)
									else {
										root.strVibranniy = modelData.path
										root.fnVybrat()//Выбор в один клик: сигнал vybran и закрытие панели.
									}
								}
							}
							Text {//Название файла или папки
								x: root.ntCoff; anchors.verticalCenter: parent.verticalCenter
								font.pixelSize: (root.ntWidth-1)*root.ntCoff//Размер шрифта по ntWidth/ntCoff.
								color: root.clrTexta
								//Строку «...» перехода наверх рисуем без слеша, как в классических диалогах.
								text: modelData.isUp ? "..." :
									(modelData.isFolder ? modelData.name + "/" : modelData.name)
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
					id: tmRjadKnopok
					Layout.fillWidth: true
					Layout.preferredHeight: root.ntWidth*root.ntCoff+root.ntCoff
					//При сужении панели кнопки строки сужаются вместе с ней, а не обрезаются.
					onWidthChanged: root.fnRasstavitKnopki()
					Component.onCompleted: root.fnRasstavitKnopki()
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
