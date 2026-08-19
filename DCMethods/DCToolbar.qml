import QtQuick
//DCToolbar.qml - компонент для работы с toolbar
Item {
	id: root
	property var vrStranica
	property int second: 11
	property string text: ""
	property string log: ""
	//Методы
	onSecondChanged: {//Если настройка с секундами изменилась.
		tmrText.interval = root.second * 1000
	}
	function fnLog(strLog){//Функция принятия логированной информации
		root.log = "";
		Qt.callLater(function() {
			root.log = strLog
		})
	}
	function fnText(strText){//Функция отображания в toolbar сообщения с его последующим удалением
		if(strText === ""){//Если пустой текст, то 
			root.text = ""//Делаем пустую строчку, что вызвать onTextChanged и изменить text="" и стоп таймер
		}
		else {
			root.text = ""//Делаем пустую строчку, что вызвать onTextChanged и изменить text="" и стоп таймер
			Qt.callLater(function() {//Делаем паузу, чтоб в onTextChanged успел пройти стоп таймер.
				root.text = strText//Присваеваем новое значение, в onTextChanged запустится новый таймер.
			})
		}
	}
	onTextChanged: {
		if(root.text === "") tmrText.stop()
		else tmrText.restart()
		//root.vrStranica.textToolbar = root.text
	}
	Timer {//ТАЙМЕР, чтоб удалить сообщение
        id: tmrText
        interval: root.second*1000; running: false; repeat: false
        onTriggered: {
			root.text = ""
        }
	}	
}
