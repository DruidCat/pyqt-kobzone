import QtQuick
//DCTimer.qml - простой таймер для замера времени.
Item {
    id: root
    //Свойства
    property string strTimer: "00:00:00"//Отображаемое время в формате ЧЧ:ММ:СС
    property bool blStart: false//Управление таймером: true - запущен, false - остановлен
    property int __elapsedSeconds: 0//Внутренний счетчик прошедших секунд (скрыт от внешнего использования)
	//Методы
    function __formatTime(totalSeconds) {//Функция форматирования секунд в строку ЧЧ:ММ:СС
        var h = Math.floor(totalSeconds / 3600)
        var m = Math.floor((totalSeconds % 3600) / 60)
        var s = totalSeconds % 60
        
        var hh = (h < 10 ? "0" : "") + h
        var mm = (m < 10 ? "0" : "") + m
        var ss = (s < 10 ? "0" : "") + s
        
        return hh + ":" + mm + ":" + ss
    }
    Timer {//Легковесный таймер с интервалом 1000 мс
        interval: 1000
        running: root.blStart
        repeat: true
        triggeredOnStart: false//Не срабатывать мгновенно при старте, ждать 1 секунду
        
        onTriggered: {
            root.__elapsedSeconds++
            root.strTimer = root.__formatTime(root.__elapsedSeconds)
        }
    }
    function reset() {//Дополнительная удобная функция для сброса таймера в ноль
        root.__elapsedSeconds = 0
        root.strTimer = "00:00:00"
    }
}
