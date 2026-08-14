import QtQuick
import QtQuick.Controls
import DCButtons 1.0
import DCMethods 1.0

Item {
    id: root
    //Свойства
    property int ntWidth: 2
    property int ntCoff: 8
    property color clrTexta: "indigo"
    property color clrFona: "white"
    property color clrMenuText: "indigo"
    property color clrMenuFon: "#f5f5f5"
    
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
    
    property real tapZagolovokLevi: 1.3
    property real tapZagolovokPravi: 1.3
    property real tapToolbarLevi: 1.3
    property real tapToolbarPravi: 1.3
    
    property int logoRazmer: 22
    property real rlProgress: 0
    property real rlLoader: 1
	//Настройки
    anchors.fill: parent
    focus: true
    //Сигналы
    signal clickedNazad()
	signal clickedSettings()
    signal clickedInfo()
    signal signalToolbar(var strToolbar)
    //Методы
    Timer {//ТАЙМЕР анимации логотипа
        id: tmrLogo
        interval: 47
        running: false
        repeat: true
        property bool blLogo: false
        onTriggered: {
            if (blLogo) {
                imgLogo.scale += 0.02
                if (imgLogo.scale >= 1.3)
                    blLogo = false
            } else {
                imgLogo.scale -= 0.02
                if (imgLogo.scale <= 0.7)
                    blLogo = true
            }
        }
        onRunningChanged: {
            if (running) {
                ldrProgress.active = true
                
                knopkaInfo.visible = false
                knopkaNastroiki.visible = false
                knopkaMenu.enabled = false
                knopkaNazad.enabled = false
                
                knopkaZagruzit.enabled = false
                knopkaAnaliz.enabled = false
                knopkaSohranit.enabled = false
            } else {
                imgLogo.scale = 1.0
                ldrProgress.active = false
                
                knopkaInfo.visible = true
                knopkaNastroiki.visible = true
                knopkaMenu.enabled = true
                knopkaNazad.enabled = true
                
                knopkaZagruzit.enabled = true
                knopkaAnaliz.enabled = contentArea.text.trim() !== ""
            }
        }
    }
    Keys.onPressed: (event) => {//Обработка горячих клавиш
        if (event.modifiers & Qt.AltModifier) {
            if (event.key === Qt.Key_Left) {
                root.clickedNazad()
                event.accepted = true
                return
            }
        }
        if (event.modifiers & Qt.ControlModifier) {
            if (event.key === Qt.Key_S) {
                if (!menuMenu.visible && knopkaSohranit.enabled) {
                    fnClickedSave()
                }
                event.accepted = true
            }
        }
        if (event.key === Qt.Key_Escape) {
            if (menuMenu.visible) {
                menuMenu.visible = false
                event.accepted = true
            } else {
                event.accepted = true
            }
        } else if (event.key === Qt.Key_F1) {
            if (!menuMenu.visible) {
                fnClickedInfo()    
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
            if (!menuMenu.visible) {
                var ltNoviY = flcZona.contentY - 50
                if (ltNoviY < 0)
                    ltNoviY = 0
                flcZona.contentY = ltNoviY
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
            if (!menuMenu.visible) {
                var ltMaxY = flcZona.contentHeight - flcZona.height
                var ltNoviY = flcZona.contentY + 50
                if (ltNoviY > ltMaxY)
                    ltNoviY = ltMaxY
                flcZona.contentY = ltNoviY
            }    
            event.accepted = true
        } else if (event.key === Qt.Key_PageUp) {
            if (!menuMenu.visible) {
                var ltNoviY = flcZona.contentY - flcZona.height
                if (ltNoviY < 0)
                    ltNoviY = 0
                flcZona.contentY = ltNoviY
            }
            event.accepted = true
        } else if (event.key === Qt.Key_PageDown) {
            if (!menuMenu.visible) {
                var ltMaxY = flcZona.contentHeight - flcZona.height
                var ltNoviY = flcZona.contentY + flcZona.height
                if (ltNoviY > ltMaxY)
                    ltNoviY = ltMaxY
                flcZona.contentY = ltNoviY
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Home) {
            if (!menuMenu.visible) {
                flcZona.contentY = 0
            }
            event.accepted = true
        } else if (event.key === Qt.Key_End) {
            if (!menuMenu.visible) {
                flcZona.contentY = flcZona.contentHeight - flcZona.height
            }
            event.accepted = true
        }
    }
    
    function fnClickedMenu() {
		root.clickedSettings()//Сигнал излучает открытие настроек.
    }
    function fnClickedInfo() {
        root.clickedInfo()
    }
    function fnClickedLoad() {
        console.log("ЗАГРУЗИТЬ")
    }
	function fnClickedOrfograf() {
        console.log("ОРФОГРАФИЯ")
	}
    function fnToggleMenu() {
        if (menuMenu.visible) menuMenu.visible = false
        else menuMenu.visible = true
    }
    function fnCloseMenuIfOpen() {
        if (menuMenu.visible) {
            menuMenu.visible = false
            return true
        }
        return false
    }
    Component.onCompleted: {
        root.forceActiveFocus()
    }
    Item {//Заголовок
        id: tmZagolovok
        DCKnopkaNazad {
            id: knopkaNazad
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.verticalCenter: tmZagolovok.verticalCenter
            anchors.left: tmZagolovok.left
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff
            tapWidth: tapHeight * root.tapZagolovokLevi
            onClicked: root.clickedNazad()
        }
        DCKnopkaMenu {
            id: knopkaMenu
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            visible: true
            anchors.verticalCenter: tmZagolovok.verticalCenter
            anchors.right: tmZagolovok.right
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff
            tapWidth: tapHeight * root.tapZagolovokPravi
            onClicked: {
                if (!fnCloseMenuIfOpen()) {
                    fnClickedMenu()
                }
            }
        }
    }
    Item {//Рабочая зона
        id: tmZona
        clip: true
        Image {//ЛОГОТИП
            id: imgLogo
            anchors.centerIn: tmZona
            width: 200
            height: 200
            source: "qrc:/resources/images/logo.png"
            fillMode: Image.PreserveAspectFit
            opacity: 0.4
            visible: true
            z: -1
            scale: 1.0
        }
        Flickable {
            id: flcZona
            anchors.fill: parent
            contentWidth: tmZona.width
            contentHeight: clmnContent.height
            clip: true
            interactive: true
            boundsBehavior: Flickable.StopAtBounds
            opacity: 0.9//ГЛАВНАЯ ПРОЗРАЧНОСТЬ!!!
            
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
            
            Column {
                id: clmnContent
                width: flcZona.width - dcScrollbar.width
                spacing: root.ntCoff/2//Расстояние между элементами по вертикали.
                topPadding: root.ntCoff * 2
                bottomPadding: root.ntCoff * 2
                leftPadding: root.ntCoff * 2
                rightPadding: root.ntCoff * 2
               
                //ОСНОВНОЙ КОД ТУТ.
            }
        }
        DCScrollbar {// Скроллбар основной области
            id: dcScrollbar
            flick: flcZona
            anchors.right: tmZona.right
            anchors.top: tmZona.top
            anchors.bottom: tmZona.bottom
            clrPolzunokOff: Qt.lighter(root.clrMenuFon, 1.3)
            clrPolzunokOn: root.clrTexta
            width: root.ntWidth * root.ntCoff
            radius: 1
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                }
            }
        }
        DCMenu {//Всплывающее меню DCMenu
            id: menuMenu
            visible: false
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.left: tmZona.left
            anchors.right: tmZona.right
            anchors.bottom: tmZona.bottom
            anchors.bottomMargin: root.ntWidth
            anchors.rightMargin: dcScrollbar.width
            pctFona: 0.90
            clrTexta: root.clrMenuText
            clrFona: root.clrMenuFon
            imyaMenu: "orfograf"
            
            onClicked: function(ntNomer, strMenu) {
                menuMenu.visible = false
                
                if (ntNomer === 1) {
                    fnClickedLoad()
                } else if (ntNomer === 2) {
                    fnClickedOrfograf()
                }  else if (ntNomer === 3) {
                    fnClickedMenu()
                } else if (ntNomer === 4) {
                    fnClickedInfo()
                } else if (ntNomer === 5) {
                    Qt.quit()
                }
            }
            onVisibleChanged: {
                if (!visible) {
                    root.forceActiveFocus()
                }
            }
        }
    }
    Item {//Тулбар
        id: tmToolbar
        clip: true
        Loader {//LOADER для DCProgress
            id: ldrProgress
            anchors.fill: tmToolbar
            source: "qrc:/DCMethods/DCProgress.qml"
            active: false
            onLoaded: {
                ldrProgress.item.ntWidth = root.ntWidth
                ldrProgress.item.ntCoff = root.ntCoff
                ldrProgress.item.clrProgress = root.clrTexta
                ldrProgress.item.clrTexta = "grey"
                ldrProgress.item.radius = root.ntCoff / 4
				ldrProgress.item.msInterval = 2200
            }
        }
        DCKnopkaInfo {
            id: knopkaInfo
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.verticalCenter: tmToolbar.verticalCenter
            anchors.left: tmToolbar.left
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            visible: true
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff
            tapWidth: tapHeight * root.tapToolbarLevi
            onClicked: {
                if (!fnCloseMenuIfOpen()) {
                    fnClickedInfo()
                }
            }
        }
        DCKnopkaNastroiki {
            id: knopkaNastroiki
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.verticalCenter: tmToolbar.verticalCenter
            anchors.right: tmToolbar.right
            clrKnopki: root.clrTexta
            clrFona: root.clrFona
            blVert: true
            tapHeight: root.ntWidth * root.ntCoff + root.ntCoff
            tapWidth: tapHeight * root.tapToolbarPravi
            onClicked: {
                fnToggleMenu()
            }
        }
    }
    MouseArea {//MouseArea для возврата фокуса
        anchors.fill: parent
        z: -1
        propagateComposedEvents: true
        onClicked: (mouse) => {
            mouse.accepted = false
            if (menuMenu.visible) {
                menuMenu.visible = false
            } else {
                root.forceActiveFocus()
            }
            root.forceActiveFocus()
        }
    }
}
