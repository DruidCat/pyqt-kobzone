import QtQuick
import QtQuick.Controls
import DCMethods 1.0//Импортируем DCToolbar
import DCPages 1.0//Импортируем страницы программы.
import DCSettings 1.0//Импортируем страницы настроек.

ApplicationWindow {
	id: root
	//Основные настройки приложения
	readonly property color clrKnopok: "#2d4288"//Индиго
	readonly property color clrFona: "lightgrey"
	readonly property color clrStranic: "#f5f5f5"
	readonly property color clrMenuText: "#2d4288"//Индиго
	readonly property int logoRazmer: 22//Размер Логотита в приложении.
	readonly property string logoImya: "kobzone"//Имя логотипа в DCLogo

	property int shrift: 2//1 - маленький, 2 - средний, 3 - большой
	property int ntWidth: 2 * shrift
	property int ntCoff: 8
 	
	property string pythonVersion: "N/A"
	property string qtVersion: "N/A"
	property bool isMobile: {//Переменная определяющая, мобильная это платформа или нет. true - мобильная.
        if((Qt.platform.os === "android") || (Qt.platform.os === "ios"))//Если мобильная платформа, то...
			return true;//Это мобильная платформа.
		else//Эсли не мобильная, то...
			return false;//Это не мобильная платформа.
	}
	//Настройки окна
	visible: true
	color: clrFona
	title: "Любимая КОБзона"
	//width: 1100
	//height: 550
    x: isMobile ? 0 : dcReestr.kobzone_x//Считываем из реестра X (в бизнес-логике)
    y: isMobile ? 0 : dcReestr.kobzone_y//Считываем из реестра Y (в бизнес-логике)
    width: {
        var vrWidth = Screen.desktopAvailableWidth;//Расчитываем доступную ширину экрана
        if(isMobile)//Если мобильная платформа, то...
            return vrWidth;//Масимально возможная ширина.
        else
            return dcReestr.kobzone_shirina;//Считываем из реестра ширину окна.
    }
    height: {
        var vrHeight = Screen.desktopAvailableHeight//Расчитываем доступную высоту экрана
        if(isMobile)//Если мобильная платформа, то...
            return vrHeight;//Масимально возможная ширина.
        else
            return dcReestr.kobzone_visota;//Считываем из реестра высоту окна.
    }
    minimumWidth: {//Минимальная ширина не для мобильных платформ.
        if(!isMobile)//Если не мобильная платформа, то...
            return ntWidth*ntCoff*12.4;//Расчёт по виджету DCSpinBox и DCScale.
    }
    minimumHeight: {//Минимальная высота не для мобильных платформ.
        if(!isMobile)//Если не мобильная платформа, то...
            return 330;
    }
    //Методы
	DCSettings {//Объект настроек
        id: dcReestr
    }
    function ensureOnScreen() {//Функция не дающая окну оказаться вне видимой области экрана
        if (isMobile) return//Если мобильное устройство, выходим из функции.
        // Может быть undefined до показа окна/привязки к монитору
        var scr = root.screen
        var a = null

        if (scr && scr.availableGeometry && scr.availableGeometry.width !== undefined) {
            a = scr.availableGeometry
        } else if (scr && scr.geometry && scr.geometry.width !== undefined) {
            a = scr.geometry// fallback #1
        } else {
            a = { x: 0, y: 0,
                  width: Screen.desktopAvailableWidth,
                  height: Screen.desktopAvailableHeight }//fallback #2 — первичный экран (без учёта панелей)
        }
        if (!a || a.width === undefined || a.height === undefined) {// Если всё ещё нет валидной геометрии, то
            Qt.callLater(ensureOnScreen)//Через паузу попробуем позже
            return
        }
        var maxX = a.x + Math.max(0, a.width  - width)
        var maxY = a.y + Math.max(0, a.height - height)
        var nx = Math.min(Math.max(x, a.x), maxX)
        var ny = Math.min(Math.max(y, a.y), maxY)
        if (nx !== x) x = nx
        if (ny !== y) y = ny
    }
    onWidthChanged: {//Если Ширина поменялась, то...
        if(!isMobile){//Если не мобильная платформа, то...
            dcReestr.kobzone_shirina = width;//Отправляем в бизнес логику ширину окна, для обработки.
        }
    }
    onHeightChanged: {//Если Высота поменялась, то...
        if(!isMobile){//Если не мобильная платформа, то...
            dcReestr.kobzone_visota = height;//Отправляем в бизнес логику высоту окна, для обработки.
        }
    }
    onXChanged: {//Если X координата изменилась, то...
        if (!isMobile)//Если не мобильное устройство, то...
            dcReestr.kobzone_x = x;//Сохранение X координаты в бизнес-логику
    }
    onYChanged: {//Если Y координата изменилась, то...
        if (!isMobile)//Если не мобильное устройство, то...
            dcReestr.kobzone_y = y;//Сохранение Y координаты в бизнес-логику
    }
    onVisibleChanged: {//Вызывать кламп после показа окна
        if(visible && !isMobile) Qt.callLater(ensureOnScreen)//Если видимое окно и не мобильное устройство
    }
    onScreenChanged: {//При смене экрана (перетаскивание между мониторами)
        if(!isMobile) Qt.callLater(ensureOnScreen)
    }
	Component.onCompleted: {
		stvStr.currentItem.forceActiveFocus()
		toolbar.log("✓ Шрифт:" + " " + font.family)
		//загружаем данные из python
		root.pythonVersion = pyPythonInfo.pythonVersion
		root.qtVersion = pyQtInfo.qtVersion
        if(!isMobile) Qt.callLater(ensureOnScreen)//Немного отложим, чтобы гарантированно применились размеры
	}
	DCToolbar {
		id: toolbar
		vrStranica: stvStr.pgStrKOBzone//Первоначальное свойство передаю
		second: 3
		onTextChanged: {
			vrStranica.textToolbar = toolbar.text//Отображаем ИМЕННО ТАК.
			tmJurnal.strDebug = toolbar.text;//Добавляем строчку в toolbar для записи и отображения
		}
		onLogsChanged: {
			//Отправляем в Логи сообщение.
			if(logs !== ""){//Если не пустая строка, то...
				pyConsole.log(toolbar.logs)//Отображаем в консоль. Минуя сломанную кодировку консоли Windows.
				//tmJurnal.strDebug = toolbar.logs;//Добавляем строчку в лог для записи и отображения
			}
		}
	}
	StackView {
		id: stvStr
		anchors.fill: parent
		initialItem: pgStrKOBzone
		focus: true

		onCurrentItemChanged: {
			if (currentItem) {
				Qt.callLater(function() {
					currentItem.forceActiveFocus()
					toolbar.vrStranica = currentItem;//Передаём указатель на страницу, которая открыта.
					toolbar.log("Фокус установлен на:" + " " + currentItem)
				})
			}
		}
		Stranica {//Любимая КОБзона
		///////////////////////////////////
		///Л Ю Б И М А Я   К О Б З О Н А///
		///////////////////////////////////
			id: pgStrKOBzone
			visible: false
			focus: true
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrFona; clrTexta: root.clrKnopok; clrRabOblasti: root.clrStranic
			textZagolovok: "МЕНЮ"
			zagolovokLevi: 1.3; zagolovokPravi: 1.3
			toolbarLevi: 1.3; toolbarPravi: 1.3
            
			onVisibleChanged: {
				if (visible) {
					toolbar.log("pgStrKOBzone стала видимой")
					Qt.callLater(function() {
						tmKOBzone.forceActiveFocus()
						toolbar.log("Фокус передан на tmKOBzone")//Передаём в лог сообщение
					})
				}
			}
			StrKOBzone {
				id: tmKOBzone
				ntWidth: pgStrKOBzone.ntWidth; ntCoff: pgStrKOBzone.ntCoff
				clrTexta: pgStrKOBzone.clrTexta; clrFona: pgStrKOBzone.clrRabOblasti
				clrMenuText: root.clrMenuText; clrMenuFon: pgStrKOBzone.clrFona
				zagolovokX: pgStrKOBzone.rctStrZagolovok.x; zagolovokY: pgStrKOBzone.rctStrZagolovok.y
				zagolovokWidth: pgStrKOBzone.rctStrZagolovok.width
				zagolovokHeight: pgStrKOBzone.rctStrZagolovok.height
				zonaX: pgStrKOBzone.rctStrZona.x; zonaY: pgStrKOBzone.rctStrZona.y
				zonaWidth: pgStrKOBzone.rctStrZona.width; zonaHeight: pgStrKOBzone.rctStrZona.height
				toolbarX: pgStrKOBzone.rctStrToolbar.x; toolbarY: pgStrKOBzone.rctStrToolbar.y
				toolbarWidth: pgStrKOBzone.rctStrToolbar.width
				toolbarHeight: pgStrKOBzone.rctStrToolbar.height
				tapZagolovokLevi: pgStrKOBzone.zagolovokLevi; tapZagolovokPravi: pgStrKOBzone.zagolovokPravi
				tapToolbarLevi: pgStrKOBzone.toolbarLevi; tapToolbarPravi: pgStrKOBzone.toolbarPravi
				logoRazmer: root.logoRazmer; logoImya: root.logoImya
				onClickedAnalizator: {
					pgStrAnalizer.textZagolovok = "НЕЙРО АНАЛИЗ ДОКУМЕНТОВ"
					stvStr.push(pgStrAnalizer)
				}
				onClickedOrfograf: {
					pgStrOrfograf.textZagolovok = "ИСПРАВЛЕНИЕ ТЕКСТА"
					stvStr.push(pgStrOrfograf)
				}
				onClickedTranskribaciya: {
					pgStrTranscribe.textZagolovok = "ТРАНСКРИБАЦИЯ"
					stvStr.push(pgStrTranscribe)
				}
				onClickedSettings: {
					stvStr.push(pgStrSetKOBzone)
				}
				onClickedInfo: {
					tmStrInstrukciya.strInstrukciya = "oprilojenii"
					stvStr.push(pgStrInstrukciya)//Переходим на страницу Инструкции Меню
				}
				onToolbar: function(strToolbar) {//Если сигнал пришёл с текстом в toolbar, то...
					toolbar.fnText(strToolbar)//Передаём на отображение в toolbar сообщение.
				}
				onLog: function (strLog) {//Если сигнал пришёл с текстом в log, то...
					toolbar.log(strLog)//Передаём в лог сообщение.
				}
			}
		}
		Stranica {//Настройка Любимой КОБзона
		///////////////////////////////////////
		///Н А С Т Р О Й К А   К О Б З О Н А///
		///////////////////////////////////////
			id: pgStrSetKOBzone
			visible: false; focus: true
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrFona; clrTexta: root.clrKnopok; clrRabOblasti: root.clrStranic
			textZagolovok: "НАСТРОЙКА ПРИЛОЖЕНИЯ"
			zagolovokLevi: 1.3; zagolovokPravi: 1.3; toolbarLevi: 1.3; toolbarPravi: 1.3
			onVisibleChanged: {
				if (visible) {
					Qt.callLater(function() {
						tmSetKOBzone.forceActiveFocus()
						toolbar.log("Фокус передан на tmSetKOBzone")
					})
				}
			}
			SetKOBzone {
				id: tmSetKOBzone
				ntWidth: pgStrSetKOBzone.ntWidth; ntCoff: pgStrSetKOBzone.ntCoff
				clrTexta: pgStrSetKOBzone.clrTexta; clrFona: pgStrSetKOBzone.clrRabOblasti
				clrMenuText: root.clrMenuText; clrMenuFon: pgStrTranscribe.clrFona
				zagolovokX: pgStrSetKOBzone.rctStrZagolovok.x; zagolovokY: pgStrSetKOBzone.rctStrZagolovok.y
				zagolovokWidth: pgStrSetKOBzone.rctStrZagolovok.width
				zagolovokHeight: pgStrSetKOBzone.rctStrZagolovok.height
				zonaX: pgStrSetKOBzone.rctStrZona.x; zonaY: pgStrSetKOBzone.rctStrZona.y
				zonaWidth: pgStrSetKOBzone.rctStrZona.width; zonaHeight: pgStrSetKOBzone.rctStrZona.height
				toolbarX: pgStrSetKOBzone.rctStrToolbar.x; toolbarY: pgStrSetKOBzone.rctStrToolbar.y
				toolbarWidth: pgStrSetKOBzone.rctStrToolbar.width
				toolbarHeight: pgStrSetKOBzone.rctStrToolbar.height
				tapZagolovokLevi: pgStrSetKOBzone.zagolovokLevi; tapZagolovokPravi: pgStrSetKOBzone.zagolovokPravi
				tapToolbarLevi: pgStrSetKOBzone.toolbarLevi; tapToolbarPravi: pgStrSetKOBzone.toolbarPravi
				logoRazmer: root.logoRazmer; logoImya: root.logoImya
				onClickedNazad: {
					stvStr.pop()//Назад страницу
					Qt.callLater(function() {
						stvStr.currentItem.forceActiveFocus()
					})
				}
				onClickedInfo: {
					tmStrInstrukciya.strInstrukciya = "set_kobzone"
					stvStr.push(pgStrInstrukciya)
				}
				onClickedJurnal: {
					stvStr.push(pgStrJurnal)//Открываем Журнал
				}
				onToolbar: function(strToolbar) {//Если сигнал пришёл с текстом в toolbar, то...
					toolbar.fnText(strToolbar)//Передаём на отображение в toolbar сообщение.
				}
				onLog: function (strLog) {//Если сигнал пришёл с текстом в log, то...
					toolbar.log(strLog)//Передаём в лог сообщение.
				}
			}
		}
		Stranica {//Нейро анализатор
		/////////////////////////////////////
		///Н Е Й Р О   А Н А Л И З А Т О Р///
		/////////////////////////////////////
			id: pgStrAnalizer
			visible: false
			focus: true
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrFona; clrTexta: root.clrKnopok; clrRabOblasti: root.clrStranic
			zagolovokLevi: 1.3; zagolovokPravi: 1.3; toolbarLevi: 1.3; toolbarPravi: 1.3
			onVisibleChanged: {
				if (visible) {
					Qt.callLater(function() {
						tmAnalizer.forceActiveFocus()
						toolbar.log("Фокус передан на tmAnalizer")
					})
				}
			}
			StrAnalizer {
				id: tmAnalizer
				ntWidth: pgStrAnalizer.ntWidth; ntCoff: pgStrAnalizer.ntCoff
                clrTexta: pgStrAnalizer.clrTexta; clrFona: pgStrAnalizer.clrRabOblasti
                clrMenuText: root.clrMenuText; clrMenuFon: pgStrAnalizer.clrFona
				zagolovokX: pgStrAnalizer.rctStrZagolovok.x; zagolovokY: pgStrAnalizer.rctStrZagolovok.y
				zagolovokWidth: pgStrAnalizer.rctStrZagolovok.width
				zagolovokHeight: pgStrAnalizer.rctStrZagolovok.height
				zonaX: pgStrAnalizer.rctStrZona.x; zonaY: pgStrAnalizer.rctStrZona.y
				zonaWidth: pgStrAnalizer.rctStrZona.width; zonaHeight: pgStrAnalizer.rctStrZona.height
				toolbarX: pgStrAnalizer.rctStrToolbar.x; toolbarY: pgStrAnalizer.rctStrToolbar.y
				toolbarWidth: pgStrAnalizer.rctStrToolbar.width
				toolbarHeight: pgStrAnalizer.rctStrToolbar.height
                tapZagolovokLevi: pgStrAnalizer.zagolovokLevi; tapZagolovokPravi: pgStrAnalizer.zagolovokPravi
                tapToolbarLevi: pgStrAnalizer.toolbarLevi; tapToolbarPravi: pgStrAnalizer.toolbarPravi
				logoRazmer: root.logoRazmer; logoImya: root.logoImya
				onClickedNazad: {
					stvStr.pop()
					Qt.callLater(function() {
						stvStr.currentItem.forceActiveFocus()
					})
				}
				onClickedSettings: {
					stvStr.push(pgStrSetAnalizer)
				}
				onClickedInfo: {
					tmStrInstrukciya.strInstrukciya = "analizer"
					stvStr.push(pgStrInstrukciya)//Переходим на страницу инструкций Анализа Документа
				}
				onToolbar: function(strToolbar) {//Если сигнал пришёл с текстом в toolbar, то...
					toolbar.fnText(strToolbar)//Передаём на отображение в toolbar сообщение.
				}
				onLog: function (strLog) {//Если сигнал пришёл с текстом в log, то...
					toolbar.log(strLog)//Передаём в лог сообщение.
				}
			}
		}
		Stranica {//Настройка нейро анализа 
		///////////////////////////////////////
		///Н А С Т Р О Й К А   А Н А Л И З А///
		///////////////////////////////////////
			id: pgStrSetAnalizer
			visible: false; focus: true
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrFona; clrTexta: root.clrKnopok; clrRabOblasti: root.clrStranic
			textZagolovok: "НАСТРОЙКА НЕЙРО АНАЛИЗА"
			zagolovokLevi: 1.3; zagolovokPravi: 1.3; toolbarLevi: 1.3; toolbarPravi: 1.3
			onVisibleChanged: {
				if (visible) {
					Qt.callLater(function() {
						tmSetAnalizer.forceActiveFocus()
						toolbar.log("Фокус передан на tmSetAnalizer")
					})
				}
			}
			SetAnalizer{
				id: tmSetAnalizer
				ntWidth: pgStrSetAnalizer.ntWidth; ntCoff: pgStrSetAnalizer.ntCoff
				clrTexta: pgStrSetAnalizer.clrTexta; clrFona: pgStrSetAnalizer.clrRabOblasti
				clrMenuText: root.clrMenuText; clrMenuFon: pgStrTranscribe.clrFona
				zagolovokX: pgStrSetAnalizer.rctStrZagolovok.x; zagolovokY: pgStrSetAnalizer.rctStrZagolovok.y
				zagolovokWidth: pgStrSetAnalizer.rctStrZagolovok.width
				zagolovokHeight: pgStrSetAnalizer.rctStrZagolovok.height
				zonaX: pgStrSetAnalizer.rctStrZona.x; zonaY: pgStrSetAnalizer.rctStrZona.y
				zonaWidth: pgStrSetAnalizer.rctStrZona.width; zonaHeight: pgStrSetAnalizer.rctStrZona.height
				toolbarX: pgStrSetAnalizer.rctStrToolbar.x; toolbarY: pgStrSetAnalizer.rctStrToolbar.y
				toolbarWidth: pgStrSetAnalizer.rctStrToolbar.width
				toolbarHeight: pgStrSetAnalizer.rctStrToolbar.height
				tapZagolovokLevi: pgStrSetAnalizer.zagolovokLevi; tapZagolovokPravi: pgStrSetAnalizer.zagolovokPravi
				tapToolbarLevi: pgStrSetAnalizer.toolbarLevi; tapToolbarPravi: pgStrSetAnalizer.toolbarPravi
				logoRazmer: root.logoRazmer; logoImya: root.logoImya
				onClickedNazad: {
					stvStr.pop()//Назад страницу
					Qt.callLater(function() {
						stvStr.currentItem.forceActiveFocus()
					})
				}
				onClickedInfo: {
					tmStrInstrukciya.strInstrukciya = "set_analizer"
					stvStr.push(pgStrInstrukciya)
				}
				onToolbar: function(strToolbar) {//Если сигнал пришёл с текстом в toolbar, то...
					toolbar.fnText(strToolbar)//Передаём на отображение в toolbar сообщение.
				}
				onLog: function (strLog) {//Если сигнал пришёл с текстом в log, то...
					toolbar.log(strLog)//Передаём в лог сообщение.
				}
			}
		}
		Stranica {//Орфография
		/////////////////////////
		///О Р Ф О Г Р А Ф И Я///
		/////////////////////////
			id: pgStrOrfograf
			visible: false
			focus: true
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrFona; clrTexta: root.clrKnopok; clrRabOblasti: root.clrStranic
			zagolovokLevi: 1.3; zagolovokPravi: 1.3; toolbarLevi: 1.3; toolbarPravi: 1.3
			onVisibleChanged: {
				if (visible) {
					Qt.callLater(function() {
						tmAnalizer.forceActiveFocus()
						toolbar.log("Фокус передан на tmOrfograf")
					})
				}
			}
			StrOrfograf {
				id: tmOrfograf
				ntWidth: pgStrOrfograf.ntWidth; ntCoff: pgStrOrfograf.ntCoff
				clrTexta: pgStrOrfograf.clrTexta; clrFona: pgStrOrfograf.clrRabOblasti
				clrMenuText: root.clrMenuText; clrMenuFon: pgStrOrfograf.clrFona
                zagolovokX: pgStrOrfograf.rctStrZagolovok.x; zagolovokY: pgStrOrfograf.rctStrZagolovok.y
				zagolovokWidth: pgStrOrfograf.rctStrZagolovok.width
				zagolovokHeight: pgStrOrfograf.rctStrZagolovok.height
                zonaX: pgStrOrfograf.rctStrZona.x; zonaY: pgStrOrfograf.rctStrZona.y
				zonaWidth: pgStrOrfograf.rctStrZona.width; zonaHeight: pgStrOrfograf.rctStrZona.height
                toolbarX: pgStrOrfograf.rctStrToolbar.x; toolbarY: pgStrOrfograf.rctStrToolbar.y
				toolbarWidth: pgStrOrfograf.rctStrToolbar.width
				toolbarHeight: pgStrOrfograf.rctStrToolbar.height
                tapZagolovokLevi: pgStrOrfograf.zagolovokLevi; tapZagolovokPravi: pgStrOrfograf.zagolovokPravi
                tapToolbarLevi: pgStrOrfograf.toolbarLevi; tapToolbarPravi: pgStrOrfograf.toolbarPravi
				logoRazmer: root.logoRazmer; logoImya: root.logoImya
				onClickedNazad: {
					stvStr.pop()
					Qt.callLater(function() {
						stvStr.currentItem.forceActiveFocus()
					})
				}
				onClickedSettings: {
					stvStr.push(pgStrSetOrfograf)
				}
				onClickedInfo: {
					tmStrInstrukciya.strInstrukciya = "orfograf"
					stvStr.push(pgStrInstrukciya)//Переходим на страницу инструкций Проверки Орфографии
				}
				onToolbar: function(strToolbar) {//Если сигнал пришёл с текстом в toolbar, то...
					toolbar.fnText(strToolbar)//Передаём на отображение в toolbar сообщение.
				}
				onLog: function (strLog) {//Если сигнал пришёл с текстом в log, то...
					toolbar.log(strLog)//Передаём в лог сообщение.
				}
			}
		}
		Stranica {//Настройка орфографии
		/////////////////////////////////////////////
		///Н А С Т Р О Й К А   О Р Ф О Г Р А Ф И И///
		/////////////////////////////////////////////
			id: pgStrSetOrfograf
			visible: false; focus: true
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrFona; clrTexta: root.clrKnopok; clrRabOblasti: root.clrStranic
			textZagolovok: "НАСТРОЙКА ОРФОГРАФИИ"
			zagolovokLevi: 1.3; zagolovokPravi: 1.3; toolbarLevi: 1.3; toolbarPravi: 1.3
			onVisibleChanged: {
				if (visible) {
					Qt.callLater(function() {
						tmSetOrfograf.forceActiveFocus()
						toolbar.log("Фокус передан на tmSetOrfograf")
					})
				}
			}
			SetOrfograf{
				id: tmSetOrfograf
				ntWidth: pgStrSetOrfograf.ntWidth; ntCoff: pgStrSetOrfograf.ntCoff
				clrTexta: pgStrSetOrfograf.clrTexta; clrFona: pgStrSetOrfograf.clrRabOblasti
				clrMenuText: root.clrMenuText; clrMenuFon: pgStrTranscribe.clrFona
				zagolovokX: pgStrSetOrfograf.rctStrZagolovok.x; zagolovokY: pgStrSetOrfograf.rctStrZagolovok.y
				zagolovokWidth: pgStrSetOrfograf.rctStrZagolovok.width
				zagolovokHeight: pgStrSetOrfograf.rctStrZagolovok.height
				zonaX: pgStrSetOrfograf.rctStrZona.x; zonaY: pgStrSetOrfograf.rctStrZona.y
				zonaWidth: pgStrSetOrfograf.rctStrZona.width; zonaHeight: pgStrSetOrfograf.rctStrZona.height
				toolbarX: pgStrSetOrfograf.rctStrToolbar.x; toolbarY: pgStrSetOrfograf.rctStrToolbar.y
				toolbarWidth: pgStrSetOrfograf.rctStrToolbar.width
				toolbarHeight: pgStrSetOrfograf.rctStrToolbar.height
				tapZagolovokLevi: pgStrSetOrfograf.zagolovokLevi; tapZagolovokPravi: pgStrSetOrfograf.zagolovokPravi
				tapToolbarLevi: pgStrSetOrfograf.toolbarLevi; tapToolbarPravi: pgStrSetOrfograf.toolbarPravi
				logoRazmer: root.logoRazmer; logoImya: root.logoImya
				onClickedNazad: {
					stvStr.pop()//Назад страницу
					Qt.callLater(function() {
						stvStr.currentItem.forceActiveFocus()
					})
				}
				onClickedInfo: {
					tmStrInstrukciya.strInstrukciya = "set_orfograf"
					stvStr.push(pgStrInstrukciya)
				}
				onToolbar: function(strToolbar) {//Если сигнал пришёл с текстом в toolbar, то...
					toolbar.fnText(strToolbar)//Передаём на отображение в toolbar сообщение.
				}
				onLog: function (strLog) {//Если сигнал пришёл с текстом в log, то...
					toolbar.log(strLog)//Передаём в лог сообщение.
				}
			}
		}
		Stranica {//Транскрибация
		//////////////////////////////
		///Т Р А Н С К Р И Б А Ц И Я//
		//////////////////////////////
			id: pgStrTranscribe
			visible: false
			focus: true
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrFona; clrTexta: root.clrKnopok; clrRabOblasti: root.clrStranic
			textZagolovok: "ТРАНСКРИБАЦИЯ"
			zagolovokLevi: 1.3; zagolovokPravi: 1.3; toolbarLevi: 1.3; toolbarPravi: 1.3
			onVisibleChanged: {
				if (visible) {
					Qt.callLater(function() {
						tmTranscribe.forceActiveFocus()
						toolbar.log("Фокус передан на tmTranscribe")
					})
				}
			}
			StrTranscribe {
				id: tmTranscribe
				ntWidth: pgStrTranscribe.ntWidth; ntCoff: pgStrTranscribe.ntCoff
				clrTexta: pgStrTranscribe.clrTexta; clrFona: pgStrTranscribe.clrRabOblasti
				clrMenuText: root.clrMenuText; clrMenuFon: pgStrTranscribe.clrFona
				zagolovokX: pgStrTranscribe.rctStrZagolovok.x
				zagolovokY: pgStrTranscribe.rctStrZagolovok.y
				zagolovokWidth: pgStrTranscribe.rctStrZagolovok.width
				zagolovokHeight: pgStrTranscribe.rctStrZagolovok.height
				zonaX: pgStrTranscribe.rctStrZona.x; zonaY: pgStrTranscribe.rctStrZona.y
				zonaWidth: pgStrTranscribe.rctStrZona.width; zonaHeight: pgStrTranscribe.rctStrZona.height
				toolbarX: pgStrTranscribe.rctStrToolbar.x; toolbarY: pgStrTranscribe.rctStrToolbar.y
				toolbarWidth: pgStrTranscribe.rctStrToolbar.width
				toolbarHeight: pgStrTranscribe.rctStrToolbar.height
				tapZagolovokLevi: pgStrTranscribe.zagolovokLevi
				tapZagolovokPravi: pgStrTranscribe.zagolovokPravi
				tapToolbarLevi: pgStrTranscribe.toolbarLevi; tapToolbarPravi: pgStrTranscribe.toolbarPravi
				logoRazmer: root.logoRazmer; logoImya: root.logoImya
				onClickedNazad: {
					stvStr.pop()
					Qt.callLater(function() {
						stvStr.currentItem.forceActiveFocus()
					})
				}
				onClickedSettings: {
					stvStr.push(pgStrSetTranscribe)
				}
				onClickedInfo: {
					tmStrInstrukciya.strInstrukciya = "transcribe"
					stvStr.push(pgStrInstrukciya)
				}
				onToolbar: function(strToolbar) {//Если сигнал пришёл с текстом в toolbar, то...
					toolbar.fnText(strToolbar)//Передаём на отображение в toolbar сообщение.
				}
				onLog: function (strLog) {//Если сигнал пришёл с текстом в log, то...
					toolbar.log(strLog)//Передаём в лог сообщение.
				}
			}
		}
		Stranica {//Настройка транскрибации
		///////////////////////////////////////////////////
		///Н А С Т Р О Й К А   Т Р А Н С К Р И Б А Ц И И///
		///////////////////////////////////////////////////
			id: pgStrSetTranscribe
			visible: false; focus: true
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrFona; clrTexta: root.clrKnopok; clrRabOblasti: root.clrStranic
			textZagolovok: "НАСТРОЙКА ТРАНСКРИБАЦИИ"
			zagolovokLevi: 1.3; zagolovokPravi: 1.3; toolbarLevi: 1.3; toolbarPravi: 1.3
			onVisibleChanged: {
				if (visible) {
					Qt.callLater(function() {
						tmSetTranscribe.forceActiveFocus()
						toolbar.log("Фокус передан на tmSetTranscribe")
					})
				}
			}
			SetTranscribe{
				id: tmSetTranscribe
				ntWidth: pgStrSetTranscribe.ntWidth; ntCoff: pgStrSetTranscribe.ntCoff
				clrTexta: pgStrSetTranscribe.clrTexta; clrFona: pgStrSetTranscribe.clrRabOblasti
				clrMenuText: root.clrMenuText; clrMenuFon: pgStrTranscribe.clrFona
				zagolovokX: pgStrSetTranscribe.rctStrZagolovok.x; zagolovokY: pgStrSetTranscribe.rctStrZagolovok.y
				zagolovokWidth: pgStrSetTranscribe.rctStrZagolovok.width
				zagolovokHeight: pgStrSetTranscribe.rctStrZagolovok.height
				zonaX: pgStrSetTranscribe.rctStrZona.x; zonaY: pgStrSetTranscribe.rctStrZona.y
				zonaWidth: pgStrSetTranscribe.rctStrZona.width; zonaHeight: pgStrSetTranscribe.rctStrZona.height
				toolbarX: pgStrSetTranscribe.rctStrToolbar.x; toolbarY: pgStrSetTranscribe.rctStrToolbar.y
				toolbarWidth: pgStrSetTranscribe.rctStrToolbar.width
				toolbarHeight: pgStrSetTranscribe.rctStrToolbar.height
				tapZagolovokLevi: pgStrSetTranscribe.zagolovokLevi; tapZagolovokPravi: pgStrSetTranscribe.zagolovokPravi
				tapToolbarLevi: pgStrSetTranscribe.toolbarLevi; tapToolbarPravi: pgStrSetTranscribe.toolbarPravi
				logoRazmer: root.logoRazmer; logoImya: root.logoImya
				onClickedNazad: {
					stvStr.pop()//Назад страницу
					Qt.callLater(function() {
						stvStr.currentItem.forceActiveFocus()
					})
				}
				onClickedInfo: {
					tmStrInstrukciya.strInstrukciya = "set_transcribe"
					stvStr.push(pgStrInstrukciya)
				}
				onToolbar: function(strToolbar) {//Если сигнал пришёл с текстом в toolbar, то...
					toolbar.fnText(strToolbar)//Передаём на отображение в toolbar сообщение.
				}
				onLog: function (strLog) {//Если сигнал пришёл с текстом в log, то...
					toolbar.log(strLog)//Передаём в лог сообщение.
				}
			}
		}
		Stranica {//Инструкция
		/////////////////////////
		///И Н С Т Р У К Ц И Я///
		/////////////////////////
			id: pgStrInstrukciya
			visible: false
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrFona; clrTexta: root.clrKnopok; clrRabOblasti: root.clrStranic
			zagolovokLevi: 1.3; zagolovokPravi: 1.3; toolbarLevi: 1.3; toolbarPravi: 1.3
			StrInstrukciya {
				id: tmStrInstrukciya
				ntWidth: pgStrInstrukciya.ntWidth; ntCoff: pgStrInstrukciya.ntCoff
				clrTexta: pgStrInstrukciya.clrTexta; clrFona: pgStrInstrukciya.clrRabOblasti
				clrPolzunka: pgStrInstrukciya.clrFona
				zagolovokX: pgStrInstrukciya.rctStrZagolovok.x; zagolovokY: pgStrInstrukciya.rctStrZagolovok.y
				zagolovokWidth: pgStrInstrukciya.rctStrZagolovok.width
				zagolovokHeight: pgStrInstrukciya.rctStrZagolovok.height
				zonaX: pgStrInstrukciya.rctStrZona.x; zonaY: pgStrInstrukciya.rctStrZona.y
				zonaWidth: pgStrInstrukciya.rctStrZona.width; zonaHeight: pgStrInstrukciya.rctStrZona.height
				toolbarX: pgStrInstrukciya.rctStrToolbar.x; toolbarY: pgStrInstrukciya.rctStrToolbar.y
				toolbarWidth: pgStrInstrukciya.rctStrToolbar.width
				toolbarHeight: pgStrInstrukciya.rctStrToolbar.height
				radiusZona: pgStrInstrukciya.rctStrZona.radius//Радиус берём из настроек элемента qml
				tapZagolovokLevi: pgStrInstrukciya.zagolovokLevi; tapZagolovokPravi: pgStrInstrukciya.zagolovokPravi
				tapToolbarLevi: pgStrInstrukciya.toolbarLevi; tapToolbarPravi: pgStrInstrukciya.toolbarPravi
				pythonVersion: root.pythonVersion
    			qtVersion: root.qtVersion
				onClickedNazad: {
					stvStr.pop()//Назад страницу
					Qt.callLater(function() {
						stvStr.currentItem.forceActiveFocus()
					})
				}
				onSignalZagolovok: function(strZagolovok) {//Слот сигнала signalZagolovok с новым Заголовком.
					pgStrInstrukciya.textZagolovok = strZagolovok;//Выставляем изменённый Заголовок.
				}
			}
		}
		Stranica {//Журнал
		/////////////////
		///Ж У Р Н А Л///
		/////////////////
			id: pgStrJurnal
			visible: false; focus: true
			ntWidth: root.ntWidth; ntCoff: root.ntCoff
			clrFona: root.clrFona; clrTexta: root.clrKnopok; clrRabOblasti: root.clrStranic
			textZagolovok: "ЖУРНАЛ"
			zagolovokLevi: 1.3; zagolovokPravi: 1.3; toolbarLevi: 1.3; toolbarPravi: 1.3
			onVisibleChanged: {
				if (visible) {
					Qt.callLater(function() {
						tmJurnal.forceActiveFocus()
						toolbar.log("Фокус передан на tmJurnal")
					})
				}
			}
			StrJurnal {
				id: tmJurnal
				ntWidth: pgStrJurnal.ntWidth; ntCoff: pgStrJurnal.ntCoff
				clrTexta: pgStrJurnal.clrTexta; clrFona: pgStrJurnal.clrRabOblasti
				clrMenuText: root.clrMenuText; clrMenuFon: pgStrTranscribe.clrFona
				zagolovokX: pgStrJurnal.rctStrZagolovok.x; zagolovokY: pgStrJurnal.rctStrZagolovok.y
				zagolovokWidth: pgStrJurnal.rctStrZagolovok.width
				zagolovokHeight: pgStrJurnal.rctStrZagolovok.height
				zonaX: pgStrJurnal.rctStrZona.x; zonaY: pgStrJurnal.rctStrZona.y
				zonaWidth: pgStrJurnal.rctStrZona.width; zonaHeight: pgStrJurnal.rctStrZona.height
				toolbarX: pgStrJurnal.rctStrToolbar.x; toolbarY: pgStrJurnal.rctStrToolbar.y
				toolbarWidth: pgStrJurnal.rctStrToolbar.width
				toolbarHeight: pgStrJurnal.rctStrToolbar.height
				tapZagolovokLevi: pgStrJurnal.zagolovokLevi; tapZagolovokPravi: pgStrJurnal.zagolovokPravi
				tapToolbarLevi: pgStrJurnal.toolbarLevi; tapToolbarPravi: pgStrJurnal.toolbarPravi
				onClickedNazad: {
					stvStr.pop()//Назад страницу
					Qt.callLater(function() {
						stvStr.currentItem.forceActiveFocus()
					})
				}
				onClickedInfo: {
					tmStrInstrukciya.strInstrukciya = "jurnal"
					stvStr.push(pgStrInstrukciya)
				}
				onToolbar: function(strToolbar) {//Если сигнал пришёл с текстом в toolbar, то...
					toolbar.fnText(strToolbar)//Передаём на отображение в toolbar сообщение.
				}
				onLog: function (strLog) {//Если сигнал пришёл с текстом в log, то...
					toolbar.log(strLog)//Передаём в лог сообщение.
				}
			}
		}
	}
}
