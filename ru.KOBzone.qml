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
    
	property int shrift: 2//1 - маленький, 2 - средний, 3 - большой
	property int ntWidth: 2 * shrift
	property int ntCoff: 8
 	
	property string pythonVersion: "N/A"
	property string qtVersion: "N/A"
	//Настройки окна
	visible: true
	color: clrFona
	title: "Любимая КОБзона"
	width: 1100
	height: 550
    
	Component.onCompleted: {
		stvStr.currentItem.forceActiveFocus()
		console.log("✓ Используется шрифт:", font.family)
		console.log("✓ Приложение запущено")
		//загружаем данные из python
		root.pythonVersion = pythonInfo.pythonVersion
		root.qtVersion = qtInfo.qtVersion
	}
	DCToolbar {
		id: dcToolbar
		vrStranica: stvStr.pgStrKOBzone//Первоначальное свойство передаю
		second: 3
		onTextChanged: {
			vrStranica.textToolbar = dcToolbar.text//Отображаем ИМЕННО ТАК.
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
					dcToolbar.vrStranica = currentItem;//Передаём указатель на страницу, которая открыта.
					console.log("Фокус установлен на:", currentItem)
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
					console.log("pgStrKOBzone стала видимой")
					Qt.callLater(function() {
						tmKOBzone.forceActiveFocus()
						console.log("Фокус передан на tmKOBzone")
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
						console.log("Фокус передан на tmSetKOBzone")
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
						console.log("Фокус передан на tmAnalizer")
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
				onSignalToolbar: function(strToolbar) {
					dcToolbar.fnText(strToolbar)
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
						console.log("Фокус передан на tmSetAnalizer")
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
						console.log("Фокус передан на tmOrfograf")
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
				onSignalToolbar: function(strToolbar) {
					pgStrOrfograf.textToolbar = strToolbar
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
						console.log("Фокус передан на tmSetOrfograf")
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
						console.log("Фокус передан на tmTranscribe")
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
				onSignalToolbar: function(strToolbar) {
					pgStrTranscribe.textToolbar = strToolbar
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
						console.log("Фокус передан на tmSetTranscribe")
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
	}
}
