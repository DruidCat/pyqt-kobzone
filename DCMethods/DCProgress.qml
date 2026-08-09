import QtQuick //2.15
//Шаблон DCProgress.qml - состоит из области, которая показывает прогресс какого либо процесса
Item {
    id: root
    //Свойства.
    property int  ntWidth: 2//Для реазмера текста.
    property int ntCoff: 8//Для реазмера текста.
    property alias radius: rctProgress.radius//Радиус зоны отображения виджета поиска.
    property alias clrProgress: rctProgress.color//цвет фона
    property alias clrTexta: txtProgress.color//цвет фона
    property alias running: tmrProgress.running//флаг который запускает таймер пролосы прогресса.
    property real progress: 0//Свойство прогресса от 0 до 100
    property alias text: txtProgress.text
    //Настройки.
    visible:  true//Видимость процесса загрузки.
    //Функции.
    onProgressChanged: {
        rctProgress.width = root.progress * root.width/100;//Задаём длину прогресса.
    }
    Text {
        id: txtProgress
        z: 1
        anchors.fill: root
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: "grey"
        font.pixelSize: root.ntWidth*root.ntCoff/2//размер шрифта текста.
        text: ""
        /*
        onTextChanged: {//Если текст изменился, то...
            if(root.width > txtProgress.width){//Если длина строки больше длины текста, то...
                for(var ltShag=txtProgress.font.pixelSize;
                                        ltShag<root.ntWidth*root.ntCoff; ltShag++){
                    if(txtProgress.width < root.width){//Если длина текста меньше динны строки
                        txtProgress.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                        if(txtProgress.width > root.width){//Но, если переборщили
                            txtProgress.font.pixelSize--;//То уменьшаем размер шрифта и...
                            return;//Выходим из увеличения шрифта.
                        }
                    }
                }
            }
            else{//Если длина строки меньше длины текста, то...
                for(let ltShag = txtProgress.font.pixelSize; ltShag > 0; ltShag--){//Цикл уменьшения
                    if(txtProgress.width > root.width)//Если текст дилиннее строки, то...
                        txtProgress.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
                }
            }
        }
        */
    }
    Rectangle {//Основной прямоугольник.
        id: rctProgress
        z: 0
        width: 1; height: root.height
        anchors.top: root.top; anchors.left: root.left
        color: "orange"; radius: 1

		// ← ДОБАВЛЕНА АНИМАЦИЯ (в 2 раза медленнее = 220ms вместо 110ms)
        Behavior on width {
            NumberAnimation {
                duration: 220
                easing.type: Easing.InOutQuad
            }
        }
    }
    Timer {
        id: tmrProgress
        interval: 1100; repeat: true; running: true
        onTriggered: {//Срабатывает таймер.
            if(root.progress <= 100)//Если меньше 100%
                root.progress += 1;//+1
            else//Если больше 100, то...
                root.running = false;//Отключаем таймер.
        }
        onRunningChanged: {
            if(!running)
                root.progress = 0;//Обнуляем счётчик.
        }
    }
}
