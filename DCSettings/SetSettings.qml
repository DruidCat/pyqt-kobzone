import QtQuick
import QtQuick.Controls
import DCPages 1.0

Stranica {
    id: root
    //Свойства
    property string settingsType: ""
	property string loadedSettingsType: ""
    property var loadedComponent: null
    //Настройки страницы
    visible: false
    focus: true
    textZagolovok: {
        if (settingsType === "set_kobzone") return "НАСТРОЙКИ ПРИЛОЖЕНИЯ"
        else if (settingsType === "set_analizer")return "НАСТРОЙКИ НЕЙРО АНАЛИЗА" 
        else if (settingsType === "set_orfograf") return "НАСТРОЙКИ ИСПРАВЛЕНИЯ ТЕКСТА"
        else if (settingsType === "set_transcribe") return "НАСТРОЙКИ ТРАНСКРИБАЦИИ"
        else return "НАСТРОЙКИ"
    }
    zagolovokLevi: 1.3
    zagolovokPravi: 1.3
    toolbarLevi: 1.3
    toolbarPravi: 1.3
	//Сигналы
	signal clickedNazad()//Сигнал назад.
    signal clickedInfo(var strSetType)
    //Отслеживание изменений
	onSettingsTypeChanged: {
		console.log("SetSettings: тип изменён на", settingsType)
		if (visible && settingsType !== "" && root.loadedSettingsType !== settingsType) {
			Qt.callLater(fnLoadSettingsPage)
		}
	}
	onVisibleChanged: {
		if (visible) {
			console.log("SetSettings: страница стала видимой, тип:", settingsType)

			if (settingsType !== ""
				&& (loadedComponent === null || root.loadedSettingsType !== settingsType)) {

				Qt.callLater(fnLoadSettingsPage)

			} else if (loadedComponent) {
				Qt.callLater(function() {
					loadedComponent.forceActiveFocus()
				})
			}

		} else {
			// Опционально: можно сбрасывать компонент при уходе со страницы.
			// Если не хотите терять состояние — оставьте как есть.

			// if (loadedComponent) {
			//     loadedComponent.destroy()
			//     loadedComponent = null
			//     root.loadedSettingsType = ""
			// }
		}
	}
    Component.onCompleted: {
    }
    function fnLoadSettingsPage() {//ФУНКЦИЯ ЗАГРУЗКИ КОМПОНЕНТА
        if (settingsType === "") {//проверка settingsType
            console.warn("⚠️ SetSettings: settingsType пуст, загрузка отменена")
            return
        }
        if (!visible) {//проверка видимости
            console.warn("⚠️ SetSettings: страница невидима, загрузка отменена")
            return
        }
		if (loadedComponent !== null && root.loadedSettingsType === settingsType) {
				Qt.callLater(function() {
					loadedComponent.forceActiveFocus()
				})
				return
		}
        if (root.rctStrZona.width <= 0 || root.rctStrZona.height <= 0) {
            console.warn("⚠️ Stranica ещё не отрисована, ждём visible=true...")
            return
        }
        //1. УНИЧТОЖАЕМ старый компонент
        if (loadedComponent) {
            console.log("  Уничтожаем старый компонент")
            loadedComponent.destroy()
            loadedComponent = null
        }
        //2. ОПРЕДЕЛЯЕМ файл
        var componentPath = ""
        
        if (settingsType === "set_kobzone") {
            componentPath = "qrc:/DCSettings/SetKOBzone.qml"
		} else if (settingsType === "set_analizer") {
            componentPath = "qrc:/DCSettings/SetAnalizer.qml"
		} else if (settingsType === "set_orfograf") {
            componentPath = "qrc:/DCSettings/SetOrfograf.qml"
        } else if (settingsType === "set_transcribe") {
            componentPath = "qrc:/DCSettings/SetTranscribe.qml"
        } else {
            console.warn("✗ Неизвестный тип настроек:", settingsType)
            return
        }
        console.log("  Путь к компоненту:", componentPath)
        //3. СОЗДАЁМ компонент
        var component = Qt.createComponent(componentPath)
        if (component.status === Component.Error) {
            console.error("✗ Ошибка загрузки компонента:")
            console.error(component.errorString())
            return
        }
        //4. СОЗДАЁМ объект с правильными координатами
        loadedComponent = component.createObject(itemContainer, {
            ntWidth: root.ntWidth,
            ntCoff: root.ntCoff,
            clrTexta: root.clrTexta,
            clrFona: root.clrRabOblasti,
            clrMenuText: root.clrTexta,
            clrMenuFon: root.clrFona,
            
            zagolovokX: root.rctStrZagolovok.x,
            zagolovokY: root.rctStrZagolovok.y,
            zagolovokWidth: root.rctStrZagolovok.width,
            zagolovokHeight: root.rctStrZagolovok.height,
            
            zonaX: root.rctStrZona.x,
            zonaY: root.rctStrZona.y,
            zonaWidth: root.rctStrZona.width,
            zonaHeight: root.rctStrZona.height,
            
            toolbarX: root.rctStrToolbar.x,
            toolbarY: root.rctStrToolbar.y,
            toolbarWidth: root.rctStrToolbar.width,
            toolbarHeight: root.rctStrToolbar.height,
            
            tapZagolovokLevi: root.zagolovokLevi,
            tapZagolovokPravi: root.zagolovokPravi,
            tapToolbarLevi: root.toolbarLevi,
            tapToolbarPravi: root.toolbarPravi
        })
        
        if (loadedComponent === null) {
            console.error("✗ Не удалось создать объект компонента")
            return
        }
		root.loadedSettingsType = settingsType
        console.log("✓ Компонент загружен успешно:", settingsType)
        //Подключаем сигналы
        if (loadedComponent.clickedNazad) {
            loadedComponent.clickedNazad.connect(function() {
				root.clickedNazad();//Назад				
            })
        }
        if (loadedComponent.clickedInfo) {
            loadedComponent.clickedInfo.connect(function() {
				root.clickedInfo(settingsType)//Излучаем сигнал с типом страницы
            })
        }
        Qt.callLater(function() {
            if (loadedComponent) {
                loadedComponent.forceActiveFocus()//Устанавливаем фокус
            }
        })
    }
    Item {//КОНТЕЙНЕР
        id: itemContainer
        anchors.fill: parent
        Component.onCompleted: {

        }
    }
}
