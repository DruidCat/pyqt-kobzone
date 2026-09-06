import QtQuick

Item {
    id: root
    //Свойства.
    property int ntWidth: 2
    property int ntCoff: 8
    property color clrKnopki: "grey"
    property color clrFona: "transparent"//Цвет фона кнопки.
    property real minDarker: 0.7//Минимальная затемнённость кнопки, когда она не активная.
    property real maxDarker: 1.3//Максимальная затемнённость кнопки, когда она нажата.
    property bool enabled: true//true - активирована, false - деактивирована кнопка.
    property bool pressed: tphKnopkaLm.pressed//true - нажали, false - не нажали
    //property bool pressed: maKnopkaLm.pressed//true - нажали, false - не нажали
    property real tapHeight: ntWidth * ntCoff//Высота зоны нажатия пальцем или мышкой
    property real tapWidth: ntWidth * ntCoff//Ширина зоны нажатия пальцем или мышкой
	property bool isLMZapuschen: false//true - инверсирована кнопка.
	//Это гарантирует, что внешние привязки (bindings) не будут сломаны.
    readonly property color realClrKnopki: root.isLMZapuschen ? root.clrFona : root.clrKnopki
    readonly property color realClrFona: root.isLMZapuschen ? root.clrKnopki : root.clrFona
    //Настройки.
    height: tapHeight
    width: tapWidth
    //Сигналы.
    signal clicked();
    //Функции. 
    //Для Авроры комментируем TapHandler, расскомментируем MouseArea и наоборот.
    TapHandler { // Обработка нажатия, замена MouseArea с Qt5.10
        id: tphKnopkaLm
        onTapped: {
            if (root.enabled) // Если активирована кнопка, то...
                root.clicked(); // Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaLm
        anchors.fill: root
        onClicked: {
            if (root.enabled) // Если активирована кнопка, то...
                root.clicked(); // Обрабатываем клик.
        }
    }
    */
    Rectangle {//Фон кнопки
        id: rctFon
		height: root.ntWidth * root.ntCoff
        width: height
        anchors.centerIn: root
        color: realClrFona
		radius: root.width/8
    }
    Item {
        id: tmKnopkaLm
        height: root.ntWidth * root.ntCoff
        width: height
        anchors.centerIn: root
        //================= БУКВА "L" =================
        Rectangle {//Левая вертикальная часть (верх)
            id: rctLLevaVerh
            width: tmKnopkaLm.width / 8
            height: tmKnopkaLm.height / 2
            anchors.top: tmKnopkaLm.top
            anchors.left: tmKnopkaLm.left
            anchors.topMargin: tmKnopkaLm.height / 8
            anchors.leftMargin: tmKnopkaLm.height / 8
            color: {
                if(root.enabled)tphKnopkaLm.pressed ? Qt.darker(realClrKnopki, root.maxDarker) : realClrKnopki
                else Qt.darker(realClrKnopki, root.minDarker)
            }
        }
        Rectangle {//Левая вертикальная часть (низ)
            id: rctLLevaNiz
            width: tmKnopkaLm.width / 8
            height: tmKnopkaLm.height / 4
            anchors.top: rctLLevaVerh.bottom
            anchors.left: tmKnopkaLm.left
            anchors.leftMargin: tmKnopkaLm.height / 8
            color: {
                if(root.enabled)tphKnopkaLm.pressed ? Qt.darker(realClrKnopki, root.maxDarker) : realClrKnopki
                else Qt.darker(realClrKnopki, root.minDarker)
            }
        }
        Rectangle {//Нижняя горизонтальная часть буквы "L"
            id: rctLDno
            width: tmKnopkaLm.width / 8
            height: tmKnopkaLm.height / 8
            anchors.bottom: tmKnopkaLm.bottom
            anchors.left: rctLLevaNiz.right
            anchors.bottomMargin: tmKnopkaLm.height / 8
            color: {
                if(root.enabled)tphKnopkaLm.pressed ? Qt.darker(realClrKnopki, root.maxDarker) : realClrKnopki
                else Qt.darker(realClrKnopki, root.minDarker)
            }
        }
        //================= БУКВА "M" =================
        Rectangle {//Левая вертикальная часть "M" (верх)
            id: rctMLevaVerh
            width: tmKnopkaLm.width / 8
            height: tmKnopkaLm.height / 2
            anchors.top: tmKnopkaLm.top
            anchors.left: tmKnopkaLm.left
            anchors.topMargin: tmKnopkaLm.height / 8
            anchors.leftMargin: tmKnopkaLm.height * 4 / 8//Сдвиг вправо для создания зазора между L и M
            color: {
                if(root.enabled)tphKnopkaLm.pressed ? Qt.darker(realClrKnopki, root.maxDarker) : realClrKnopki
                else Qt.darker(realClrKnopki, root.minDarker)
            }
        }
        Rectangle {//Левая вертикальная часть "M" (низ)
            id: rctMLevaNiz
            width: tmKnopkaLm.width / 8
            height: tmKnopkaLm.height / 4
            anchors.top: rctMLevaVerh.bottom
            anchors.left: tmKnopkaLm.left
            anchors.leftMargin: tmKnopkaLm.height * 4 / 8
            color: {
                if(root.enabled)tphKnopkaLm.pressed ? Qt.darker(realClrKnopki, root.maxDarker) : realClrKnopki
                else Qt.darker(realClrKnopki, root.minDarker)
            }
        }
        Rectangle {//Левая диагональ/центральная часть "M"
            id: rctMCentrLeva
            width: tmKnopkaLm.width / 8
            height: tmKnopkaLm.height / 4
            anchors.top: tmKnopkaLm.top
            anchors.left: rctMLevaVerh.right
            anchors.topMargin: tmKnopkaLm.height * 2 / 8
            color: {
                if(root.enabled)tphKnopkaLm.pressed ? Qt.darker(realClrKnopki, root.maxDarker) : realClrKnopki
                else Qt.darker(realClrKnopki, root.minDarker)
            }
        }
        Rectangle {//Правая диагональ/центральная часть "M"
            id: rctMCentrPrava
            width: tmKnopkaLm.width / 8
            height: tmKnopkaLm.height / 4
            anchors.top: tmKnopkaLm.top
            anchors.right: rctMPravaVerh.left
            anchors.topMargin: tmKnopkaLm.height * 2 / 8
            color: {
                if(root.enabled)tphKnopkaLm.pressed ? Qt.darker(realClrKnopki, root.maxDarker) : realClrKnopki
                else Qt.darker(realClrKnopki, root.minDarker)
            }
        }
        Rectangle {//Правая вертикальная часть "M" (верх)
            id: rctMPravaVerh
            width: tmKnopkaLm.width / 8
            height: tmKnopkaLm.height / 2
            anchors.top: tmKnopkaLm.top
            anchors.right: tmKnopkaLm.right
            anchors.topMargin: tmKnopkaLm.height / 8
            anchors.rightMargin: tmKnopkaLm.height / 8
            color: {
                if(root.enabled)tphKnopkaLm.pressed ? Qt.darker(realClrKnopki, root.maxDarker) : realClrKnopki
                else Qt.darker(realClrKnopki, root.minDarker)
            }
        }
        Rectangle {//Правая вертикальная часть "M" (низ)
            id: rctMPravaNiz
            width: tmKnopkaLm.width / 8
            height: tmKnopkaLm.height / 4
            anchors.top: rctMPravaVerh.bottom
            anchors.right: tmKnopkaLm.right
            anchors.rightMargin: tmKnopkaLm.height / 8
            color: {
                if(root.enabled)tphKnopkaLm.pressed ? Qt.darker(realClrKnopki, root.maxDarker) : realClrKnopki
                else Qt.darker(realClrKnopki, root.minDarker)
            }
        }
    }
}
