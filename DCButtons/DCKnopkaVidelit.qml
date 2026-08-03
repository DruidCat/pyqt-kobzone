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
    property bool pressed: tphKnopkaVidelit.pressed//true - нажали false - не нажали
    //property bool pressed: maKnopkaVidelit.pressed//true - нажали false - не нажали
    property bool isVidelit: false//true - выделить, false - захватить.
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
        id: tphKnopkaVidelit
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaVidelit
        anchors.fill: root
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Rectangle{
        id: rctKnopkaVidelit
        height: root.ntWidth*root.ntCoff
        width: height
        anchors.centerIn: root
        color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaVidelit.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                //maKnopkaVidelit.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
            else//Если деактивирована кнопка, то...
                Qt.darker(clrFona, root.minDarker)
        }

        Rectangle {
            id: rctBorder
            height: rctKnopkaVidelit.height
            width: height/8*7
            anchors.top: rctKnopkaVidelit.top
            anchors.left: rctKnopkaVidelit.left
            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaVidelit.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                    //maKnopkaVidelit.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrFona, root.minDarker)
            }
            border.color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaVidelit.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaVidelit.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            border.width: isVidelit ? rctKnopkaVidelit.height/8/4 : 0
            radius: height/4
        }
        Rectangle{
            id: rctVidelit1
            width: rctKnopkaVidelit.width/8
            height: rctKnopkaVidelit.height/8*6
            anchors.top: rctKnopkaVidelit.top
            anchors.left: rctKnopkaVidelit.left
            anchors.topMargin: rctKnopkaVidelit.width/8
            anchors.leftMargin: rctKnopkaVidelit.width/8*3

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaVidelit.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaVidelit.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
        }
        Rectangle{
            id: rctVidelit2
            width: rctKnopkaVidelit.width/8*3
            height: rctKnopkaVidelit.height/8
            anchors.top: rctKnopkaVidelit.top
            anchors.left: rctKnopkaVidelit.left
            anchors.topMargin: rctKnopkaVidelit.width/8
            anchors.leftMargin: rctKnopkaVidelit.width/4

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaVidelit.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaVidelit.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaVidelit.width/2//Круг
        }
        Rectangle{
            id: rctVidelit3
            width: rctKnopkaVidelit.width/8*3
            height: rctKnopkaVidelit.height/8
            anchors.bottom: rctKnopkaVidelit.bottom
            anchors.left: rctKnopkaVidelit.left
            anchors.bottomMargin: rctKnopkaVidelit.width/8
            anchors.leftMargin: rctKnopkaVidelit.width/4

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaVidelit.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaVidelit.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaVidelit.width/2//Круг
        }
	}	
}
