import QtQuick
import QtQuick.Controls
import DCPages 1.0

ApplicationWindow {
    id: root
    
    // Основные настройки приложения
    readonly property color clrKnopok: "indigo"
    readonly property color clrFona: "white"
    readonly property color clrStranic: "#f5f5f5"
    readonly property color clrMenuText: "indigo"
    
    property int shrift: 2
    property int ntWidth: 2 * shrift
    property int ntCoff: 8
    
    // Настройки окна
    visible: true
    color: clrFona
    title: "KOBzona - Анализ текста"
    width: 900
    height: 700
    
    // Навигация между страницами
    StackView {
        id: stvStr
        anchors.fill: parent
        initialItem: pgStrKOBzone
        
        // Главная страница (меню)
        Stranica {
            id: pgStrKOBzone
            visible: false
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            clrFona: root.clrFona
            clrTexta: root.clrKnopok
            clrRabOblasti: root.clrStranic
            textZagolovok: "KOBzona"
            zagolovokLevi: 1.3
            zagolovokPravi: 1.3
            toolbarLevi: 1.3
            toolbarPravi: 1.3
            
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
                    pgStrAnalizer.textZagolovok = "Анализатор текста"
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
        
        // Страница анализатора
        Stranica {
            id: pgStrAnalizer
            visible: false
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            clrFona: root.clrFona
            clrTexta: root.clrKnopok
            clrRabOblasti: root.clrStranic
            zagolovokLevi: 1.3
            zagolovokPravi: 1.3
            toolbarLevi: 1.3
            toolbarPravi: 1.3
            
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
                
                onClickedNazad: stvStr.pop()
                
                onSignalToolbar: function(strToolbar) {
                    pgStrAnalizer.textToolbar = strToolbar
                }
            }
        }
    }
}
