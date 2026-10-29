import QtQuick
import QtQuick.Controls
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
	property bool isMobile: false//true - мобильное устройство.
	property string strStudioImya: "LM Studio"//LM Studio приложение по умолчанию, может быть Bionic.
	property string __strProgress: ""//строка, которая будет в строке загрузки
	//Массив кнопок для навигации
    property var knopkiMassiv: []//Массив кнопок, между которыми нужно листать.
    property int currentIndex: 0//Выбранная кнопка.
	//Модель
	property string putLMStudio: DCSettings.studio_lms_put//Путь к приложению Studio из реестра.
	property string putCLI: DCSettings.studio_cli_put//Путь к cli lms Studio из реестра.
	property string serverURL: DCSettings.studio_server_url//URL Сервера Studio
	property string strModel: DCSettings.studio_model_imya//Имя модели ИИ
	property string strModelNoName: ""//Получаем имя модели ОТСУТСТВУЕТ.
	property bool isMmprojMulti: DCSettings.studio_mmproj_multi//режим мультимодальности имеется/не имеется
	property bool isMmprojStatus: DCSettings.studio_mmproj_status//режим мультимодальности включен/выключен
	property string strSandbox: DCSettings.studio_sandbox//имя программы, которая запускает в песочнице
	property bool __isMacOS: false//true - запуск на MacOS
	property bool __isModelNoName: false//true - выбрана модель MODEL_NO_NAME, чтоб её выгрузить.
	property bool __isMmprojOn: false//true - запущен режим смены статуса мультимодальности.
	property int maxContext: DCSettings.studio_max_context//Максимальное количество токенов
	property bool isStudioOn: false//true - Studio запущена.
	property bool isServerOn: false//true - сервер lms запущена на стороне LM Studio или Bionic.
	property int gpuOffload: DCSettings.studio_gpu_offload
	property bool isModelStart: false//true - первая иннициализация уже была
	property bool isContextStart: false//true - первая иннициализация уже была
	property bool isGpuOffloadStart: false//true - первая иннициализация уже была
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
		root.strModelNoName = pyLM.polModelNoName()//Получаем имя модели ОТСУТСТВУЕТ.
		fnModelEnabled()//Функция управляет политикой кнопок Temperatura, Context, GPU
		knopkiMassiv = [knopkaLMStart, knopkaLMStop, knopkaLMPut, knopkaCLIPut, knopkaServerURL, knopkaSandbox,
						knopkaModeli, knopkaMmproj, knopkaContext, knopkaGPU]
		
		if (DCSettings.studio_lms_put !== "")//Передаём путь из настроек в Python
			pyLM.ustPutStudio(DCSettings.studio_lms_put)
		if (DCSettings.studio_cli_put !== "")
    		pyLM.ustPutCLI(DCSettings.studio_cli_put)
		pyLM.ustSandbox(root.strSandbox)//передать начальное значение
		if (Qt.platform.os === "osx")__isMacOS = true;//Запуск на macOS
		if (__isMacOS || putLMStudio === "" || putCLI === "")knopkaSandbox.enabled = false//не активная кнопка
		else knopkaSandbox.enabled = true//активная кнопка.
		root.forceActiveFocus()	
	}
	onServerURLChanged: {
		pyLM.ustServerURL(serverURL)//Загрузка при иннициации приложения и при изменении значения.
	}
	onStrSandboxChanged: {
		pyLM.ustSandbox(root.strSandbox)
	}
	onStrModelChanged: {//Если Модель изменится, то...
		fnModelEnabled()//Функция управляет политикой кнопок Temperatura, Context, GPU
		if (isModelStart)//Первую иннициализацию не обрабатываем, когда данные читаются из реестра
			fnUstParametri()//Устанавливаем параметры root.strModel, ltMaxContext, ltTemperatura, ltGPU
		isModelStart = true
	}
	onMaxContextChanged: {
		if (isContextStart)//Первую иннициализацию не обрабатываем, когда данные читаются из реестра
			fnUstParametri()//Устанавливаем параметры root.strModel, ltMaxContext, ltTemperatura, ltGPU
		isContextStart = true
	}
	onGpuOffloadChanged: {
		if (isGpuOffloadStart)//Первую иннициализацию не обрабатываем, когда данные читаются из реестра
			fnUstParametri()//Устанавливаем параметры root.strModel, ltMaxContext, ltTemperatura, ltGPU
		isGpuOffloadStart = true
	}	
	onPutLMStudioChanged: {//Если путь к Studio изменился, то...
		if (root.putLMStudio === ""){//Если пустой, то...
			knopkaSandbox.enabled = false//Кнопка не активна.
			DCSettings.studio_sandbox = ""//Выключаем sandbox
		} else {//Если не пустой путь, то...
			pyLM.ustPutStudio(root.putLMStudio)//Передаём его в логику Python
			if(__isMacOS || putCLI === "") knopkaSandbox.enabled = false
			else knopkaSandbox.enabled = true
		}
	}
	onPutCLIChanged: {//Если путь к серверу поменялся, то...
		if (root.putCLI === "") {//Если путь к серверу пустой, то...
			knopkaSandbox.enabled = false//Кнопка не активна.
			DCSettings.studio_sandbox = ""//Выключаем sandbox
		} else {
			if(__isMacOS || putLMStudio === "") knopkaSandbox.enabled = false
			else knopkaSandbox.enabled = true
		}
	}
	onIsStudioOnChanged: {
		knopkaLMPut.enabled = !root.isStudioOn//статус запуска студии поменялся, меняем политику изминения
	}
	onIsServerOnChanged: {
		knopkaCLIPut.enabled = !root.isServerOn//статус запуска сервера поменялся, меняем политику изминения
	}
	onIsMmprojMultiChanged: {
		knopkaMmproj.enabled = root.isMmprojMulti
	}
	onIsMmprojStatusChanged: {
		
	}
    Connections {//Обработчик загрузки моделей из Python
        target: pyLM

		function onSigLog(logMsg) {//Обработка сигнала сообщений из Класса
			root.log(logMsg)
		}
        function onSigError(ntError, errorMsg) {
			if(ntError === 3){//3 - Не удалось найти исполняемый файл Studio
				vprVopros.ntVopros = 3
				vprVopros.visible = true
			} else if (ntError === 6){//6 - Studio не запущен.
				vprVopros.ntVopros = 6
				vprVopros.visible = true
			} else if (ntError === 9){//9 - CLI lms не найден. Укажите путь в настройках
				vprVopros.ntVopros = 9
				vprVopros.visible = true
			} else if (ntError === 10) {//10 - Модель не загрузилась
				//Тут отобразится сообщение if(ntError !== 13)
			} else if (ntError === 14) {//14 - Ошибка по Sandbox, если песочница не та или не установлена, то.
				pvSandbox.currentIndex = 0//Первый элемент sandbox = выкл
				root.strSandbox = ""//Сохраняем значение
				Qt.callLater(function(){//Важна небольшая пауза, иначе запищется этот а потом другой sandbox
					DCSettings.studio_sandbox = ""//записываем в реестр.
				})
			}
			if(ntError !== 13){//Если это ошибка связана не с выбранной модели, то...
            	root.toolbar(`Ошибка: ${errorMsg}`)
				pvModels.isServerZapustit = false
				ldrProgress.active = false
			} else if(root.__isModelNoName){//Если выгрузка модели, то...
				root.__isModelNoName = false//Сбрасываем флаг.
				root.__isMmprojOn = false//сбрасываем флаг, так как при выгрузке модели может возникнуть ошиб.
				ldrProgress.active = false
			}
        }
		//0 - Ошибка HTTP при запросе списка моделей (сервер ответил кодом, отличным от 200).
		//1 - Ошибка сетевого подключения к Studio (сервер недоступен или не запущен).
		//2 - Неизвестная критическая ошибка при парсинге или загрузке списка моделей.
		//3 - Не удалось найти исполняемый файл Studio (требуется указать путь вручную в настройках).
		//4 - Ошибка при инициализации процесса запуска (сбой до или во время создания потока).
		//5 - Ошибка при попытке принудительной остановки процесса Studio (нет прав или процесс уже мертв).
		//6 - Studio не запущен.
		//7 - Ошибка системного запуска процесса (сбой subprocess.Popen в фоновом потоке).
		//8 - Превышено время ожидания запуска (сервер не стал доступен после 10 попыток по 3 секунды).
		//9 - CLI lms не найден. Укажите путь в настройках
		//10 - Ошибка загрузки модели
		//11 - Ошибка запуска сервера
		//12 - Ошибка остановки сервера
		//13 - Модель не выбрана
		//14 - Ошибка по Sandbox
		//15 - Ошибка связанная с Mmproj
		function onSigLMSPut(strLMSPut){//Если путь к Студии автоматически обнаружен, то он придут из PyLM
			DCSettings.studio_lms_put = strLMSPut;//Записываем в реестр настроек.
		}
		function onSigCLIPut(strCLIPut){//Если путь автоматически обнаружен, то он придёт из pyLM
			DCSettings.studio_cli_put = strCLIPut;//Запоминаем в реестре настроек.
		}
		function onSigStudioStarted() {//Обработка сигнала старта Studio
			root.__strProgress = qsTr(`Загрузка ${root.strStudioImya}.`)
			ldrProgress.active = true//Запускаем полосу прогресса
		}
		function onSigStudioStoped() {//Обработка сигнала остановки Studio
			root.__strProgress = qsTr(`Остановка ${root.strStudioImya}.`)
			ldrProgress.active = true//Запускаем полосу прогресса
		}
		function onSigStudioZapuschen() {
			vprVopros.visible = false
			ldrProgress.active = false//Закрываем полосу прогресса
			root.toolbar(`${root.strStudioImya} запущен!`)
			pyLM.proverkaServera()	
		}
		function onSigStudioOstanovlen() {
			tmrStudioOstanovlen.running = true	
		}		
		function onSigStudioStatus(blStatus) {
			root.isStudioOn = blStatus
		}
		function onSigServerURLIzmenen(strServerURL){//Сигнал о том, что изменён адрес сервера
			root.toolbar(`Адрес сервера изменён на: ${strServerURL}`)
		}
		function onSigServerZapuschen() {
			if(pvModels.isServerZapustit){
				root.toolbar(`✓ Сервер ${root.strStudioImya} готов`)
				pyLM.zagruzitModeli()//Загружаем модели после запуска сервера
				pvModels.visible = true//Делаем видимым виджет
				pvModels.karusel.forceActiveFocus()//фокус PathView, чтоб hotkey работали.
				pvModels.isServerZapustit = false
			}
		}
		function onSigServerOstanovlen() {
			root.toolbar("Сервер остановлен")
		}
		function onSigServerStatus(blStatus) {
			root.isServerOn = blStatus
		}
		function onSigServerError(strError) {
			root.log(strError)//В лог
			root.toolbar(strError)//На панель toolbar
		}
		function onSigModelsLoaded(models) {
            modelModels.clear()//Очищаем старую модель
            for (let i = 0; i < models.length; i++) {//Заполняем новыми данными
				console.log(models[i])
                modelModels.append({ spisok: models[i] })
            }
            let savedModel = DCSettings.studio_model_imya//Устанавливаем текущий индекс

            if (savedModel === "" || savedModel === root.strModelNoName) {
                pvModels.currentIndex = 0//Первый элемент = отсутствует
            } else {
                for (let i = 0; i < models.length; i++) {//Ищем сохранённую модель в списке
                    if (models[i] === savedModel) {
                        pvModels.currentIndex = i
                        break
                    }
                }
            }
			fnMmprojStatus(savedModel)//Проверяем статус mmproj у модели и выставляем его.
            root.log(`Загружено моделей: ${models.length}`)
        }
		function onSigModelZagrujena(strModel, ntContext){//Модель загрузилась
			ldrProgress.active = false
		}
		function onSigModelVigrujena(blStatus){
			if(root.__isModelNoName) {//Если выбран режим выгрузки модели, то...
				ldrProgress.active = false
				root.__isModelNoName = false//Сбрасываем флаг.
			} else if (root.__isMmprojOn) {//Если активирован режим мультимодальности модели, то...
				root.__strProgress = qsTr(`Переключение мультимодальности ${root.strModel}`)
			}
		}
		function onSigModelProgress(ntProgress) {
			if (ldrProgress.item) {
				ldrProgress.item.progress = ntProgress
			}
		}
		function onSigMmprojStatus(isMultimodal, isStatus) {
			root.isMmprojMulti = isMultimodal
			root.isMmprojStatus = isStatus
		}
		function onSigMmprojPereklyuchen(isStatus) {//Сигнал о том, что режим мультимодальности переключён.
			root.isMmprojStatus = isStatus//Запоминае, чтоб переключатель на кнопке переключился.
			DCSettings.studio_mmproj_status = root.isMmprojStatus//Сохраняем в реестре.
			root.__isMmprojOn = false//Сбрасываю флаг, так как на этом этапе скрипт перестал работать.
			fnUstParametri()//Устанавливаем параметры root.strModel, ltMaxContext, ltTemperatura, ltGPU
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
	DCFileDialog {//Панель выбора пускового файла, виджет DCFileDialog из DCMethods
		id: fldPutStudio
		ntCoff: root.ntCoff; ntWidth: root.ntWidth
		hide: true//Открываем с показом скрытых папок и файлов. ВАЖНО!!!
		clrTexta: root.clrTexta; clrFona: root.clrFona; clrFonaZatem: root.clrMenuFon 
		isMobile: root.isMobile
		//Python функция списков папки, включая скрытые. ВАЖНО!!! Именно функция-обёртка,
		fnSpisokPapki: function(vrPapka){
			return pyLM ? pyLM.polSpisokPapki(vrPapka) : "[]"
		}
		property var fnKudaZapisat: null//Функция куда сохранять выбранный путь
		//Обработчик выбора пути из панели. ВАЖНО!!! Именно функция со своим параметром (vrPut),
		onVybran: (vrPut) => {
			if (fldPutStudio.fnKudaZapisat !== null) fldPutStudio.fnKudaZapisat(vrPut)
			fldPutStudio.fnKudaZapisat = null
		}
		onZakrit: root.forceActiveFocus()//Возвращаем фокус корню чтобы работали горячие клавиши. ВАЖНО!!!
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
		if (pvSandbox.visible) {
			pvSandbox.visible = false
		}
		if (pvModels.visible) {
			pvModels.visible = false
		}
		txnVvod.visible = false//Делаем невидимым ввот чисел
    }
	function fnClickedNazad() {
		fnClickedEscape()//Функция нажатия на клавишу Escape
		fnStatus(false)//Функция, которая останавливает мониторинг Студии и Сервера lms
		root.clickedNazad()
	}
	function fnClickedZakrit(){//Функция обрабатывающая кнопку Закрыть.
		txnVvod.visible = false//Делаем невидимым ввот чисел
	}
	function fnClickedOk(){//Нажимаем на Ок(Сохранить)
		if(txnVvod.ntVvod === 0){//Максимальный контекст
			let ltContext = Number(txnVvod.text)//Явно приобразовываем в число.
			let ltResult = Math.round(ltContext / 64) * 64;//Получаем число кратное 64.
			if(ltResult < 8000 || ltResult > 131072) root.toolbar("Неверное значение, необходимо от 8000 до 131072.")
			else DCSettings.studio_max_context = ltResult//Сохраняем в реестре значение.
		} else if(txnVvod.ntVvod === 1){//Путь к cli lms
			var vrPutCLI = txnVvod.text
			if(pyLM.proverkaLMSFaila(vrPutCLI)){//Если такой путь существует, то...
				DCSettings.studio_cli_put  = vrPutCLI
				pyLM.ustPutCLI(vrPutCLI)
			} else {
				root.toolbar("Указан неверный путь до lms.")
			}
		} else if (txnVvod.ntVvod === 2){//ввод gpu offload
			let ltGPU = Number(txnVvod.text)//Явно преобразуем в число.
			if(ltGPU >= 0 && ltGPU <= 100){
				DCSettings.studio_gpu_offload = ltGPU
			} else {
				root.toolbar("Неверно задан параметр gpu offload (0-100%).")
			}
		} else if(txnVvod.ntVvod === 3){//Server URL
			var vrServerURL = txnVvod.text
			if(pyLM.proverkaServerURL(vrServerURL)){//Если такой url существует, то...
				DCSettings.studio_server_url = vrServerURL
			} else {
				root.toolbar("Указан неверный адрес сервера.")
			}
		}
		txnVvod.visible = false//Делаем невидимым данных
	}
	function fnClickedInfo() {
		fnClickedEscape()//Функция нажатия на клавишу Escape
		root.clickedInfo()
	}
	function fnToggleMenu() {
		if (menuMenu.visible) 
			menuMenu.visible = false
		else {
			if (pvSandbox.visible) pvSandbox.visible = false
			if (pvModels.visible) pvModels.visible = false
			if (txnVvod.visible) txnVvod.visible = false
			if (vprVopros.visible) vprVopros.visible = false
			menuMenu.visible = true
		}
	}
	function fnStatus(blFlag){//Функция,которая проверку статус запуска LM Studio или Bionic и Сервера lms
		if(blFlag) fnTmrStatus()//Если пришёл сигнал опроса статуса Студии и lms сервера, тут же запускаем его
		tmrStatus.running = blFlag//Запускаем/останавливаем мониторинг запуска Студии и Сервера lms
	}
	function fnTmrStatus() {//Функция обрабатывающая таймер Статуса
		pyLM.proverkaStudio()
		if(root.isStudioOn) pyLM.proverkaServera()//Если Студия запущена, проверяем статус Серевера lms
		else root.isServerOn = false//Если студия закрыта, то и сервер тоже неработает.
	}
	function fnCloseMenuIfOpen() {
		if (menuMenu.visible) {
			menuMenu.visible = false
			return true
		}
		return false
	}
	function fnCloseSandboxIfOpen() {
		if (pvSandbox.visible) {
			pvSandbox.visible = false
			root.forceActiveFocus()//фокус root, чтоб hotkey работали.
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
	function fnCloseTXNtIfOpen() {
		if (txnVvod.visible) {
			txnVvod.visible = false
			return true
		}
		return false
	}
	function fnCloseVoprosIfOpen() {
		if (vprVopros.visible) {
			vprVopros.visible = false
			return true
		}
		return false
	}
	function fnUstParametri() {//Устанавливаем параметры root.strModel, ltMaxContext, ltTemperatura, ltGPU
		if(root.strModel === root.strModelNoName) root.__isModelNoName = true
		else root.__strProgress = qsTr(`Загрузка модели: ${root.strModel}`)
		let ltMaxContext = DCSettings.studio_max_context
		let ltGPU = DCSettings.studio_gpu_offload
		ldrProgress.active = true//Запускаем полосу прогресса загрузки модели
		pyLM.ustParametri(root.strModel, ltMaxContext, ltGPU)
	}
	function fnModelEnabled(){//Функция управляет политикой кнопок Temperatura, Context, GPU
		let ltFlag = true//Истина
		if(root.strModel === root.strModelNoName) ltFlag = false
		knopkaContext.enabled = ltFlag
		knopkaGPU.enabled = ltFlag
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
				pvModels.isServerZapustit = true
			   	pyLM.zapustitServer()//Всегда запускаем сервер, даже если он запущен.
				root.toolbar(qsTr("Ожидайте."))
			})
		}
	}
	function fnMmprojStatus(strModel) {//Проверяем статус mmproj у модели и выставляем его.
		if (strModel !== "" && strModel !== root.strModelNoName) pyLM.proverkaMmproj(strModel)
		else root.isMmprojMulti = false//Не активная кнопка по прерывани. будет.
	}
	function fnClickedLMSZapustit(){//Функция запуска Studio
		pyLM.zapustitStudio()//Запускаем Студию, если путь не задан,то автоматически искать будет или ошибку=3
	}
	function fnClickedLMSZaktit() {//Функция закрытия Studio
		pyLM.ostanovitStudio()//Закрываем студию.
	}
	function fnClickedVvod(vvod){//Функция выбора Ввода данных
		txnVvod.ntVvod = vvod
		txnVvod.visible = !txnVvod.visible
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
	//Функция открытия панели выбора файлов со скрытыми папками (виджет DCFileDialog)
	function fnOtkritFaylovik(strZagolovok, strPapka, fnKuda) {
		fldPutStudio.fnKudaZapisat = fnKuda//Запоминаем куда сохранять выбранный путь
		fldPutStudio.fnOtkrit(strZagolovok, strPapka)//Стартовую папку виджет определит сам
	}
	Timer {//ТАЙМЕР запуска проверки соединения с сервером lms
        id: tmrServerLMS
        interval: 3300; running: false; repeat: true
        onTriggered: {
			if(root.isStudioOn) pyLM.proverkaServera()//Если студия запущена, то проверяем статус Сервера lms
        }
    }
	Timer {//ТАЙМЕР запуска проверки работы LM Studio или Bionic
        id: tmrStatus
        interval: 3300; running: false; repeat: true
        onTriggered: {
			fnTmrStatus()//Функция обрабатывающая таймер Статуса
        }
    }
	Timer {//ТАЙМЕР остановки Studio 
        id: tmrStudioOstanovlen
        interval: 1100; running: false; repeat: false
        onTriggered: {
			ldrProgress.active = false//Закрываем полосу прогресса
			root.toolbar(`${root.strStudioImya} остановлен`)
        }
    }
	Item {//Заголовок
		id: tmZagolovok
		DCKnopkaNazad {
			id: knopkaNazad
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			anchors.verticalCenter: tmZagolovok.verticalCenter; anchors.left: tmZagolovok.left
			clrKnopki: root.clrTexta; clrFona: root.clrFona
			tapHeight: root.ntWidth * root.ntCoff + root.ntCoff; tapWidth: tapHeight * root.tapZagolovokLevi
			onClicked: fnClickedNazad()
		}
		DCKnopkaSvetofor {
            id: knopkaServer
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            visible: true
            anchors.verticalCenter: tmZagolovok.verticalCenter; anchors.right: knopkaLM.left
			clrKnopki: root.clrTexta; clrFona: root.clrFona
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff; tapWidth: tapHeight * root.tapZagolovokPravi
			enabled: false
			isInvers: root.isServerOn
        }
		DCKnopkaLM {
            id: knopkaLM
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            visible: true
            anchors.verticalCenter: tmZagolovok.verticalCenter; anchors.right: tmZagolovok.right
            clrKnopki: root.clrTexta; clrFona: root.clrFona
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff; tapWidth: tapHeight * root.tapZagolovokPravi
			enabled: false
			isLMZapuschen: root.isStudioOn
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
				id: txnVvod
				ntWidth: root.ntWidth
				ntCoff: root.ntCoff
				anchors.fill: tmTextInput
				visible: false
				isNumber: {
					if (ntVvod === 0) return true//Вводим только цифры
					else if(ntVvod === 1) return false//Не вводим только цифры
					else if(ntVvod === 2) return true//Вводим только цифры
					else if(ntVvod === 3) return false//Не Вводим только цифры
				}
				placeholderText: {//Подсказки пользователю
					if (ntVvod === 0) return qsTr("8000-131072")
					else if(ntVvod === 1) {
						if (Qt.platform.os === "windows") return "~\\.lmstudio\\bin\\lms.exe"
					   	return "~/.lmstudio/bin/lms"
					} else if(ntVvod === 2) return qsTr("0-100")
					else if(ntVvod === 3) return qsTr("http://127.0.0.1:1234")
				}
				clrTexta: root.clrTexta; clrFona: root.clrMenuFon
				radius: root.ntCoff/2
				textInput.maximumLength: {
			   		if(ntVvod === 0 ) return 6//Ограницение по вводу максимальны токенов для локальной модели
					else if (ntVvod === 1) return 111//Длина пути до cli lms
					else if (ntVvod === 2) return 3//0-100
					else if (ntVvod === 3) return 30//Максимальная длина адреса http://127.000.000.001:1234
				}
				blSqlProtect: {//Настройка по SQL инъекции.
					if(ntVvod === 0) return false
					else if (ntVvod === 1) return false//Для Windows путь прописать нужно через :
					else if (ntVvod === 2) return false
					else if (ntVvod === 3) return true
				}
				property int ntVvod: 0//0 - max_context, 1 - cli_lms, 2 - gpu_offload, 3 - server_url
				onSgnDebug: function (strDebug) { root.toolbar(strDebug) }//Ошибка из виджета в программу.
				onVisibleChanged: {//Если видимость DCTextInput изменился, то...
					if(txnVvod.visible){//Если DCTextInput видим, то...
						knopkaNazad.visible = false;//Конопка Назад Невидимая.
						knopkaLM.visible = false;//Кнопка LM невидимая.
						knopkaZakrit.visible = true;//Кнопка закрыть Видимая
						knopkaOk.visible = true;//Кнопка Ок Видимая.
						if(ntVvod === 0){//Максимальный контекст
							text = DCSettings.studio_max_context//Показываем значение макс контекста
						} else if(ntVvod === 1){//Путь к cli lms
							text = DCSettings.studio_cli_put//Путь к cli lms
						} else if (ntVvod === 2){//gpu offload
							text = DCSettings.studio_gpu_offload
						} else if (ntVvod === 3){//server_url
							text = DCSettings.studio_server_url
						}
					}
					else{//Если DCTextInput не видим, то...
						knopkaNazad.visible = true;//Конопка Информация Видимая.
						knopkaLM.visible = true;//Кнопка LM видимая.
						knopkaZakrit.visible = false;//Кнопка закрыть Невидимая
						knopkaOk.visible = false;//Кнопка Ок Невидимая.
						txnVvod.text = "";//Текст обнуляем вводимый.
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
		DCVopros {
			id: vprVopros
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			anchors.top: tmZagolovok.top; anchors.bottom: tmZagolovok.bottom
			anchors.left: tmZagolovok.left; anchors.right: tmZagolovok.right
			clrFona: root.clrVnimanie; clrTexta: root.clrFona
			clrKnopki: root.clrFona; clrBorder: root.clrFona
			tapKnopkaZakrit: root.tapZagolovokLevi; tapKnopkaOk: root.tapZagolovokPravi
			visible: false
			property int ntVopros: 0//Смотри на номера ошибок sigError
			text: {
				if(ntVopros === 3) return qsTr(`Путь к исполняемому файлу ${root.strStudioImya} не найден. Задать?`)
				else if(ntVopros === 6) return qsTr(`${root.strStudioImya} не запущена. Запустить?`)
				else if (ntVopros === 9) return qsTr("Путь к серверу lms не действительный. Задать?")
				else return qsTr("Любовь")
			}
			function fnVoprosOk(flag){//Функция открытия вопроса по флагу
				if(flag === 3){
					fnOtkritFaylovik(qsTr(`Выберите путь к ${root.strStudioImya}`), DCSettings.studio_lms_put,
						function(vrPut) { DCSettings.studio_lms_put = vrPut })//Сохраняем путь в DCSettings
				} else if (flag === 6){
					fnClickedLMSZapustit()//Функция запуска Studio
				} else if (flag === 9){
					fnClickedVvod(1)//Функция задания пути для cli lms
				}
			}
			onVisibleChanged: {
				if(visible) {
					knopkaNazad.visible = false
				} else {
					knopkaNazad.visible = true
        			root.forceActiveFocus()//Переводим фокус на основное окно, чтоб работали горячие кнопки.
				}
			}
			onClickedOk: {
				vprVopros.visible = false//Делаем невидимый диалог
				fnVoprosOk(ntVopros)//Запускаем функцию с параметром
			}
			onClickedOtmena: {
				vprVopros.visible = false//Делаем невидимый диалог.
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
					if(!knopkaContext.pressedTmr550 && !knopkaCLIPut.pressedTmr550 
													&& !knopkaGPU.pressedTmr550 
													&& !knopkaServerURL.pressedTmr550) fnCloseTXNtIfOpen()
					if(!pvSandbox.jdi && !pvSandbox.pressed) fnCloseSandboxIfOpen()//Закрываем карусель pv....
					if(!pvModels.jdi && !pvModels.pressed) fnCloseModelsIfOpen()//Закрываем карусель pv....
					if(!knopkaModeli.pressedTmr550 	&& !knopkaLMStart.pressedTmr550
													&& !knopkaLMStop.pressedTmr550)fnCloseVoprosIfOpen()
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
				DCKnopkaOriginal {//Кнопка запуска/остановки Studio
					id: knopkaLMStart
					text: qsTr(`запустить ${root.strStudioImya}`)
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 0) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 0
						fnClickedLMSZapustit()//Функция запуска Studio
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseTXNtIfOpen() && !fnCloseVoprosIfOpen()){
								if (pressed && !pvSandbox.pressed && !pvModels.pressed) fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {//Кнопка остановки Studio
					id: knopkaLMStop
					text: qsTr(`остановить ${root.strStudioImya}`)
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
					anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 1) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 1
						fnClickedLMSZaktit()//Функция закрытия Studio
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseTXNtIfOpen() && !fnCloseVoprosIfOpen()) {
								if (pressed && !pvSandbox.pressed && !pvModels.pressed) fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {//Кнопка выбора пути Studio 
                    id: knopkaLMPut
                    text: {
                        let ltText = qsTr(`путь к ${root.strStudioImya}: `);//
						if (root.putLMStudio === "") ltText += qsTr("не задан")
						else {//Отображаем путь в зависимости от операционной системы
							if (Qt.platform.os === "windows") ltText += root.putLMStudio.replace(/\//g, "\\");
							else ltText += root.putLMStudio
						}
						return ltText;
                    }
                    ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 2) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					enabled: !root.isStudioOn
					function fnPress() {
						root.currentIndex = 2
						fnOtkritFaylovik(qsTr(`Выберите путь к ${root.strStudioImya}`), DCSettings.studio_lms_put,
							function(vrPut) { DCSettings.studio_lms_put = vrPut })//Сохраняем путь в DCSettings
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseTXNtIfOpen() && !fnCloseVoprosIfOpen()) {
								if (pressed && !pvSandbox.pressed && !pvModels.pressed) fnPress()
							}
						}
					}	
                }

				DCKnopkaOriginal {//Кнопка выбора пути cli lms
                    id: knopkaCLIPut
                    text: {
                        let ltText = qsTr("путь к lms: ");//
						if (root.putCLI === "") ltText += qsTr("...")
						else ltText += root.putCLI
						return ltText;
                    }
                    ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 3) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					enabled: !root.isServerOn
					function fnPress() {
						root.currentIndex = 3
						fnClickedVvod(1)//Функция задающая путь к cli lms
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseTXNtIfOpen() && !fnCloseVoprosIfOpen()) {
								if (pressed && !pvSandbox.pressed && !pvModels.pressed) fnPress()
							}
						}
					}	
                }
				DCKnopkaOriginal {
					id: knopkaServerURL
					text: {
						let ltText = qsTr("адрес lms сервера: ")
						ltText += root.serverURL
						return ltText
					}
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 4) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 4
						fnClickedVvod(3)//Функция ввода адреса сервера
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseTXNtIfOpen() && !fnCloseVoprosIfOpen()) {
								if (pressed && !pvSandbox.pressed && !pvModels.pressed) fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {//Кнопка включения Sandbox
                    id: knopkaSandbox
                    text: {
                        let ltText = qsTr("sandbox ");//
						if (root.strSandbox === ""){
						   	ltText += qsTr("выкл")
							pvSandbox.currentIndex = 0//Первый элемент = выкл
						} else {
							ltText += root.strSandbox
							for (let i = 0; i < modelSandbox.count; i++) {//Ищем сохранённую модель в списке
								if (modelSandbox.get(i).spisok === root.strSandbox) {
									pvSandbox.currentIndex = i//Выставляем в карусели нужный элемент.
									break
								}
							}
						}
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
						Qt.callLater(function(){//пауза, иначе не сработает фокус и pvSandbox. ВАЖНО!!!
							pvSandbox.visible = !pvSandbox.visible//Инверсируем
						})
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseTXNtIfOpen() && !fnCloseVoprosIfOpen()) {
								if (pressed && !pvSandbox.pressed && !pvModels.pressed) fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {//Кнопка выбора размера шрифта
                    id: knopkaModeli
                    text: {
                        let ltText = qsTr("модель ");//
						if (root.strModel === "" || root.strModel === root.strModelNoName) {
							ltText += root.strModelNoName
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
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 6) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 6
						fnClickedModel()//Функция выбора Модели.
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseTXNtIfOpen() && !fnCloseVoprosIfOpen()) {
								if (pressed && !pvSandbox.pressed && !pvModels.pressed) fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {//Кнопка включения Sandbox
                    id: knopkaMmproj
					text: root.isMmprojStatus 	? qsTr("мультимодальность модели вкл")
												: qsTr("мультимодальность модели выкл")
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 7) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					enabled: root.isMmprojMulti
					function fnPress() {
						root.currentIndex = 7
						root.__strProgress = qsTr(`Выгружаем модель: ${root.strModel}`)
						root.__isMmprojOn = true//Активируем режим смены мультимодальности модели.
						ldrProgress.active = true//Запускаем полосу прогресса загрузки модели
						pyLM.pereklyuchitMmproj(root.strModel, !root.isMmprojStatus)
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseTXNtIfOpen() && !fnCloseVoprosIfOpen()) {
								if (pressed && !pvSandbox.pressed && !pvModels.pressed) fnPress()
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
                    clrKnopki: (root.currentIndex === 8) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 8
						fnClickedVvod(0)//Функция выбора максимального контекста
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseTXNtIfOpen() && !fnCloseVoprosIfOpen()) {
								if (pressed && !pvSandbox.pressed && !pvModels.pressed) fnPress()
							}
						}
					}
				}
				DCKnopkaOriginal {
					id: knopkaGPU
					text: {
						let ltText = qsTr("gpu offload: ")
						ltText += root.gpuOffload + "%"
						return ltText
					}
					ntHeight: root.ntWidth; ntCoff: root.ntCoff
					anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					clrTexta: root.clrMenuText
                    clrKnopki: (root.currentIndex === 9) ? Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                    opacityKnopki: 0.9
					function fnPress() {
						root.currentIndex = 9
						fnClickedVvod(2)//Функция ввода gpu offload
					}
					onClicked: {
						if (pressed) {
							if (!fnCloseMenuIfOpen() && !fnCloseTXNtIfOpen() && !fnCloseVoprosIfOpen()) {
								if (pressed && !pvSandbox.pressed && !pvModels.pressed) fnPress()
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
		ListModel {//Модель с Sandbox приложениями
            id: modelSandbox
			ListElement { spisok: "выкл" }
            ListElement { spisok: "firejail" }
            ListElement { spisok: "sandboxie" }
        }
        DCPathView {
            id: pvSandbox
            visible: false
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            anchors.left: tmZona.left; anchors.right: tmZona.right; anchors.bottom: tmZona.bottom
            anchors.leftMargin: dcScrollbar.width; anchors.rightMargin: dcScrollbar.width
            clrFona: root.clrFona; clrTexta: root.clrMenuText; clrMenuFon: root.clrMenuFon
            modelData: modelSandbox
            onClicked: function(sandbox) {
				Qt.callLater(function(){//пауза, иначе не сработает фокус и pvSandbox. ВАЖНО!!!
					pvSandbox.visible = false//Делаем невидимым виджет
					if(sandbox === "выкл" || sandbox === "off") sandbox = ""
					root.strSandbox = sandbox//Сохраняем значение
					DCSettings.studio_sandbox = sandbox//записываем в реестр.
				})
            }
			onVisibleChanged: {//Если видимость поменялась, то...
				if(!visible) root.forceActiveFocus()//Если невидимый, то фокус на root, чтоб hotkey работали.
			}
        }
		ListModel {//Модель с Языковыми Моделями
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
			property bool isServerZapustit: false//true - запускаем сервер для показа списка моделей.
			property bool isStartPerti: true//false - загрузка модели не первый раз.
            onClicked: function(strModel) {
				Qt.callLater(function(){//пауза, иначе не сработает фокус и pvModels. ВАЖНО!!!
					pvModels.visible = false//Делаем невидимым виджет
					DCSettings.studio_model_imya = strModel//Сохраняем в Реестре
					DCSettings.studio_mmproj_multi = root.isMmprojMulti//Запоминаем режим мультимодальности
					DCSettings.studio_mmproj_status = root.isMmprojStatus//Запоминаем статус мультимодальности
				})
            }
			onElement: function(strElement) {
				if(isStartPerti) isStartPerti = false//Если первый раз старт, элемент всегда пустой будет.
				else fnMmprojStatus(strElement)//Проверяем статус mmproj у модели и выставляем его.
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
		Loader {//LOADER для DCProgress
            id: ldrProgress
            anchors.fill: tmToolbar
            source: "qrc:/DCMethods/DCProgress.qml"
            active: false
			onActiveChanged: {
				if(active){
					root.toolbar("")//Очищаем toolbar, чтоб ненаслаивать предыдущие сообщения и загрузку.
					knopkaInfo.visible = false
					knopkaNastroiki.visible = false
					knopkaNazad.enabled = false
					knopkaLMStart.enabled = false
					knopkaLMStop.enabled = false
					knopkaLMPut.enabled = false
					knopkaCLIPut.enabled = false
					knopkaSandbox.enabled = false
					knopkaModeli.enabled = false
					knopkaMmproj.enabled = false
					knopkaContext.enabled = false
					knopkaGPU.enabled = false
					knopkaServerURL.enabled = false
				} else {
					knopkaInfo.visible = true
					knopkaNastroiki.visible = true
					knopkaNazad.enabled = true
					knopkaLMStart.enabled = true
					knopkaLMStop.enabled = true
					if(root.isStudioOn)knopkaLMPut.enabled = false//При запущенной студии нельзя менять путь
					else knopkaLMPut.enabled = true
					if(root.isServerOn)knopkaCLIPut.enabled = false//При запущенном сервере нельзя менять путь
					else knopkaCLIPut.enabled = true
					if(__isMacOS || putLMStudio === "" || putCLI === "") knopkaSandbox.enabled = false
					else knopkaSandbox.enabled = true
					knopkaModeli.enabled = true
					if(root.isMmprojMulti) knopkaMmproj.enabled = true//Если модель мультимодальная, то True
					else knopkaMmproj.enabled = false//Если модель не мультимодальная,нельзя изменить параметр
					fnModelEnabled()//Функция управляет политикой кнопок Temperatura, Context, GPU
					//knopkaContext.enabled = true
					//knopkaGPU.enabled = true
					knopkaServerURL.enabled = true
				}
			}
            onLoaded: {
                ldrProgress.item.ntWidth = root.ntWidth
                ldrProgress.item.ntCoff = root.ntCoff
                ldrProgress.item.clrProgress = root.clrTexta
                ldrProgress.item.clrTexta = "grey"
                ldrProgress.item.radius = root.ntCoff / 4
				ldrProgress.item.text = root.__strProgress
            }
        }
		DCKnopkaInfo {
			id: knopkaInfo
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			anchors.verticalCenter: tmToolbar.verticalCenter; anchors.left: tmToolbar.left
			clrKnopki: root.clrTexta; clrFona: root.clrFona
			tapHeight: root.ntWidth * root.ntCoff + root.ntCoff; tapWidth: tapHeight * root.tapToolbarLevi
			onClicked: {
				if (!fnCloseMenuIfOpen() && !fnCloseTXNtIfOpen() && !fnCloseVoprosIfOpen()) {
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
			if (menuMenu.visible || pvSandbox.visible || pvModels.visible || txnVvod.visible){
				menuMenu.visible = false
				pvSandbox.visible = false
				pvModels.visible = false
				txnVvod.visible = false
			} else root.forceActiveFocus()
			root.forceActiveFocus()
		}
	}
}

