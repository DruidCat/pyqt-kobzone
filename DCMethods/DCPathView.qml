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
    property bool pressed: (tphKarusel.pressed||tphKnopki.pressed)?true:false//if нажата карусель||кнопки?true
    property var modelData: []//Свойства для модели.
    property int currentIndex: 0//0-первый элемент отображается....2-третий элемент отображается по умолчанию.
    property alias karusel: pvwKarusel
    //Настройки.
    height:pvwKarusel.pathItemCount*ntWidth*ntCoff*1.5//Высота виджета
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
        if(visible) pvwKarusel.focus = true;//Если видимый, то фокусируемся на карусели, чтоб кнопки работали.
    }

    Rectangle {
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
        }
    }
    Rectangle {
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
            onClicked: pvwKarusel.decrementCurrentIndex()//Прокрутка вверх
        }
        DCKnopkaVniz {
            id: knopkaVniz
            ntCoff: root.ntCoff; ntWidth: root.ntWidth
            anchors.bottom: rctKnopki.bottom; anchors.left: rctKnopki.left
            anchors.margins: root.ntCoff/2
            clrKnopki: root.clrTexta; clrFona: root.clrFona
            onClicked: pvwKarusel.incrementCurrentIndex()//Прокрутка вниз
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
        }
    }

	Path {//Размеры PathView, и направление бесконечного скролинга.
        id: pthKarusel
		//Середина - начало.
        startX: root.width/2//Середина строчки списка - это середина Item
        startY: root.height/2
		PathAttribute { name: "prozrachnost"; value: 1.0 }
        PathAttribute { name: "masshtab"; value: 0.85 }
		PathAttribute { name: "z"; value: 0 }//0 (+1 - это передний слой, -1 - это занлий слой)
		//Верх
		PathQuad {
            x: root.width/2
            y: (root.ntWidth*root.ntCoff+root.ntCoff)/2
            controlX: root.width/2
            controlY: (root.height/2-(root.ntWidth*root.ntCoff+root.ntCoff)/2)/2
		}

		PathAttribute { name: "prozrachnost"; value: 0.5 }
        PathAttribute { name: "masshtab"; value: 0.83 }
		PathAttribute { name: "z"; value: -1 }
		//Низ
		PathQuad {
            x: root.width/2
            y: root.height-(root.ntWidth*root.ntCoff+root.ntCoff)/2
            controlX: root.width/2
            controlY: root.height/2
		}

		PathAttribute { name: "prozrachnost"; value: 0.5 }
        PathAttribute { name: "masshtab"; value: 0.83 }
		PathAttribute { name: "z"; value: -1 }

		PathQuad{//Переход к началу в середину.
            x: root.width/2
            y: root.height/2
            controlX: root.width/2
            controlY: root.height/2+(root.height/2
                -(root.ntWidth*root.ntCoff+root.ntCoff)/2)/2
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
        pathItemCount: 3//Количество видимых элементов модели.
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
                while (acc >= step) { pvwKarusel.decrementCurrentIndex(); acc -= step }
                while (acc <= -step) { pvwKarusel.incrementCurrentIndex(); acc += step }
            }
            onCanceled: { acc = 0; prevT = 0 }//Чтобы жесты не «залипали» при прерывании, обнуляем.
        }
        //Доснап к центру, чтобы выглядело аккуратно
        snapMode: PathView.SnapOneItem
        preferredHighlightBegin: height/2
        preferredHighlightEnd: height/2
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: root.highlightMs
        //Функции
        onCurrentIndexChanged: {//Если индекс отображаемого элемента изменился, то...
            if (!internalChange && root.currentIndex !== currentIndex) {//Если значение ещё не менялось, то...
                root.currentIndex = pvwKarusel.currentIndex//Изменяем значение в root переменной currentIndex
            }
        }
        function activateCurrentItem() {//Функция выбора активного элемента модели.
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
        Keys.onUpPressed: if(root.visible) decrementCurrentIndex();//Если нажата стрелка вверх, и видимый, то
        Keys.onDownPressed: if(root.visible) incrementCurrentIndex();//Если нажата стрелка вниз, и видимый, то
        Keys.onEnterPressed: if(root.visible) activateCurrentItem();//Если нажата Enter, и видимый, то
        Keys.onReturnPressed: if(root.visible) activateCurrentItem()//Если нажата Return, и видимый, то
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
                Qt.callLater(function () {//Делаем паузу на такт,иначе не успеет пересчитаться высота!
                    txtText.font.pixelSize = rctStroka.height-root.ntCoff
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
                pvwKarusel.decrementCurrentIndex()//Прокрутка вверх
            else{
                if (event.angleDelta.y < 0)
                    pvwKarusel.incrementCurrentIndex()//Прокрутка вниз
            }
        }
    }
    /*
    import QtQuick 2.15
    WheelArea {//Для Qt5.15 WheelArea для прокрутки модели колесиком мыши
        id: wheelArea
        anchors.fill: pvwKarusel // чтобы ловить колесо по всей области PathView
        onWheel: function(event) {
            if (event.angleDelta.y > 0)
                pvwKarusel.decrementCurrentIndex()//Прокрутка вверх
            else{
                if (event.angleDelta.y < 0)
                    pvwKarusel.incrementCurrentIndex()//Прокрутка вниз
            }
        }
    }
    */
	Component.onCompleted: {//Слот, кода всё представление отрисовалось.
        pvwKarusel.forceActiveFocus();//Без форсированного фокуса не будут работать клавиши.
	}
}
