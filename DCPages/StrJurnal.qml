import QtQuick //2.15

import DCButtons 1.0//Импортируем кнопки
import DCMethods 1.0//Импортируем методы написанные мной.
//Страница с отладочной информацией.
Item {
    id: root
    //Свойства.
    property int ntWidth: 2
    property int ntCoff: 8
    property color clrTexta: "Orange"
	property color clrFona: "Black"
    property color clrMenuText: "Orange"
    property color clrMenuFon: "SlateGray"
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
    property real tapZagolovokLevi: 1
    property real tapZagolovokPravi: 1
    property real tapToolbarLevi: 1
    property real tapToolbarPravi: 1
	property alias radiusZona: txdZona.radius
	property string strDebug: ""//Глобальная переменная, в ней собирается строка со всеми Сообщениями.
    property int ntPoisk//Переменная, которая будет хранить диапазон поиска по Журналу.
	property bool isMobile: false
    //Настройки.
	anchors.fill: parent//Растянется по Родителю.
    focus: true;//Чтоб работали горячие клавиши.
    //Сигналы.
	signal clickedNazad();//Сигнал нажатия кнопки Назад
    signal clickedInfo();//Сигнал нажатия кнопки Инфо, где будет описание работы Файлового Диалога.
    signal toolbar(var strToolbar);//Сигнал, когда передаём новую надпись в Тулбар.
    signal log(var strLog)
    //Функции.
    Keys.onPressed: (event) => {//Это запись для Qt6, для Qt5 нужно удалить event =>
        if(event.modifiers & Qt.ControlModifier){//Если нажат "Ctrl"
            if(event.key === Qt.Key_F){//Если нажата клавиша F, то...
                if(knopkaPoisk.visible)//Если кнопка Поиск видимая, то...
                    fnClickedPoisk();//Функция нажатия Поиска.
                event.accepted = true;//Завершаем обработку эвента.
            }
        }
        else{
            if(event.modifiers & Qt.AltModifier){//Если нажат "Alt"
                if (event.key === Qt.Key_Left){//Если нажата клавиша стрелка влево, то...
                    if(knopkaNazad.visible)//Если кнопка Назад видимая, то...
                        fnClickedNazad();//Функция нажатия кнопки Назад
                    event.accepted = true;//Завершаем обработку эвента.
                }
            }
            else{
                if(event.key === Qt.Key_Escape){//Если нажата на странице кнопка Escape, то...
                    fnClickedEscape();//Функция нажатия кнопки Escape.
                }
                else{
                    if(event.key === Qt.Key_F1){//Если нажата кнопка F1, то...
                        if(knopkaInfo.visible)
                            fnClickedInfo();//Функция нажатия на кнопку Информация.
                        event.accepted = true;//Завершаем обработку эвента.
                    }
                }
            }
        }
    }
	Component.onCompleted: {
		root.forceActiveFocus()
	}
    onStrDebugChanged: {//Если переменная strDebug изменилась, то...
		if(root.strDebug !== ""){
			pyJurnal.writeLog(root.strDebug)// Записываем лог в файл через Python
			var vrGodMesyac = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss")//Временная метка
			txdZona.text = txdZona.text + vrGodMesyac + " " +  root.strDebug + '\n'//Добавляем данные в Журнал
		}
    }
    function fnClickedNazad(){//Функция нажатия кнопки Назад
        fnClickedEscape();//Меню сворачиваем
        root.clickedNazad();
    }
    function fnClickedInfo(){//Функция нажатия на кнопку Информации.
        fnClickedEscape();//Меню сворачиваем
        root.clickedInfo();//Сигнал излучаем, что нажата кнопка Описание.
    }
    function fnClickedPoisk(){//Функция нажатия кнопки Poisk.
        menuMenu.visible = false;//Делаем невидимым всплывающее меню.
        pvPoisk.visible = !pvPoisk.visible
    }
    function fnClickedEscape(){//Меню сворачиваем
        menuMenu.visible = false;//Делаем невидимым всплывающее меню.
        pvPoisk.visible = false;//Делаем невидимым выбор поиска.
    }
    Item {//Данные Заголовок
		id: tmZagolovok
        DCKnopkaNazad {
            id: knopkaNazad
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
			anchors.verticalCenter: tmZagolovok.verticalCenter
			anchors.left:tmZagolovok.left
            clrKnopki: root.clrTexta
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff
            tapWidth: tapHeight*root.tapZagolovokLevi
            onClicked: fnClickedNazad();//Функция нажатия кнопки Назад
        }
		DCKnopkaPoisk{
            id: knopkaPoisk
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.verticalCenter: tmZagolovok.verticalCenter
            anchors.right: tmZagolovok.right
            clrKnopki: root.clrTexta//Цвет файлов
            clrFona: root.clrFona
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff
            tapWidth: tapHeight*root.tapZagolovokLevi
            onClicked: fnClickedPoisk();//Функция нажатия кнопки Poisk.
        }
    }
    Item {//Данные Зона
		id: tmZona
        clip: true//Обрезаем всё что выходит за пределы этой области. Это для листания нужно.
        DCTextEdit {//Модуль просмотра текста, прокрутки и редактирования.
			id: txdZona
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
			readOnly: true//Запрещено редактировать текст
            textEdit.selectByMouse: root.isMobile ? false : true//Запрещаем выделять текст для свайпа Android
            pixelSize: root.ntWidth/2*root.ntCoff//размер шрифта текста в два раза меньше.
            radius: root.ntCoff/4//Радиус возьмём из настроек элемента qml через property
            clrFona: root.clrFona//Цвет фона рабочей области
            clrTexta: root.clrTexta//Цвет текста
            clrBorder: root.clrTexta//Цвет бардюра при редактировании текста.
			italic: true//Текст курсивом.
			onPressed: {
				if(!pvPoisk.pressed) fnClickedEscape();//Если нажали на пустое место
			}
        }
        ListModel {//Модель с шриштами
            id: modelPoisk
            ListElement { spisok: qsTr("неделя") }
            ListElement { spisok: qsTr("месяц") }
            ListElement { spisok: qsTr("год") }
        }
        DCPathView {
            id: pvPoisk
            visible: false
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            anchors.left: tmZona.left; anchors.right: tmZona.right; anchors.bottom: tmZona.bottom
            anchors.leftMargin: 22; anchors.rightMargin:22
            clrFona: root.clrFona; clrTexta: root.clrMenuText; clrMenuFon: root.clrMenuFon
            modelData: modelPoisk
            onClicked: function(strShrift) {
                pvPoisk.visible = false;
                root.ntPoisk = pvPoisk.currentIndex;//Приравниваем значение к переменной.
				var vrLogs = ""//Переменная хранящая логи сортированные.
                if(root.ntPoisk === 0) vrLogs = pyJurnal.polDebugNedelya()
                else if(root.ntPoisk === 1) vrLogs = pyJurnal.polDebugMesyac()
				else if(root.ntPoisk === 2) vrLogs = pyJurnal.polDebugGod()
				txdZona.text = vrLogs//Отображаем загруженные логи
            }
            onVisibleChanged: if(!visible) txdZona.fnFocus();//Чтоб горячие кнопки листания работали.
        }
        DCMenu {
            id: menuMenu
            visible: false//Невидимое меню.
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.left: tmZona.left
            anchors.right: tmZona.right
            anchors.bottom: tmZona.bottom
            anchors.margins: root.ntCoff
            pctFona: 0.90//Прозрачность фона меню.
            clrTexta: root.clrMenuText; clrFona: root.clrMenuFon
            imyaMenu: "jurnal"//Глянь в DCMenu все варианты меню в слоте окончательной отрисовки.
            onClicked: function(ntNomer, strMenu) {
                menuMenu.visible = false;//Делаем невидимым меню.
                if(ntNomer === 1){//Поиск
                    fnClickedPoisk();//Поиск.
                }else if(ntNomer === 2){//Очистить журнал
                    txdZona.text = ""//Очищаем журнал
                } else if(ntNomer === 3){//Информация
                    fnClickedInfo();//Открываем инструкцию Журнала
                } else if(ntNomer === 4){//Закрыть.
                    fnClickedNazad();//Закрываем журнал.
                }
            }
            onVisibleChanged: if(!visible) txdZona.fnFocus();//Чтоб горячие кнопки листания работали.
        }
    }
    Item {//Данные Тулбар
		id: tmToolbar
		DCKnopkaInfo {
            id: knopkaInfo
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            visible: true
            anchors.verticalCenter: tmToolbar.verticalCenter
            anchors.left: tmToolbar.left
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff
            tapWidth: tapHeight*root.tapZagolovokLevi
            onClicked: fnClickedInfo();//Функция нажатия на кнопку Информации.
        } 
        DCKnopkaNastroiki {
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.verticalCenter: tmToolbar.verticalCenter
            anchors.right: tmToolbar.right
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            blVert: true//Вертикольное исполнение
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff
            tapWidth: tapHeight*root.tapZagolovokLevi
            onClicked: {
                if(pvPoisk.visible) pvPoisk.visible = false//Делаем невидимый выбор поиска
                menuMenu.visible ? menuMenu.visible = false : menuMenu.visible = true;
                root.toolbar("");//Делаем пустую строку в Toolbar.
            }
        }
    }
	MouseArea {//MouseArea для возврата фокуса
		anchors.fill: parent
		z: -1
		propagateComposedEvents: true
		onClicked: (mouse) => {
			mouse.accepted = false
			if (menuMenu.visible)
				menuMenu.visible = false
			else 
				root.forceActiveFocus()
			root.forceActiveFocus()
		}
	}
}
