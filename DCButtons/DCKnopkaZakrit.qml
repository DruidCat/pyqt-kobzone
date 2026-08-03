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
    property bool pressed: tphKnopkaZakrit.pressed//true - нажали false - не нажали
    //property bool pressed: maKnopkaZakrit.pressed//true - нажали false - не нажали
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
        id: tphKnopkaZakrit
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaZakrit
        anchors.fill: root
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Rectangle {
        id: rctKnopkaZakrit
        height: root.ntWidth*root.ntCoff
        width: height
        anchors.centerIn: root

        color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaZakrit.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                //maKnopkaZakrit.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
            else//Если деактивирована кнопка, то...
                Qt.darker(clrFona, root.minDarker)
        }
        border.color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaZakrit.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                //maKnopkaZakrit.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
            else//Если деактивирована кнопка, то...
                Qt.darker(clrKnopki, root.minDarker)
        }
        border.width: width/8/4
        radius: width/4

        Rectangle {
            id: rctVerhPravo
            width: rctKnopkaZakrit.width/4
            height: width
            anchors.top: rctKnopkaZakrit.top
            anchors.right: rctKnopkaZakrit.right
            anchors.topMargin: rctKnopkaZakrit.width/8
            anchors.rightMargin: rctKnopkaZakrit.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaZakrit.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaZakrit.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaZakrit.width/4
        }
        Rectangle {
            id: rctVerhLevo
            width: rctKnopkaZakrit.width/4
            height: width
            anchors.top: rctKnopkaZakrit.top
            anchors.left: rctKnopkaZakrit.left
            anchors.topMargin: rctKnopkaZakrit.width/8
            anchors.leftMargin: rctKnopkaZakrit.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaZakrit.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaZakrit.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaZakrit.width/4
        }
        Rectangle {
            id: rctCentor
            width: rctKnopkaZakrit.width/4
            height: width
            anchors.centerIn: rctKnopkaZakrit

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaZakrit.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaZakrit.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaZakrit.width/4
        }
        Rectangle {
            id: rctNizPravo
            width: rctKnopkaZakrit.width/4
            height: width
            anchors.bottom: rctKnopkaZakrit.bottom
            anchors.right: rctKnopkaZakrit.right
            anchors.bottomMargin: rctKnopkaZakrit.width/8
            anchors.rightMargin: rctKnopkaZakrit.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaZakrit.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaZakrit.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaZakrit.width/4
        }
        Rectangle {
            id: rctNizLevo
            width: rctKnopkaZakrit.width/4
            height: width
            anchors.bottom: rctKnopkaZakrit.bottom
            anchors.left: rctKnopkaZakrit.left
            anchors.bottomMargin: rctKnopkaZakrit.width/8
            anchors.leftMargin: rctKnopkaZakrit.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaZakrit.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaZakrit.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaZakrit.width/4
        } 
    } 
}
