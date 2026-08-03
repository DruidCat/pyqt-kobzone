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
    property bool pressed: tphKnopkaMenu.pressed//true - нажали false - не нажали
    //property bool pressed: maKnopkaMenu.pressed//true - нажали false - не нажали
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
        id: tphKnopkaMenu
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaMenu
        anchors.fill: root
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Rectangle{
		id: rctKnopkaMenu
        height: root.ntWidth*root.ntCoff
        width: height
        anchors.centerIn: root

        color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaMenu.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                //maKnopkaMenu.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
            else//Если деактивирована кнопка, то...
                Qt.darker(clrFona, root.minDarker)
        }
		Rectangle{
			id: rctKnopkaVerh
			width: rctKnopkaMenu.width
			height: rctKnopkaMenu.width/4
			anchors.top: rctKnopkaMenu.top
			anchors.left: rctKnopkaMenu.left

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaMenu.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaMenu.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaMenu.width/4
		}

		Rectangle{
			id: rctKnopkaSeredina
			width: rctKnopkaMenu.width
			height: rctKnopkaMenu.width/4
			anchors.verticalCenter: rctKnopkaMenu.verticalCenter
			anchors.left: rctKnopkaMenu.left

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaMenu.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaMenu.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaMenu.width/4
		}

		Rectangle{
			id: rctKnopkaNiz
			width: rctKnopkaMenu.width
			height: rctKnopkaMenu.width/4
			anchors.bottom: rctKnopkaMenu.bottom
			anchors.left: rctKnopkaMenu.left

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaMenu.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaMenu.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaMenu.width/4
        } 
	}	
}
