import QtQuick //2.15
import QtQuick.Controls
//DCScrollbar.qml
Item {//Самодельный вертикальный скроллбар
    id: root
    property var flick
    //Свойства
    property color clrTrack: "#40000000"//Полупрозрачный трек
    property color clrPolzunokOff: "Grey"//Цвет ползунка, когда он не активен.
    property color clrPolzunokOn: "Orange"//оранжевый при наведении
    readonly property int minVisotaPolzunka: 22//Минимальная высота Позунка
    property alias radius: rctPolzunok.radius
    //Настройки
    width: 11//Ширина Трека
    visible: flick ? ((flick.contentHeight - flick.height) > 1) : false//Показываем когда есть что скроллить.
    Rectangle {//Трек
        id: rctTrack
        anchors.fill: root
        color: root.clrTrack
        z: 0//Первым создаётся Трек, по верх него всё остальное накладываться будет.
        MouseArea {//Клик по треку — прыжок к позиции
            anchors.fill: rctTrack
            acceptedButtons: Qt.LeftButton//Обрабатываем только левую клавишу мыши.
            onPressed: (mouse) => {//Если было нажатие мышкой на треке, то...
                if(flick){//Если передан объект, то...
                    const kontentVisota = flick.contentHeight//Высота всего текста
                    const flickVisota = flick.height//Высота боласти пролистывания flickable
                    const maxY = root.height - rctPolzunok.height
                    if (kontentVisota <= flickVisota || maxY <= 0)//Если текста меньше выстоты листания,то
                        return//Ничего не делаем
                    const target = Math.max(0, Math.min(mouse.y - rctPolzunok.height/2, maxY))
                    flick.contentY = target / maxY * (kontentVisota - flickVisota)
                }
            }
        }
    }
    Rectangle {//Ползунок
        id: rctPolzunok
        color: (maPolzunka.containsMouse || maPolzunka.pressed) ? root.clrPolzunokOn : root.clrPolzunokOff
        width: root.width-2//Ширина ползунка такая же, как и у всего scrollbar  и -2 пикселя.
        height: {//Высота ползунка пропорциональна видимой части
            if(flick){//Если объект существует, то...
                const kontentVisota = flick.contentHeight//Высота всего текста
                const flickVisota = tmZona.height//Высота боласти пролистывания flickable
                if (kontentVisota <= 0)//Если высота всего текста меньше или равно нулю, то...
                    return root.minVisotaPolzunka//высота полунка минимально заданная.
                const ratio = Math.min(1, flickVisota / kontentVisota)
                return Math.max(root.minVisotaPolzunka, flickVisota * ratio)//Расчёт высоты
            }
            else//Если не существует, то...
                return 0
        }
        x: 1//верхний левый угол прямогугольника в координате x = 1, чтоб был зазор в 1 пиксель
        y: {//Позиция ползунка синхронизируется со скроллом
            if(flick){//Если объект существует, то...
                const kontentVisota = flick.contentHeight//Высота всего текста
                const flickVisota = flick.height//Высота боласти пролистывания flickable
                const maxY = root.height - rctPolzunok.height
                if (kontentVisota <= flickVisota || maxY <= 0)//Если высота текста меньше зоны листания,то
                    return 0//То верхний левый угол ползунка растоложить на y = 0
                return flick.contentY / (kontentVisota - flickVisota) * maxY
            }
            else//Если не существует, то...
                return 0
        }
        z: 1//Поверх трека накладывается ползунок.
        radius: 0//По умолчанию без радиуса на ползунке.
        MouseArea {//Претаскивание ползунка мышью
            id: maPolzunka
            anchors.fill: rctPolzunok
            hoverEnabled: true
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor//При нажатии анимация руки
            drag.target: rctPolzunok//Перетаскиваем ползунок
            drag.axis: Drag.YAxis
            drag.minimumY: 0
            drag.maximumY: root.height - rctPolzunok.height

            onPositionChanged: {//Если позиция изменилась
                if (pressed) {//Если мышка нажата, то...
                    if(flick){//Если объект существует, то...
                        const kontentVisota = flick.contentHeight//Высота всего текста
                        const flickVisota = flick.height//Высота боласти пролистывания flickable
                        const maxY = root.height - rctPolzunok.height
                        if (kontentVisota > flickVisota && maxY > 0)
                            flick.contentY = rctPolzunok.y / maxY * (kontentVisota - flickVisota)
                    }
                }
            }
        }
    }
}
