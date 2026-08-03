import QtQuick
import DCButtons 1.0

Item {
    id: root
    
    // Свойства
    property int ntWidth: 2
    property int ntCoff: 8
    property color clrTexta: "indigo"
    property color clrFona: "white"
    property color clrMenuText: "indigo"
    property color clrMenuFon: "#f5f5f5"//Светло-серый для кнопок
    
    property alias zagolovokX: tmZagolovok.x
    property alias zagolovokY: tmZagolovok.y
    property alias zagolovokWidth: tmZagolovok.width
    property alias zagolovokHeight: tmZagolovok.height
    property alias zonaX: tmZona.x
    property alias zonaY: tmZona.y
    property alias zonaWidth: tmZona.width
    property alias zonaHeight: tmZona.height
    property alias toolbarX: tmToolbar.x
    property alias toolbarY: tmToolbar.y
    property alias toolbarWidth: tmToolbar.width
    property alias toolbarHeight: tmToolbar.height
    
    property real tapZagolovokLevi: 1
    property real tapZagolovokPravi: 1
    property real tapToolbarLevi: 1
    property real tapToolbarPravi: 1
    //Настройки
    anchors.fill: parent
    focus: true
    //Сигналы
    signal clickedAnalizator()
    signal clickedRedaktor()
    signal clickedTranskribaciya()
    //Функции
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            if (tmZona.currentIndex > 0)
                tmZona.currentIndex--
            else
                tmZona.currentIndex = rctZona.children.length - 1
            event.accepted = true
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            if (tmZona.currentIndex < (rctZona.children.length - 1))
                tmZona.currentIndex++
            else
                tmZona.currentIndex = 0
            event.accepted = true
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            fnClickedEnter()
            event.accepted = true
        }
    }
    function fnClickedEnter() {
        var vrKnopkaID = rctZona.children[tmZona.currentIndex]
        if (vrKnopkaID && typeof vrKnopkaID.fnPress === "function" && 
            vrKnopkaID.visible && vrKnopkaID.enabled) {
            vrKnopkaID.fnPress()
        }
    }
    Item {//Заголовок
        id: tmZagolovok
    }
    Item {//Рабочая зона
        id: tmZona
        property int currentIndex: 0
        Image {//Логотип на заднем фоне
            id: imgLogo
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.6, parent.height * 0.6)
            height: width
			source: "qrc:/resources/images/logo.png"//Используем ресурс с префиксом qrc:
            fillMode: Image.PreserveAspectFit
            opacity: 1
            visible: true
        }
        Column {
            anchors.centerIn: parent
            spacing: root.ntWidth * 2
            width: parent.width * 0.8
            
            Rectangle {
                id: rctZona
                width: parent.width
                height: childrenRect.height
                color: "transparent"
                
                Column {
                    width: parent.width
                    spacing: root.ntWidth
                    DCKnopkaOriginal {//Кнопка "Анализатор текста"
                        id: knopkaAnalizator
                        ntHeight: root.ntWidth * 2
                        ntCoff: root.ntCoff
                        anchors.left: parent.left
                        anchors.right: parent.right
                        clrTexta: root.clrMenuText
                        clrKnopki: (tmZona.currentIndex === 0) ? 
                            Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                        text: "АНАЛИЗАТОР ТЕКСТА"
                        opacityKnopki: 0.7
                        function fnPress() {
                            tmZona.currentIndex = 0
                            root.clickedAnalizator()
                        }
                        onPressedChanged: {//Если нажатие на кнопку изменилось, то...
                            if (pressed) fnPress()
                        }
                    }
                    DCKnopkaOriginal {//Кнопка "Редактор текста"
                        id: knopkaRedaktor
                        ntHeight: root.ntWidth * 2
                        ntCoff: root.ntCoff
                        anchors.left: parent.left
                        anchors.right: parent.right
                        clrTexta: root.clrMenuText
                        clrKnopki: (tmZona.currentIndex === 1) ? 
                            Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                        text: "РЕДАКТОР ТЕКСТА"
                        opacityKnopki: 0.7
                        enabled: true//Пока не реализовано
                        function fnPress() {
                            tmZona.currentIndex = 1
                            root.clickedRedaktor()
                        }
                        onPressedChanged: {//Если нажатие на кнопку изменилось, то...
                            if (pressed) fnPress()
                        }
                    }
                    DCKnopkaOriginal {//Кнопка "Транскрибация"
                        id: knopkaTranskribaciya
                        ntHeight: root.ntWidth * 2
                        ntCoff: root.ntCoff
                        anchors.left: parent.left
                        anchors.right: parent.right
                        clrTexta: root.clrMenuText
                        clrKnopki: (tmZona.currentIndex === 2) ? 
                            Qt.darker(root.clrMenuFon, 1.2) : root.clrMenuFon
                        text: "ТРАНСКРИБАЦИЯ"
                        opacityKnopki: 0.7
                        enabled: true//Пока не реализовано
                        function fnPress() {
                            tmZona.currentIndex = 2
                            root.clickedTranskribaciya()
                        }
                        onPressedChanged: {//Если нажатие на кнопку изменилось, то...
                            if (pressed) fnPress()
                        }
                    }
                }
            }
        }
    }
    Item {//Тулбар
        id: tmToolbar
    }
}
