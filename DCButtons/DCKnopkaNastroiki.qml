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
    property bool pressed: tphKnopkaNastroiki.pressed//true - нажали false - не нажали
    //property bool pressed: maKnopkaNastroiki.pressed//true - нажали false - не нажали
    property bool blVert: false//true - вертикально точки расположены.
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
        id: tphKnopkaNastroiki
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaNastroiki
        anchors.fill: root
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Rectangle{
		id: rctKnopkaNastroiki
        height: root.ntWidth*root.ntCoff
        width: height
        anchors.centerIn: root

        color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaNastroiki.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                //maKnopkaNastroiki.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
            else//Если деактивирована кнопка, то...
                Qt.darker(clrFona, root.minDarker)
        }
        Rectangle{
			id: rctKnopkaLevo
            visible: blVert ? false : true
            width: rctKnopkaNastroiki.width/4
			height: rctKnopkaNastroiki.width/4
			anchors.verticalCenter: rctKnopkaNastroiki.verticalCenter
			anchors.left: rctKnopkaNastroiki.left

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaNastroiki.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaNastroiki.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaNastroiki.width/2//Круг
		}

		Rectangle{
			id: rctKnopkaSeredina
			width: rctKnopkaNastroiki.width/4
			height: rctKnopkaNastroiki.width/4
			anchors.centerIn: rctKnopkaNastroiki

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaNastroiki.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaNastroiki.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaNastroiki.width/2//Круг
		}

		Rectangle{
			id: rctKnopkaPravo
            visible: blVert ? false : true
            width: rctKnopkaNastroiki.width/4
			height: rctKnopkaNastroiki.width/4
			anchors.verticalCenter: rctKnopkaNastroiki.verticalCenter
			anchors.right: rctKnopkaNastroiki.right

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaNastroiki.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaNastroiki.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaNastroiki.width/2//Круг
		}

        Rectangle{
            id: rctKnopkaVerh
            visible: blVert ? true : false
            width: rctKnopkaNastroiki.width/4
            height: rctKnopkaNastroiki.width/4
            anchors.horizontalCenter: rctKnopkaNastroiki.horizontalCenter
            anchors.top: rctKnopkaNastroiki.top

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaNastroiki.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaNastroiki.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaNastroiki.width/2//Круг
        }
        Rectangle{
            id: rctKnopkaNiz
            visible: blVert ? true : false
            width: rctKnopkaNastroiki.width/4
            height: rctKnopkaNastroiki.width/4
            anchors.horizontalCenter: rctKnopkaNastroiki.horizontalCenter
            anchors.bottom: rctKnopkaNastroiki.bottom

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaNastroiki.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaNastroiki.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaNastroiki.width/2//Круг
        } 
	}	
}
