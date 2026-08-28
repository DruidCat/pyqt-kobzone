import QtQuick //2.15

import DCButtons 1.0//Импортируем кнопки
//DCPathView - каруселька выбора трёх элементов.
Item {
    id: root
    //Свойства.
	property int ntWidth: 2
	property int ntCoff: 8
    property color clrFona: "Black"//Цвет фона, на котором кнопки распологаются.
    property color clrTexta: "Orange"//Цвет текста на кнопках
    property color clrMenuFon: "Slategray"//Цвет кнопок с текстом
    property real scrollSlow: 4.0//Замедление свайпа. Если листается слишком быстро — увеличиваем на 5 или 6.
    property real stepRatio: 0.6//Доля высоты строки для шага. Если шаги «слишком рано» срабатывают - 0.7–0.8.
    property int  dragThresh: 5//Порог активации жеста. Если жест всё ещё «тяжело» запускается, уменьши до 2–3
    property int  highlightMs: 181//Длительность снапа.
    property bool pressed: false
    property var modelData: []//Свойства для модели.
    property int currentIndex: 0//0-первый элемент отображается....2-третий элемент отображается по умолчанию.
    property alias karusel: pvwKarusel
	property bool jdi: false//true - жди, только что открылся виджет
    //Настройки.
	height: (ntWidth * ntCoff + ntCoff) * 3 * 1.2
    //Сигналы
    signal clicked(var strSpisok);//Сигнал нажатия на элемент
    //Функции.
    onCurrentIndexChanged: {//Если индекс отображения элемента изменился, то...
        if (pvwKarusel.currentIndex !== root.currentIndex){//Если значение не равно, то...
            pvwKarusel.internalChange = true;//Это против самозацикливания. Взводим флаг.
            pvwKarusel.currentIndex = root.currentIndex//запоминаем индекс отображения номера элемента
            pvwKarusel.internalChange = false;//Это против самозацикливания. Сбрасываем флаг.
        }
    }
    onVisibleChanged: {//Если видимость изменилась, то...
		if(visible){
			pvwKarusel.focus = true;//Если видимый, то фокусируемся на карусели, чтоб кнопки работали.
			root.jdi = true;//Жди, виджет только что открылся
			tmrJdi.restart();//Запускаем таймер сбрасывающий флаг root.jdi
		}
    }
	Timer {//Таймер оставляет флаг pressed взведённым на интервал,чтоб обработчики сигнала страболи в програме
		id: tmrPressed
		interval: 220; running: false; repeat: false
        onTriggered: {
			root.pressed = false
		}
	}
	Timer {//Таймер того, что фиксирует флаг открытия приложения на интервал, для обработчиков в программе.
		id: tmrJdi
		interval: 220; running: false; repeat: false
        onTriggered: {
			root.jdi = false
		}
	}
    Rectangle {//Основной прямоугольник виджета
        id: rctKarusel
        anchors.top: root.top
        anchors.left: root.left
        anchors.right: rctKnopki.left
        anchors.bottom: root.bottom
        color: root.clrFona
        border.width: 1
        border.color: root.clrTexta
        TapHandler {//Обработка нажатия, замена MouseArea с Qt5.10
            id: tphKarusel//Зону нажатия на карусель отслеживает.
			onPressedChanged: {//Если изменилось состояние, то...
				if(pressed) {//Если нажато, то...
					root.pressed = true//Взводим флаг.
					tmrPressed.restart()//Взводим таймер на изменение флага.
				}
			}
        }
    }
    Rectangle {//Прямоугольник зоны кнопок.
        id: rctKnopki
        width: root.ntCoff * root.ntWidth + root.ntCoff
        height: root.height
        anchors.top: root.top
        anchors.right: root.right
        color: root.clrMenuFon
        border.width: 1
        border.color: root.clrTexta
        DCKnopkaVverh {
            id: knopkaVverh
            ntCoff: root.ntCoff; ntWidth: root.ntWidth
            anchors.top: rctKnopki.top; anchors.left: rctKnopki.left
            anchors.margins: root.ntCoff/2
            clrKnopki: root.clrTexta; clrFona: root.clrFona
            onClicked: pvwKarusel.incrementCurrentIndex()//Прокрутка вверх
        }
        DCKnopkaVniz {
            id: knopkaVniz
            ntCoff: root.ntCoff; ntWidth: root.ntWidth
            anchors.bottom: rctKnopki.bottom; anchors.left: rctKnopki.left
            anchors.margins: root.ntCoff/2
            clrKnopki: root.clrTexta; clrFona: root.clrFona
            onClicked: pvwKarusel.decrementCurrentIndex()//Прокрутка вниз 
        }
        DCKnopkaZakrit {
            id: knopkaZakrit
            ntCoff: root.ntCoff; ntWidth: root.ntWidth
            anchors.centerIn: rctKnopki
            clrKnopki: root.clrTexta; clrFona: root.clrFona
            onClicked: root.visible = false//Делаем невидимым виджет.
        }
        TapHandler {//Обработка нажатия, замена MouseArea с Qt5.10
            id: tphKnopki//Зону нажатия на кнопок отслеживает.
			onPressedChanged: {//Если изменилось состояние, то...
				if(pressed) {//Если нажато, то...
					root.pressed = true//Взводим флаг.
					tmrPressed.restart()//Взводим таймер на изменение флага.
				}
			}
        }
    }
	Path {
		id: pthKarusel
		property real itemHeight: root.ntWidth * root.ntCoff + root.ntCoff
		property real centerY: root.height / 2
		//Начало — центр (текущий элемент)
		startX: root.width / 2
		startY: centerY
		PathAttribute { name: "prozrachnost"; value: 1.0 }
		PathAttribute { name: "masshtab"; value: 0.85 }
		PathAttribute { name: "z"; value: 1 }
		//Позиция -1 (сверху, сзади)
		PathLine {
			x: root.width / 2
			y: pthKarusel.centerY - pthKarusel.itemHeight * 1.1
		}
		PathAttribute { name: "prozrachnost"; value: 0.5 }
		PathAttribute { name: "masshtab"; value: 0.83 }
		PathAttribute { name: "z"; value: -1 }
		//Позиция 0 (центр) — повтор для цикла
		PathLine {
			x: root.width / 2
			y: pthKarusel.centerY
		}
		PathAttribute { name: "prozrachnost"; value: 1.0 }
		PathAttribute { name: "masshtab"; value: 0.85 }
		PathAttribute { name: "z"; value: 1 }
		//Позиция +1 (снизу, сзади)
		PathLine {
			x: root.width / 2
			y: pthKarusel.centerY + pthKarusel.itemHeight * 1.1
		}
		PathAttribute { name: "prozrachnost"; value: 0.5 }
		PathAttribute { name: "masshtab"; value: 0.83 }
		PathAttribute { name: "z"; value: -1 }
		//Замыкание к началу
		PathLine {
			x: root.width / 2
			y: pthKarusel.centerY
		}
	}	
	PathView {//Представление модели с бесконечным скролингом.
        id: pvwKarusel
        //Свойства.
        property bool internalChange: false//Синхронизация currentIndex, против самозацикливания.
        //Настройки
        anchors.fill: rctKarusel
        model: root.modelData//Добавляем модель из свойства.
        currentIndex: root.currentIndex
        delegate: cmpKarusel
        path: pthKarusel//Устанавливаем габариты и направление скролинга в представлении
		pathItemCount: 3//Максимально 3 показывать.
		cacheItemCount: 0
        interactive: false //отключаем встроенную перетаскиваемость
        DragHandler {//Шаговое управление свайпом/мышью, «перехватывает» захват у MouseArea
            id: drhSvaip
            //Свойства
            property real acc: 0
            property real prevT: 0//запоминаем предыдущее значение translation.y
            property real slow: root.scrollSlow//во сколько раз замедлит
            readonly property real stepBase: root.ntWidth * root.ntCoff
            readonly property real step: stepBase * root.stepRatio//срабатывание на (0.6)~60% высоты строки
            //Настройки
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchScreen
            acceptedButtons: Qt.LeftButton
            xAxis.enabled: false//Тащить по x запрещено
            yAxis.enabled: true//Тащить по y разрешено
            dragThreshold: root.dragThresh//Чтобы жест быстрее «включался»
            //Разрешаем перехватывать захват у MouseArea
            grabPermissions: PointerHandler.CanTakeOverFromItems
                             | PointerHandler.CanTakeOverFromHandlersOfDifferentType
            //Функции.
            onActiveChanged: { acc = 0; prevT = 0 }//важно сбрасывать и prevT
            onTranslationChanged: {
                const dy = translation.y - prevT;//дельта с предыдущего события
                prevT = translation.y
                acc -= dy/slow//замедляем в slow раз
                while (acc >= step) { pvwKarusel.incrementCurrentIndex(); acc -= step }
                while (acc <= -step) { pvwKarusel.decrementCurrentIndex(); acc += step }
            }
            onCanceled: { acc = 0; prevT = 0 }//Чтобы жесты не «залипали» при прерывании, обнуляем.
        }
        //Доснап к центру, чтобы выглядело аккуратно
        snapMode: PathView.SnapOneItem
        preferredHighlightBegin: 0.5
		preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: root.highlightMs
        //Функции
        onCurrentIndexChanged: {//Если индекс отображаемого элемента изменился, то...
            if (!internalChange && root.currentIndex !== currentIndex) {//Если значение ещё не менялось, то...
                root.currentIndex = pvwKarusel.currentIndex//Изменяем значение в root переменной currentIndex
            }
        }
        function fnClickedEnter() {//Функция выбора активного элемента модели.
            if (typeof model.get === "function") {//Если model объект типа ListModel (у него есть функция get)
                var elementModel = model.get(currentIndex)//Получаем текущий элемент модели по currentIndex
                if (elementModel)//Если элемент найден, то...
                    root.clicked(elementModel.spisok)//Вызываем сигнал clicked и передаём значение spisok
            }
            else {//Если не ListModel, то...
                if (Array.isArray(model)) {//Если model — это обычный массив (Array)
                    let elementModel = model[currentIndex]//Получаем текущий элемент массива по currentIndex
                    if (elementModel)//Если элемент найден, то...
                        root.clicked(elementModel.spisok)//Вызываем сигнал clicked и передаём значение spisok
                }
            }
        }
        Keys.onUpPressed: if(root.visible) incrementCurrentIndex();//Если нажата стрелка вниз, и видимый, то
        Keys.onDownPressed: if(root.visible) decrementCurrentIndex();//Если нажата стрелка вверх, и видимый,то
        Keys.onEnterPressed: if(root.visible) fnClickedEnter();//Если нажата Enter, и видимый, то
        Keys.onReturnPressed: if(root.visible) fnClickedEnter()//Если нажата Return, и видимый, то
    }
    Component {//Делегат
        id: cmpKarusel
        Rectangle {//Прямоугольник каждой отдельной строчки в модели.
            id: rctStroka
            width: rctKarusel.width
            height: root.ntWidth*root.ntCoff+root.ntCoff
            opacity: PathView.prozrachnost//Прозрачность
            z: PathView.z//Номер отображаемого элемента списка
            scale: PathView.masshtab//Масштаб

            color: maStroka.containsPress ? Qt.darker(root.clrMenuFon, 1.3) : root.clrMenuFon
            radius: (width/(root.ntWidth*root.ntCoff))/root.ntCoff

            Text {//Текст внутри прямоугольника, считанный из модели.
                id: txtText
                anchors.horizontalCenter: rctStroka.horizontalCenter
                anchors.verticalCenter: rctStroka.verticalCenter

                color:maStroka.containsPress ? Qt.darker(root.clrTexta, 1.3) : root.clrTexta
                text: spisok//Читаем текст из модели.
                font.pixelSize: rctStroka.height-root.ntCoff
            }
            Component.onCompleted:{//Когда текст отрисовался, нужно выставить размер шрифта.
                if(rctStroka.width > txtText.width){//Если длина строки больше длины текста, то...
                    for(var ltShag=txtText.font.pixelSize; ltShag<rctStroka.height-root.ntCoff; ltShag++){
                        if(txtText.width < rctStroka.width){//Если длина текста меньше динны строки
                            txtText.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                            if(txtText.width > rctStroka.width){//Но, если переборщили
                                txtText.font.pixelSize--;//То уменьшаем размер шрифта и...
                                return;//Выходим из увеличения шрифта.
                            }
                        }
                    }
                }
                else{//Если длина строки меньше длины текста, то...
                    for(let ltShag = txtText.font.pixelSize; ltShag > 0; ltShag--){//Цикл уменьшения
                        if(txtText.width > rctStroka.width)//Если текст дилиннее строки, то...
                            txtText.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
                    }
                }
            }
            onWidthChanged: {//Если длина строки изменилась, то...
                if(rctStroka.width > txtText.width){//Если длина строки больше длины текста, то...
                    for(var ltShag=txtText.font.pixelSize; ltShag<rctStroka.height-root.ntCoff; ltShag++){
                        if(txtText.width < rctStroka.width){//Если длина текста меньше динны строки
                            txtText.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                            if(txtText.width > rctStroka.width){//Но, если переборщили
                                txtText.font.pixelSize--;//То уменьшаем размер шрифта и...
                                return;//Выходим из увеличения шрифта.
                            }
                        }
                    }
                }
                else{//Если длина строки меньше длины текста, то...
                    for(let ltShag = txtText.font.pixelSize; ltShag > 0; ltShag--){//Цикл уменьшения
                        if(txtText.width > rctStroka.width)//Если текст дилиннее строки, то...
                            txtText.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
                    }
                }
            }
            onHeightChanged: {//Если изменилась высота, значит изменился размер Шрифта в StrMenu.
				let ltCoff = root.ntCoff
                Qt.callLater(function () {//Делаем паузу на такт,иначе не успеет пересчитаться высота!
                    txtText.font.pixelSize = rctStroka.height-ltCoff
                    if(rctStroka.width > txtText.width){//Если длина строки больше длины текста, то...
                        for(var ltShag=txtText.font.pixelSize;ltShag<rctStroka.height-root.ntCoff;ltShag++){
                            if(txtText.width < rctStroka.width){//Если длина текста меньше динны строки
                                txtText.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                                if(txtText.width > rctStroka.width){//Но, если переборщили
                                    txtText.font.pixelSize--;//То уменьшаем размер шрифта и...
                                    return;//Выходим из увеличения шрифта.
                                }
                            }
                        }
                    }
                    else{//Если длина строки меньше длины текста, то...
                        for(let ltShag = txtText.font.pixelSize; ltShag > 0; ltShag--){//Цикл уменьшения
                            if(txtText.width > rctStroka.width)//Если текст дилиннее строки, то...
                                txtText.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
                        }
                    }
                })
            }
            MouseArea {
                id: maStroka
                anchors.fill: rctStroka
                preventStealing: false
                //Если DragHandler уже активировался — не перехватываем события MouseArea
                onPressed: (mouse) => {
                    if(drhSvaip.active)
                        mouse.accepted = false
                }
                onPositionChanged: (mouse) => {
                    if(drhSvaip.active)
                        mouse.accepted = false
                }
                onClicked: {
                    if(!drhSvaip.active)
                        root.clicked(spisok)
               }
            }
        }
    }
    WheelHandler {//Для Qt6 прокрутки модели колесиком мыши
        target: pvwKarusel//Чтобы события ловились на PathView
        acceptedDevices: PointerDevice.Mouse//колесо работало только при наведении мыши на PathView
        onWheel: function(event) {
            if (event.angleDelta.y > 0)
				pvwKarusel.incrementCurrentIndex()//Прокрутка вниз
            else if (event.angleDelta.y < 0)
				pvwKarusel.decrementCurrentIndex()//Прокрутка вверх
        }
    }
    /*
    import QtQuick 2.15
    WheelArea {//Для Qt5.15 WheelArea для прокрутки модели колесиком мыши
        id: wheelArea
        anchors.fill: pvwKarusel // чтобы ловить колесо по всей области PathView
        onWheel: function(event) {
            if (event.angleDelta.y > 0)
				pvwKarusel.incrementCurrentIndex()//Прокрутка вниз
            else if (event.angleDelta.y < 0)
				pvwKarusel.decrementCurrentIndex()//Прокрутка вверх
        }
    }
    */
	Component.onCompleted: {//Слот, кода всё представление отрисовалось.
        pvwKarusel.forceActiveFocus();//Без форсированного фокуса не будут работать клавиши.
	}
}
