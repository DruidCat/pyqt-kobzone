import QtQuick //2.15
//import QtQuick.Handlers//Не требуется в Qt 6.2+

Item{
    id: root
    //Свойства.
	property int ntWidth: 2
	property int ntCoff: 8
	property color clrKnopki: "grey"
	property color clrFona: "transparent"
    property real minDarker: 0.7//Миннимальная затемнённость кнопки, когда она не активная.
    property real maxDarker: 1.3//Максимальная затемнённость кнопки, когда она нажата.
    property bool enabled: true//true - активирована, false - деактивированна кнопка.
    property bool pressed: tphKnopkaVniz.pressed//true - нажали false - не нажали
    //property bool pressed: maKnopkaVniz.pressed//true - нажали false - не нажали
    property real tapHeight: ntWidth*ntCoff//Высота зоны нажатия пальцем или мышкой
    property real tapWidth: ntWidth*ntCoff//Ширина зоны нажатия пальцем или мышкой
    //Настройки.
    height: tapHeight
    width: tapWidth
    //Сигналы.
    signal clicked();
    //Функции.
    //Для Авроры комментируем TapHandler, расскомментируем MouseArea и наоборот.
    TapHandler {//Обработка нажатия, замена MouseArea с Qt5.10
        id: tphKnopkaVniz
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaVniz
        anchors.fill: root
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Rectangle {
		id: rctKnopkaVniz
        height: root.ntWidth*root.ntCoff
        width: height
        anchors.centerIn: root

        color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaVniz.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                //maKnopkaVniz.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
            else//Если деактивирована кнопка, то...
                Qt.darker(clrFona, root.minDarker)
        }
        border.color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaVniz.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                //maKnopkaVniz.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
            else//Если деактивирована кнопка, то...
                Qt.darker(clrKnopki, root.minDarker)
        }
        border.width: width/8/4
        radius: width/4

		Rectangle {
			id: rctStrelkaVerhPravo
			visible: true
			width: rctKnopkaVniz.width/4
			height: width
			anchors.top: rctKnopkaVniz.top
			anchors.right: rctKnopkaVniz.right
			anchors.topMargin: rctKnopkaVniz.width/8*2
			anchors.rightMargin: rctKnopkaVniz.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaVniz.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaVniz.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaVniz.width/4
		}

		Rectangle {
			id: rctStrelkaVerhLevo
			width: rctKnopkaVniz.width/4
			height: width
			anchors.top: rctKnopkaVniz.top
			anchors.left: rctKnopkaVniz.left
			anchors.topMargin: rctKnopkaVniz.width/8*2
			anchors.leftMargin: rctKnopkaVniz.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaVniz.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaVniz.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaVniz.width/4
		}

		Rectangle {
			id: rctStrelkaCentor
			width: rctKnopkaVniz.width/4
			height: width
			anchors.top: rctKnopkaVniz.verticalCenter
			anchors.left: rctKnopkaVniz.left
			anchors.leftMargin: rctKnopkaVniz.width/8*3

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaVniz.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaVniz.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaVniz.width/4
		} 
	}	
}
