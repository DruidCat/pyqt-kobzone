import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import Qt.labs.platform as Platform
import DCButtons 1.0
import DCMethods 1.0

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
    
    property real rlProgress: 0
    property real rlLoader: 1
    property real prozrachZona: 0.9
	//Свойства для управления состоянием транскрибации
	property bool isTranscribing: false
	property int currentFile: 0
	property int totalFiles: 0
    //Настройки
    anchors.fill: parent
    focus: true 
    //Сигналы
    signal clickedNazad()
    signal clickedInfo()
    signal signalToolbar(var strToolbar)
	//Методы
    DCSettings {//Объект настроек
        id: settings
    }
    Keys.onPressed: (event) => {//Обработка горячих клавиш
        if (event.modifiers & Qt.AltModifier) {
            if (event.key === Qt.Key_Left) {
                console.log("Alt+Left: возврат назад")
                fnClickedNazad()
                event.accepted = true
                return
            }
        }
        if (event.key === Qt.Key_Escape) {
            if (menuMenu.visible) {
                menuMenu.visible = false
                event.accepted = true
            } else {
                event.accepted = true
            }
        }
        if (event.key === Qt.Key_F1) {
            if (!menuMenu.visible) {
                fnClickedInfo()    
            }
            event.accepted = true
        }
        if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
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
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_T) {
                if (!menuMenu.visible && btnTranscribe.enabled) {
                    fnClickedTranscribe()
                }
                event.accepted = true
            }
        }
    }
	Timer {//ТАЙМЕР анимации логотипа
        id: tmrLogo
        interval: 47
        running: false
        repeat: true
        property bool blLogo: false
        onTriggered: {
            if (blLogo) {
                imgLogo.scale += 0.02
                if (imgLogo.scale >= 1.3)
                    blLogo = false
            } else {
                imgLogo.scale -= 0.02
                if (imgLogo.scale <= 0.7)
                    blLogo = true
            }
        }
        onRunningChanged: {
            if (running) {
                imgLogo.opacity = 0.5
                //imgLogo.opacity = 1.0
                imgLogo.visible = true
                
            } else {
                imgLogo.scale = 1.0
                imgLogo.opacity = 0.0
                imgLogo.visible = false
            }
        }
    }
	function fnClickedNazad() {
		if (isTranscribing) {
			// Показать диалог подтверждения остановки
			console.log("⚠️ Попытка выхода во время транскрибации")
			// TODO: Добавить DCVopros для подтверждения
			transcriber.stop()
		} else {
			root.clickedNazad()
		}
	}
    function fnClickedMenu() {
        console.log("НАСТРОЙКИ")
    }
    function fnClickedInfo() {
        root.clickedInfo()
    }
	function fnClickedTranscribe() {
		if (isTranscribing) {
			console.log("⚠️ Транскрибация уже запущена")
			return
		}
		console.log("🎙️ Запуск транскрибации...")
		console.log("  Аудио:", settings.audioPath)
		console.log("  Текст:", settings.textPath)
		
		txdZona.strCopy = ""
		txdZona.text = ""
		//Запускаем транскрибацию через Python бэкенд PyTranscriber.py
		transcriber.start(settings.audioPath, settings.textPath)
	}
    function fnClickedPutAudio() {
        folderDialogAudio.open()
    }
    function fnClickedPutText() {
        folderDialogText.open()
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
    Component.onCompleted: {
        root.forceActiveFocus()
        txtAudioPath.text = settings.audioPath
        txtTextPath.text = settings.textPath
    }
	Connections {//Connections для транскрибера
		target: transcriber
		function onTranscriptionStarted() {
			console.log("✓ Транскрибация начата")
			root.isTranscribing = true
			ldrProgress.active = true

			knopkaInfo.visible = false
			knopkaNastroiki.visible = false
			knopkaMenu.enabled = false
			knopkaNazad.enabled = false

			btnTranscribe.enabled = false
			btnAudioBrowse.enabled = false
			btnTextBrowse.enabled = false
			txtAudioPath.enabled = false
			txtTextPath.enabled = false

			tmrLogo.running = true
		}
		function onTranscriptionFinished(success, message) {
			console.log("✓ Транскрибация завершена:", message)
			root.isTranscribing = false
			if (ldrProgress.item) {
				ldrProgress.item.progress = 100
			}
			Qt.callLater(function() {
				ldrProgress.active = false

				knopkaInfo.visible = true
				knopkaNastroiki.visible = true
				knopkaMenu.enabled = true
				knopkaNazad.enabled = true

				btnTranscribe.enabled = true
				btnAudioBrowse.enabled = true
				btnTextBrowse.enabled = true
				txtAudioPath.enabled = true
				txtTextPath.enabled = true
				
				tmrLogo.running = false
			})

			if (success) {
				txdZona.strCopy += "\n✅ Транскрибация успешно завершена!\n"
			} else {
				txdZona.strCopy += "\n❌ Ошибка: " + message + "\n"
			}
			txdZona.text = txdZona.strCopy
		}
		function onLogMessage(message) {
			//Добавляем сообщение в лог
			txdZona.strCopy += message + "\n"
			txdZona.text = txdZona.strCopy
		}
		function onProgressUpdate(current, total) {
			console.log(`Прогресс: ${current}/${total}`)

			root.currentFile = current
			root.totalFiles = total

			if (ldrProgress.item) {
				var progress = (current / (total + 1)) * 100
				ldrProgress.item.progress = progress
				ldrProgress.item.text = `${current}/${total + 1}`
			}
		}
	}
    Platform.FolderDialog {//Диалог выбора папки для аудио
        id: folderDialogAudio
        title: "Выберите папку с аудиофайлами"
        folder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.MusicLocation)
        
        onAccepted: {
            var path = folderDialogAudio.folder.toString()
            //Убираем "file://" из начала пути
            path = path.replace(/^file:\/\//, "")
            settings.audioPath = path
            txtAudioPath.text = path
            console.log("✓ Аудио папка:", path)
        }
    }
    Platform.FolderDialog {//Диалог выбора папки для текстов
        id: folderDialogText
        title: "Выберите папку для сохранения результатов"
        folder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.DocumentsLocation)
        
        onAccepted: {
            var path = folderDialogText.folder.toString()
            path = path.replace(/^file:\/\//, "")
            settings.textPath = path
            txtTextPath.text = path
            console.log("✓ Текст папка:", path)
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
			
			text: qsTr("Остановить транскрибацию?")
			visible: false
			
			clrFona: "red"
			clrTexta: root.clrFona
			clrKnopki: root.clrFona
			clrBorder: root.clrFona
			
			tapKnopkaZakrit: root.tapZagolovokLevi
			tapKnopkaOk: root.tapZagolovokPravi
			
			onClickedOk: {
				transcriber.stop()
				stopDialog.visible = false
			}
			onClickedOtmena: {
				stopDialog.visible = false
			}
		}
    }
    Item {//Рабочая зона
        id: tmZona
        clip: true
		Image {//ЛОГОТИП
            id: imgLogo
            anchors.centerIn: tmZona
            width: 200
            height: 200
            source: "qrc:/resources/images/logo.png"
            fillMode: Image.PreserveAspectFit
            opacity: 0.0
            visible: false
            z: -1
            scale: 1.0
			/*
            Behavior on scale {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.InOutQuad
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
			*/
        }
        Flickable {
            id: flcZona
            anchors.fill: parent
            contentWidth: tmZona.width
            contentHeight: clmnContent.height
            clip: true
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            opacity: root.prozrachZona
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
            Column {
                id: clmnContent
                width: flcZona.width - scbScrollbar.width
                //spacing: root.ntCoff//Расстояние между элементами по вертикали.
                topPadding: root.ntCoff * 2
                bottomPadding: root.ntCoff * 2
                leftPadding: root.ntCoff * 2
                rightPadding: root.ntCoff * 2
                DCKnopkaOriginal {//Кнопка "Транскрибация"
                    id: btnTranscribe
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
                    text: "Путь к аудио файлам:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                Row {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    spacing: root.ntCoff
                    
                    TextField {
                        id: txtAudioPath
                        width: parent.width - btnAudioBrowse.width - parent.spacing
						height: root.ntHeight
						font.pixelSize: root.pixelHeight//Имперический размер шрифта.
                        placeholderText: "Путь к папке с аудиофайлами"
                        selectByMouse: true
                        color: root.clrTexta
            			opacity: root.prozrachZona
                        
                        background: Rectangle {
                            color: "white"
                            border.color: root.clrTexta
                            border.width: 1
                            radius: root.ntCoff / 2
                        }
                        
                        onTextChanged: {
                            settings.audioPath = text
                        }
                    }
                    
                    DCKnopkaOriginal {
                        id: btnAudioBrowse
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
                        id: txtTextPath
                        width: parent.width - btnTextBrowse.width - parent.spacing
						height: root.ntHeight
						font.pixelSize: root.pixelHeight//Имперический размер шрифта.
                        placeholderText: "Путь к папке для сохранения результатов"
                        selectByMouse: true
                        color: root.clrTexta
            			opacity: root.prozrachZona
                        
                        background: Rectangle {
                            color: "white"
                            border.color: root.clrTexta
                            border.width: 1
                            radius: root.ntCoff / 2
                        }
                        
                        onTextChanged: {
                            settings.textPath = text
                        }
                    }
                    
                    DCKnopkaOriginal {
                        id: btnTextBrowse
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
            }
        }
        DCScrollbar {//Скроллбар
            id: scbScrollbar
            flick: flcZona
            anchors.right: tmZona.right
            anchors.top: tmZona.top
            anchors.bottom: tmZona.bottom
            clrPolzunokOff: Qt.lighter(root.clrMenuFon, 1.3)
            clrPolzunokOn: root.clrTexta
            width: root.ntWidth * root.ntCoff
            radius: 1
            opacity: root.prozrachZona
            
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
            anchors.rightMargin: scbScrollbar.width
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
            onLoaded: {
                ldrProgress.item.ntWidth = root.ntWidth
                ldrProgress.item.ntCoff = root.ntCoff
                ldrProgress.item.clrProgress = root.clrTexta
                ldrProgress.item.clrTexta = "grey"
                ldrProgress.item.radius = root.ntCoff / 4
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
