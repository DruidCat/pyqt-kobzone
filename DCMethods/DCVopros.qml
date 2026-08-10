import QtQuick //2.15

import DCButtons 1.0//Импортируем кнопки
//Шаблон DCVopros.qml - Задаёт вопрос и предлагает его подтвердить или отменить.
Item {
    id: root
    //Свойства.
    property int  ntWidth: 2
    property int ntCoff: 8
    property alias radius: rctVopros.radius//Радиус зоны отображения удаляемого документа.
    property alias clrFona: rctVopros.color//цвет фона
    property alias clrTexta: txtVopros.color//цвет текста
    property color clrKnopki: "red"//цвет Кнопок
    property color clrBorder: "transparent"//цвет границы
    property string text: "?" //Вопрос.
    property alias bold: txtVopros.font.bold
    property alias italic: txtVopros.font.italic
    property alias textVopros: txtVopros//Передаём в виде свойства весь объект Text
    property real tapKnopkaZakrit: 1
    property real tapKnopkaOk: 1
    //Сигналы.
    signal clickedOk();//Сигнал Подтверждения.
    signal clickedOtmena();//Сигнал Отмены.
    //Функции.
    function fnClickedZakrit(){//Функция Закрытия виджета.
        root.clickedOtmena();//Запускаем сигнал отмены.
    }
    Rectangle {//Основной прямоугольник.
        id: rctVopros
        anchors.fill: root
        color: "transparent"
        radius: root.ntCoff/2
        visible: {
            if(root.visible){//Если виджет видимый, то...
                focus = true;//Фокусируемся на виджете
                forceActiveFocus();//Напрямую форсируем фокус, по другому не работает.
                return true;//Видимый виджет
            }
            else{//Если виджет видимый, то...
                focus =  false;//Не фокусируемся на виджете.
                return false;//невидимый виджет
            }
        }
        Keys.onPressed: (event) => {//Это запись для Qt6, для Qt5 нужно удалить event =>
            if(event.key === Qt.Key_Escape){//Если нажат Escape, то...
                fnClickedZakrit();//Функция закрытия виджета.
                event.accepted = true;//Завершаем обработку эвента.
            }
            //console.log(event.key);
        }
        DCKnopkaZakrit {//Кнопка Отмены.
            id: knopkaOtmena
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.verticalCenter: rctVopros.verticalCenter
            anchors.left:rctVopros.left
            clrKnopki: root.clrKnopki
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff; tapWidth: tapHeight*root.tapKnopkaZakrit
            onClicked: fnClickedZakrit();//Функция Закрытия виджета.
        }
        Rectangle {
            id: rctText
            anchors.top: rctVopros.top
            anchors.bottom: rctVopros.bottom
            anchors.left: knopkaOtmena.right
            anchors.right: knopkaOk.left
            anchors.leftMargin: root.ntCoff/2
            anchors.rightMargin: root.ntCoff/2

            color: "transparent"
            border.color: root.clrBorder
            border.width: root.ntCoff/8
            radius: root.ntCoff/2
            clip: true//Обрезаем всё что больше этого прямоугольника.
            Text {
                id: txtVopros
				anchors.horizontalCenter: rctText.horizontalCenter
				anchors.verticalCenter: rctText.verticalCenter
                color: root.clrTexta
                font.pixelSize: root.ntWidth*root.ntCoff//размер шрифта текста.
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.text
				onTextChanged: {//Если текст изменился, то...
                    if(rctText.width > txtVopros.width){//Если длина строки больше длины текста, то...
                        for(var ltShag=txtVopros.font.pixelSize;
                                                ltShag<root.ntWidth*root.ntCoff; ltShag++){
                            if(txtVopros.width < rctText.width){//Если длина текста меньше динны строки
                                txtVopros.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                                if(txtVopros.width > rctText.width){//Но, если переборщили
                                    txtVopros.font.pixelSize--;//То уменьшаем размер шрифта и...
									return;//Выходим из увеличения шрифта.
								}
							}
						}
					}
					else{//Если длина строки меньше длины текста, то...
                        for(let ltShag = txtVopros.font.pixelSize; ltShag > 0; ltShag--){//Цикл уменьшения
                            if(txtVopros.width > rctText.width)//Если текст дилиннее строки, то...
                                txtVopros.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
						}
					}
				}
			}
			onWidthChanged: {//Если длина строки измениасть, то...
                if(rctText.width > txtVopros.width){//Если длина строки больше длины текста, то...
                for(var ltShag=txtVopros.font.pixelSize;
                                                ltShag<root.ntWidth*root.ntCoff; ltShag++){
                        if(txtVopros.width < rctText.width){//Если длина текста меньше динны строки
                            txtVopros.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                            if(txtVopros.width > rctText.width){//Но, если переборщили
                                txtVopros.font.pixelSize--;//То уменьшаем размер шрифта и...
								return;//Выходим из увеличения шрифта.
							}
						}
					}
				}
				else{//Если длина строки меньше длины текста, то...
                    for(let ltShag = txtVopros.font.pixelSize; ltShag > 0; ltShag--){//Цикл уменьшения
                        if(txtVopros.width > rctText.width)//Если текст дилиннее строки, то...
                            txtVopros.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
					}
				}
			}
        }
        DCKnopkaOk{//Кнопка подтверждения.
            id: knopkaOk
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.verticalCenter: rctVopros.verticalCenter
            anchors.right: rctVopros.right
            clrKnopki: root.clrKnopki
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff; tapWidth: tapHeight*root.tapKnopkaOk
            onClicked: root.clickedOk();//Сигнал Подтверждения.
        }
    }
}
