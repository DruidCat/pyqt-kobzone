import QtQuick //2.15
//DCTextInput - ШАБЛОН ДЛЯ РАБОТЫ СО СТРОКОЙ ТЕКСТА. (33 БУКВЫ, работает ESCAPE и ENTER)
Item {
    id: root
    //Свойства.
    property alias text: txnTextInput.text //Текст
	property alias textInput: txnTextInput//Передаём в виде свойства весь объект TextInput
    property alias radius: rctTextInput.radius//Радиус рабочей зоны
    property alias clrFona: rctTextInput.color //цвет текста
    property alias clrTexta: txnTextInput.color //цвет текста
    property alias bold: txnTextInput.font.bold
    property alias italic: txnTextInput.font.italic
	property bool blSqlProtect: false//true - защита от Sql инъекция, прещён ввод определённых символов
    property int  ntWidth: 2
    property int ntCoff: 8
    property alias placeholderText: txtTextInput.text//Текст в строке, подсказывающий, что нужно вводить юзеру
    property alias placeholderColor: txtTextInput.color//Цвет текста подсказки
    //Настройки.
    anchors.fill: parent
    //Сигналы.
	signal clickedEnter();//Сигнал нажатия Enter
	signal clickedEscape();//Сигнал нажатия Escape
    signal clickedCopyToClipboard();//Скопировать в буфер обмена.
    signal sgnDebug(string strDebug);//Сигнал, излучающий ошибку из виджета.
    //Функции.
	function ustText (strText){//Функция вставления текста, нужна для Android и обновления вирт клавиатуры.
        txnTextInput.focus = false//Убрать фокус.
        txnTextInput.text = strText//Вставить текст.
        Qt.callLater(function() {//Пауза в такт.
            txnTextInput.focus = true//Установить фокус.
            Qt.inputMethod.reset();//Сбросить виртуальную клавиатуру, чтоб при удалении обновлялся текст.
        })
	}
    Rectangle {
        id: rctTextInput
		anchors.fill: root
		color: "transparent"//Текст фона прозрачный.
		clip: true//Обрезаем текст, который выходит за границы этогопрямоугольника.
		visible: {
			if(root.visible){//Если видимый виджет, то...
				txnTextInput.readOnly = false;//Можно редактировать.
				txnTextInput.focus = true;//Фокусируемся.
				txnTextInput.forceActiveFocus();//Напрямую форсируем фокус, по другому не работает.
				return true;//Видимый
			}
			else{//Если невидимый виджет, то...
				txnTextInput.readOnly = true;//Нельзя редактировать.
				txnTextInput.focus = false;//Не фокусируемся.
				return false;//Невидимый
			}
		}
        TextInput {//Область текста.
            id: txnTextInput
            anchors.centerIn: rctTextInput
            //anchors.fill: rctTextInput
            color: "black"//цвет текста
			horizontalAlignment: TextInput.AlignHCenter
			verticalAlignment: TextInput.AlignVCenter
			
			//TODO Qt6 интерфейс. Закоментировать не нужный.

			validator: RegularExpressionValidator {//Чтоб не было SQL инъекции, запрещены символы ';*%_?\
                //regularExpression: /[0-9a-zA-Zа-яА-ЯёЁ ~`!@#№$^:&<>,./"(){}|=+-]+/
                //Если код начинается с ^ [^.....] то это запретить вводить и перечисляются символы.\\ - это \
				regularExpression: blSqlProtect ? /[^';*%_\\?]+/ : /.*/
            }

			//TODO Qt5 Интерфейс. Закоментировать не нужный.
            //validator: RegExpValidator {//Чтоб не было SQL инъекции, запрещены символы ';*%_?\
                //regExp: /[0-9a-zA-Zа-яА-ЯёЁ ~`!@#№$^:&<>,./"(){}|=+-]+/
                //Если код начинается с ^ [^.....] то это запретить вводить и перечисляются символы.\\ - это \
                //regExp: blSqlProtect ? /[^';*%_\\?]+/ : /.*/
            //}
            text: ""
            font.pixelSize: root.ntWidth*root.ntCoff//размер шрифта текста.
			//font.capitalization: Font.AllUppercase//Отображает текст весь с заглавных букв.
            //inputMethodHints: Qt.ImhUppercaseOnly//Буквы в виртуальной клавиатуре заглавные
            //cursorPosition: text.length;//Курсор в конец текста
            maximumLength: 33//Максимальная длина ввода текста.
			readOnly: true//нельзя редактировать. 
            focus: false//Фокус не на TextInput
			selectByMouse: true//пользователь может использовать мышь/палец для выделения текста.
			cursorVisible: true//Курсор сделать видимым
			Keys.onPressed: (event) => {//Это запись для Qt6, для Qt5 нужно удалить event =>
                if(event.modifiers & Qt.ControlModifier){//Если нажат "Ctrl"
                    if(event.key === Qt.Key_C){//Если нажата "C",то...
                        root.clickedCopyToClipboard();//Копируем выделенный текст в буфер обмена.
                        event.accepted = true;//Завершаем обработку эвента.
                    }
                }
                else{
                    if((event.key === 16777220)||(event.key === 16777221)){//Код 16777220 и 16777221 - Enter
                        root.clickedEnter();//Излучаем сигнал о том, что нажат Enter.
                        event.accepted = true;//Enter не использовался в качестве сочетания клавишь с другими клав
                    }
                    if(event.key === Qt.Key_Escape){
                        root.clickedEscape();//Излучаем сигнал о том, что нажат Ecape
                    }
                    if(blSqlProtect&&((event.key===63)||(event.key===39)||(event.key===59)||(event.key===42)
                                      ||(event.key === 37)||(event.key === 95)||(event.key === 92))){
                        root.sgnDebug("Нельза использовать символы % ? ' ; * _ \\ ");//Сигнал ошибки
                    }
                }
                //console.log(event.key);
            } 
            Text {//Текст, подсказывающий пользователю, что нужно вводить.
                id: txtTextInput
                anchors.centerIn: txnTextInput//Обязательно по центру, иначе масштабирование не будет работать
                font.pixelSize: root.ntWidth*root.ntCoff//размер шрифта текста.
                text: ""//По умолчанию нет надписи.
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "#aaa"//Светло серый цвет по умолчанию.
                visible: !txnTextInput.text
				onVisibleChanged: {//Если изменилась видимость, то...
					if(text){//(Защита от пустого текста) Если не пустой текст, то...
						if(visible){//Если подсказка становится видимой, то...
							if(rctTextInput.width > txtTextInput.width){//Если длина строки > длины текста,то
                                for(var ltShag = txtTextInput.font.pixelSize;
												ltShag < rctTextInput.height-root.ntCoff; ltShag++){
									if(txtTextInput.width < rctTextInput.width){//длина текста < динны строки
										txtTextInput.font.pixelSize = ltShag;//Увеличиваем размер шрифта
										if(txtTextInput.width > rctTextInput.width){//Но, если переборщили
											txtTextInput.font.pixelSize--;//То уменьшаем размер шрифта и...
											return;//Выходим из увеличения шрифта.
										}
									}
								}
							}
							else{//Если длина строки меньше длины текста, то...
								for(let ltShag = txtTextInput.font.pixelSize; ltShag > 0; ltShag--){//Цикл --
									if(txtTextInput.width > rctTextInput.width)//Если текст дилиннее строки,то
										txtTextInput.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
								}
							}
						}
					}
				}	
            }
        }
    }
	onWidthChanged: {//Если изменилась ширина прямоугольника, то...
		if(txtTextInput.text){//(Защита от пустого текста) Если не пустой текст, то...
			if(txtTextInput.visible){//Если подсказка становится видимой, то...
				if(rctTextInput.width > txtTextInput.width){//Если длина строки > длины текста,то
                    for(var ltShag = txtTextInput.font.pixelSize;
									ltShag < rctTextInput.height-root.ntCoff; ltShag++){
						if(txtTextInput.width < rctTextInput.width){//длина текста < динны строки
							txtTextInput.font.pixelSize = ltShag;//Увеличиваем размер шрифта
							if(txtTextInput.width > rctTextInput.width){//Но, если переборщили
								txtTextInput.font.pixelSize--;//То уменьшаем размер шрифта и...
								return;//Выходим из увеличения шрифта.
							}
						}
					}
				}
				else{//Если длина строки меньше длины текста, то...
					for(let ltShag = txtTextInput.font.pixelSize; ltShag > 0; ltShag--){//Цикл --
						if(txtTextInput.width > rctTextInput.width)//Если текст дилиннее строки,то
							txtTextInput.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
					}
				}
			}
		}
		if(txnTextInput.text){//(Защита от пустого текста) Если не пустой текст, то...
			if(txnTextInput.visible){//Если текст становится видимым, то...
				if(rctTextInput.width > txnTextInput.width){//Если длина строки > длины текста,то
					for(let ltShag = txnTextInput.font.pixelSize;
									ltShag < rctTextInput.height-root.ntCoff; ltShag++){
						if(txnTextInput.width < rctTextInput.width){//длина текста < динны строки
							txnTextInput.font.pixelSize = ltShag;//Увеличиваем размер шрифта
							if(txnTextInput.width > rctTextInput.width){//Но, если переборщили
								txnTextInput.font.pixelSize--;//То уменьшаем размер шрифта и...
								return;//Выходим из увеличения шрифта.
							}
						}
					}
				}
				else{//Если длина строки меньше длины текста, то...
					for(let ltShag = txnTextInput.font.pixelSize; ltShag > 0; ltShag--){//Цикл --
						if(txnTextInput.width > rctTextInput.width)//Если текст дилиннее строки,то
							txnTextInput.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
					}
				}
			}
		}
	}
	onPlaceholderTextChanged: {//Если изменилcя текст подсказки, то...
		if(txtTextInput.text){//(Защита от пустого текста) Если не пустой текст, то...
			if(txtTextInput.visible){//Если подсказка становится видимой, то...
				if(rctTextInput.width > txtTextInput.width){//Если длина строки > длины текста,то
                    for(var ltShag = txtTextInput.font.pixelSize;
									ltShag < rctTextInput.height-root.ntCoff; ltShag++){
						if(txtTextInput.width < rctTextInput.width){//длина текста < динны строки
							txtTextInput.font.pixelSize = ltShag;//Увеличиваем размер шрифта
							if(txtTextInput.width > rctTextInput.width){//Но, если переборщили
								txtTextInput.font.pixelSize--;//То уменьшаем размер шрифта и...
								return;//Выходим из увеличения шрифта.
							}
						}
					}
				}
				else{//Если длина строки меньше длины текста, то...
					for(let ltShag = txtTextInput.font.pixelSize; ltShag > 0; ltShag--){//Цикл --
						if(txtTextInput.width > rctTextInput.width)//Если текст дилиннее строки,то
							txtTextInput.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
					}
				}
			}
		}
	}
	onTextChanged: {//Если изменилcя вводимый текст, то...
        Qt.callLater(function() {//Чтоб успела посчитаться длина строки вставленного текста.
            if(txnTextInput.text){//(Защита от пустого текста) Если не пустой текст, то...
                if(txnTextInput.visible){//Если текст становится видимым, то...
                    if(rctTextInput.width > txnTextInput.width){//Если длина строки > длины текста,то
                        for(var ltShag = txnTextInput.font.pixelSize;
                                        ltShag < rctTextInput.height-root.ntCoff; ltShag++){
                            if(txnTextInput.width < rctTextInput.width){//длина текста < динны строки
                                txnTextInput.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                                if(txnTextInput.width > rctTextInput.width){//Но, если переборщили
                                    txnTextInput.font.pixelSize--;//То уменьшаем размер шрифта и...
                                    return;//Выходим из увеличения шрифта.
                                }
                            }
                        }
                    }
                    else{//Если длина строки меньше длины текста, то...
                        for(let ltShag = txnTextInput.font.pixelSize; ltShag > 0; ltShag--){//Цикл --
                            if(txnTextInput.width > rctTextInput.width)//Если текст дилиннее строки,то
                                txnTextInput.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
                        }
                    }
                }
            }
        })
    }
    TapHandler {//Обрабатывает нажатие только виджета, но не срабаывает на область txnTextInput
        id: tphRoot
        onTapped: {//Если тапнули, то...
            if(root.visible){//Если виджет видимый, то...
                var vrX = point.position.x//Координата клика по X в виджете.
                var vrSeredina = root.width/2//Считаем середину клика
                txnTextInput.focus = true;//Делаем фокус на вводимом текста, чтоб появился курсор
                if(vrSeredina < vrX)//Если координата клика больше середины, то...
                    txnTextInput.cursorPosition = txnTextInput.text.length;//Курсор в конец текста
                else//Если меньше середины, то...
                    txnTextInput.cursorPosition = 0;//Курсор в начало текста
            }
        }
    }
}
