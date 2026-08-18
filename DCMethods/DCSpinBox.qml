import QtQuick //2.15

import DCButtons 1.0//Импортируем кнопки
//DCSpinBox - ШАБЛОН ДЛЯ РАБОТЫ С ЧИСЛАМИ И ИХ УВЕЛИЧЕНИЕМ И УМЕНЬШЕНИЕМ КНОПКАМИ [+] И [-].
Item {
    id: root
    //Свойства
	property alias spinBox: txnSpinBox//Передаём в виде свойства весь объект TextInput
    property alias radius: rctSpinBox.radius//Радиус рабочей зоны
    property color clrTexta: "Orange"//цвет текста
    property color clrFonaPassive: "Transparent"//Цвет текста в пассивном режиме
    property color clrFonaActive: "Transparent"//Цвет текста в активном режиме ввода.
    property alias bold: txnSpinBox.font.bold
    property alias italic: txnSpinBox.font.italic
    property int  ntWidth: 2
    property int ntCoff: 8
    property int value: 0
	property int from: 0//Задаём значение по умолчанию.
	property int to: 32767//Задаём значение по умолчанию.
	property int stepSize: 1//Шаг увеличения и уменьшения value
    property real tapKnopkaMinus: 1
    property real tapCentor: 2.9
    property real tapKnopkaPlus: 1
    //Настройки
    height: ntWidth*ntCoff
    width:	height*(tapKnopkaMinus+tapCentor+tapKnopkaPlus)
    //Сигналы.
	signal valueModified();//Сигнал нажатия [-],[+],Enter с изменением значения. А значение по value получить.
    //Функции.
    onValueChanged:{//Если значение номера пришло из вне или из нутри метода, то...
        if(value <= from){//Если число меньше или РАВНО минимального, то...
            value = Math.min(from, value);//Приравниваем минимальному значению число.
            knopkaMinus.enabled = false;//Кнопка Минус не активная.
            knopkaPlus.enabled = true;//Кнопка Плюс активная.
        }
        else{
            if(value >= to){//Если число больше или РАВНО максимально, то...
                value = Math.max(to, value);//Приравниваем максимальное число значению.
                knopkaPlus.enabled = false;//Кнопка Плюс не активная.
                knopkaMinus.enabled = true;//Кнопка Минус активная.
            }
            else{//Если значение не меньше и не больше заданного, то...
                knopkaMinus.enabled = true;//Кнопка Минус активная.
                knopkaPlus.enabled = true;//Кнопка Плюс активная.
            }
        }
        txnSpinBox.text = value;//Это важная строка, она отображает Номер,когда он приходит из вне или внутри
	}
	onFromChanged:{//Защита от неверного ввода max и min значения, которое роняет приложение.
        if(from < 0){//С отрицательными числами DCSpinBox не работает.
			from = 0;//Задаём значение по умолчанию.
			console.error(qsTr("DCSpinBox.qml::from(int): from - задано отрицательное значение."));
			if(to < 0){//Если при этом to отрицательное число, то...
				to = 32767;//Задаём значение по умолчанию.
				console.error(qsTr("DCSpinBox.qml::from(int): to - задано отрицательное значение."));
			}
		}
		else{//Если это не отрицательное значение, то...
			if(from > to){
				from = 0;//Задаём значение по умолчанию.
				to = 32767;//Задаём значение по умолчанию.
				console.error(qsTr("DCSpinBox.qml::from(int): from > to."));
			}
        }
        //from и to выставленны после не верного ввода свойств, а теперь активируем, деактивируем кнопки.
        if((from === to)){//Если мин = макс, то...
            knopkaMinus.enabled = false;//Кнопка Минус не активная.
            knopkaPlus.enabled = false;//Кнопка Плюс не активная.
        }
        else{
            if(value <= from){//Если число меньше или РАВНО минимального, то...
                knopkaMinus.enabled = false;//Кнопка Минус не активная.
                knopkaPlus.enabled = true;//Кнопка Плюс активная.
            }
            else {
                if(value >= to){//Если число больше или РАВНО максимально, то...
                    knopkaPlus.enabled = false;//Кнопка Плюс не активная.
                    knopkaMinus.enabled = true;//Кнопка Минус активная.
                }
                else{//Если значение не меньше и не больше заданного, то...
                    knopkaMinus.enabled = true;//Кнопка Минус активная.
                    knopkaPlus.enabled = true;//Кнопка Плюс активная.
                }
            }
        }
    }
	onToChanged:{//Защита от неверного ввода max и min значения, которое роняет приложение.
        if(to < 0){//С отрицательными числами DCSpinBox не работает.
			to = 32767;//Задаём значение по умолчанию.
			console.error(qsTr("DCSpinBox.qml::to(int): to - задано отрицательное значение."));
			if(from < 0){//Если при этом from отрицательное число, то...
				from = 0;//Задаём значение по умолчанию.
				console.error(qsTr("DCSpinBox.qml::to(int): from - задано отрицательное значение."));
			}
		}
		else{//Если это не отрицательное значение, то...
			if(to < from){
				from = 0;//Задаём значение по умолчанию.
				to = 32767;//Задаём значение по умолчанию.
				console.error(qsTr("DCSpinBox.qml::to(int): to < from."));
			}
        }
        //from и to выставленны после не верного ввода свойств, а теперь активируем, деактивируем кнопки.
        if((from === to)){//Если мин = макс, то...
            knopkaMinus.enabled = false;//Кнопка Минус не активная.
            knopkaPlus.enabled = false;//Кнопка Плюс не активная.
        }
        else{
            if(value <= from){//Если число меньше или РАВНО минимального, то...
                knopkaMinus.enabled = false;//Кнопка Минус не активная.
                knopkaPlus.enabled = true;//Кнопка Плюс активная.
            }
            else {
                if(value >= to){//Если число больше или РАВНО максимально, то...
                    knopkaPlus.enabled = false;//Кнопка Плюс не активная.
                    knopkaMinus.enabled = true;//Кнопка Минус активная.
                }
                else{//Если значение не меньше и не больше заданного, то...
                    knopkaMinus.enabled = true;//Кнопка Минус активная.
                    knopkaPlus.enabled = true;//Кнопка Плюс активная.
                }
            }
        }
    }
	onStepSizeChanged: {
		if(stepSize < 1){
			stepSize = 1;
			console.error(qsTr("DCSpinBox.qml::stepSize(int): значение меньше 1."));
		}
	}
	function fnClickedEscape (){//Функция нажатия Escape.
        txnSpinBox.text = root.value;//Отображаем последнее значение.
	}
	function fnClickedEnter(){//Функция нажатия Enter/
		if(txnSpinBox.text){//Если не пустая строка, то...
            root.value = parseInt(txnSpinBox.text);//Приравниваем обязательно.
            root.valueModified();//Отправляем Сигнал, как в оригинальном  виджете SpinBox.
		}
		else//Если пустая строка, пользователь удалил число, то...
			fnClickedEscape();//Функция нажатия Escape, запонить пустое значение последним значением.
	}
	function fnClickedMinus(){//Функция нажатия кнопки минус.
		if(txnSpinBox.text){//Если не пустая строка, то...
            if(root.value !== parseInt(txnSpinBox.text)){//Если нет равенства, значит число вручную ввели.
                root.value = parseInt(txnSpinBox.text);//Приравниваем, чтоб не застрять в этом неравенстве.
                root.valueModified();//Отправляем Сигнал, как в оригинальном  виджете SpinBox.
            }
			else{//Если есть равенство, значит изменение идёт через + или -
                if(root.value !== root.from){//Если нет равенства с минимальным значением, то..
                    root.value = root.value - root.stepSize;//Уменьшаем.
					//А отображение value в txnSpinBox.text произойдет в слоте onValueChanged
                    root.valueModified();//Отправляем Сигнал, как в оригинальном  виджете SpinBox.
				}
			}
		}
		else{//Если пустая строка, то...
			fnClickedEscape();//Эмулируем нажатия Escape. Выставляем прежнее значение.
		}	
    }
	function fnClickedPlus(){//Функция нажатиякнопки плюс.
		if(txnSpinBox.text){//Если не пустая строка, то...
            if(root.value !== parseInt(txnSpinBox.text)){//Если нет равенства, значит число вручную ввели.
                root.value = parseInt(txnSpinBox.text);//Приравниваем, чтоб не застрять в этом неравенстве.
                root.valueModified();//Отправляем Сигнал, как в оригинальном  виджете SpinBox.
			}
			else{//Если есть равенство, значит изменение идёт через + или -
                if(root.value !== root.to){//Если нет равенства с максимальным значением, то.
                    root.value = root.value + root.stepSize;//Увеличиваем.
					//А отображение value в txnSpinBox.text произойдет в слоте onValueChanged
                    root.valueModified();//Отправляем Сигнал, как в оригинальном  виджете SpinBox.
				}
			}
		}
        else//Если пустая строка, то...
			fnClickedEscape();//Эмулируем нажатия Escape. Выставляем прежнее значение.
	}
    Rectangle {
        id: rctSpinBox
        anchors.fill: root
        color: root.clrFonaPassive
        DCKnopkaMinus{//Кнопка минус.
			id: knopkaMinus
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            anchors.verticalCenter: rctSpinBox.verticalCenter; anchors.left:rctSpinBox.left
            clrKnopki: root.clrTexta
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff; tapWidth: tapHeight*root.tapKnopkaMinus
            onClicked: fnClickedMinus()//Функция нажатия Минус.
		}
		Rectangle {
			id: rctTextInput
            height: root.ntWidth*root.ntCoff
			anchors.verticalCenter: rctSpinBox.verticalCenter
            anchors.left: knopkaMinus.right; anchors.right: knopkaPlus.left
			color: "transparent"
            radius: root.ntCoff/2//Так красивее.
            clip: true//Обрезаем текст, который выходит за границы этогопрямоугольника.
			TextInput {//Область текста.
                id: txnSpinBox
                anchors.left: rctTextInput.left; anchors.right: rctTextInput.right
                anchors.verticalCenter: rctTextInput.verticalCenter
                color: root.clrTexta
                horizontalAlignment: TextInput.AlignHCenter; verticalAlignment: TextInput.AlignVCenter
                validator: IntValidator {//Вводим только цифры.
                    bottom: 0  // Минимальное значение
                    top: root.to // Максимальное значение
                }
                inputMethodHints: Qt.ImhDigitsOnly//Подсказка для клавиатуры, чтобы показывать только цифры
                text: root.value
                font.pixelSize: root.ntWidth*root.ntCoff//размер шрифта текста.
				readOnly: false//Можно редактировать. 
				selectByMouse: true//пользователь может использовать мышь/палец для выделения текста.
                cursorPosition: text.length;//Курсор в конец текста
				cursorVisible: true//Курсор сделать видимым
				Keys.onPressed: (event) => {//Это запись для Qt6, для Qt5 нужно удалить event =>
					if((event.key === 16777220)||(event.key === 16777221)){//Код 16777220 и 16777221 - Enter
						fnClickedEnter();//Функция нажатия Enter.
						event.accepted = true;//Enter не использовался в сочетании клавишь с другими клавишами
					}
					if(event.key === Qt.Key_Escape){
						fnClickedEscape();//функция нажатия Escape
					}
					//console.error(event.key);
				}
				onFocusChanged: {//Если фокус изменился...
                    if(focus)//Если фокус на вводе текста, то...
                        rctTextInput.color = root.clrFonaActive
                    else//Если не в фокусе, то...
                        rctTextInput.color = root.clrFonaPassive

					if(!text){//Если пустая строчка, то...
						if(!focus){//Если фокус пропал, то...
							fnClickedEscape();//То выставляем последнее значение.
						}
					}
				}
				onTextChanged: {//Если текст меняет пользователь вручную или кнопками.
                    var ntValue = parseInt(txnSpinBox.text);//Приравниваем значение.
					if(text){//Если не пустая строка, эта важная строка, чтоб можно было вводить число.
                        if(ntValue > root.to){//Если пользователь вводит число больше заданного
                            if(root.value !== root.to){//Если нет равенства, то...
                                root.value = root.to;//Выставляем максимальное значение.
                                text = root.value;//В этом слоте,onValueChanged не срабатывает,приравнив
                                root.valueModified();//Отправляем Сигнал, как в оригинальном SpinBox.
							}
							else{
                                if(ntValue > root.to){
                                    root.value = root.to;//Выставляем максимальное значение.
                                    text = root.value;//В этом слоте,onValueChanged не срабатывает,прирав
								}
							}
						}
                        if(ntValue < root.from){//Если пользователь вводит число меньше заданного
                            if(root.value !== root.from){//Если нет равенства, то...
                                root.value = root.from;//Выставляем минимальное значение.
                                text = root.value;//В этом слоте,onValueChanged не срабатывает,приравнив
                                root.valueModified();//Отправляем Сигнал, как в оригинальном SpinBox.
							}
							else{
                                if(ntValue < root.from){
                                    root.value = root.from;//Выставляем минимальное значение.
                                    text = root.value;//В этом слоте,onValueChanged не срабатывает,прирав
								}
							}
						}
					}
				}
			}
		}
        DCKnopkaPlus {//Кнопка плюс.
			id: knopkaPlus
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            anchors.verticalCenter: rctSpinBox.verticalCenter; anchors.right:rctSpinBox.right
            clrKnopki: root.clrTexta
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff; tapWidth: tapHeight*root.tapKnopkaPlus
            onClicked: fnClickedPlus()//Функция нажатия Плюс.
		}
    }
}
