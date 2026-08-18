import QtQuick
import QtQuick.Controls
import QtCore
import QtQuick.Dialogs
import DCButtons 1.0
import DCMethods 1.0
import DCSettings 1.0

Item {
    id: root
    //Свойства
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
    
    property int logoRazmer: 22
    property real rlProgress: 0
    property real rlLoader: 1
	//Настройки
    anchors.fill: parent
    focus: true
    //Сигналы
    signal clickedNazad()
	signal clickedSettings()
    signal clickedInfo()
    signal signalToolbar(var strToolbar)
    //Методы
	DCSettings {//Объект настроек
        id: dcReestr
    }
	DCMarkdown {//Подключаем конвертер Markdown
		id: dcMarkdown
	}
	Keys.onPressed: (event) => {//Обработка горячих клавиш
        if (event.modifiers & Qt.AltModifier) {
            if (event.key === Qt.Key_Left) {
                fnClickedNazad()//Функция закрытия страницы.
                event.accepted = true
                return
            } else if (event.key === Qt.Key_F) {
                fnClickedMenu()//Функция открытия настроек анализа документов.
                event.accepted = true
                return
            }
        }
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_S) {
                if (!menuMenu.visible && knopkaSohranit.enabled) {
                    fnClickedSave()//Функция сохранения результата анализа.
                }
                event.accepted = true
            }
        }
        if (event.key === Qt.Key_Escape) {
			fnClickedEscape()//Функция нажатия на клавишу Escape
			event.accepted = true
        } else if (event.key === Qt.Key_F1) {
            fnClickedInfo()//Функция открытия помощи.
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
	FileDialog {//Диалог выбора нескольких файлов для загрузки
		id: dialogZagruzka
		title: "Выберите текстовые файлы для анализа"
		currentFolder: {//Используем сохранённый путь из реестра, или стандартную домашнюю папку
			if (dcReestr.analizer_put_text !== "") return "file://" + dcReestr.analizer_put_text
			else return StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
		}
		nameFilters: ["Текстовые файлы (*.txt)", "Все файлы (*)"]
		fileMode: FileDialog.OpenFiles//Множественный выбор файлов
		onAccepted: {
			fnLoadMultipleDocuments(selectedFiles)//Загружаем файлы в функцию.
			var filePut = selectedFiles[0].toString()//Получаем путь для первого файла.
			filePut = filePut.replace(/^file:\/\//, "")//Убираем "file://" из начала пути
			var papkaPut = filePut.substring(0, filePut.lastIndexOf('/'));//Обрезаем имя файла по /
			dcReestr.analizer_put_text = papkaPut//Записываем в реестр имя папки в реестр.
		}
		onRejected: {
			console.log("Загрузка файлов отменена")
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
				root.signalToolbar("")//Очищаем перед запуском тулбар
                ldrProgress.active = true
                
                knopkaInfo.visible = false
                knopkaNastroiki.visible = false
                knopkaMenu.enabled = false
                knopkaNazad.enabled = false
                
                knopkaZagruzit.enabled = false
                knopkaAnaliz.enabled = false
                knopkaSohranit.enabled = false
            } else {
                imgLogo.scale = 1.0
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

			knopkaInfo.visible = true
			knopkaNastroiki.visible = true
			knopkaMenu.enabled = true
			knopkaNazad.enabled = true
			
			knopkaZagruzit.enabled = true
			knopkaAnaliz.enabled = contentArea.text.trim() !== ""
        }
	}
	Connections {//CONNECTIONS для прогресса
		target: analyzer
		function onAnalysisStarted() {//Запускаем нейро анализ документов.
			console.log("✓ Анализ начался")
			root.rlProgress = 0
			var estimated_chunks = fnEstimateChunks(contentArea.text)//Определяем количество чанков
			console.log("Примерное количество чанков:", estimated_chunks)
			tmrLogo.running = true//Запускаем анимацию логотипа и включаем политики кнопок.
			if (ldrProgress.item) {//Если существует объект, то...
				ldrProgress.total = estimated_chunks//Для Пересчёт скорости смещения полосы.
				if (estimated_chunks === 1)//Если один чанк, то...
					ldrProgress.item.text = "Финальный анализ..."//показываем текст "Финальный анализ..."
				else//Если несколько чанков, то...
					ldrProgress.item.text = `0/${estimated_chunks + 1}`//Для нескольких чанков показываем 0/N
			}
		}
		function onAnalysisFinished() {
			console.log("✓ Анализ завершён")
			tmrLogo.running = false
		}
		function onChunkStarted(ntCurrent, ntTotal) {
			console.log(`Чанк ${ntCurrent}/${ntTotal} начал обрабатываться`)
			if (ldrProgress.item && ntTotal > 1) {//Только для множественных чанков
				ldrProgress.item.text = `${ntCurrent}/${ntTotal + 1}`
			}
		}	
		function onChunkFinished(ntCurrent, ntTotal) {
			console.log(`Чанк ${ntCurrent}/${ntTotal} завершён`)
			if (ntTotal > 1) {//Только для множественных чанков
				// Прогресс обновляется после завершения чанка
				// +1 резервируем для финального анализа
				root.rlLoader = 100 / (ntTotal + 1)
				root.rlProgress = ntCurrent * root.rlLoader
				if (ldrProgress.item) {
					ldrProgress.item.progress = root.rlProgress
					ldrProgress.item.text = `${ntCurrent}/${ntTotal + 1}`
				}
			}
		}	
		function onFinalAnalysisStarted() {//Обработчик финального анализа
			console.log("✓ Начался финальный анализ")
			if (ldrProgress.item) {//Всегда показываем "Финальный анализ..."
				ldrProgress.item.text = "Финальный анализ..."
				// Если чанков несколько — устанавливаем прогресс перед финалом
				var estimated_chunks = fnEstimateChunks(contentArea.text)
				if (estimated_chunks > 1 && root.rlProgress < 90) {
					// Доводим до ~90% перед финальным анализом
					root.rlProgress = 90
					ldrProgress.item.progress = 90
				}
			}
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
		fnClickedEscape()//Функция нажатия на клавишу Escape
		root.clickedNazad()
	}
    function fnClickedMenu() {//Функция открытия настроек анализа документов.
		fnClickedEscape()//Функция нажатия на клавишу Escape
		root.clickedSettings()//Сигнал излучает открытие настроек.
    }
    function fnClickedInfo() {//Функция открытия помощи.
		fnClickedEscape()//Функция нажатия на клавишу Escape
        root.clickedInfo()
    }
    function fnClickedLoad() {//Функция открывающая Файловый диалог загрузки файлов
		dialogZagruzka.open()
    }
	function fnLoadMultipleDocuments(selectedFiles) {//Загрузка нескольких документов
		console.log("Загрузка документов:", selectedFiles)
		var filePaths = []//Преобразуем список URL в массив путей
		for (var i = 0; i < selectedFiles.length; i++) {
			var vtFail = selectedFiles[i].toString()
			vtFail = vtFail.replace(/^file:\/\//, "")//Убираем "file://"
			vtFail = decodeURIComponent(vtFail)//Декодируем URL (например, %3F → ?)
			filePaths.push(vtFail)
		}
		analyzer.loadMultipleDocuments(filePaths)//Вызываем метод Python для загрузки файлов
	}	
    function fnClickedAnalizer() {//Функция запускающая нейро анализ документов
		analyzer.setCurrentPrompt(promptField.text)//Сохраняем промт перед анализом
        analyzer.analyze(contentArea.text, promptField.text)
    }
    function fnClickedSave() {//Функция сохранения результата анализа.
        analyzer.saveResult()
    }
    function fnToggleMenu() {//Функция изменяет состояние всплывающего меню если открыто, закрывает и наоборот
        if (menuMenu.visible) menuMenu.visible = false
        else menuMenu.visible = true
    }
    function fnCloseMenuIfOpen() {//ЗАкрывает всплывающее меню, если оно открыто.
        if (menuMenu.visible) {
            menuMenu.visible = false
            return true
        }
        return false
    }
	function fnEstimateChunks(text) {//Функция приблизительного подсчёта количества чанков
		if (!text || text.trim() === "") return 0
		
		var max_tokens = 8000
		var chars_per_token = 4
		var chunk_size = (max_tokens * chars_per_token) / 2
		
		var estimated_chunks = Math.ceil(text.length / chunk_size)
		return estimated_chunks
	}
    Component.onCompleted: {
        root.forceActiveFocus()
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
            onClicked: fnClickedNazad()//Функция закрытия страницы.
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
                    fnClickedMenu()//Функция открытия настроек анализа документов.
                }
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
            opacity: 0.4
            visible: true
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
            opacity: 0.9//ГЛАВНАЯ ПРОЗРАЧНОСТЬ!!!
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
            Column {
                id: clmnContent
                width: flcZona.width - dcScrollbar.width
                spacing: root.ntCoff/2//Расстояние между элементами по вертикали.
                topPadding: root.ntCoff * 2
                bottomPadding: root.ntCoff * 2
                leftPadding: root.ntCoff * 2
                rightPadding: root.ntCoff * 2
                DCKnopkaOriginal {//Кнопка загрузки файла
                    id: knopkaZagruzit
                    text: "📁 Загрузить документы"
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
                            fnClickedLoad()//Функция открывающая Файловый диалог загрузки файлов
                        }
                    }
                }
                Text {//Содержимое файла
                    text: "Содержимое файла:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                Rectangle {
                    id: rctContentArea
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    height: 180
                    color: "transparent"
                    border.color: root.clrTexta
                    border.width: 1
                    radius: root.ntCoff / 2
                    clip: true
                    
                    Flickable {
                        id: flcContentArea
                        anchors.fill: parent
                        anchors.margins: 5
                        anchors.rightMargin: scbContentArea.width + 5
                        contentWidth: width
                        contentHeight: contentArea.contentHeight
                        clip: true
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
                        
                        TextArea.flickable: TextArea {
                            id: contentArea
                            objectName: "contentArea"
                            placeholderText: "Загрузите файл или вставьте текст..."
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            color: root.clrTexta
                            background: null
                            
                            onTextChanged: analyzer.setTextContent(text)
                        }
                    }
                    DCScrollbar {
                        id: scbContentArea
                        flick: flcContentArea
                        anchors.right: rctContentArea.right
                        anchors.top: rctContentArea.top
                        anchors.bottom: rctContentArea.bottom
                        anchors.margins: 5
                        clrPolzunokOff: Qt.lighter(root.clrMenuFon, 1.3)
                        clrPolzunokOn: root.clrTexta
                        width: root.ntWidth * root.ntCoff
                        radius: 1
                    }
                }
                Text {//Промт для модели
                    text: "Промт для модели:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
				TextField {
					id: promptField
					width: parent.width - parent.leftPadding - parent.rightPadding
					placeholderText: "Проанализируй этот текст и выдели основные темы"
					selectByMouse: true
					color: root.clrTexta
					background: Rectangle {
						color: "transparent"
						border.color: root.clrTexta
						border.width: 1
						radius: root.ntCoff / 2
					}
					Keys.onReturnPressed: {
						if (contentArea.text.trim() !== "") {
							analyzer.analyze(contentArea.text, promptField.text)
						}
					}
					onTextChanged: {
						analyzer.setCurrentPrompt(text)//Сохраняем промт при изменении
					}
				}	
                DCKnopkaOriginal {//Кнопка анализа
                    id: knopkaAnaliz
                    text: "🚀 Анализировать"
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
                    clrKnopki: "#2196F3"
                    clrTexta: root.clrFona
                    enabled: contentArea.text.trim() !== ""
					anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
                    onClicked: {
                        if (!fnCloseMenuIfOpen()) {
                            fnClickedAnalizer()//Функция запускающая нейро анализ документов
                        }
                    }
                }
                Text {//Результат
                    text: "Результат:"
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                Rectangle {
                    id: rctResultArea
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    height: 300
                    color: "transparent"
                    border.color: root.clrTexta
                    border.width: 1
                    radius: root.ntCoff / 2
                    clip: true
                    Flickable {
                        id: flcResultArea
                        anchors.fill: parent
                        anchors.margins: 5
                        anchors.rightMargin: scbResultArea.width + 5
                        contentWidth: width
                        contentHeight: resultArea.contentHeight
                        clip: true
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
                        TextArea.flickable: TextArea {//TextArea.flickable на Text с HTML
                            id: resultArea
                            readOnly: true
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            placeholderText: "Результат анализа появится здесь..."
                            color: root.clrTexta
							background: null
							textFormat: TextEdit.RichText//ВКЛЮЧАЕМ HTML
                            Connections {
                                target: analyzer
                                function onResultReady(result) {
                                    resultArea.text = dcMarkdown.toHtml(result)//Конвертируем Markdown в HTML
                                    knopkaSohranit.enabled = (result !== "" && 
                                                            result !== "Анализируется..." &&
                                                            !result.startsWith("Ошибка:"))
                                }
								function onDocumentsLoaded(combinedText, filesCount) {
									contentArea.text = combinedText//Обновление contentArea при загрузке файло
									console.log(`✓ Загружено ${filesCount} файлов в contentArea`)
									root.signalToolbar(`Загружено файлов: ${filesCount}`)
								}
                            }
                        }
                    }
                    DCScrollbar {
                        id: scbResultArea
                        flick: flcResultArea
                        anchors.right: rctResultArea.right
                        anchors.top: rctResultArea.top
                        anchors.bottom: rctResultArea.bottom
                        anchors.margins: 5
                        clrPolzunokOff: Qt.lighter(root.clrMenuFon, 1.3)
                        clrPolzunokOn: root.clrTexta
                        width: root.ntWidth * root.ntCoff
                        radius: 1
                    }
                }
                DCKnopkaOriginal {//Кнопка сохранения результата
                    id: knopkaSohranit
                    text: "💾 Сохранить результат"
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
                    clrKnopki: "#4CAF50"
                    clrTexta: root.clrFona
                    enabled: false
					anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
                    onClicked: {
                        if (!fnCloseMenuIfOpen()) {
                            fnClickedSave()//Функция сохранения результата анализа.
                        }
                    }
                    Connections {
                        target: analyzer
                        function onFileSaved(path) {
                            if (path.startsWith("[Ошибка")) {
                                console.log("Ошибка сохранения:", path)
                            } else {
                                console.log("✓ Файл сохранён:", path)
                                root.signalToolbar("Сохранено: " + path.split('/').pop())
                            }
                        }
                    }
                }
            }
        }
        DCScrollbar {// Скроллбар основной области
            id: dcScrollbar
            flick: flcZona
            anchors.right: tmZona.right
            anchors.top: tmZona.top
            anchors.bottom: tmZona.bottom
            clrPolzunokOff: Qt.lighter(root.clrMenuFon, 1.3)
            clrPolzunokOn: root.clrTexta
            width: root.ntWidth * root.ntCoff
            radius: 1
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
            imyaMenu: "analizer"
            onClicked: function(ntNomer, strMenu) {
                menuMenu.visible = false
                if (ntNomer === 1) {
                    fnClickedLoad()//Функция открывающая Файловый диалог загрузки файлов
                } else if (ntNomer === 2) {
                    fnClickedAnalizer()//Функция запускающая нейро анализ документов
                } else if (ntNomer === 3) {
                    fnClickedSave()//Функция сохранения результата анализа.
                } else if (ntNomer === 4) {
                    fnClickedMenu()//Функция открытия настроек анализа документов.
                } else if (ntNomer === 5) {
                    fnClickedInfo()//Функция открытия помощи.
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
                    fnClickedInfo()//Функция открытия помощи.
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
