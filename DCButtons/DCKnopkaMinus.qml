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
    property bool pressed: tphKnopkaMinus.pressed//true - нажали false - не нажали
    //property bool pressed: maKnopkaMinus.pressed//true - нажали false - не нажали
    property bool border: true
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
        id: tphKnopkaMinus
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaMinus
        anchors.fill: root
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Rectangle {
        id: rctKnopkaMinus
        height: root.ntWidth*root.ntCoff
        width: height
        anchors.centerIn: root

        color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaMinus.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                //maKnopkaMinus.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
            else//Если деактивирована кнопка, то...
                Qt.darker(clrFona, root.minDarker)
        }
        radius: width/4

        Rectangle {
            id: rctCentor
            height: rctKnopkaMinus.width/4
            width: height*3
            anchors.centerIn: rctKnopkaMinus

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaMinus.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaMinus.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            radius: rctKnopkaMinus.width/4
        } 
	}
	Component.onCompleted: {
        if(root.border){
            if(root.enabled){//Если активирована кнопка, то...
                rctKnopkaMinus.border.color = tphKnopkaMinus.pressed
                        ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                //rctKnopkaMinus.border.color = maKnopkaMinus.containsMouse
                          ?Qt.darker(clrKnopki,root.maxDarker):clrKnopki
            }
            else//Если деактивирована кнопка, то...
                rctKnopkaMinus.border.color = Qt.darker(clrKnopki, root.minDarker)
            rctKnopkaMinus.border.width = rctKnopkaMinus.width/8/4;
		}
	} 
}
