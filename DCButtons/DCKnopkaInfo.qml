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
    property bool pressed: tphKnopkaInfo.pressed//true - нажали false - не нажали
    property bool opened: false//true - радиус 0, false - root.width/4
    //property bool pressed: maKnopkaInfo.pressed//true - нажали false - не нажали
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
        id: tphKnopkaInfo
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaInfo
        anchors.fill: root
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Rectangle {
		id: rctKnopkaInfo
        height: root.ntWidth*root.ntCoff
        width: height
        anchors.centerIn: root

        color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaInfo.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                //maKnopkaInfo.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
            else//Если деактивирована кнопка, то...
                Qt.darker(clrFona, root.minDarker)
        }
        border.color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaInfo.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                //maKnopkaInfo.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
            else//Если деактивирована кнопка, то...
                Qt.darker(clrKnopki, root.minDarker)
        }
        border.width: root.width/8/4
        radius: root.opened ? 0 : root.width/4

		Rectangle {
			id: rctBukvaTochka
			visible: true
			width: rctKnopkaInfo.width/4
			height: width
			anchors.top: rctKnopkaInfo.top
			anchors.horizontalCenter: rctKnopkaInfo.horizontalCenter
            anchors.topMargin: rctKnopkaInfo.width/8

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaInfo.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaInfo.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaInfo.width/4
		}

		Rectangle {
			id: rctBukvaPalochka1
			width: rctKnopkaInfo.width/4
			height: rctKnopkaInfo.width/8
			anchors.top: rctKnopkaInfo.verticalCenter
			anchors.horizontalCenter: rctKnopkaInfo.horizontalCenter

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaInfo.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaInfo.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
        }

		Rectangle {
			id: rctBukvaPalochka2
			width: rctKnopkaInfo.width/4
			height: rctKnopkaInfo.width/4
			anchors.top: rctBukvaPalochka1.bottom
			anchors.horizontalCenter: rctKnopkaInfo.horizontalCenter

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaInfo.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaInfo.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
        }
	}
}
