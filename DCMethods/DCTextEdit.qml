import QtQuick
import DCMethods 1.0//Импортируем методы написанные мной. Для DCScrollbar
//DCTextEdit - ШАБЛОН РАБОТЫ С ТЕКСТОМ НА СТРАНИЦЕ (ЛИСТАТЬ, РЕДАКТИРОВАТЬ, ВЫДЕЛЯТЬ).
Item {
    id: root
    //Публичный API
    property alias text: txdTextEdit.text//Текст
    property alias readOnly: txdTextEdit.readOnly//читать Только текст. (false - можно изменять)
    property bool scrollAuto: false//true-текст скроллится автоматически вверх, если выходит за рамки экрана.
    property alias textEdit: txdTextEdit//Передаём в виде свойства весь объект TextEdit
    property alias radius: rctTextEdit.radius//Радиус рабочей зоны
    property color clrFona: "transparent"//цвет фона текста
    property color clrTexta: "orange"//цвет текста
    property color clrPolzunka: "grey"//Цвет ползунка, когда он не активный.
    property color clrBorder: "transparent"//Цвет границы области текста.
    property alias bold: txdTextEdit.font.bold//Жирный текст.
    property alias italic: txdTextEdit.font.italic//Наклонный текст.
    property real pixelSize: root.ntWidth * root.ntCoff//размер шрифта текста.
    property int ntWidth: 2
    property int ntCoff: 8
	property string placeholderText: ""//Подсказка пользователю
    property color clrPlaceholder: Qt.darker(root.clrTexta, 1.4)//Цвет подсказки пользователю
	property bool isBorder: false//true - показывать бордюр текста
    //Приватные свойства
    property bool _userScrolled: false
    //Сигналы
    signal pressed()
    //Настройки
    //anchors.fill: parent
    //Методы
	Connections {
        target: root
        function onReadOnlyChanged() {
            if (root.readOnly) {
                flcListat.forceActiveFocus()
            }
        }
    }
    function fnFocus() {//Функция фокусировки на виджете, чтоб горячие клавиши работали.
        flcListat.forceActiveFocus()//Чтоб курсор активный был, и горячие клавиши работали.
    }
    function scrollTop() {//Функция Скролл вверх
        flcListat.contentY = 0
    }
    function scrollBottom() {//Функция Скролл вниз
        Qt.callLater(function() {
            flcListat.contentY = Math.max(0, flcListat.contentHeight - flcListat.height)
        })
    }
    function scrollBy(delta) {
        flcListat.contentY = Math.max(0, Math.min(
            flcListat.contentHeight - flcListat.height,
            flcListat.contentY + delta
        ))
    }
    Rectangle {
        id: rctTextEdit
        anchors.fill: parent
        color: root.clrFona
        Flickable {//Перелистывание
            id: flcListat
            //Настройки
            boundsBehavior: Flickable.StopAtBounds//чтобы не было «подпрыгиваний» из‑за овершута
            anchors.fill: parent
            anchors.margins: root.ntCoff//Отступ, чтоб текст не налазил на бардюр.
            contentWidth: txdTextEdit.width//ширина вьюпорта
            contentHeight: txdTextEdit.paintedHeight//Общая высота листания = высоте всего текста
            interactive: true//Перелистывание активировать.
            clip: true//Обрезаем всё, что выходит за границы этого элемента.
			focus: root.readOnly//Фокус у Flickable только в режиме чтения
            onMovingChanged: {
                if (moving) {
                    _userScrolled = true
                    autoScrollTimer.restart()
                }
            }
            Keys.onPressed: (event) => {//Обработчик клавиатуры.
                const keyActions = {
                    [Qt.Key_Up]: () => scrollBy(-root.pixelSize * 1.2),
                    [Qt.Key_K]: () => scrollBy(-root.pixelSize * 1.2),
                    [1042]: () => scrollBy(-root.pixelSize * 1.2),  // В
                    
                    [Qt.Key_Down]: () => scrollBy(root.pixelSize * 1.2),
                    [Qt.Key_J]: () => scrollBy(root.pixelSize * 1.2),
                    [1053]: () => scrollBy(root.pixelSize * 1.2),  // Н
                    
                    [Qt.Key_PageUp]: () => scrollBy(-flcListat.height),
                    [Qt.Key_PageDown]: () => scrollBy(flcListat.height)
                }
                if (event.key in keyActions) {
                    keyActions[event.key]()
                    event.accepted = true
                }
            }
            function fnEnsureVisible(cursor) {//Функция расчитывающая видимость текста, следующая за курсором.
                if (contentX >= cursor.x)
                    contentX = cursor.x
                else if (contentX + width <= cursor.x + cursor.width)
                    contentX = cursor.x + cursor.width - width
                
                if (contentY >= cursor.y)
                    contentY = cursor.y
                else if (contentY + height <= cursor.y + cursor.height)
                    contentY = cursor.y + cursor.height - height
            }
            TextEdit {//Область текста.
                id: txdTextEdit
                //Настройки
                width: flcListat.width - scbScrollbar.width//Ширина зоны прокрутки и минус ширина ScrollBar.
                height: Math.max(paintedHeight, flcListat.height)//Высота растёт вместе с текстом
                //textFormat: TextEdit.AutoText//Формат текста АВТОМАТИЧЕСКИ определяется.Предпочтителен HTML4
                color: root.clrTexta
                text: ""
                font.pixelSize: root.pixelSize//размер шрифта текста.
                wrapMode: TextEdit.Wrap//Текст в конце строки переносим на новую строку.
				persistentSelection: true//Для больших HTML текстов
                textMargin: 2//Для больших HTML текстов
                readOnly: true//true - Запрещено редактировать. 
                focus: !root.readOnly
                selectByMouse: true//пользователь может использовать мышь/палец для выделения текста.
                Text {//ПЛЕЙСХОЛДЕР, подсказка пользователю (Отображается когда текст пустой)
                    id: txtPlaceholder
                    text: root.placeholderText
                    color: root.clrPlaceholder
                    font: txdTextEdit.font
                    visible: txdTextEdit.text === ""
                    opacity: 0.6
                }
                TapHandler {//Нажимаем на область TextEdit
					onTapped: {
						if (!root.readOnly) {//Если режим редактирования, то...
                			flcListat.forceActiveFocus()//Только так появляется курсор.
               				txdTextEdit.forceActiveFocus()//Чтоб курсор появился в месте клика мышью
            			} else flcListat.forceActiveFocus()
						root.pressed()//Если нажали, то запускаем сигнал вне виджета.
					}
                }
                onCursorRectangleChanged: {//Если позиция курсора измениласть, то..
                    if (!root.readOnly)//Если активирован режим редактирования, то...
                        flcListat.fnEnsureVisible(cursorRectangle)//За курсором листается текст.
                }
                onPaintedHeightChanged: {//Если высота отрисованного текста изменилась, то...
                    if (root.scrollAuto && root.readOnly && !_userScrolled) {//Если автоскрол и чтение только, то...
                        //Активируем автоскролл, держим курсор в конце — это низ.
                        cursorPosition = length
                        flcListat.contentY = Math.max(0, flcListat.contentHeight - flcListat.height)
                    }
                }
                onLinkActivated: (link) => Qt.openUrlExternally(link)//Если ссылка активизировалась, то...
            }
        }
        DCScrollbar {//Скроллбар
            id: scbScrollbar
            //Настройки
            flick: flcListat//Передаём объект Flickable
            anchors.right: flcListat.right
            anchors.top: flcListat.top
            anchors.bottom: flcListat.bottom
            clrPolzunokOff: root.clrPolzunka//Цвет ползунка, когда он не активен.
            clrPolzunokOn: root.clrTexta
            width: root.ntWidth * root.ntCoff
            radius: 1//Небольшой радиус
        }
        Rectangle {
            id: rctBorder
            anchors.fill: parent
            color: "transparent"
            radius: rctTextEdit.radius
            border.color: root.isBorder ? root.clrBorder : (root.readOnly ? "transparent" : root.clrBorder)
            border.width: 1
            z: 2//Поверх Трека и Ползунка, чтоб ползунок не наезжал на Границу.
        }
    }
    Timer {
        id: autoScrollTimer
        interval: 2000
        onTriggered: _userScrolled = false
    } 
}
//Любые пробелы и табы в тексте отобразятся в приложении.
//<html>Корневой элемент, содержащий весь контент страницы.</html>
//<body>Элемент, содержащий видимый контент страницы.</body>
//<h1>Заголовок первого уровня, используется для заголовка страницы.</h>
//<p>Абзац текста, используется для отображения блоков текста.</p>
//<b>Жирный текст</b>
//<i>Курсивный текст</i>
//<u>Подчеркнуть текст</u>
//<center>По центру текст</center>
//<pre>В данной записи сохранятся все tab и пробелы, как задумал разработчик.</pre>
//<a href=\"http://ya.ru\">Яндекс</a> - форма записи ссылок.
//&lt; - это символ <
//&gt; - это символ >
