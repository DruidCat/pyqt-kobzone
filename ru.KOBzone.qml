import QtQuick
import QtQuick.Controls
import DCPages 1.0

ApplicationWindow {
    id: root
    
    // Основные настройки приложения
    readonly property color clrKnopok: "#2d4288"//Индиго
    readonly property color clrFona: "lightgrey"
    readonly property color clrStranic: "#f5f5f5"
    readonly property color clrMenuText: "#2d4288"//Индиго
    
    property int shrift: 2
    property int ntWidth: 2 * shrift
    property int ntCoff: 8
    
    // Настройки окна
    visible: true
    color: clrFona
    title: "Любимая КОБзона"
    width: 1100
    height: 500
    
    Component.onCompleted: {
        stvStr.currentItem.forceActiveFocus()
        console.log("✓ Приложение запущено")
        console.log("✓ Используется шрифт:", font.family)
    }
    
    StackView {
        id: stvStr
        anchors.fill: parent
        initialItem: pgStrKOBzone
        focus: true

        onCurrentItemChanged: {
            if (currentItem) {
                console.log("Смена страницы, передаём фокус")
                Qt.callLater(function() {
                    currentItem.forceActiveFocus()
                    console.log("Фокус установлен на:", currentItem)
                })
            }
        }
        
        Stranica {
            id: pgStrKOBzone
            visible: false
            focus: true
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            clrFona: root.clrFona
            clrTexta: root.clrKnopok
            clrRabOblasti: root.clrStranic
            textZagolovok: "МЕНЮ"
            zagolovokLevi: 1.3
            zagolovokPravi: 1.3
            toolbarLevi: 1.3
            toolbarPravi: 1.3
            
            onVisibleChanged: {
                if (visible) {
                    console.log("pgStrKOBzone стала видимой")
                    Qt.callLater(function() {
                        tmKOBzone.forceActiveFocus()
                        console.log("Фокус передан на tmKOBzone")
                    })
                }
            }

            StrKOBzone {
                id: tmKOBzone
                ntWidth: pgStrKOBzone.ntWidth
                ntCoff: pgStrKOBzone.ntCoff
                clrTexta: pgStrKOBzone.clrTexta
                clrFona: pgStrKOBzone.clrRabOblasti
                clrMenuText: root.clrMenuText
                clrMenuFon: pgStrKOBzone.clrFona
                
                zagolovokX: pgStrKOBzone.rctStrZagolovok.x
                zagolovokY: pgStrKOBzone.rctStrZagolovok.y
                zagolovokWidth: pgStrKOBzone.rctStrZagolovok.width
                zagolovokHeight: pgStrKOBzone.rctStrZagolovok.height
                
                zonaX: pgStrKOBzone.rctStrZona.x
                zonaY: pgStrKOBzone.rctStrZona.y
                zonaWidth: pgStrKOBzone.rctStrZona.width
                zonaHeight: pgStrKOBzone.rctStrZona.height
                
                toolbarX: pgStrKOBzone.rctStrToolbar.x
                toolbarY: pgStrKOBzone.rctStrToolbar.y
                toolbarWidth: pgStrKOBzone.rctStrToolbar.width
                toolbarHeight: pgStrKOBzone.rctStrToolbar.height
                
                tapZagolovokLevi: pgStrKOBzone.zagolovokLevi
                tapZagolovokPravi: pgStrKOBzone.zagolovokPravi
                tapToolbarLevi: pgStrKOBzone.toolbarLevi
                tapToolbarPravi: pgStrKOBzone.toolbarPravi
                
                onClickedAnalizator: {
                    console.log("Переход на анализатор")
                    pgStrAnalizer.textZagolovok = "АНАЛИЗАТОР ТЕКСТА"
                    stvStr.push(pgStrAnalizer)
                }
                onClickedRedaktor: {
                    console.log("Редактор текста - в разработке")
                }
                onClickedTranskribaciya: {
                    console.log("Транскрибация - в разработке")
                }
            }
        }
        
        Stranica {
            id: pgStrAnalizer
            visible: false
            focus: true
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            clrFona: root.clrFona
            clrTexta: root.clrKnopok
            clrRabOblasti: root.clrStranic
            zagolovokLevi: 1.3
            zagolovokPravi: 1.3
            toolbarLevi: 1.3
            toolbarPravi: 1.3
            
            onVisibleChanged: {
                if (visible) {
                    Qt.callLater(function() {
                        tmAnalizer.forceActiveFocus()
						console.log("Фокус передан на tmAnalizer")
                    })
                }
            }

            StrAnalizer {
                id: tmAnalizer
                ntWidth: pgStrAnalizer.ntWidth
                ntCoff: pgStrAnalizer.ntCoff
                clrTexta: pgStrAnalizer.clrTexta
                clrFona: pgStrAnalizer.clrRabOblasti
                clrMenuText: root.clrMenuText
                clrMenuFon: pgStrAnalizer.clrFona
                
                zagolovokX: pgStrAnalizer.rctStrZagolovok.x
                zagolovokY: pgStrAnalizer.rctStrZagolovok.y
                zagolovokWidth: pgStrAnalizer.rctStrZagolovok.width
                zagolovokHeight: pgStrAnalizer.rctStrZagolovok.height
                
                zonaX: pgStrAnalizer.rctStrZona.x
                zonaY: pgStrAnalizer.rctStrZona.y
                zonaWidth: pgStrAnalizer.rctStrZona.width
                zonaHeight: pgStrAnalizer.rctStrZona.height
                
                toolbarX: pgStrAnalizer.rctStrToolbar.x
                toolbarY: pgStrAnalizer.rctStrToolbar.y
                toolbarWidth: pgStrAnalizer.rctStrToolbar.width
                toolbarHeight: pgStrAnalizer.rctStrToolbar.height
                
                tapZagolovokLevi: pgStrAnalizer.zagolovokLevi
                tapZagolovokPravi: pgStrAnalizer.zagolovokPravi
                tapToolbarLevi: pgStrAnalizer.toolbarLevi
                tapToolbarPravi: pgStrAnalizer.toolbarPravi
                
                onClickedNazad: {
                    stvStr.pop()
                    Qt.callLater(function() {
                        stvStr.currentItem.forceActiveFocus()
                    })
                }
                onSignalToolbar: function(strToolbar) {
                    pgStrAnalizer.textToolbar = strToolbar
                }
            }
        }
    }
}
