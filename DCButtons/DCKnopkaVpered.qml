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
    property bool pressed: tphKnopkaVpered.pressed//true - нажали false - не нажали
    //property bool pressed: maKnopkaVpered.pressed//true - нажали false - не нажали
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
        id: tphKnopkaVpered
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaVpered
        anchors.fill: root
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Rectangle {
		id: rctKnopkaVpered
        height: root.ntWidth*root.ntCoff
        width: height
        anchors.centerIn: root

        color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaVpered.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                //maKnopkaVpered.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
            else//Если деактивирована кнопка, то...
                Qt.darker(clrFona, root.minDarker)
        }
        border.color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaVpered.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                //maKnopkaVpered.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
            else//Если деактивирована кнопка, то...
                Qt.darker(clrKnopki, root.minDarker)
        }
        border.width: width/8/4
        radius: width/4

		Rectangle {
			id: rctStrelkaVerh
			visible: true
			width: rctKnopkaVpered.width/4
			height: width
			anchors.top: rctKnopkaVpered.top
			anchors.left: rctKnopkaVpered.left
			anchors.leftMargin: rctKnopkaVpered.width/8*2
			anchors.topMargin: rctKnopkaVpered.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaVpered.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaVpered.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaVpered.width/4
		}

		Rectangle {
			id: rctStrelkaNiz
			width: rctKnopkaVpered.width/4
			height: width
			anchors.bottom: rctKnopkaVpered.bottom
			anchors.left: rctKnopkaVpered.left
			anchors.leftMargin: rctKnopkaVpered.width/8*2
			anchors.bottomMargin: rctKnopkaVpered.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaVpered.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaVpered.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaVpered.width/4
		}

		Rectangle {
			id: rctStrelkaCentor
			width: rctKnopkaVpered.width/4
			height: width
			anchors.left: rctKnopkaVpered.horizontalCenter
			anchors.top: rctKnopkaVpered.top
			anchors.topMargin: rctKnopkaVpered.width/8*3

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaVpered.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaVpered.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaVpered.width/4
		} 
	}	
}
