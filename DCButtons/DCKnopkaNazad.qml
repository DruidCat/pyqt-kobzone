import QtQuick //2.15
//import QtQuick.Handlers//Не требуется в Qt 6.2+

Item{
    id: root
    //Свойства
	property int ntWidth: 2
	property int ntCoff: 8
	property color clrKnopki: "grey"
	property color clrFona: "transparent"
    property real minDarker: 0.7//Миннимальная затемнённость кнопки, когда она не активная.
    property real maxDarker: 1.3//Максимальная затемнённость кнопки, когда она нажата.
    property bool enabled: true//true - активирована, false - деактивированна кнопка.
    //property bool pressed: tphKnopkaNazad.pressed//true - нажали false - не нажали (вариант TapHandler)
    property bool pressedPriKlike: false//true только в момент доставки сигнала clicked. MouseArea сбрасывает pressed в false ДО сигнала clicked, а TapHandler (старый вариант) держал pressed=true в момент сигнала. Без этого флага обработчики вида onClicked:{if(pressed){...}} (SetStudio и др.) не пропускают действие.
    property bool pressed: maKnopkaNazad.pressed || pressedPriKlike//true - нажали false - не нажали (вариант MouseArea)
    //property bool pressed: maKnopkaNazad.pressed//true - нажали false - не нажали
    property real tapHeight: ntWidth*ntCoff//Высота зоны нажатия пальцем или мышкой
    property real tapWidth: ntWidth*ntCoff//Ширина зоны нажатия пальцем или мышкой
    //Настройки.
    height: tapHeight
    width: tapWidth
    //Сигналы.
	signal clicked();
    //Функции.
    //НА ДЕСКТОПЕ кнопка делается на MouseArea: TapHandler берёт ПАССИВНЫЙ граб, и клик «прокалывает» все слои вниз до кнопок, лежащих под кнопкой по z (проверено на Qt 6.10: свойства grabActiveOnPress нет, а exclusiveGrab() из QML вызывается с ошибкой TypeError). MouseArea берёт эксклюзивный граб — клик заканчивается на кнопке и дальше по слоям не идёт. Для Авроры делаем наоборот: комментируем MouseArea, расскомментируем TapHandler.
    /*
    TapHandler {//Обработка нажатия, замена MouseArea с Qt5.10
        id: tphKnopkaNazad
		enabled: root.enabled
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    MouseArea {
        id: maKnopkaNazad
        anchors.fill: parent
		enabled: root.enabled
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                {//Обрабатываем клик. Эмулируем поведение TapHandler: в момент доставки сигнала кнопка «нажата», иначе обработчики вида if(pressed) на вызывающей стороне не пропустят действие.
                    root.pressedPriKlike = true
                    root.clicked()
                    root.pressedPriKlike = false
                }
        }
    }
    Rectangle {
		id: rctKnopkaNazad
        height: root.ntWidth*root.ntCoff
        width: height
        anchors.centerIn: root

        color: {
            if(root.enabled)//Если активирована кнопка, то...
                maKnopkaNazad.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                //maKnopkaNazad.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
            else//Если деактивирована кнопка, то...
                Qt.darker(clrFona, root.minDarker)
        }
        border.color: {
            if(root.enabled)//Если активирована кнопка, то...
                maKnopkaNazad.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                //maKnopkaNazad.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
            else//Если деактивирована кнопка, то...
                Qt.darker(clrKnopki, root.minDarker)
        }
        border.width: width/8/4
        radius: width/4

		Rectangle {
			id: rctStrelkaVerh
			visible: true
			width: rctKnopkaNazad.width/4
			height: width
			anchors.top: rctKnopkaNazad.top
			anchors.right: rctKnopkaNazad.right
			anchors.rightMargin: rctKnopkaNazad.width/8*2
			anchors.topMargin: rctKnopkaNazad.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    maKnopkaNazad.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaNazad.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaNazad.width/4
		}

		Rectangle {
			id: rctStrelkaNiz
			width: rctKnopkaNazad.width/4
			height: width
			anchors.bottom: rctKnopkaNazad.bottom
			anchors.right: rctKnopkaNazad.right
			anchors.rightMargin: rctKnopkaNazad.width/8*2
			anchors.bottomMargin: rctKnopkaNazad.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    maKnopkaNazad.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaNazad.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaNazad.width/4
		}

		Rectangle {
			id: rctStrelkaCentor
			width: rctKnopkaNazad.width/4
			height: width
			anchors.right: rctKnopkaNazad.horizontalCenter
			anchors.top: rctKnopkaNazad.top
			anchors.topMargin: rctKnopkaNazad.width/8*3

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    maKnopkaNazad.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaNazad.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaNazad.width/4
		} 
	}	
}
