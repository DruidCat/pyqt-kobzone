import QtQuick //2.15
//import QtQuick.Handlers//Не требуется в Qt 6.2+

Item {
    id: root
    //Свойства.
	property int ntWidth: 2
	property int ntCoff: 8
	property color clrKnopki: "black"
    property color clrFona: "white"
    property real minDarker: 0.7//Миннимальная затемнённость кнопки, когда она не активная.
    property real maxDarker: 1.3//Максимальная затемнённость кнопки, когда она нажата.
    property bool enabled: true//true - активирована, false - деактивированна кнопка.
    property bool pressed: tphKnopkaSozdat.pressed//true - нажали false - не нажали
    //property bool pressed: maKnopkaSozdat.pressed//true - нажали false - не нажали
    property bool blKrug: true
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
        id: tphKnopkaSozdat
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaSozdat
        anchors.fill: root
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Item {
        id: tmKnopkaSozdat
        height: root.ntWidth*root.ntCoff
        width: height
        anchors.centerIn: root

        Rectangle{
            id: rctKnopkaKrug
            anchors.fill: tmKnopkaSozdat

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaSozdat.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                    //maKnopkaSozdat.containsMouse ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrKnopki, root.minDarker)
            }
            border.color: {
                if(root.enabled)
                    Qt.darker(clrKnopki, root.maxDarker)//Граница кнопки чуть темнее
                else
                    clrKnopki
            }
            border.width: 1//Ширина границы
            radius: blKrug ? width/2 : 1
            smooth: true//Сглаживание
        }
        Rectangle{
            id: rctKnopkaSeredina
            width: tmKnopkaSozdat.width/2
            height: tmKnopkaSozdat.width/8
            anchors.centerIn: tmKnopkaSozdat

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaSozdat.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                    //maKnopkaSozdat.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrFona, root.minDarker)
            }
            radius: tmKnopkaSozdat.width/4
        }
        Rectangle{
            id: rctKnopkaNiz
            width: tmKnopkaSozdat.width/8
            height: tmKnopkaSozdat.width/2
            anchors.centerIn: tmKnopkaSozdat

            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaSozdat.pressed ? Qt.darker(clrFona, root.maxDarker) : clrFona
                    //maKnopkaSozdat.containsMouse ? Qt.darker(clrFona, root.maxDarker) : clrFona
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrFona, root.minDarker)
            }
            radius: tmKnopkaSozdat.width/4
        }
    }
}
