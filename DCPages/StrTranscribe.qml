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
    property real prozrachZona: 1.0

	//свойства для управления состоянием
	property bool isTranscribing: false
	property int currentFile: 0
	property int totalFiles: 0

    // Настройки
    anchors.fill: parent
    focus: true
    
    // Объект настроек
    DCSettings {
        id: settings
    }
    
    // Сигналы
    signal clickedNazad()
    signal clickedInfo()
    signal signalToolbar(var strToolbar)
    
    // Обработка горячих клавиш
    Keys.onPressed: (event) => {
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
		
		// Запускаем транскрибацию через Python бэкенд
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

	//Connections для транскрибера
	Connections {
		target: transcriber

		function onTranscriptionStarted() {
			console.log("✓ Транскрибация начата")
			root.isTranscribing = true
			root.prozrachZona = 0.5
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
		}

		function onTranscriptionFinished(success, message) {
			console.log("✓ Транскрибация завершена:", message)
			root.isTranscribing = false
			root.prozrachZona = 1.0

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
			})

			if (success) {
				txdZona.strCopy += "\n✅ Транскрибация успешно завершена!\n"
			} else {
				txdZona.strCopy += "\n❌ Ошибка: " + message + "\n"
			}
			txdZona.text = txdZona.strCopy
		}

		function onLogMessage(message) {
			// Добавляем сообщение в лог
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

    // Диалог выбора папки для аудио
    Platform.FolderDialog {
        id: folderDialogAudio
        title: "Выберите папку с аудиофайлами"
        folder: Platform.StandardPaths.writableLocation(Platform.StandardPaths.MusicLocation)
        
        onAccepted: {
            var path = folderDialogAudio.folder.toString()
            // Убираем "file://" из начала пути
            path = path.replace(/^file:\/\//, "")
            settings.audioPath = path
            txtAudioPath.text = path
            console.log("✓ Аудио папка:", path)
        }
    }
    
    // Диалог выбора папки для текстов
    Platform.FolderDialog {
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
    
    // Заголовок
    Item {
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
    
    // Рабочая зона
    Item {
        id: tmZona
        clip: true
        
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
                spacing: root.ntCoff * 2
                topPadding: root.ntCoff * 2
                bottomPadding: root.ntCoff * 2
                leftPadding: root.ntCoff * 2
                rightPadding: root.ntCoff * 2
                
                // Кнопка "Транскрибация"
                DCKnopkaOriginal {
                    id: btnTranscribe
                    text: "🎙️ Транскрибация"
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
                    clrKnopki: root.clrTexta    
                    clrTexta: root.clrFona
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 0
                    anchors.rightMargin: 0
                    
                    onClicked: {
                        if (!fnCloseMenuIfOpen()) {
                            fnClickedTranscribe()
                        }
                    }
                }
                
                // Путь к аудио
                Text {
                    text: "Путь к аудио протоколам:"
                    font.pixelSize: root.ntWidth * root.ntCoff
                    color: root.clrTexta
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                
                Row {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    spacing: root.ntCoff
                    
                    TextField {
                        id: txtAudioPath
                        width: parent.width - btnAudioBrowse.width - parent.spacing
                        placeholderText: "Путь к папке с аудиофайлами"
                        selectByMouse: true
                        color: root.clrTexta
                        
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
                
                // Путь сохранения результатов
                Text {
                    text: "Путь сохранения результатов:"
                    font.pixelSize: root.ntWidth * root.ntCoff
                    color: root.clrTexta
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                
                Row {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    spacing: root.ntCoff
                    
                    TextField {
                        id: txtTextPath
                        width: parent.width - btnTextBrowse.width - parent.spacing
                        placeholderText: "Путь к папке для сохранения результатов"
                        selectByMouse: true
                        color: root.clrTexta
                        
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
                
                // Прогресс транскрибации
                Text {
                    text: "Прогресс транскрибации:"
                    font.pixelSize: root.ntWidth * root.ntCoff
                    color: root.clrTexta
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
        
        // Скроллбар
        DCScrollbar {
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
        
        // Всплывающее меню DCMenu
        DCMenu {
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
                }
                if (ntNomer === 2) {
                    fnClickedPutAudio()
                }
                if (ntNomer === 3) {
                    fnClickedPutText()
                }
                if (ntNomer === 4) {
                    fnClickedMenu()
                }
                if (ntNomer === 5) {
                    fnClickedInfo()
                }
                if (ntNomer === 6) {
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
    
    // Тулбар
    Item {
        id: tmToolbar
        clip: true
        
        // LOADER для DCProgress
        Loader {
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
    
    // MouseArea для возврата фокуса
    MouseArea {
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
