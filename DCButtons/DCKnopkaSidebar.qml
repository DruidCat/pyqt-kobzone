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
    property bool pressed: tphSidebar.pressed//true - нажали false - не нажали
    property bool opened: false//true - боковая панель открыта, false - боковая панель закрыта
    //property bool pressed: maKnopkaNazad.pressed//true - нажали false - не нажали
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
        id: tphSidebar
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maSidebar
        anchors.fill: root
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Rectangle {
        id: rctSidebar
        height: root.ntWidth*root.ntCoff
        width: height
        anchors.centerIn: root

        color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphSidebar.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                //maSidebar.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
            else//Если деактивирована кнопка, то...
                Qt.darker(clrFona, root.minDarker)
        }
        border.color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphSidebar.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                //maSidebar.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
            else//Если деактивирована кнопка, то...
                Qt.darker(clrKnopki, root.minDarker)
        }
        border.width: width/8/4
        radius: width/4

        Rectangle {
            id: rctPalka
            width: rctSidebar.width/4
            height: rctSidebar.width
            anchors.top: rctSidebar.top
            anchors.left: rctSidebar.left

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphSidebar.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maSidebar.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
        }
        Rectangle {
            id: rctStrelkaVerh
            visible: true
            width: rctSidebar.width/4
            height: width
            anchors.top: rctSidebar.top
            anchors.right: rctSidebar.right
            anchors.rightMargin: root.opened ? rctSidebar.width/8 : rctSidebar.width/8*3
            anchors.topMargin: rctSidebar.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphSidebar.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maSidebar.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctSidebar.width/4
        }

        Rectangle {
            id: rctStrelkaNiz
            width: rctSidebar.width/4
            height: width
            anchors.bottom: rctSidebar.bottom
            anchors.right: rctSidebar.right
            anchors.rightMargin: root.opened ? rctSidebar.width/8 : rctSidebar.width/8*3
            anchors.bottomMargin: rctSidebar.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphSidebar.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maSidebar.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctSidebar.width/4
        }

        Rectangle {
            id: rctStrelkaCentr
            width: rctSidebar.width/4
            height: width
            anchors.right: rctSidebar.right
            anchors.top: rctSidebar.top
            anchors.rightMargin: root.opened ? rctSidebar.width/8*3 : rctSidebar.width/8
            anchors.topMargin: rctSidebar.width/8*3

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphSidebar.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maSidebar.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctSidebar.width/4
        }
    }
}
