import QtQuick
import QtQuick.Controls
import QtCore
import QtQuick.Dialogs
import DCButtons 1.0
import DCMethods 1.0
import DCSettings 1.0//Настройки из реестра.

Item {
    id: root
    // Свойства
    property int ntWidth: 2
    property int ntCoff: 8
	property int ntHeight: ntWidth*ntCoff+ntCoff//Высота виджетов, в которых будет распологаться текст
	property real pixelHeight: (ntHeight - ntCoff) * 0.7//В пикселях примерно размер шрифта
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
	//Свойства для управления состоянием создания RAG
	property bool isRAG: false//true - создание RAG началась.
	property int tekushiFail: 0//Текущий файл в обработке.
	property int kolichestvoFailov: 0//общее количество обрабатываемых файлов
    //Настройки
    anchors.fill: parent
    focus: true 
    //Сигналы
    signal clickedNazad()
	signal clickedSettings()
    signal clickedInfo()
	signal toolbar(var strToolbar)
    signal log(var strLog)
	//Методы
    Keys.onPressed: (event) => {//Обработка горячих клавиш
        if (event.modifiers & Qt.AltModifier) {
            if (event.key === Qt.Key_Left) {
                fnClickedNazad()
                event.accepted = true
                return
            } else if (event.key === Qt.Key_F || event.key === 1040) {
                fnClickedMenu()//Функция Настройки
                event.accepted = true
                return
            }
        }
		if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_T || event.key === 1045) {
                if (!menuMenu.visible && knopkaRAG.enabled) {
                    fnClickedRAG()
                }
                event.accepted = true
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
	Component.onCompleted: {
        root.forceActiveFocus()
    }
	Connections {//Connections для транскрибера
		target: pyRAG
		function onSigRAGStarted() {//Функция начала работы скрипта DCRAGMake.py
			root.isRAG = true//Взводим флаг, что создание RAG началась.
			tmrLogo.running = true//Запускаем анимацию логотипа и политику кнопок.
		}
		function onSigRAGFinished(success, message) {//Функция окончания работы скрипта DCRAGMake.py
			fnStopRAG()//Останавливаем создание RAG.	
			if (!success) {//Если ошибка, то...
				txdZona.strCopy += "\n❌ Ошибка: " + message + "\n"
				txdZona.text = txdZona.strCopy
			}
		}
		function onLogMessage(message) {//Функция выводящая в Прогресс сообщения скрипта DCRAGMake.py
			//Добавляем сообщение в лог
			txdZona.strCopy += message + "\n"//Собираю сообщения в переменную.
			txdZona.text = txdZona.strCopy//Отображаю в "Прогрессе транскрибации" сообщения со скрипта.
			root.log (message)//В логи
		}
		function onProgressUpdate(current, total) {//Функция обновления прогресса из python
			current = current - 1//Обязательно, чтоб с 0 прогресс начинался.
			root.tekushiFail = current
			root.kolichestvoFailov = total
			if (ldrProgress.item) {
				var progress = (current / (total)) * 100
				ldrProgress.total = root.kolichestvoFailov//Пересчёт скорости смещения полосы.
				ldrProgress.item.progress = progress//Перемещение на позицию пропорции.
				ldrProgress.item.text = `${current}/${total}`//Отображаем прогресс по середине полосы.
			}
		}
	}
	Timer {//ТАЙМЕР анимации логотипа
        id: tmrLogo
        interval: 110
        running: false
        repeat: true
        property bool blLogo: false
        onTriggered: {
            if(blLogo){//Если true, то...
                lgLogo.ntCoff++;
                if(lgLogo.ntCoff >= root.logoRazmer)
                    blLogo = false;
            }
            else{
                lgLogo.ntCoff--;
                if(lgLogo.ntCoff <= 1)
                    blLogo = true;
            }
        }
        onRunningChanged: {
            if (running) {
				knopkaMenu.enabled = false
				knopkaRAG.enabled = false
				knopkaPutDoc.enabled = false
				knopkaPutDB.enabled = false
				knopkaInfo.visible = false
				knopkaNastroiki.visible = false

				ldrProgress.active = true
            } else {
				lgLogo.ntCoff = root.logoRazmer//Задаём размер логотипа.
				if (ldrProgress.item) ldrProgress.item.progress = 100
				tmrProgress.running = true//Запускаем таймер отображения 100% прогресса и политику кнопок
            }
        }
    }
	Timer {//ТАЙМЕР, чтоб можно было увидеть 100% прогресса призавершении.
        id: tmrProgress
        interval: 1100; running: false; repeat: false
        onTriggered: {
			ldrProgress.active = false

			knopkaMenu.visible = true
			knopkaMenu.enabled = true//Включаем кнопку, чтоб она нажималась
			knopkaNazad.visible = true
			knopkaNazad.enabled = true//Включаем кнопку, чтоб она нажималась
			knopkaRAG.enabled = true
			knopkaPutDoc.enabled = true//Включаем кнопку, чтоб она нажималась
			knopkaPutDB.enabled = true//Включаем кнопку, чтоб она нажималась
            knopkaInfo.visible = true
			knopkaNastroiki.visible = true
        }
	}
	function fnClickedEscape() {//Функция нажатия на клавишу Escape
		if (menuMenu.visible) {
			menuMenu.visible = false
		} else {
			//Если меню закрыто, ничего не делаем (можно добавить другую логику)
		}
    }
	function fnClickedNazad() {//Функция закрытия страницы.
		if (isRAG) {//Если создание RAG идёт, то...
			knopkaNazad.visible = false//Невидимая кнопка, чтоб она не нажималась, при нажатии Отмены.
			knopkaMenu.visible = false// Невидимая кнопка, чтоб она не нажималась, при нажатии Ок.
			stopDialog.visible = true//Выдаём вопрос об остановке создания RAG.
		} else {
			fnClickedEscape()//Функция нажатия на клавишу Escape
			root.clickedNazad()
		}
	}
    function fnClickedMenu() {
		fnClickedEscape()//Функция нажатия на клавишу Escape
		root.clickedSettings()//Сигнал излучает открытие настроек.
    }
    function fnClickedInfo() {
		fnClickedEscape()//Функция нажатия на клавишу Escape
        root.clickedInfo()
    }
	function fnClickedRAG() {//Функция нажатия кнопки начала создания RAG.
		if (!isRAG) {//Если создание RAG не запущена, то...
			txdZona.strCopy = ""//Очищаем переменную Прогресса созадания RAG.
			txdZona.text = ""//Очищаем зону отображения прогресса RAG.
			//Запускаем через бэкенд pyRAG.py	
			pyRAG.start(DCSettings.rag_put_doc, DCSettings.rag_put_db, DCSettings.rag_gpu)
		}
	}
	function fnStopRAG() {//Функция Остановки создания RAG.
		root.isRAG = false//возвращаем флаг, что создание RAG окончилась.	
		tmrLogo.running = false//Отключаем анимацию логотипа и активируем политику кнопок.
	}
    function fnClickedPutDoc(){//Функция открытия диалога выбора папки с документами.
        dialogDoc.open()
    }
    function fnClickedPutDB(){//Функция открытия диалога выбора папки для размещения RAG базы данных.
        dialogDB.open()
    }
    function fnToggleMenu() {
        if (menuMenu.visible) {
            menuMenu.visible = false
        } else {
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
	function fnPathToUrl(localPath) {//Функция кроссплатформенного преобразования пути в URL
		if (!localPath) return ""
		if (localPath.startsWith("file://")) return localPath//Если это уже URL — возвращаем как есть
		//Для локальных файлов нужен формат file:///
		if (localPath.startsWith("/")) {//Linux: /home/user/ -> file:///home/user/ (добавляем file://)
			return "file://" + localPath//file:// + /path = file:///path
		} else {//Windows: C:/Users/ -> file:///C:/Users/ (добавляем file:///)
			return "file:///" + localPath//file:/// + C:/path = file:///C:/path
		}
	}
	function fnUrlToLocalPath(url) {//Функция кроссплатформенного преобразования URL в путь
		if (!url) return ""
		var path = url.toString()
		if (path.startsWith("file:///")) {//Если путь начинается с file:///
			path = path.substring(7)//Убираем "file://" чтоб осталось "/" /home, /mnt и тд
		} else if (path.startsWith("file://")) {//Если путь начинается с file://
			path = path.substring(7)//Убираем "file://"
		}
		path = decodeURIComponent(path)//Декодируем URL-кодирование (%20 → пробел, %3F → ?)
		if (Qt.application.os === "windows") {//Windows: если путь начинается с /C:/, убираем первый /
			if (path.length > 2 && path[0] === '/' && path[2] === ':') {
				path = path.substring(1)
			}
		}
		if (Qt.application.os !== "windows" && path.startsWith("//")) {//Linux-убираем двойной слеш,если появился
			path = path.substring(1)
		}
		return path
	} 
	FolderDialog {//Диалог выбора папки с документами
		id: dialogDoc
		title: "Выберите папку с документами"
		currentFolder: {//Используем сохранённый путь из настроек, или стандартную домашнюю папку
			if (DCSettings.rag_put_doc !== "") {
				return fnPathToUrl(DCSettings.rag_put_doc)//Преобразуем сохранённый путь в URL
			}
			else return StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
		}
		onAccepted: {
			var vtPut = fnUrlToLocalPath(selectedFolder)//Используем кроссплатформенную функцию
			DCSettings.rag_put_doc = vtPut
			root.toolbar(`RAG. Выбрана папка с документами: ${vtPut}`)//Сообщение в toolbar и журнал.
		}
	}	
	FolderDialog {//Диалог выбора папки для текстовых файлов
		id: dialogDB
		title: "Выберите папку для размещения RAG базы данных"
		currentFolder: {//Используем сохранённый путь из настроек, или стандартную домашнюю папку
			if (DCSettings.rag_put_db !== "") {
				return fnPathToUrl(DCSettings.rag_put_db)//Преобразуем сохранённый путь в URL
			}
			else return StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
		}
		onAccepted: {
			var vtPut = fnUrlToLocalPath(selectedFolder)//Используем кроссплатформенную функцию
			DCSettings.rag_put_db = vtPut
			root.toolbar(`RAG. Выбрана папка размещения БД: ${vtPut}`)//Сообщение в toolbar и журнал.
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
        DCKnopkaMenu {
            id: knopkaMenu
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            visible: true
            anchors.verticalCenter: tmZagolovok.verticalCenter
            anchors.right: tmZagolovok.right
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff
            tapWidth: tapHeight * root.tapZagolovokPravi
            
            onClicked: {
                if (!fnCloseMenuIfOpen()) {
                    fnClickedMenu()
                }
            }
        }
		DCVopros {
			id: stopDialog
			ntWidth: root.ntWidth
			ntCoff: root.ntCoff
			anchors.top: tmZagolovok.top
			anchors.bottom: tmZagolovok.bottom
			anchors.left: tmZagolovok.left
			anchors.right: tmZagolovok.right
			
			text: qsTr("ОСТАНОВИТЬ СОЗДАНИЕ RAG БАЗЫ ДАННЫХ?")
			visible: false
			
			clrFona: "red"
			clrTexta: root.clrFona
			clrKnopki: root.clrFona
			clrBorder: root.clrFona
			
			tapKnopkaZakrit: root.tapZagolovokLevi
			tapKnopkaOk: root.tapZagolovokPravi
			
			onClickedOk: {
				stopDialog.visible = false//Делаем невидимый диалог
        		root.forceActiveFocus()//Переводим фокус на основное окно, чтоб работали горячие кнопки.
				pyRAG.stop()//Останавливаем принудительно транскрибацию.
				fnStopRAG()//Останавливаем создание RAG.
			}
			onClickedOtmena: {
				stopDialog.visible = false//Делаем невидимый диалог.
        		root.forceActiveFocus()//Переводим фокус на основное окно, чтоб работали горячие кнопки.
				knopkaNazad.visible = true//видимая кнопка, чтоб она нажималась
				knopkaMenu.visible = true// видимая кнопка, чтоб она нажималась
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
			TapHandler {//Нажимаем на всю область виджета.
				onTapped: fnCloseMenuIfOpen()//Закрыть меню если оно открыто	
			}
            Column {
                id: clmnContent
                width: flcZona.width - dcScrollbar.width
                spacing: root.ntCoff / 2//Расстояние между элементами по вертикали.
                topPadding: root.ntCoff * 2
                bottomPadding: root.ntCoff * 2
                leftPadding: root.ntCoff * 2
                rightPadding: root.ntCoff * 2
                DCKnopkaOriginal {//Кнопка "RAG"
                    id: knopkaRAG
                    text: "Создать RAG БД"
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
                    clrKnopki: root.clrTexta    
                    clrTexta: root.clrFona
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
                    onClicked: {
                        if (!fnCloseMenuIfOpen()) {
                            fnClickedRAG()
                        }
                    }
                }
                Text {//Путь к документам
                    text: "Путь к документам:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
				DCKnopkaOriginal {
					id: knopkaPutDoc
					text: DCSettings.rag_put_doc
					ntHeight: root.ntWidth
					ntCoff: root.ntCoff
					clrKnopki: root.clrTexta
					clrTexta: root.clrFona
					anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
					
					onClicked: {
						if (!fnCloseMenuIfOpen()) {
							fnClickedPutDoc()
						}
					}
				}
                Text {//Путь сохранения RAG базы данных
                    text: "Путь размещения RAG базы данных:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                } 
				DCKnopkaOriginal {
					id: knopkaPutDB
					text: DCSettings.rag_put_db
					ntHeight: root.ntWidth
					ntCoff: root.ntCoff
					clrKnopki: root.clrTexta
					clrTexta: root.clrFona
					anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
					
					onClicked: {
						if (!fnCloseMenuIfOpen()) {
							fnClickedPutDB()
						}
					}
				}
                Text {//Прогресс транскрибации
                    text: "Прогресс создания RAG базы данных:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                Rectangle {
                    id: rctTextEdit
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    height: 400
                    border.color: root.clrTexta
                    border.width: 3
                    color: "transparent"
                    radius: root.ntCoff / 2
                    clip: true
                    DCTextEdit {
                        id: txdZona
                        property string strCopy: ""
                        
                        ntWidth: root.ntWidth
                        ntCoff: root.ntCoff
                        readOnly: true
                        scrollAuto: true
                        textEdit.selectByMouse: false
                        pixelSize: root.ntWidth / 3 * root.ntCoff
                        radius: root.ntCoff / 4
                        clrFona: "transparent"
                        clrTexta: root.clrTexta   
                        onPressed: fnCloseMenuIfOpen()
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
            opacity: 0.9
            
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
            imyaMenu: "rag"
            
            onClicked: function(ntNomer, strMenu) {
                menuMenu.visible = false
                if (ntNomer === 1) {
                    fnClickedRAG()
                } else if (ntNomer === 2) {
                    fnClickedPutDoc()
                } else if (ntNomer === 3) {
                    fnClickedPutDB()
                } else if (ntNomer === 4) {
                    fnClickedMenu()
                } else if (ntNomer === 5) {
                    fnClickedInfo()
                } else if (ntNomer === 6) {
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
        Loader {//LOADER для DCProgress
            id: ldrProgress
            anchors.fill: tmToolbar
            source: "qrc:/DCMethods/DCProgress.qml"
            active: false
			property int total: 1//Переменная, хранящая количество файлов на обработку
			property int interval: 2200//Интервал между смещением полосы.
            onLoaded: {
                ldrProgress.item.ntWidth = root.ntWidth
                ldrProgress.item.ntCoff = root.ntCoff
                ldrProgress.item.clrProgress = root.clrTexta
                ldrProgress.item.clrTexta = "grey"
                ldrProgress.item.radius = root.ntCoff / 4
				ldrProgress.item.msInterval = ldrProgress.interval//Пауза между смещением.
            }
			onTotalChanged: {//Если переменная изменилась, то происходит пересчёт скорости смещения.
				ldrProgress.item.msInterval = interval * total//Чем больше файлов, тем медленней движется.
			}
        }
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
            if (menuMenu.visible) {
                menuMenu.visible = false
            } else {
                root.forceActiveFocus()
            }
            root.forceActiveFocus()
        }
    }
}


