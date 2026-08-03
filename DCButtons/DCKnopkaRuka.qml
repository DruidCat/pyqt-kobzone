import QtQuick //2.15
//import QtQuick.Handlers//Не требуется в Qt 6.2+

Item {
    id: root
    //Свойства.
	property int ntWidth: 2
	property int ntCoff: 8
	property color clrKnopki: "grey"
	property color clrFona: "transparent"
    property real minDarker: 0.7//Миннимальная затемнённость кнопки, когда она не активная.
    property real maxDarker: 1.3//Максимальная затемнённость кнопки, когда она нажата.
    property bool enabled: true//true - активирована, false - деактивированна кнопка.
    property bool pressed: tphKnopkaRuka.pressed//true - нажали false - не нажали
    //property bool pressed: maKnopkaVidelit.pressed//true - нажали false - не нажали
    property bool isRuka: false//true - выделить, false - захватить.
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
        id: tphKnopkaRuka
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaRuka
        anchors.fill: root
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Rectangle{
        id: rctKnopkaRuka
        height: root.ntWidth*root.ntCoff
        width: height
        anchors.centerIn: root

        color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaRuka.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                //maKnopkaRuka.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
            else//Если деактивирована кнопка, то...
                Qt.darker(clrFona, root.minDarker)
        }
        border.color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaRuka.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                //maKnopkaRuka.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
            else//Если деактивирована кнопка, то...
                Qt.darker(clrKnopki, root.minDarker)
        }
        border.width: isRuka ? width/8/4 : 0
        radius: width/4

        Rectangle{
            id: rctPalec1
            width: rctKnopkaRuka.width/8
            height: rctKnopkaRuka.height/8*3
            anchors.top: rctKnopkaRuka.top
            anchors.left: rctKnopkaRuka.left
            anchors.topMargin: rctKnopkaRuka.width/2
            anchors.leftMargin: rctKnopkaRuka.width/4

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaRuka.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaRuka.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaRuka.width/2//Круг
		}
        Rectangle{
            id: rctPalec2
            width: rctKnopkaRuka.width/8
            height: rctKnopkaRuka.height
            anchors.top: rctKnopkaRuka.top
            anchors.left: rctPalec1.right

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaRuka.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaRuka.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaRuka.width/2//Круг
        }
        Rectangle{
            id: rctPalec3
            width: rctKnopkaRuka.width/8
            height: rctKnopkaRuka.height/8*6
            anchors.top: rctKnopkaRuka.top
            anchors.left: rctPalec2.right
            anchors.topMargin: rctKnopkaRuka.width/4

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaRuka.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaRuka.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaRuka.width/2//Круг
        }
        Rectangle{
            id: rctPalec4
            width: rctKnopkaRuka.width/8
            height: rctKnopkaRuka.height/8*5
            anchors.top: rctKnopkaRuka.top
            anchors.left: rctPalec3.right
            anchors.topMargin: rctKnopkaRuka.width/8*3

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaRuka.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaRuka.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaRuka.width/2//Круг
        }
        Rectangle{
            id: rctPalec5
            width: rctKnopkaRuka.width/8
            height: rctKnopkaRuka.height/8*3
            anchors.top: rctKnopkaRuka.top
            anchors.left: rctPalec4.right
            anchors.topMargin: rctKnopkaRuka.width/2

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaRuka.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaRuka.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaRuka.width/2//Круг
        }
        Rectangle{
            id: rctKist1
            width: rctKnopkaRuka.width/8*3
            height: rctKnopkaRuka.height/8*3
            anchors.bottom: rctKnopkaRuka.bottom
            anchors.left: rctKnopkaRuka.left
            anchors.leftMargin: rctKnopkaRuka.width/8*3

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaRuka.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaRuka.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            //radius: rctKnopkaRuka.width/2//Круг
        }
        Rectangle{
            id: rctKist2
            width: rctKnopkaRuka.width/8*5
            height: rctKnopkaRuka.height/8
            anchors.bottom: rctKnopkaRuka.bottom
            anchors.left: rctKnopkaRuka.left
            anchors.bottomMargin: rctKnopkaRuka.width/8
            anchors.leftMargin: rctKnopkaRuka.width/4

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaRuka.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaRuka.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaRuka.width/2//Круг
        }
	}	
}
