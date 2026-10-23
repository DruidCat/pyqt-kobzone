import QtQuick //2.15
//import QtQuick.Handlers//Не требуется в Qt 6.2+

Item {
    id: root
    //Свойства.
	property int ntWidth: 2
	property int ntCoff: 8
	property color clrKnopki: "grey"
	property color clrFona: "white"
    property real minDarker: 0.7//Миннимальная затемнённость кнопки, когда она не активная.
    property real maxDarker: 1.3//Максимальная затемнённость кнопки, когда она нажата.
    property bool enabled: true//true - активирована, false - деактивированна кнопка.
    property bool pressed: tphKnopkaInfo.pressed//true - нажали false - не нажали
    property bool isInvers: false//true - радиус 0, false - root.width/4
	property bool isBig: false//true - большой, false - маленький 
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
		enabled: root.enabled
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaInfo
        anchors.fill: root
		enabled: root.enabled
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Rectangle {
		id: rctKnopkaSvetofor
        height: root.ntWidth*root.ntCoff/(isBig ? 1 : 2); width: height
        anchors.centerIn: root
        color: {
            if(root.enabled){//Если активирована кнопка, то...
				tphKnopkaInfo.pressed 	? Qt.darker(isInvers ? clrKnopki
										: clrFona, root.maxDarker) : isInvers ? clrKnopki : clrFona
				//maKnopkaInfo.containsMouse ? Qt.darker(isInvers ? clrKnopki
				//							: clrFona, root.maxDarker) : isInvers ? clrKnopki : clrFona
			} else Qt.darker(isInvers ? clrKnopki : clrFona, root.minDarker)
        }
        border.color: {
            if(root.enabled){//Если активирована кнопка, то...
                tphKnopkaInfo.pressed 	? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                //maKnopkaInfo.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
            } else Qt.darker(clrKnopki, root.minDarker)
        }
        border.width: root.width/8/4
        radius: root.width/2
		/*
		Rectangle {
			id: rctTochka
			width: rctKnopkaSvetofor.width/4; height: width
			anchors.horizontalCenter: rctKnopkaSvetofor.horizontalCenter
			anchors.verticalCenter: rctKnopkaSvetofor.verticalCenter
            color: {
                if(root.enabled){//Если активирована кнопка, то...
					tphKnopkaInfo.pressed 	? Qt.darker(isInvers ? clrFona : clrKnopki, root.maxDarker)
											: isInvers ? clrFona : clrKnopki
                    //maKnopkaInfo.containsMouse ? Qt.darker(isInvers ? clrFona : clrKnopki, root.maxDarker)
					//						: isInvers ? clrFona : clrKnopki
				} else Qt.darker(isInvers ? clrFona : clrKnopki, root.minDarker)
            }
            radius: rctKnopkaSvetofor.width/4
		}
		*/
	}
}
