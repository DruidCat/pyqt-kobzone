import QtQuick //2.15
//import QtQuick.Handlers//Не требуется в Qt 6.2+

Item {
    id: root
    //Свойства.
    property int ntCoff: 8
    property int ntHeight: 2
    property alias text: txtText.text
    property alias bold: txtText.font.bold
    property alias italic: txtText.font.italic
    property alias pixelSize: txtText.font.pixelSize
	property color clrKnopki: "transparent"
	property color clrTexta: "black"
    property real minDarker: 0.7//Миннимальная затемнённость кнопки, когда она не активная.
    property real maxDarker: 1.3//Максимальная затемнённость кнопки, когда она нажата.
    property bool enabled: true//true - активирована, false - деактивированна кнопка.
    property bool pressed: tphKnopkaOriginal.pressed//true - нажали false - не нажали
    //property bool pressed: maKnopkaOriginal.pressed//true - нажали false - не нажали
    property real opacityKnopki: 1
    property real opacityTexta: 1
    //Настройки.
    height: ntHeight*ntCoff+ntCoff
	//Длина кнопки расчитывается автоматически в слоте onCompleted в конце файла.
    //Сигналы.
	signal clicked();
    //Функции.
    onHeightChanged: {//Если изменился ntHeight или ntCoff (размер шрифта), то...
        txtText.font.pixelSize = root.height - root.ntCoff//Выставляем размер текста, и...
        if(rctKnopka.width > txtText.width){//Если длина строки больше длины текста, то...
            for(var ltShag=txtText.font.pixelSize; ltShag<rctKnopka.height-root.ntCoff; ltShag++){
                if(txtText.width < rctKnopka.width){//Если длина текста меньше динны строки
                    txtText.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                    if(txtText.width > rctKnopka.width){//Но, если переборщили
                        txtText.font.pixelSize--;//То уменьшаем размер шрифта и...
                        return;//Выходим из увеличения шрифта.
                    }
                }
            }
        }
        else{//Если длина строки меньше длины текста, то...
            for(let ltShag = txtText.font.pixelSize; ltShag > 0; ltShag--){//Цикл уменьшения
                if(txtText.width > rctKnopka.width)//Если текст дилиннее строки, то...
                    txtText.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
            }
        }
    }
    //Для Авроры комментируем TapHandler, расскомментируем MouseArea и наоборот.
    TapHandler {//Обработка нажатия, замена MouseArea с Qt5.10
        id: tphKnopkaOriginal
        onTapped: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    /*
    MouseArea {
        id: maKnopkaOriginal
        anchors.fill: root
        onClicked: {
            if(root.enabled)//Если активирована кнопка, то...
                root.clicked();//Обрабатываем клик.
        }
    }
    */
    Rectangle {
        id: rctKnopka
        anchors.fill: root

        color: {
            if(root.enabled)//Если активирована кнопка, то...
                tphKnopkaOriginal.pressed ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
                //maKnopkaOriginal.containsPress ? Qt.darker(clrKnopki, root.maxDarker) : clrKnopki
            else//Если деактивирована кнопка, то...
                Qt.darker(clrKnopki, root.minDarker)
        }
        radius: height/4
		smooth: true//Сглаживание.
        opacity: root.opacityKnopki//Прозрачность Кнопки.
        border.color: {
            if(root.enabled)
                Qt.darker(clrKnopki, root.maxDarker)//Граница чуть темнее цвета кнопки
            else
                clrKnopki
        }
        border.width: 1//Толщина граници кнопки один пиксель
        clip: true//Всё, что будет внутри прямоугольника и будет выходить за границы обрезается.

		Text {
            id: txtText
            anchors.horizontalCenter: rctKnopka.horizontalCenter
            anchors.verticalCenter: rctKnopka.verticalCenter
            color: {
                if(root.enabled)//Если активирована кнопка, то...
                    tphKnopkaOriginal.pressed ? Qt.darker(clrTexta, root.maxDarker) : clrTexta
                    //maKnopkaOriginal.containsPress ? Qt.darker(clrTexta, root.maxDarker) : clrTexta
                else//Если деактивирована кнопка, то...
                    Qt.darker(clrTexta, root.minDarker)
            }
            text: "Кнопка"
            font.pixelSize: root.height - root.ntCoff
			font.bold: false//Не жирный текст
            font.italic: false//Не курсивный текст
            opacity: root.opacityTexta//Прозрачность Текста.
            onTextChanged: {//Если поменяется текст в кнопке, то и размер шрифта пересчитается.
                if(rctKnopka.width > txtText.width){//Если длина строки больше длины текста, то...
                    for(var ltShag=txtText.font.pixelSize; ltShag<rctKnopka.height-root.ntCoff; ltShag++){
                        if(txtText.width < rctKnopka.width){//Если длина текста меньше динны строки
                            txtText.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                            if(txtText.width > rctKnopka.width){//Но, если переборщили
                                txtText.font.pixelSize--;//То уменьшаем размер шрифта и...
                                return;//Выходим из увеличения шрифта.
                            }
                        }
                    }
                }
                else{//Если длина строки меньше длины текста, то...
                    for(let ltShag = txtText.font.pixelSize; ltShag > 0; ltShag--){//Цикл уменьшения
                        if(txtText.width > rctKnopka.width)//Если текст дилиннее строки, то...
                            txtText.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
                    }
                }
            }
        }
        onWidthChanged: {//При onComplited посчитается ширина, а на основании её, сработает этот сигнал.
            if(rctKnopka.width > txtText.width){//Если длина строки больше длины текста, то...
                for(var ltShag=txtText.font.pixelSize; ltShag<rctKnopka.height-root.ntCoff; ltShag++){
                    if(txtText.width < rctKnopka.width){//Если длина текста меньше динны строки
                        txtText.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                        if(txtText.width > rctKnopka.width){//Но, если переборщили
                            txtText.font.pixelSize--;//То уменьшаем размер шрифта и...
                            return;//Выходим из увеличения шрифта.
                        }
                    }
                }
            }
            else{//Если длина строки меньше длины текста, то...
                for(let ltShag = txtText.font.pixelSize; ltShag > 0; ltShag--){//Цикл уменьшения
                    if(txtText.width > rctKnopka.width)//Если текст дилиннее строки, то...
                        txtText.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
                }
            }
        }
	}
	Component.onCompleted: {//Слот обрабатывает данные, когда сомпонет полностью отрисовался.
        root.width = txtText.text.length*root.height;//Расчёт длины строки (кол-во символов на высоту кнопки).
	}
}
