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
	property color clrVnimanie: "red"
	
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
	property bool isLMStart: false;//true - LM Studio запущена и доступна в виде сервера.
	property string putLMStudio: DCSettings.analizer_lms_put//Путь к приложению LM Studio из реестра.
	property string strModel: DCSettings.analizer_model_imya//Имя модели ИИ
	property real rlTemperatura: DCSettings.analizer_temperatura//Температура ИИ
	property int maxContext: DCSettings.analizer_max_context//Максимальное количество токенов
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
        knopkiMassiv = [knopkaLMStart, knopkaLMStop, knopkaLMPut, knopkaModeli, knopkaTemperatura, knopkaContext]
		if (DCSettings.analizer_lms_put !== "")//Передаём путь из настроек в Python
			pyLMStudio.ustPut(DCSettings.analizer_lms_put)
		root.forceActiveFocus()
	}
	onStrModelChanged: {//Если Модель изменится, то...
        pyLMStudio.ustModel(root.strModel)//Отправляем в Python
        //Обновляем настройки анализатора
        let ltMaxContext = DCSettings.analizer_max_context
		let ltTemperatura = DCSettings.analizer_temperatura
        let ltPerekritie = DCSettings.analizer_perekritie
        pyAnalyzer.ustModelSettings(root.strModel, ltMaxContext, ltTemperatura, ltPerekritie)
	}
	onRlTemperaturaChanged: {	
        //Обновляем настройки анализатора
        let ltMaxContext = DCSettings.analizer_max_context
		let ltTemperatura = DCSettings.analizer_temperatura
        let ltPerekritie = DCSettings.analizer_perekritie
        pyAnalyzer.ustModelSettings(root.strModel, ltMaxContext, ltTemperatura, ltPerekritie)
	}
	onMaxContextChanged: {
        //Обновляем настройки анализатора
		let ltMaxContext = DCSettings.analizer_max_context
		let ltTemperatura = DCSettings.analizer_temperatura
        let ltPerekritie = DCSettings.analizer_perekritie
        pyAnalyzer.ustModelSettings(root.strModel, ltMaxContext, ltTemperatura, ltPerekritie)
	}
	onPutLMStudioChanged: {//Если путь к LM Studio изменился, то...
		if (root.putLMStudio !== ""){//Если он не пустой, то...
			pyLMStudio.ustPut(root.putLMStudio)//Передаём его в логику Python
		}
	}
    Connections {//Обработчик загрузки моделей из Python
        target: pyLMStudio

        function onSigModelsLoaded(models) {
            modelModels.clear()//Очищаем старую модель
            for (let i = 0; i < models.length; i++) {//Заполняем новыми данными
                modelModels.append({ spisok: models[i] })
            }
            let savedModel = DCSettings.analizer_model_imya//Устанавливаем текущий индекс

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
            root.log(`Загружено моделей: ${models.length}`)
        }
		function onSigLMSProverkaOK() {
			root.isLMStart = true//Запущена и доступна.
		}
        function onSigError(ntError, errorMsg) {
			root.isLMStart = false//Не доступна.
            root.log(`Ошибка ${ntError}: ${errorMsg}`)
        }
		//0 - Ошибка HTTP при запросе списка моделей (сервер ответил кодом, отличным от 200).
		//1 - Ошибка сетевого подключения к LM Studio (сервер недоступен или не запущен).
		//2 - Неизвестная критическая ошибка при парсинге или загрузке списка моделей.
		//3 - Не удалось найти исполняемый файл LM Studio (требуется указать путь вручную в настройках).
		//4 - Ошибка при инициализации процесса запуска (сбой до или во время создания потока).
		//5 - Ошибка при попытке принудительной остановки процесса LM Studio (нет прав или процесс уже мертв).
		//6 - Сервер LM Studio не отвечает на прямой запрос проверки статуса (метод proverkaServera).
		//7 - Ошибка системного запуска процесса (сбой subprocess.Popen в фоновом потоке).
		//8 - Превышено время ожидания запуска (сервер не стал доступен после 10 попыток по 3 секунды).
		function onSigZapuschen() {
			root.toolbar("LM Studio запущен!")
			pyLMStudio.poluchitStatusServera()	
		}
		function onSigOstanovlen() {
			root.toolbar("LM Studio остановлен")
			root.isLMStart = false
			knopkaLMStop.isPerehodniProces = false
		}
		function onSigLog(logMsg) {//Обработка сигнала сообщений из Класса
			root.log(logMsg)
		}
		function onSigStarted() {//Обработка сигнала старта LM Studio
			knopkaLMStart.isPerehodniProces = true;//Запуск LM Studio.
		}
		function onSigServerStatus(blStatus) {
			if(blStatus){
				pyLMStudio.zagruzitModeli()//загружаем модели
				knopkaLMStart.isPerehodniProces = false
			} else {
			   	pyLMStudio.zapustitServer()
			}
		}
		function onSigServerZapuschen() {
			root.toolbar("✓ Сервер LM Studio готов")
			root.isLMStart = true
			pyLMStudio.zagruzitModeli()//Загружаем модели после запуска сервера
		}

		function onSigServerOstanovlen() {
			root.toolbar("Сервер остановлен")
			root.isLMStart = false
		}

		function onSigServerError(errorMsg) {
			root.toolbar(errorMsg)
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
			if (DCSettings.analizer_lms_put !== "") {
				var vrPut = DCSettings.analizer_lms_put
				vrPut = fnPathToUrl(vrPut)//Преобразуем сохранённый путь в URL
				return vrPut.substring(0, vrPut.lastIndexOf("/"));//Обрезаем имя файла.
			}
			else return StandardPaths.writableLocation(StandardPaths.HomeLocation)//Открываем домашнюю локацию
		}
		onAccepted: {
			var vrPut = fnUrlToLocalPath(selectedFile)//Используем кроссплатформенную функцию
			DCSettings.analizer_lms_put = vrPut
			if(knopkaLMStart.isStartBezPuti){//Если путь к LM Studio выбран и была попытка старта, то...
				knopkaLMStart.isStartBezPuti = false;//Сбрасываем флаг.
				pyLMStudio.zapustit()//Запускаем LM Studio.
				root.toolbar("⏳ Запуск LM Studio...")
			}
			if(knopkaLMStop.isStopBezPuti){//Если путь к LM Studio выбран и была попытка остановки, то...
				knopkaLMStop.isStopBezPuti = false;//Сбрасываем флаг.
				pyLMStudio.ostanovit()//Останавливаем LM Studio.
				root.toolbar("Остановка LM Studio...")
			}
		}
		onRejected: {//Если нажата кнопка отмены, то...
			knopkaLMStart.isStartBezPuti = false;//Сбрасываем флаг.
			knopkaLMStop.isStopBezPuti = false;//Сбрасываем флаг.
			knopkaLMStart.isPerehodniProces = false//Деактивируем переходный процесс.
			knopkaLMStop.isPerehodniProces = false//Деактивируем переходный процесс.
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
		}
		if (pvModels.visible) {
			pvModels.visible = false
		}
		if (pvTemperatura.visible) {
			pvTemperatura.visible = false
		}
		txnZagolovok.visible = false//Делаем невидимым ввот чисел
    }
	function fnClickedNazad() {
		fnClickedEscape()//Функция нажатия на клавишу Escape
		root.clickedNazad()
	}
	function fnClickedZakrit(){//Функция обрабатывающая кнопку Закрыть.
		txnZagolovok.visible = false//Делаем невидимым ввот чисел
	}
	function fnClickedOk(){//Нажимаем на Ок(Сохранить)
		let ltContext = Number(txnZagolovok.text)//Явно приобразовываем в число.
		let ltResult = Math.round(ltContext / 64) * 64;//Получаем число кратное 64.
		DCSettings.analizer_max_context = ltResult//Сохраняем в реестре значение.
		txnZagolovok.visible = false//Делаем невидимым ввот чисел
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
			if (pvTemperatura.visible) pvTemperatura.visible = false
			if (txnZagolovok.visible) txnZagolovok.visible = false
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
	function fnCloseModelsIfOpen() {
		if (pvModels.visible) {
			pvModels.visible = false
			root.forceActiveFocus()//фокус root, чтоб hotkey работали.
			return true
		}
		return false
	}
	function fnCloseTemperaturaIfOpen(){
		if (pvTemperatura.visible) {
			pvTemperatura.visible = false
			root.forceActiveFocus()//фокус root, чтоб hotkey работали.
			return true
		}
		return false
	}
	function fnCloseContextIfOpen() {
		if (txnZagolovok.visible) {
			txnZagolovok.visible = false
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
				pyLMStudio.poluchitStatusServera()	
				//pyLMStudio.proverkaServera()//Перепроверяем доступность
				pyLMStudio.zagruzitModeli()//загружаем модели
				pvModels.visible = true//Делаем видимым виджет
				pvModels.karusel.forceActiveFocus()//фокус PathView, чтоб hotkey работали.
			})
		}
	}
	function fnClickedTemperatura(){//Функция выбора Температуры ИИ
		if(pvTemperatura.visible){//Если видимый виджет, то...
			Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
				pvTemperatura.visible = false//Делаем невидимым виджет
				root.forceActiveFocus()//фокус PathView, чтоб hotkey работали.
			})
		}
		else{//Если невидимый виджет, то...
			Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
				pvTemperatura.visible = true//Делаем видимым виджет
				pvTemperatura.karusel.forceActiveFocus()//фокус PathView, чтоб hotkey работали.
			})
		}
	}
	function fnClickedContext(){//Функция выбора максимального контекста
		txnZagolovok.visible = !txnZagolovok.visible
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
		DCKnopkaZakrit {
            id: knopkaZakrit
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            visible: false
            anchors.verticalCenter: tmZagolovok.verticalCenter
            anchors.left: tmZagolovok.left
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff
            tapWidth: tapHeight*root.tapZagolovokLevi
            onClicked: fnClickedZakrit();//Функция обрабатывающая кнопку Закрыть.
        }
		DCKnopkaOk {
            id: knopkaOk
			ntWidth: root.ntWidth
			ntCoff: root.ntCoff
			visible: false
			anchors.verticalCenter: tmZagolovok.verticalCenter
			anchors.right: tmZagolovok.right
			clrKnopki: root.clrTexta
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff
            tapWidth: tapHeight*root.tapZagolovokLevi
            onClicked: fnClickedOk();//Нажимаем на Ок(Сохранить)	
		}
		Item {
            id: tmTextInput
			anchors.top: tmZagolovok.top
			anchors.bottom: tmZagolovok.bottom
			anchors.left: knopkaZakrit.right
			anchors.right: knopkaOk.left
            anchors.topMargin: root.ntCoff/4
            anchors.bottomMargin: root.ntCoff/4
            anchors.leftMargin: root.ntCoff/2
            anchors.rightMargin: root.ntCoff/2
			DCTextInput {
				id: txnZagolovok
				ntWidth: root.ntWidth
				ntCoff: root.ntCoff
				anchors.fill: tmTextInput
				visible: false
				isNumber: true//Вводим только цифры
				clrTexta: root.clrTexta; clrFona: root.clrMenuFon
				radius: root.ntCoff/2
				//textInput.font.capitalization: Font.AllUppercase//Отображает текст весь с заглавных букв.
				//textInput.inputMethodHints: Qt.ImhUppercaseOnly//Буквы в виртуальной клавиатуре заглавные
				textInput.maximumLength: 6//Ограницение по вводу максимальны токенов для локальной модели
				onSgnDebug: function (strDebug) { root.toolbar(strDebug) }//Ошибка из виджета в программу.
				onVisibleChanged: {//Если видимость DCTextInput изменился, то...
					if(txnZagolovok.visible){//Если DCTextInput видим, то...
						knopkaNazad.visible = false;//Конопка Назад Невидимая.
						knopkaZakrit.visible = true;//Кнопка закрыть Видимая
						knopkaOk.visible = true;//Кнопка Ок Видимая.
						text = DCSettings.analizer_max_context//Показываем значение максимального контекста
					}
					else{//Если DCTextInput не видим, то...
						knopkaNazad.visible = true;//Конопка Информация Видимая.
						knopkaZakrit.visible = false;//Кнопка закрыть Невидимая
						knopkaOk.visible = false;//Кнопка Ок Невидимая.
						txnZagolovok.text = "";//Текст обнуляем вводимый.
						root.forceActiveFocus()//Фокус на главной странице, чтоб горячие клавиши работали.
					}
				}
				onClickedEnter: {//слот нажатия кнопки Enter.
					if(knopkaOk.visible) fnClickedOk();//Функция сохранения данных.
				}
				onClickedEscape: {
					if(knopkaZakrit.visible) fnClickedZakrit()//Функция закрытия виджета
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
					if(!knopkaContext.pressedTmr550) fnCloseContextIfOpen()//Закрываем контекст максимальный
					if(!pvModels.jdi && !pvModels.pressed) fnCloseModelsIfOpen()//Закрываем карусель pv....
					if(!pvTemperatura.jdi && !pvTemperatura.pressed) fnCloseTemperaturaIfOpen()//Закрываем
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
					text: qsTr("запустить LM Studio")
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 0) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					enabled: !isPerehodniProces//Делаем неактивной кнопку, если переходный процесс.
					property bool isStartBezPuti: false//true - попытка запуска LM Studio без заданного пути.
					property bool isPerehodniProces: false//true-когда запуск или становка LM Studio началась
					function fnPress() {
						root.currentIndex = 0
						knopkaLMStart.isPerehodniProces = true//Активируем переходный процесс.
						if (root.putLMStudio === "") {//Если путь не задан
							knopkaLMStart.isStartBezPuti = true;//Попутка запустить LM Studio.
							dialogLMPut.open()//Функция выбора пути к LM Studio.
						}
						else{
							pyLMStudio.zapustit()
							root.toolbar("⏳ Запуск LM Studio...")
						}
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseContextIfOpen()) {//Сначала закрываем меню
								if (pressed && !pvModels.pressed && !pvTemperatura.pressed) fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {//Кнопка остановки LM Studio
					id: knopkaLMStop
					text: qsTr("остановить LM Studio")
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 1) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					enabled: !isPerehodniProces//Делаем неактивной кнопку, если переходный процесс.
					property bool isStopBezPuti: false//true - попытка запуска LM Studio без заданного пути.
					property bool isPerehodniProces: false//true-когда запуск или становка LM Studio началась
					function fnPress() {
						root.currentIndex = 1
						
			   			pyLMStudio.zapustitServer()
						/*
						knopkaLMStop.isPerehodniProces = true//Активируем переходный процесс.
						if (root.putLMStudio === "") {//Если путь не задан
							knopkaLMStop.isStopBezPuti = true;//Попытка остановить LM Studio.
							dialogLMPut.open()//Функция выбора пути к LM Studio.
						}
						else{
							pyLMStudio.ostanovit()
							root.toolbar("Остановка LM Studio...")
						}
						*/
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseContextIfOpen()) {//Сначала закрываем меню если открыто
								if (pressed && !pvModels.pressed && !pvTemperatura.pressed) fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {//Кнопка выбора пути LM Studio 
                    id: knopkaLMPut
                    text: {
                        let ltText = qsTr("путь к LM Studio: ");//
						if (root.putLMStudio === "") ltText += qsTr("не задан")
						else ltText += root.putLMStudio
						return ltText;
                    }
                    ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 2) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 2
						dialogLMPut.open()//Функция выбора пути к LM Studio.
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseContextIfOpen()) {//Сначала закрываем меню если открыто
								if (pressed && !pvModels.pressed && !pvTemperatura.pressed) fnPress()
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
                    ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					enabled: !knopkaLMStart.isPerehodniProces
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 3) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 3
						fnClickedModel()//Функция выбора Модели.
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseContextIfOpen()) {//Сначала закрываем меню если открыто
								if (pressed && !pvModels.pressed && !pvTemperatura.pressed)fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {//Кнопка выбора Температуры ИИ
                    id: knopkaTemperatura
                    text: {
                        let ltText = qsTr("температура ");//
						ltText += root.rlTemperatura//Добавляем в строчку температуру из параметра
                        pvTemperatura.currentIndex = root.rlTemperatura*10//Выставляем в карусели нужную Темп.
						return ltText;
                    }
                    ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 4) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 4
						fnClickedTemperatura()//Функция выбора Температуры ИИ
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseContextIfOpen()) {//Сначала закрываем меню если открыто
								if (pressed && !pvModels.pressed && !pvTemperatura.pressed) fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {//Кнопка выбора максимального количества токенов
                    id: knopkaContext
                    text: {
                        let ltText = qsTr("максимальный контекст ");//
						ltText += root.maxContext//Добавляем в строчку значения максимального контекста.
						return ltText;
                    }
                    ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 5) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 5
						fnClickedContext()//Функция выбора максимального контекста
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseContextIfOpen()) {//Сначала закрываем меню если открыто
								if (pressed && !pvModels.pressed && !pvTemperatura.pressed) fnPress()
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
					DCSettings.analizer_model_imya = strModel//Сохраняем в Реестре
				})
            }
			onVisibleChanged: {//Если видимость поменялась, то...
				if(!visible) root.forceActiveFocus()//Если невидимый, то фокус на root, чтоб hotkey работали.
			}
        }
		ListModel {//Модель с температурами для ИИ
		id: modelTemperatura
            ListElement { spisok: 0 }
            ListElement { spisok: 0.1 }
            ListElement { spisok: 0.2 }
            ListElement { spisok: 0.3 }
            ListElement { spisok: 0.4 }
            ListElement { spisok: 0.5 }
            ListElement { spisok: 0.6 }
            ListElement { spisok: 0.7 }
            ListElement { spisok: 0.8 }
            ListElement { spisok: 0.9 }
            ListElement { spisok: 1 }
        }
		DCPathView {
            id: pvTemperatura
            visible: false
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            anchors.left: tmZona.left; anchors.right: tmZona.right; anchors.bottom: tmZona.bottom
            anchors.leftMargin: dcScrollbar.width; anchors.rightMargin: dcScrollbar.width
            clrFona: root.clrFona; clrTexta: root.clrMenuText; clrMenuFon: root.clrMenuFon
            modelData: modelTemperatura
            onClicked: function(strTemperatura) {
				Qt.callLater(function(){//пауза, иначе не сработает фокус и pvTemperatura. ВАЖНО!!!
					pvTemperatura.visible = false//Делаем невидимым виджет
					root.rlTemperatura = strTemperatura//Приравнываем значение полученное
					DCSettings.analizer_temperatura = root.rlTemperatura//Сохраняем в реестре температуру ИИ.
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
				if (!fnCloseMenuIfOpen() && !fnCloseContextIfOpen()) {
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
			if (menuMenu.visible || pvModels.visible || pvTemperatura.visible || txnZagolovok.visible){
				menuMenu.visible = false
				pvModels.visible = false
				pvTemperatura.visible = false
				txnZagolovok.visible = false
			} else root.forceActiveFocus()
			root.forceActiveFocus()
		}
	}
}

