import QtQuick
import QtQuick.Controls
import QtCore
import QtQuick.Dialogs
import QtQuick.Layouts
import DCButtons 1.0
import DCMethods 1.0
import DCSettings 1.0//Настройки из реестра.

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
    property var strSpisokDokumentov: []//Локальные пути загруженных .txt документов.
    property string strLog: ""//Последнее сообщение лога Python бэкенда.
    property string strOshibka: ""//Последняя ошибка Python бэкенда.

	property bool isServerZapustit: false//true - запускаем сервер для начала анализа
	property bool isMobile: false//true - мобильное устройство.
	property bool isModelZagruzit: false//true - жду загрузки модели из StrAnalizer
	//Настройки
    anchors.fill: parent
    focus: true
    //Сигналы
    signal clickedNazad()
	signal clickedSettings()
    signal clickedInfo()
	signal clickedInfoOrfograf()//Информация по настройкам нейроорфографии.
	signal toolbar(var strToolbar)
    signal log(var strLog)
    //Методы
	Component.onCompleted: {
    	root.forceActiveFocus()
    }
    Connections {//CONNECTIONS сигналов Python бэкенда исправления орфографии
    	target: pyOrfograf
    	function onStrLog(strMessage) {//Пишем в лог приложения.
    		root.strLog = strMessage
    		root.log(strMessage)
    	}
    	function onStrOshibka(ntCode, strMessage) {//Код ошибки и текст ошибки.
        	tmrLogo.running = false//Останавливаем анимацию логотипа (выход из режима анализа).
    		root.strOshibka = strMessage
			txdRezultat.text += strMessage
			root.log("❌ Ошибка [" + ntCode + "]: " + strMessage)
    		root.toolbar("❌ Ошибка [" + ntCode + "]: " + strMessage)
			root.isServerZapustit = false
			root.isModelZagruzit = false//Сбрасываю флаг
    	}
    	function onSigProgress(strImya, ntFrag, ntVsego) {//Прогресс показываем в DCProgress.
    		if (ldrProgress.item) {
    			ldrProgress.item.text = strImya + " фрагмент " + ntFrag + "/" + ntVsego
    			ldrProgress.item.progress = (ntVsego > 0) ? (ntFrag * 100 / ntVsego) : 0
    		}
    	}
    	function onSigDokumentGotov(strImya, strPut, ntIzmenenij) {//Фрагменты склеены, файл сохранён.
    		txdRezultat.text += "✅ " + strImya + " — исправлено мест: " + ntIzmenenij + "\n"
    		txdRezultat.text += "   сохранён: " + strPut + "\n"
    		txdRezultat.scrollBottom()
    	}
    	function onSigVseGotovo(ntVseho, ntOshibok) {//Все документы обработаны.
    		txdRezultat.text += "🏁 Готово: обработано " + ntVseho + ", ошибок: " + ntOshibok + "\n"
    		txdRezultat.scrollBottom()
			tmrLogo.running = false//Анализ закончен: стоп логотип, кнопки обратно.
    	}
    }
	Connections {//Обработчик загрузки моделей из Python
        target: pyLM
	
        function onSigError(ntError, errorMsg) {
			if(ntError === 3){//3 - Не удалось найти исполняемый файл Studio
				//vprVopros.ntFlag = 3//3 - вопрос, что не найден cli lms
				//vprVopros.visible = true
			} else if (ntError === 6){//6 - Studio не запущен.
				//vprVopros.ntFlag = 6//6 - вопрос, что не запустилась Studio
				//vprVopros.visible = true
			} else if (ntError === 9){//9 - CLI lms не найден. Укажите путь в настройках
				//vprVopros.ntFlag = 9//9 - вопрос, что не найден cli lms
				//vprVopros.visible = true
			} else if (ntError === 13){//13 - Модель не выбрана
				if(root.isModelZagruzit){//Если модель не загружена по просьбе StrOrfograf, то..
				//	vprVopros.ntFlag = 13//13 - Модель не выбрана
				//	vprVopros.visible = true
				}
			}
			console.log(ntError, errorMsg)
			tmrLogo.running = false//Останавливаем анимацию анализа и политики кнопок
			ldrProgress.active = false
			root.isServerZapustit = false
			root.isModelZagruzit = false//Сбрасываю флаг
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
		//10 - Модель не загрузилась
		//11 - Ошибка запуска сервера
		//12 - Ошибка остановки сервера
		//13 - Модель не выбрана
		//14 - Ошибка по Sandbox
		//15 - Ошибка связанная с Mmproj
		function onSigStudioZapuschen() {//Если запущена Studio
			//vprVopros.visible = false//Эта строка закрывает плашку с вопросом, которая автоматич. появляется
		}
		function onSigServerZapuschen() {//Если сервер запустился, то начинаем анализ Документов.
			if(root.isServerZapustit){
				root.isServerZapustit = false//Сбрасываем флаг.
				let ltModel = pyLM.polModel()//Получаем имя модели.
				if (ltModel){//Если это не пустая строка, то...
					if (root.isModelZagruzit) {//Если модель загружена по просьбе StrOrfograf, то...
						root.isModelZagruzit = false//Сбрасываю флаг
						pyOrfograf.startOrfografiya(root.strSpisokDokumentov,
													DCSettings.orfograf_put_rezultat,
													DCSettings.orfograf_temperatura,
													DCSettings.studio_max_context,
													DCSettings.orfograf_perekritie)
					}
				} else {//Если пустая строка, то...
					ldrProgress.active = true//Запускаем полосу прогресса загрузки модели
					ldrProgress.total = 1//Задаём скорость движения полосы прогресса.
					if(ldrProgress.item)ldrProgress.item.text="Загрузка модели: "+DCSettings.studio_model_imya
					pyLM.ustParametri(DCSettings.studio_model_imya, DCSettings.studio_max_context,
											DCSettings.studio_gpu_offload)
				}
			}
		}
		function onSigModelZagrujena(strModel, ntContext) {
			ldrProgress.active = false//Отключаем прогрессбар, после загрузки Модели.
			if (root.isModelZagruzit) {//Если модель загружена по просьбе StrAnalizer, то...
				root.isModelZagruzit = false//Сбрасываю флаг
				ldrProgress.active = true//Включаем прогрессбар, после загрузки Модели.
				pyOrfograf.startOrfografiya(root.strSpisokDokumentov,
													DCSettings.orfograf_put_rezultat,
													DCSettings.orfograf_temperatura,
													DCSettings.studio_max_context,
													DCSettings.orfograf_perekritie)
			}
		}
		function onSigModelProgress(ntProgress) {
			if (ldrProgress.item) {
				ldrProgress.item.progress = ntProgress
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
            if (running) {//Идёт исправление: блокируем все кнопки кроме кнопкаНазад.
                ldrProgress.active = true
            } else {//Исправление закончилось: возвращаем кнопки в исходное состояние.
                lgLogo.ntCoff = root.logoRazmer//Задаём фиксированный размер логотипа.
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
			root.toolbar(`Анализ орфографии завершён`)
        }
	}
    Keys.onPressed: (event) => {//Обработка горячих клавиш
        if (event.modifiers & Qt.AltModifier) {
            if (event.key === Qt.Key_Left) {
                fnClickedNazad()//Функция закрытия страницы.
                event.accepted = true
                return
            } else if (event.key === Qt.Key_F || event.key === 1040) {
                fnClickedMenu()//Функция Настройки
                event.accepted = true
                return
            } else if (event.key === Qt.Key_S || event.key === 1067) {
                fnClickedSidebar()//Функция открытия боковой панели
                event.accepted = true
                return
            }
        }
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (knopkaAnaliz.enabled) fnClickedOrfograf()//Старт исправления орфографии.
                event.accepted = true
            } if (event.key === Qt.Key_O || event.key === 1065) {
                if (!menuMenu.visible && knopkaOtkrit.enabled) fnClickedOtkrit()//открытия результатов
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
	function fnClickedEscape() {//Функция нажатия на клавишу Escape
		if (menuMenu.visible) {
			menuMenu.visible = false
		} else {
			//Если меню закрыто, ничего не делаем (можно добавить другую логику)
		}
		fnCloseSidebarIfOpen()//Закрываем боковую панель настроек, если она открыта.
    }
    function fnClickedNazad() {//Функция закрытия страницы.
        if (tmrLogo.running) {//Если анализ идёт, спрашиваем про его остановку.
            vprVopros.ntFlag = 22
            vprVopros.visible = true
        } else {
            fnClickedEscape()//Функция нажатия на клавишу Escape
            root.clickedNazad()
        }
    }
    function fnClickedMenu() {
		fnClickedEscape()//Функция нажатия на клавишу Escape
		root.clickedSettings()//Сигнал излучает открытие настроек.
    }
    function fnClickedSidebar() {//Функция нажатия кнопки SideBar (боковая панель).
        if(dcSidebar.position){//Если боковая панель открыта, то...
        	dcSidebar.close()//Закрываем её
        }
        else//Если боковая панель закрыта, то...
            dcSidebar.open()//Открываем её.
    }
    function fnCloseSidebarIfOpen() {//Закрываем боковую панель настроек, если она открыта.
        if(dcSidebar.position){//Если боковая панель открыта, то...
        	dcSidebar.close()//Закрываем её
            return true
        }
        return false
    }
    function fnClickedInfo() {
		fnClickedEscape()//Функция нажатия на клавишу Escape
        root.clickedInfo()
    }
    function fnPathToUrl(localPath) {//Преобразуем локальный путь в URL диалога.
		if (!localPath) return ""
		if (localPath.startsWith("file://")) return localPath//Если это уже URL — возвращаем как есть
		//Для локальных файлов нужен формат file:///
		if (localPath.startsWith("/")) {//Linux: /home/user/ -> file:///home/user/ (добавляем file://)
			return "file://" + localPath//file:// + /path = file:///path
		} else {//Windows: C:/Users/ -> file:///C:/Users/ (добавляем file:///)
			return "file:///" + localPath//file:/// + C:/path = file:///C:/path
		}	
    }
    function fnUrlToLocalPath(url) {//Преобразуем URL диалога в локальный путь.
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
    function fnImyaDokument(strPut) {//Достаём имя документа из полного пути.
        var chPos = strPut.lastIndexOf("/")
        if (chPos >= 0) return strPut.substring(chPos + 1)
        return strPut
    }
    function fnUstanovitDokumenty(vrPutei) {//Пишем список документов, UI, и путь к папке с файлами в реестр.
        root.strSpisokDokumentov = vrPutei
		if(vrPutei.length > 0){//Проверяем длину массива, если она не ноль, то сохраняем в реестр путь папки.
			var filePut = vrPutei[0].toString()//Получаем путь для первого файла.
			filePut = fnUrlToLocalPath(filePut)//Используем кроссплатформенную функцию Убираем "file://" 
			var papkaPut = filePut.substring(0, filePut.lastIndexOf('/'));//Обрезаем имя файла по /
			DCSettings.orfograf_put_text = papkaPut//Записываем в реестр имя папки в реестр.
		}
        knopkaZagruzitOchistit_1.visible = vrPutei.length > 0
        knopkaZagruzitOchistit_2.visible = vrPutei.length > 0
        knopkaAnaliz.enabled = vrPutei.length > 0 && !tmrLogo.running
    }
    function fnClickedZagruzit() {//Функция открытия диалога загрузки документов.
        dialogZagruzit.open()//Открываем диалог выбора .txt документов.
    }
    function fnClickedPapka() {//Функция диалога выбора папки результатов.
        dialogPapka.open()//Открываем диалог выбора папки.
    }
    function fnClickedOrfograf() {//Функция запуска исправления орфографии.
        if (root.strSpisokDokumentov.length === 0) {
            fnClickedZagruzit()//Нет документов - предлагаем сначала загрузить.
            return
        }
		root.isServerZapustit = true
		root.isModelZagruzit = true//Устанавливаем флаг ожидания, из Str
        tmrLogo.running = true//Запускаем анимацию логотипа (режим анализа).
		if (DCSettings.orfograf_put_rezultat === ""){//Если путь для сохранения результатов пустой, то..
			DCSettings.orfograf_put_rezultat = fnUrlToLocalPath(StandardPaths.writableLocation(StandardPaths.DocumentsLocation))
		}
        txdRezultat.text = "⏳ Исправление орфографии...\n"
		pyLM.zapustitServer()//Всегда запускаем сервер, даже если он запущен.
    }
    function fnClickedStop() {//Функция остановки исправления орфографии.
        pyOrfograf.stopOrfografiya()//Запрещаем дальнейшую обработку в Python бэкенде.
        tmrLogo.running = false//Останавливаем анимацию логотипа (выход из режима анализа).
        root.toolbar("Исправление орфографии остановлено.")
    }
    function fnClickedOtkrit() {//Функция диалога осмотра исправленных документов.
        dialogOtkrit.open()//Открываем диалог в папке orfograf_put_rezultat.
    }
    function fnToggleMenu() {
        if (menuMenu.visible) menuMenu.visible = false
        else menuMenu.visible = true
    }
    function fnCloseMenuIfOpen() {
        if (menuMenu.visible) {
            menuMenu.visible = false
            return true
        }
        return false
    } 
    FolderDialog {//Диалог выбора папки сохранения исправленных документов
        id: dialogPapka
        title: "Выберите папку для исправленных документов"
        currentFolder: {
            if (DCSettings.orfograf_put_rezultat !== "") {
                return fnPathToUrl(DCSettings.orfograf_put_rezultat)
            }
            else return StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        }
        onAccepted: {
			var vrPut = fnUrlToLocalPath(selectedFolder)//Используем кроссплатформенную функцию
            DCSettings.orfograf_put_rezultat = vrPut//Пишем путь в реестр.
            root.toolbar(`Орфография. Выбрана папка результатов: ${vrPut}`)
        }
        onRejected: {}
    }
    FileDialog {//Диалог загрузки текстовых документов
        id: dialogZagruzit
        title: "Выберите текстовые документы (*.txt) для исправления орфографии"
        currentFolder: {
            if (DCSettings.orfograf_put_text !== "") {
                return fnPathToUrl(DCSettings.orfograf_put_text)
            }
            else return StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        }
        nameFilters: ["Текстовые файлы (*.txt)", "Все файлы (*)"]
        fileMode: FileDialog.OpenFiles//Множественный выбор файлов
        onAccepted: {
            var vrPutei = []
            for (var i = 0; i < selectedFiles.length; i++)//Собираем локальные пути.
                vrPutei.push(fnUrlToLocalPath(selectedFiles[i]))
            fnUstanovitDokumenty(vrPutei)//Запоминаем список документов и сохраняем в реестр путь к папке
            root.toolbar("Загружено документов: " + vrPutei.length)	
        }
        onRejected: {}
    }
    FileDialog {//Диалог открытия исправленного документа для просмотра
        id: dialogOtkrit
        title: "Выберите исправленный документ для просмотра"
        currentFolder: {
            if (DCSettings.orfograf_put_rezultat !== "") {
                return fnPathToUrl(DCSettings.orfograf_put_rezultat)
            }
            else return StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        }
        nameFilters: ["Текстовые файлы (*.txt)", "Все файлы (*)"]
        fileMode: FileDialog.OpenFile
        onAccepted: {
			var vrPutFaila = fnUrlToLocalPath(selectedFile);//Преобразуем в путь из url
			root.toolbar(`Орфография. Выбран файл: ${vrPutFaila}`)//Сообщение в toolbar и журнал.
            pyFileOpener.openFile(selectedFile.toString())//Открываем файл через Python.
        }
        onRejected: {}
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
        DCKnopkaSidebar {//Кнопка боковой панели страницы орфографии.
            id: knopkaSidebar
            opened: dcSidebar.opened//Подсвечиваем кнопку когда боковая панель открыта.
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.verticalCenter: tmZagolovok.verticalCenter
            anchors.right: knopkaMenu.left
            clrKnopki: root.clrTexta
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff
            tapWidth: tapHeight * root.tapZagolovokPravi
            isInvers: true
            onClicked: if (!fnCloseMenuIfOpen()) fnClickedSidebar()//Функция нажатия кнопки SideBar.
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
        DCVopros {//Вопрос об остановке процесса исправления орфографии
            id: vprVopros
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            anchors.top: tmZagolovok.top; anchors.bottom: tmZagolovok.bottom
            anchors.left: tmZagolovok.left; anchors.right: tmZagolovok.right
            clrFona: root.clrVnimanie; clrTexta: root.clrFona
            clrKnopki: root.clrFona; clrBorder: root.clrFona
            tapKnopkaZakrit: root.tapZagolovokLevi; tapKnopkaOk: root.tapZagolovokPravi
            visible: false
            property int ntFlag: 0//0 - нет вопроса, 22 - остановить анализ документов.
            text: {
                if (ntFlag === 22)
                    return qsTr("ОСТАНОВИТЬ ИСПРАВЛЕНИЕ ОРФОГРАФИИ?")
                else return qsTr("Любовь")
            }
            onVisibleChanged: {
                if (visible) {//Прячем кнопки заголовка, пока висит вопрос.
                    knopkaNazad.visible = false
                    knopkaMenu.visible = false
                } else {
                    knopkaNazad.visible = true
                    knopkaMenu.visible = true
                    root.forceActiveFocus()//Возвращаем фокус, чтоб работали горячие клавиши.
                }
            }
            onClickedOk: {
                vprVopros.visible = false//Делаем диалог невидимым
                if (ntFlag === 22) fnClickedStop()//Останавливаем анализ документов.
            }
            onClickedOtmena: {
                vprVopros.visible = false//Делаем диалог невидимым.
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
			logoOpacity: 0.1
			z: -1
		}
        Flickable {
            id: flcZona
			//Свойства
			property int __height: 0//Высота области Результата с кнопкой Сохранить Результат.
			//Настройки
            anchors.fill: parent
            contentWidth: tmZona.width
            contentHeight: clmnContent.height
            clip: true
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            opacity: 0.9//ГЛАВНАЯ ПРОЗРАЧНОСТЬ!!!
            anchors.rightMargin: dcSidebar.position * dcSidebar.width - dcSidebar.position * root.ntCoff
			//Методы
			onHeightChanged: {//Если изменяется высота Flickable, то...
				flcZona.__height = flcZona.height 	- txtRezultat.height
															- knopkaOtkrit.height
															- txtKlavishi.height
															- root.ntCoff * 4
			}
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
                spacing: root.ntCoff/2//Расстояние между элементами по вертикали.
                topPadding: root.ntCoff * 2
                bottomPadding: root.ntCoff * 2
                leftPadding: root.ntCoff * 2
                rightPadding: root.ntCoff * 2
                
                RowLayout {//Строка загрузки документов и очистки списка
                    id: rowZagruzit
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    spacing: root.ntCoff / 2
					DCKnopkaZakrit {//Кнопка очистки списка загруженных документов
                        id: knopkaZagruzitOchistit_1
                        ntWidth: root.ntWidth; ntCoff: root.ntCoff
						clrKnopki: root.clrTexta; clrFona: root.clrFona
                        visible: false
                        onClicked: fnUstanovitDokumenty([])//Очищаем список документов.
                    }
                    DCKnopkaOriginal {//Кнопка загрузки документов
                        id: knopkaZagruzit
                        text: "📂 загрузить ваши документы"
                        ntHeight: root.ntWidth; ntCoff: root.ntCoff
                        clrKnopki: root.clrTexta; clrTexta: root.clrFona
						Layout.fillWidth: true //Растягиваемся по всей длине
						Layout.preferredHeight: root.ntWidth * root.ntCoff + root.ntCoff
                        onClicked: {
                            if (!fnCloseMenuIfOpen()) fnClickedZagruzit()
                        }
                    }
                    DCKnopkaZakrit {//Кнопка очистки списка загруженных документов
                        id: knopkaZagruzitOchistit_2
                        ntWidth: root.ntWidth; ntCoff: root.ntCoff
						clrKnopki: root.clrTexta; clrFona: root.clrFona
                        visible: false
                        onClicked: fnUstanovitDokumenty([])//Очищаем список документов.
                    }
                }
                Column {//Список загруженных документов
                    id: clmnDokumenty
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    Repeater {
                        model: root.strSpisokDokumentov
                        Text {
                            text: "   " + (index + 1) + ". " + root.fnImyaDokument(modelData)
                            color: root.clrTexta
                            font.pixelSize: root.ntCoff * 1.2
                        }
                    }
                }
                DCKnopkaOriginal {//Кнопка выбора папки результатов
                    id: knopkaPapka
                    ntHeight: root.ntWidth; ntCoff: root.ntCoff
                    clrKnopki: root.clrTexta; clrTexta: root.clrFona
					anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
                    text: "📁 папка результатов: " + DCSettings.orfograf_put_rezultat
                    onClicked: {
                        if (!fnCloseMenuIfOpen()) fnClickedPapka()
                    }
                }
                DCKnopkaOriginal {//Кнопка запуска исправления орфографии
                    id: knopkaAnaliz
                    ntHeight: root.ntWidth; ntCoff: root.ntCoff
                    clrKnopki: root.clrTexta; clrTexta: root.clrFona
					anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
					text: {
						if(dcTimer.blStart) return "📊 исправление: " + dcTimer.strTimer
						else return "✍️ исправить орфографию документов"
					}
                    enabled: false
                    onClicked: {
                        if (!fnCloseMenuIfOpen()) fnClickedOrfograf()
                    }
                } 
				DCTimer {//Таймер
					id: dcTimer
					property string strVremyaAnaliza: ""
				}
				Text {//Результат
					id: txtRezultat
					text: {
						let ltRezultat = "Результат: "
						if(!dcTimer.blStart) ltRezultat += dcTimer.strVremyaAnaliza 
						return ltRezultat
					}
                    font.pixelSize: root.ntWidth/2 * root.ntCoff
                    color: root.clrTexta
					font.bold: true//Жирный текст.
                    width: parent.width - parent.leftPadding - parent.rightPadding
                }
                DCTextEdit {//Поле отчёта исправления орфографии
                    id: txdRezultat
                    width: parent.width - parent.leftPadding - parent.rightPadding
					height: flcZona.__height
                    ntWidth: root.ntWidth/2//разделить на 2, чтоб уменьшить размер шрифта и скролбар
                    ntCoff: root.ntCoff
                    readOnly: true
                    scrollAuto: false
                    clrFona: "transparent"; clrTexta: root.clrTexta
                    clrPolzunka: Qt.lighter(root.clrMenuFon, 1.3); clrBorder: root.clrTexta
                    radius: root.ntCoff / 2
                    isBorder: true//Показываем бордюр области текста.
                    placeholderText: "Отчёт об исправлении орфографии появится здесь."
                }
                Text {//Подсказка по горячим клавишам
					id: txtKlavishi
                    text: "Alt+← назад | Alt+F настройка AI | Alt+S настройка орфографии | Ctrl+Enter старт проверки орфографии | F1 справка"
                    color: "grey"
                    font.pixelSize: root.ntCoff * 1.1
                }
				DCKnopkaOriginal {//Кнопка осмотра исправленных документов
                    id: knopkaOtkrit
                    ntHeight: root.ntWidth; ntCoff: root.ntCoff
                    clrKnopki: root.clrTexta; clrTexta: root.clrFona
					anchors.left: parent.left; anchors.right: parent.right
                    anchors.leftMargin: root.ntCoff * 2; anchors.rightMargin: root.ntCoff * 2
                    text: "👁 открыть исправленные документы"
                    enabled: true
                    onClicked: {
                        if (!fnCloseMenuIfOpen()) fnClickedOtkrit()
                    }
                }
            }
        }
        SetOrfograf {
            id: dcSidebar
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            height: tmZona.height
            clrTexta: root.clrTexta; clrFona: root.clrFona; clrMenuFon: root.clrMenuFon
            isMobile: root.isMobile
            onOpenedChanged: {//Если состояние боковой панели изменилось, она открыта или закрыта, то...
                if(opened) fnFocus()//Фокус на странице настроек нейро орфографии
                else root.forceActiveFocus()//Фокус на странице исправления текста.
            }
            onClickedInfo: root.clickedInfoOrfograf()//Информация по настройкам орфографии.
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
            imyaMenu: "orfograf"
            
            onClicked: function(ntNomer, strMenu) {
                menuMenu.visible = false
                
                if (ntNomer === 1) {
                    fnClickedZagruzit()
                } else if (ntNomer === 2) {
                    fnClickedOrfograf()
                }  else if (ntNomer === 3) {
                    fnClickedMenu()
                } else if (ntNomer === 4) {
                    fnClickedSidebar()//Функция нажатия кнопки SideBar (боковая панель).
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
			onActiveChanged: {
				if (active){//Если активировался прогресбар, то...
					dcTimer.blStart = true//Запуск таймера.
					dcSidebar.readOnly = true//Запрещено редактировать
					dcSidebar.isEnabled = false
					fnCloseSidebarIfOpen()
					knopkaInfo.visible = false
					knopkaNastroiki.visible = false
					knopkaMenu.enabled = false
					knopkaNazad.enabled = true//КнопкаНазад всегда активна.
					knopkaZagruzit.enabled = false
					knopkaZagruzitOchistit_1.enabled = false
					knopkaZagruzitOchistit_2.enabled = false
					knopkaPapka.enabled = false
					knopkaAnaliz.enabled = false
					knopkaOtkrit.enabled = false					
				} else {
					dcTimer.strVremyaAnaliza = dcTimer.strTimer
					dcTimer.blStart = false//Останавливаем таймер.
					dcSidebar.readOnly = false//Разрешено редактировать
					dcSidebar.isEnabled = true
					knopkaInfo.visible = true
					knopkaNastroiki.visible = true
					knopkaMenu.enabled = true
					knopkaNazad.enabled = true
					knopkaZagruzit.enabled = true
					knopkaZagruzitOchistit_1.enabled = true
					knopkaZagruzitOchistit_2.enabled = true
					knopkaPapka.enabled = true
					knopkaAnaliz.enabled = root.strSpisokDokumentov.length > 0
					knopkaOtkrit.enabled = true
				}
			}
			onLoaded: {
                ldrProgress.item.ntWidth = root.ntWidth
                ldrProgress.item.ntCoff = root.ntCoff
                ldrProgress.item.clrProgress = root.clrTexta
                ldrProgress.item.clrTexta = "grey"
                ldrProgress.item.radius = root.ntCoff / 4
				ldrProgress.item.msInterval = ldrProgress.interval//Пауза между смещением.
            }
			onTotalChanged: {//Если переменная изменилась, то происходит пересчёт скорости смещения.
				if(ldrProgress.item)//Если существует
					ldrProgress.item.msInterval = interval * total//Чем больше файлов, тем медленней движется.
			}
        }
        DCKnopkaInfo {
            id: knopkaInfo
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            anchors.verticalCenter: tmToolbar.verticalCenter; anchors.left: tmToolbar.left
            clrKnopki: root.clrTexta; clrFona: root.clrFona
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff; tapWidth: tapHeight * root.tapToolbarLevi
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
