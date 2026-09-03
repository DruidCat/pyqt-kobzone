import QtQuick
import QtQuick.Controls
import QtCore
import QtQuick.Dialogs
import DCButtons 1.0
import DCMethods 1.0
import DCSettings 1.0
//StrAnalizer - страница по анализу документов или текстов через ИИ.
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
    
    property int logoRazmer: 22//Размер Логотипа
    property string logoImya: "kobzone"//Имя логотипа в DCLogo
    property real rlProgress: 0
    property real rlLoader: 1
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
	DCMarkdown {//Подключаем конвертер Markdown
		id: dcMarkdown
	}	
	Connections {//CONNECTIONS для прогресса
		target: pyAnalyzer
		function onSigResultReady(result) {//Сигнал готовности результата анализа.
			resultArea.text = dcMarkdown.toHtml(result)//Конвертируем Markdown в HTML
			knopkaSohranit.enabled = (result !== "" && 
									result !== "Анализируется..." &&
									!result.startsWith("Ошибка:"))
		}
		function onSigAnalizSohranit(strPut) {//Сигнал о том, что файл сохранился.
			if (strPut.startsWith("[Ошибка")) {
				root.toolbar("Ошибка сохранения: " + strPut)
			} else {
				root.toolbar("Сохранено: " + strPut.split('/').pop())
				DCSettings.analizer_put_sohranit = strPut;//Сохраняем путь папки, у котороую сохранили результат
			}
		}
		function onSigChunkStarted(ntCurrent, ntTotal) {
			root.log(`Чанк ${ntCurrent}/${ntTotal} начал обрабатываться`)
			if (ldrProgress.item) {
				if (ntCurrent === 1) {//Настраиваем прогресс при первом чанке
					ldrProgress.total = ntTotal
					if (ntTotal === 1) {
						ldrProgress.item.text = "Финальный анализ..."
					} else {
						ldrProgress.item.text = `${ntCurrent}/${ntTotal + 1}`
					}
				} else if (ntTotal > 1) {
					ldrProgress.item.text = `${ntCurrent}/${ntTotal + 1}`
				}
			}
		}
		function onSigChunkFinished(ntCurrent, ntTotal) {//Сигнал окончания обработки Чанка.
			root.log(`Чанк ${ntCurrent}/${ntTotal} завершён`)
			if (ntTotal > 1) {//Только для множественных чанков
				//Прогресс обновляется после завершения чанка
				root.rlLoader = 100 / (ntTotal + 1)//+1 резервируем для финального анализа
				root.rlProgress = ntCurrent * root.rlLoader
				if (ldrProgress.item) {
					ldrProgress.item.progress = root.rlProgress
					ldrProgress.item.text = `${ntCurrent}/${ntTotal + 1}`//+1 резервируем для финального анали
				}
			}
		}
		function onSigAnalizFinalStart() {//Сигнал Начала финального анализа
			root.log("✓ Начался финальный анализ")
			if (ldrProgress.item) {//Всегда показываем "Финальный анализ..."
				ldrProgress.item.text = "Финальный анализ..."
				/*
				//Если чанков несколько — устанавливаем прогресс перед финалом
				var kolichestvo_chankov = fnKolichestvoChankov(txaContent.text)
				if (kolichestvo_chankov > 1 && root.rlProgress < 90) {
					//Доводим до ~90% перед финальным анализом
					root.rlProgress = 90
					ldrProgress.item.progress = 90
				}
				*/
			}
		}
		function onSigAnalizStart() {//Сигнал Начала анализа.
			root.log("✓ Анализ начался")
			root.rlProgress = 0
			tmrLogo.running = true//Запускаем анимацию логотипа и включаем политики кнопок.
			if (ldrProgress.item) {//Если существует объект, то...
				ldrProgress.item.text = "Подготовка..."//Устанавливаем прогресс в режим ожидания
				ldrProgress.item.progress = 0
			}
		}
		function onSigAnalizFinish() {//сигнал Анализ завершён. 
			root.toolbar(`Анализ завершён: ${txfPromt.text}`)
			tmrLogo.running = false//Останавливаем анимацию анализа и политики кнопок
		}	
		function onSigDocumentsLoaded(combinedText, filesCount) {//Сигнал загрузки документов (текст, кол-во)
			txaContent.text = combinedText//Обновление txaContent при загрузке файло
			root.toolbar(`Загружено файлов: ${filesCount}`)
		}
	}
	Component.onCompleted: {
        root.forceActiveFocus()
		pyAnalyzer.ustModelSettings(DCSettings.analizer_model_imya, DCSettings.analizer_max_context,
			DCSettings.analizer_temperatura, DCSettings.analizer_perekritie)//Передаём настройки в Python
    }
	Keys.onPressed: (event) => {//Обработка горячих клавиш
        if (event.modifiers & Qt.AltModifier) {
            if (event.key === Qt.Key_Left) {
                fnClickedNazad()//Функция закрытия страницы.
                event.accepted = true
                return
            } else if (event.key === Qt.Key_F || event.key === 1040) {
                fnClickedMenu()//Функция открытия настроек анализа документов.
                event.accepted = true
                return
            }
        }
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_S || event.key === 1067) {
                if (!menuMenu.visible && knopkaSohranit.enabled) {
                    fnClickedSohranit()//Функция сохранения результата анализа.
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
		//root.log(event.key)
    }
	FileDialog {//Диалог выбора нескольких файлов для загрузки
		id: dialogZagruzka
		title: "Выберите текстовые файлы для анализа"
		currentFolder: {//Используем сохранённый путь из реестра, или стандартную домашнюю папку
			if (DCSettings.analizer_put_text !== "") return "file://" + DCSettings.analizer_put_text
			else return StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
		}
		nameFilters: ["Текстовые файлы (*.txt)", "Все файлы (*)"]
		fileMode: FileDialog.OpenFiles//Множественный выбор файлов
		onAccepted: {
			fnUstMultipleDocuments(selectedFiles)//Загружаем файлы в функцию.
			var filePut = selectedFiles[0].toString()//Получаем путь для первого файла.
			filePut = fnUrlToLocalPath(filePut)//Используем кроссплатформенную функцию Убираем "file://" 
			var papkaPut = filePut.substring(0, filePut.lastIndexOf('/'));//Обрезаем имя файла по /
			DCSettings.analizer_put_text = papkaPut//Записываем в реестр имя папки в реестр.
		}
		onRejected: {

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
				root.toolbar("")//Очищаем перед запуском тулбар
                ldrProgress.active = true
                
                knopkaInfo.visible = false
                knopkaNastroiki.visible = false
                knopkaMenu.enabled = false
                knopkaNazad.enabled = false
                
                knopkaZagruzit.enabled = false
                knopkaAnaliz.enabled = false
                knopkaSohranit.enabled = false
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

			knopkaInfo.visible = true
			knopkaNastroiki.visible = true
			knopkaMenu.enabled = true
			knopkaNazad.enabled = true
			
			knopkaZagruzit.enabled = true
			knopkaAnaliz.enabled = txaContent.text.trim() !== ""
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
    function fnClickedZagruzka() {//Функция открывающая Файловый диалог загрузки файлов
		dialogZagruzka.open()
    }
	function fnUstMultipleDocuments(selectedFiles) {//Загрузка нескольких документов
		root.log("Загрузка документов: " + selectedFiles)
		var filePaths = []//Преобразуем список URL в массив путей
		for (var i = 0; i < selectedFiles.length; i++) {
			var vtFail = selectedFiles[i].toString()
			filePaths.push(vtFail)
		}
		pyAnalyzer.ustMultipleDocuments(filePaths)//Вызываем метод Python для загрузки файлов
	}
	function fnClickedOchistit() {//Функция очистки промта.
		txfPromt.text = ""//Очищаем промт.
	}
    function fnClickedAnaliz() {//Функция запускающая нейро анализ документов
        pyAnalyzer.startAnaliza(txaContent.text, txfPromt.text)
    }
    function fnClickedSohranit() {//Функция сохранения результата анализа.
        pyAnalyzer.sohranitAnaliz(DCSettings.analizer_put_sohranit)//Открываем Диалог в папке (путь из реестра).
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
            opacity: 0.9//ГЛАВНАЯ ПРОЗРАЧНОСТЬ!!!

			TapHandler {//Нажимаем на всю область
				onTapped: fnCloseMenuIfOpen()//Закрыть меню если оно открыто	
			}
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
                            fnClickedZagruzka()//Функция открывающая Файловый диалог загрузки файлов
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
                    id: rctContent
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    height: 180
                    color: "transparent"
                    border.color: root.clrTexta
                    border.width: 1
                    radius: root.ntCoff / 2
                    clip: true
                    
                    Flickable {
                        id: flcContent
                        anchors.fill: parent
                        anchors.margins: 5
                        anchors.rightMargin: scbContent.width + 5
                        contentWidth: width
                        contentHeight: txaContent.contentHeight
                        clip: true
                        interactive: true
                        boundsBehavior: Flickable.StopAtBounds
            			            
                        TextArea.flickable: TextArea {
                            id: txaContent
                            objectName: "txaContent"
                            placeholderText: "Загрузите файл или вставьте текст..."
                            wrapMode: TextArea.Wrap
                            selectByMouse: true
                            color: root.clrTexta
                            background: null
                            onTextChanged: pyAnalyzer.ustContentText(text)
							TapHandler {//Нажимаем на всю область
								onTapped: fnCloseMenuIfOpen()//Закрыть меню если оно открыто	
							}
                        }
                    }
                    DCScrollbar {
                        id: scbContent
                        flick: flcContent
                        anchors.right: rctContent.right
                        anchors.top: rctContent.top
                        anchors.bottom: rctContent.bottom
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
				Row {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    spacing: root.ntCoff
					TextField {
						id: txfPromt
						width: parent.width - parent.leftPadding
					   						- parent.rightPadding
											- knopkaOchistit.width//минус ширина кнопки
											- parent.spacing//минус расстояние Row
						height: knopkaOchistit.height
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
							if (txaContent.text.trim() !== "") {
								fnClickedAnaliz()//Функция запускающая нейро анализ документов
							}
						}
						onTextChanged: {
							pyAnalyzer.ustPromt(text)//Сохраняем промт при изменении
						}
						TapHandler {//Нажимаем на всю область
							onTapped: fnCloseMenuIfOpen()//Закрыть меню если оно открыто	
						}
					}	
					DCKnopkaZakrit {
						id: knopkaOchistit
						ntWidth: root.ntWidth
						ntCoff: root.ntCoff
						clrKnopki: root.clrTexta
						clrFona: root.clrFona
						onClicked: {
                        	if (!fnCloseMenuIfOpen()) fnClickedOchistit()//Функция очистки промта.
						}
					}
				}
                DCKnopkaOriginal {//Кнопка анализа
                    id: knopkaAnaliz
                    text: "🚀 Анализировать"
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
                    clrKnopki: "#2196F3"
                    clrTexta: root.clrFona
                    enabled: txaContent.text.trim() !== ""
					anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
                    onClicked: {
                        if (!fnCloseMenuIfOpen()) {
                            fnClickedAnaliz()//Функция запускающая нейро анализ документов
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
							TapHandler {//Нажимаем на всю область
								onTapped: fnCloseMenuIfOpen()//Закрыть меню если оно открыто	
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
                            fnClickedSohranit()//Функция сохранения результата анализа.
                        }
                    } 
                }
            }
        }
        DCScrollbar {//Скроллбар основной области
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
                    fnClickedZagruzka()//Функция открывающая Файловый диалог загрузки файлов
                } else if (ntNomer === 2) {
                    fnClickedAnaliz()//Функция запускающая нейро анализ документов
                } else if (ntNomer === 3) {
                    fnClickedSohranit()//Функция сохранения результата анализа.
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
