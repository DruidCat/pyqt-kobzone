import QtQuick
import QtQuick.Controls
import QtCore
import QtQuick.Dialogs
import DCButtons 1.0
import DCMethods 1.0

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
	//Массив кнопок для навигации
    property var knopkiMassiv: []//Массив кнопок, между которыми нужно листать.
    property int currentIndex: 0//Выбранная кнопка.
	//Модель
	property string strModel: dcReestr.analizer_model_imya//Имя модели ИИ
	property bool isLMStart: false;//true - LM Studio запущена и доступна в виде сервера.
	property string putLMStudio: dcReestr.analizer_lms_put//Путь к приложению LM Studio из реестра.
	//Настройки
	anchors.fill: parent
	focus: true
	//Сигналы
	signal clickedNazad()
	signal clickedInfo()
	signal toolbar(var strToolbar)
    signal log(var strLog)
	//Методы
	Component.onCompleted: {
        knopkiMassiv = [knopkaLMStart, knopkaLMPut, knopkaModeli]//Сюда добавляем id кнопок
		if(Qt.application.os !== "windows"){//TODO ЭТО ДЛЯ ОТЛАДКИ ПРОГРАММЫ, ЧТОБ БЫСТРЕЕ ЗАПУСКАЛАСЬ.
			pyModelManager.proverkaServera()//Проверяем сервер перед загрузкой моделей
			pyModelManager.zagruzitModeli()//Загружаем модели при открытии страницы
			if (dcReestr.analizer_lms_put !== "")//Передаём путь из настроек в Python
				pyLMStart.ustPut(dcReestr.analizer_lms_put)
		}
		root.forceActiveFocus()
	}
	DCSettings {//Объект настроек
        id: dcReestr
    }
	onStrModelChanged: {//Если Модель изменится, то...
        dcReestr.analizer_model_imya = root.strModel//Сохраняем в реестре имя Модели.
        pyModelManager.ustModel(root.strModel)//Отправляем в Python
        //Обновляем настройки анализатора
        let ltMaxContext = dcReestr.analizer_max_context
		let ltTemperatura = dcReestr.analizer_temperatura
        let ltPerekritie = dcReestr.analizer_perekritie
        pyAnalyzer.ustModelSettings(root.strModel, ltMaxContext, ltTemperatura, ltPerekritie)
    }
	onPutLMStudioChanged: {//Если путь к LM Studio изменился, то...
		if (root.putLMStudio !== ""){//Если он не пустой, то...
			pyLMStart.ustPut(root.putLMStudio)//Передаём его в логику Python
			console.log("AAAAA")
		}
	}
    Connections {//Обработчик загрузки моделей из Python
        target: pyModelManager

        function onSigModelsLoaded(models) {
            modelModels.clear()//Очищаем старую модель
            for (let i = 0; i < models.length; i++) {//Заполняем новыми данными
                modelModels.append({ spisok: models[i] })
            }
            let savedModel = dcReestr.analizer_model_imya//Устанавливаем текущий индекс

            if (savedModel === "" || savedModel === "(автовыбор модели)") {
                pvModels.currentIndex = 0//Первый элемент = автовыбор
            } else {
                for (let i = 0; i < models.length; i++) {//Ищем сохранённую модель в списке
                    if (models[i] === savedModel) {
                        pvModels.currentIndex = i
                        break
                    }
                }
            }
            root.log(`✓ Загружено моделей: ${models.length}`)
        }
		function onSigServerOk() {
			root.isLMStart = true//Запущена и доступна.
		}
        function onSigError(errorMsg) {
			root.isLMStart = false//Не доступна.
            root.log(`Ошибка: ${errorMsg}`)
        }
    }
	Connections {
		target: pyLMStart
		
		function onSigZapuschen() {
			root.log("✓ LM Studio запущен!")
			//Перепроверяем доступность и загружаем модели
			pyModelManager.proverkaServera()
			pyModelManager.zagruzitModeli()
		}
		function onSigOstanovlen() {
			root.log("✓ LM Studio остановлен")
			root.isLMStart = false
		}
		function onSigError(errorMsg) {
			root.log(`✗ ${errorMsg}`)
		}
		function onSigLog(logMsg) {
			root.log(logMsg)
		}
		function onSigProverkaStarted() {
			root.log("Ожидание запуска сервера (до 30 секунд)...")
		}
	}
	Keys.onPressed: (event) => {
		if (event.modifiers & Qt.AltModifier) {
			if (event.key === Qt.Key_Left) {
				fnClickedNazad()
				event.accepted = true
				return
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
				root.currentIndex--
                if (root.currentIndex < 0)
                    root.currentIndex = knopkiMassiv.length - 1
                
                fnScrollKnopok(false)
			}
			event.accepted = true
		} else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || event.key === 1054) {
			if (!menuMenu.visible) {
				root.currentIndex++
                if (root.currentIndex >= knopkiMassiv.length)
                    root.currentIndex = 0
                
                fnScrollKnopok(true)
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
		} else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            if (!menuMenu.visible) {//Enter работает только если меню закрыто
                fnClickedEnter()
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
	FileDialog {
		id: dialogLMPut
		title: qsTr("Выберите путь к LM Studio")
		nameFilters: {
			if(Qt.application.os === "windows") return ["Исполняемые файлы (*.exe)", "Все файлы (*)"]
			else if (Qt.application.os === "linux") return ["AppImage (*.AppImage)", "Все файлы (*)"]
			else if (Qt.application.os === "osx") return ["Приложения (*.app)", "Все файлы (*)"]
			return ["Все файлы (*)"];//Безопасный фоллбэк
		}
		currentFolder: {//Используем сохранённый путь из реестра, или стандартную домашнюю папку
			if (dcReestr.analizer_lms_put !== "") {
				var vrPut = dcReestr.analizer_lms_put
				vrPut = fnPathToUrl(vrPut)//Преобразуем сохранённый путь в URL
				return vrPut.substring(0, vrPut.lastIndexOf("/"));//Обрезаем имя файла.
			}
			else return StandardPaths.writableLocation(StandardPaths.HomeLocation)//Открываем домашнюю локацию
		}
		onAccepted: {
			var vrPut = fnUrlToLocalPath(selectedFile)//Используем кроссплатформенную функцию
			dcReestr.analizer_lms_put = vrPut
			if(knopkaLMStart.isStart){//Если путь к LM Studio выбран и была попытка старта, то...
				knopkaLMStart.isStart = false;//Сбрасываем флаг.
				pyLMStart.zapustit()//Запускаем LM Studio.
				root.toolbar("⏳ Запуск LM Studio...")
			}
		}
		onRejected: {//Если нажата кнопка отмены, то...
			knopkaLMStart.isStart = false;//Сбрасываем флаг.
		}
	}
	function fnClickedEnter() {//Функция обработки нажатия клавиши Enter
        if (root.currentIndex >= 0 && root.currentIndex < knopkiMassiv.length) {
            var vrKnopkaID = knopkiMassiv[root.currentIndex]
            
            if (vrKnopkaID && typeof vrKnopkaID.fnPress === "function" && 
                vrKnopkaID.visible && vrKnopkaID.enabled) {
                vrKnopkaID.fnPress()
            }
        }
    }
    function fnScrollKnopok(isPlus) {//Функция скроллина кнопок
        var knopkaID = knopkiMassiv[root.currentIndex]
        if (!knopkaID) {
            return
        }
        if (knopkaID.visible) {
            var knopkaTop = knopkaID.y
            var knopkaBottom = knopkaTop + knopkaID.height + root.ntWidth
            var visibleTop = flcZona.contentY
            var visibleBottom = visibleTop + flcZona.height
            
            if (knopkaTop < visibleTop)
                flcZona.contentY = knopkaTop
            else if (knopkaBottom > visibleBottom)
                flcZona.contentY = knopkaBottom - flcZona.height
        }
    }
	function fnClickedEscape() {//Функция нажатия на клавишу Escape
		if (menuMenu.visible) {
			menuMenu.visible = false
		} else {
			//Если меню закрыто, ничего не делаем (можно добавить другую логику)
		}
		if (pvModels.visible) {
			pvModels.visible = false
		}
    }
	function fnClickedNazad() {
		fnClickedEscape()//Функция нажатия на клавишу Escape
		root.clickedNazad()
	}
	function fnClickedInfo() {
		fnClickedEscape()//Функция нажатия на клавишу Escape
		root.clickedInfo()
	}
	function fnToggleMenu() {
		if (menuMenu.visible) 
			menuMenu.visible = false
		else {
			if (pvModels.visible) pvModels.visible = false
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
	function fnCloseKaruselIfOpen() {
		if (pvModels.visible) {
			pvModels.visible = false
			root.forceActiveFocus()//фокус root, чтоб hotkey работали.
			return true
		}
		return false
	}
	function fnClickedModel(){//Функция выбора Модели
		if(pvModels.visible){//Если видимый виджет, то...
			Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
				pvModels.visible = false//Делаем невидимым виджет
				root.forceActiveFocus()//фокус PathView, чтоб hotkey работали.
			})
		}
		else{//Если невидимый виджет, то...
			Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
				pvModels.visible = true//Делаем видимым виджет
				pvModels.karusel.forceActiveFocus()//фокус PathView, чтоб hotkey работали.
			})
		}
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
			TapHandler {//Нажимаем на всю область
				onTapped: {
					fnCloseMenuIfOpen()//Закрыть меню если оно открыто	
					if(!pvModels.jdi && !pvModels.pressed) fnCloseKaruselIfOpen()//Закрываем карусель pv....
				}
			}
			Column {
				id: clmnContent
				width: flcZona.width - dcScrollbar.width
				spacing: root.ntCoff / 2
				topPadding: root.ntCoff * 2
				bottomPadding: root.ntCoff * 2
				leftPadding: root.ntCoff * 2
				rightPadding: root.ntCoff * 2
				//ТУТ КОНТЕНТ НАСТРОЕК
				DCKnopkaOriginal {//Кнопка запуска/остановки LM Studio
					id: knopkaLMStart
					text: root.isLMStart ? qsTr("Остановить LM Studio") : qsTr("Запустить LM Studio")
					ntHeight: root.ntWidth
					ntCoff: root.ntCoff
					anchors.left: parent.left
					anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2
					anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 0) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					property bool isStart: false//true - попытка запуска LM Studio без заданного пути.
					function fnPress() {
						root.currentIndex = 0
						if(root.isLMStart){
							pyLMStart.ostanovit()
							root.toolbar("Остановка LM Studio...")
						}
						else{
							if (root.putLMStudio === "") {//Если путь не задан
								knopkaLMStart.isStart = true;//Попутка запустить LM Studio.
								dialogLMPut.open()//Функция выбора пути к LM Studio.
							}
							else{
								pyLMStart.zapustit()
								root.toolbar("⏳ Запуск LM Studio...")
							}
						}
					}
					onPressedChanged: {
						if (pressed) {
							if (!fnCloseMenuIfOpen()) {//Сначала закрываем меню если открыто
								if (pressed && !pvModels.pressed) fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {//Кнопка выбора пути LM Studio 
                    id: knopkaLMPut
                    text: {
                        let ltText = qsTr("Путь к LM Studio: ");//
						if (root.putLMStudio === "") ltText += qsTr("не задан")
						else ltText += root.putLMStudio
						return ltText;
                    }
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
					anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 1) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 1
						dialogLMPut.open()//Функция выбора пути к LM Studio.
					}
					onPressedChanged: {
						if (pressed) {
							if (!fnCloseMenuIfOpen()) {//Сначала закрываем меню если открыто
								if (pressed && !pvModels.pressed) fnPress()
							}
						}
					}	
                }
				DCKnopkaOriginal {//Кнопка выбора размера шрифта
                    id: knopkaModeli
                    text: {
                        let ltText = qsTr("модель ");//
						if (root.strModel === "" || root.strModel === "(автовыбор модели)") {
							ltText += qsTr("автовыбор")
						} else {
							// Показываем только последнюю часть имени (без пути)
							let parts = root.strModel.split("/")
							ltText += parts[parts.length - 1]
						}
						return ltText;
                    }
                    ntHeight: root.ntWidth
                    ntCoff: root.ntCoff
					anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2
                    anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 2) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 2
						fnClickedModel()//Функция выбора Модели.
					}
					onPressedChanged: {
						if (pressed) {
							if (!fnCloseMenuIfOpen()) {//Сначала закрываем меню если открыто
								if (pressed && !pvModels.pressed) fnPress()
							}
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
			Behavior on opacity {
				NumberAnimation {
					duration: 300
				}
			}
		}
		ListModel {//Модель с шриштами
            id: modelModels
			//Будет заполняться динамически из Python
        }
        DCPathView {
            id: pvModels
            visible: false
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            anchors.left: tmZona.left; anchors.right: tmZona.right; anchors.bottom: tmZona.bottom
            anchors.leftMargin: dcScrollbar.width; anchors.rightMargin: dcScrollbar.width
            clrFona: root.clrFona; clrTexta: root.clrMenuText; clrMenuFon: root.clrMenuFon
            modelData: modelModels
            onClicked: function(strModel) {
				Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
					pvModels.visible = false//Делаем невидимым виджет
					root.strModel = strModel//Сохраняем выбор
				})
            }
			onVisibleChanged: {//Если видимость поменялась, то...
				if(!visible) root.forceActiveFocus()//Если невидимый, то фокус на root, чтоб hotkey работали.
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
			imyaMenu: "settings"
			onClicked: function(ntNomer, strMenu) {
				menuMenu.visible = false
				if (ntNomer === 1) {
					fnClickedInfo()
				} else if (ntNomer === 2) {
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
			if (menuMenu.visible || pvModels.visible){
				menuMenu.visible = false
				pvModels.visible = false
			} else root.forceActiveFocus()
			root.forceActiveFocus()
		}
	}
}

