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
	//Свойства для управления состоянием транскрибации
	property bool isTranscribing: false//true - транскрибация началась.
	property int tekushiAudioFail: 0//Текущий аудио файл в обработке.
	property int kolichestvoAudioFailov: 0//общее количество обрабатываемых файлов
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
    DCSettings {//Объект настроек
        id: dcReestr
    }
    Keys.onPressed: (event) => {//Обработка горячих клавиш
        if (event.modifiers & Qt.AltModifier) {
            if (event.key === Qt.Key_Left) {
                fnClickedNazad()
                event.accepted = true
                return
            } else if (event.key === Qt.Key_F) {
                fnClickedMenu()//Функция Настройки
                event.accepted = true
                return
            }
        }
		if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_T) {
                if (!menuMenu.visible && knopkaTranscribe.enabled) {
                    fnClickedTranscribe()
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
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            if (!menuMenu.visible) {
                var ltNoviY = flcZona.contentY - 50
                if (ltNoviY < 0)
                    ltNoviY = 0
                flcZona.contentY = ltNoviY
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
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
        txfTextPut.text = dcReestr.transcribe_put_text
        txfAudioPut.text = dcReestr.transcribe_put_audio
    }
	Connections {//Connections для транскрибера
		target: pyTranscriber
		function onTranscriptionStarted() {//Функция начала работы скрипта DCTranscribe.py
			root.isTranscribing = true//Взводим флаг, что транскрибация началась.
			tmrLogo.running = true//Запускаем анимацию логотипа и политику кнопок.
		}
		function onTranscriptionFinished(success, message) {//Функция окончания работы скрипта DCTranscribe.py
			fnStopTranscriber()//Останавливаем транскрибацию.	
			if (!success) {//Если ошибка, то...
				txdZona.strCopy += "\n❌ Ошибка: " + message + "\n"
				txdZona.text = txdZona.strCopy
			}
		}
		function onLogMessage(message) {//Функция выводящая в Прогресс сообщения скрипта DCTranscribe.py
			//Добавляем сообщение в лог
			txdZona.strCopy += message + "\n"//Собираю сообщения в переменную.
			txdZona.text = txdZona.strCopy//Отображаю в "Прогрессе транскрибации" сообщения со скрипта.
			root.log (message)//В логи
		}
		function onProgressUpdate(current, total) {//Функция обновления прогресса из python
			current = current - 1//Обязательно, чтоб с 0 прогресс начинался.
			root.tekushiAudioFail = current
			root.kolichestvoAudioFailov = total
			if (ldrProgress.item) {
				var progress = (current / (total)) * 100
				ldrProgress.total = root.kolichestvoAudioFailov//Пересчёт скорости смещения полосы.
				ldrProgress.item.progress = progress//Перемещение на позицию пропорции.
				ldrProgress.item.text = `${current}/${total}`//Отображаем прогресс по середине полосы.
			}
		}
	}
	Connections {//Connections для pyFileOpener
		target: pyFileOpener
		function onSignalFileOpened(success, message) {
			if (success) {
				root.toolbar(message)//Файл открыт
			} else {
				console.error("✗ Ошибка:", message)
				root.toolbar("Ошибка: " + message)
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
				knopkaTranscribe.enabled = false
				knopkaAudioPut.enabled = false
				knopkaTextPut.enabled = false
				txfAudioPut.enabled = false
				txfTextPut.enabled = false
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
			knopkaTranscribe.enabled = true
			knopkaAudioPut.enabled = true//Включаем кнопку, чтоб она нажималась
			knopkaTextPut.enabled = true//Включаем кнопку, чтоб она нажималась
			txfAudioPut.enabled = true
			txfTextPut.enabled = true
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
		if (isTranscribing) {//Если транскрибация идёт, то...
			knopkaNazad.visible = false//Невидимая кнопка, чтоб она не нажималась, при нажатии Отмены.
			knopkaMenu.visible = false// Невидимая кнопка, чтоб она не нажималась, при нажатии Ок.
			stopDialog.visible = true//Выдаём вопрос об остановке транскрибации.
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
	function fnClickedTranscribe() {//Функция нажатия кнопки начала транскрибации.
		if (!isTranscribing) {//Если транскрибация не запущена, то...
			txdZona.strCopy = ""//Очищаем переменную Прогресса транскрибации.
			txdZona.text = ""//Очищаем зону отображения прогресса транскрибации.
			//Запускаем через бэкенд PyTranscriber.py	
			pyTranscriber.start(dcReestr.transcribe_put_audio, dcReestr.transcribe_put_text)
		}
	}
	function fnStopTranscriber() {//Функция Остановки транскрибации.
		root.isTranscribing = false//возвращаем флаг, что транскрибация окончилась.	
		tmrLogo.running = false//Отключаем анимацию логотипа и активируем политику кнопок.
	}
    function fnClickedPutAudio(){//Функция открытия диалога выбора папки с аудио файлами.
        dialogAudio.open()
    }
    function fnClickedPutText(){//Функция открытия диалога выбора папки для результатов работы.
        dialogText.open()
    }
	function fnClickedOtkrit(){//Функция открытия результатов транскрибации.
		dialogOtkrit.open()
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
		console.log("PATH", path)
		if (path.startsWith("file:///")) {//Если путь начинается с file:///
			path = path.substring(7)//Убираем "file://" чтоб осталось "/" /home, /mnt и тд
		} else if (path.startsWith("file://")) {//Если путь начинается с file://
			path = path.substring(7)//Убираем "file://"
		}
		path = decodeURIComponent(path)//Декодируем URL-кодирование (%20 → пробел, %3F → ?)
		if (Qt.platform.os === "windows") {//Windows: если путь начинается с /C:/, убираем первый /
			if (path.length > 2 && path[0] === '/' && path[2] === ':') {
				path = path.substring(1)
			}
		}
		if (Qt.platform.os !== "windows" && path.startsWith("//")) {//Linux-убираем двойной слеш,если появился
			path = path.substring(1)
		}
		return path
	} 
	FolderDialog {//Диалог выбора папки для аудио
		id: dialogAudio
		title: "Выберите папку с аудио файлами"
		currentFolder: {//Используем сохранённый путь из настроек, или стандартную домашнюю папку
			if (dcReestr.transcribe_put_audio !== "") {
				return fnPathToUrl(dcReestr.transcribe_put_audio)//Преобразуем сохранённый путь в URL
			}
			else return StandardPaths.writableLocation(StandardPaths.MusicLocation)
		}
		onAccepted: {
			var vtPut = fnUrlToLocalPath(selectedFolder)//Используем кроссплатформенную функцию
			dcReestr.transcribe_put_audio = vtPut
			txfAudioPut.text = vtPut
			console.log("✓ Выбрана папка аудио:", vtPut)
		}
	}	
	FolderDialog {//Диалог выбора папки для текстовых файлов
		id: dialogText
		title: "Выберите папку для текстовых файлов"
		currentFolder: {//Используем сохранённый путь из настроек, или стандартную домашнюю папку
			if (dcReestr.transcribe_put_text !== "") {
				return fnPathToUrl(dcReestr.transcribe_put_text)//Преобразуем сохранённый путь в URL
			}
			else return StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
		}
		onAccepted: {
			var vtPut = fnUrlToLocalPath(selectedFolder)//Используем кроссплатформенную функцию
			dcReestr.transcribe_put_text = vtPut
			txfTextPut.text = vtPut
			console.log("✓ Выбрана папка результатов:", vtPut)
		}
	}	
	FileDialog {//Диалог открытия текстового файла для просмотра
		id: dialogOtkrit
		title: "Выберите текстовый файл для просмотра"
		currentFolder: {//Используем сохранённый путь из настроек, или стандартную домашнюю папку
			if (dcReestr.transcribe_put_text !== "") {
				return fnPathToUrl(dcReestr.transcribe_put_text)//Преобразуем сохранённый путь в URL
			}
			else return StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
		}
		nameFilters: ["Текстовые файлы (*.txt)", "Все файлы (*)"]
		fileMode: FileDialog.OpenFile//Единичный выбор файла
		onAccepted: {
			console.log("✓ Выбран файл:", selectedFile)//Используем Python для открытия
			pyFileOpener.openFile(selectedFile.toString())// Открываем через Python
			//pyFileOpener.openFolder("file://" + dcReestr.transcribe_put_text)//Так можно открыть папку.
		}
		onRejected: {
			console.log("Выбор файла отменён")
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
			
			text: qsTr("ОСТАНОВИТЬ ТРАНСКРИБАЦИЮ?")
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
				pyTranscriber.stop()//Останавливаем принудительно транскрибацию.
				fnStopTranscriber()//Останавливаем транскрибацию.
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
            Column {
                id: clmnContent
                width: flcZona.width - dcScrollbar.width
                spacing: root.ntCoff / 2//Расстояние между элементами по вертикали.
                topPadding: root.ntCoff * 2
                bottomPadding: root.ntCoff * 2
                leftPadding: root.ntCoff * 2
                rightPadding: root.ntCoff * 2
                DCKnopkaOriginal {//Кнопка "Транскрибация"
                    id: knopkaTranscribe
                    text: "🎙️ Транскрибация"
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
                            fnClickedTranscribe()
                        }
                    }
                }
                Text {//Путь к аудио
                    text: "Путь к аудиофайлам:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                Row {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    spacing: root.ntCoff
                    
                    TextField {
                        id: txfAudioPut
                        width: parent.width - knopkaAudioPut.width - parent.spacing
						height: root.ntHeight
						font.pixelSize: root.pixelHeight//Имперический размер шрифта.
                        placeholderText: "Путь к папке с аудиофайлами"
                        selectByMouse: true
                        color: root.clrTexta
                        background: Rectangle {
                            color: "transparent"
                            border.color: root.clrTexta
                            border.width: 1
                            radius: root.ntCoff / 2
                        }
                        onTextChanged: {
                            dcReestr.transcribe_put_audio = text
                        }
                    }
                    
                    DCKnopkaOriginal {
                        id: knopkaAudioPut
                        text: "..."
                        ntHeight: root.ntWidth
                        ntCoff: root.ntCoff
                        clrKnopki: root.clrTexta
                        clrTexta: root.clrFona
                        width: root.ntWidth * root.ntCoff * 3
                        
                        onClicked: {
                            if (!fnCloseMenuIfOpen()) {
                                fnClickedPutAudio()
                            }
                        }
                    }
                }
                Text {//Путь сохранения результатов
                    text: "Путь сохранения результатов:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                
                Row {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    spacing: root.ntCoff
                    
                    TextField {
                        id: txfTextPut
                        width: parent.width - knopkaTextPut.width - parent.spacing
						height: root.ntHeight
						font.pixelSize: root.pixelHeight//Имперический размер шрифта.
                        placeholderText: "Путь к папке для сохранения результатов"
                        selectByMouse: true
                        color: root.clrTexta
                        background: Rectangle {
                            color: "transparent"
                            border.color: root.clrTexta
                            border.width: 1
                            radius: root.ntCoff / 2
                        }
                        onTextChanged: {
                            dcReestr.transcribe_put_text = text
                        }
                    }
                    
                    DCKnopkaOriginal {
                        id: knopkaTextPut
                        text: "..."
                        ntHeight: root.ntWidth
                        ntCoff: root.ntCoff
                        clrKnopki: root.clrTexta
                        clrTexta: root.clrFona
                        width: root.ntWidth * root.ntCoff * 3
                        
                        onClicked: {
                            if (!fnCloseMenuIfOpen()) {
                                fnClickedPutText()
                            }
                        }
                    }
                }
                Text {//Прогресс транскрибации
                    text: "Прогресс транскрибации:"
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
				DCKnopkaOriginal {//Кнопка "Открыть результат транскрибации."
                    id: knopkaOtkrit
                    text: "Открыть результаты расшифровки"
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
                            fnClickedOtkrit()
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
            imyaMenu: "transcribe"
            
            onClicked: function(ntNomer, strMenu) {
                menuMenu.visible = false
                if (ntNomer === 1) {
                    fnClickedTranscribe()
                } else if (ntNomer === 2) {
                    fnClickedPutAudio()
                } else if (ntNomer === 3) {
                    fnClickedPutText()
                } else if (ntNomer === 4) {
                    fnClickedOtkrit()
                } else if (ntNomer === 5) {
                    fnClickedMenu()
                } else if (ntNomer === 6) {
                    fnClickedInfo()
                } else if (ntNomer === 7) {
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
