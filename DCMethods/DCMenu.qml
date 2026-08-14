import QtQuick //2.15

import "qrc:/resources/js/jsJSON.js" as JSMenu
//DCMenu - ШАБЛОН ВСПЛЫВАЮЩЕГО МЕНЮ НАСТРОЕК.
Item {
    id: root
    //Свойства.
    property int ntWidth: 2
	property int ntCoff: 8
	property color clrTexta: "orange"
	property color clrFona: "SlateGray"
    property real pctTexta: 1//Прозрачность текста меню.
    property real pctFona: 1//Прозрачность фона меню.
    property string imyaMenu: ""
    //Сигналы.
	signal clicked(int ntNomer, var strMenu)
    //Функции.
    ListView {
		id: lsvMenu
        focus: {
           if(root.visible){//Если виджет видимый, то...
                forceActiveFocus();//Напрямую форсируем фокус, по другому не работает.
                return true;
           }
           else//Если виджет не видимый, то...
                return false;
        }
		Component {
			id: cmpMenu
			Rectangle {
				id: rctMenu
                width: lsvMenu.width
                height: root.ntWidth*root.ntCoff+root.ntCoff
                radius: (width/(root.ntWidth*root.ntCoff))/root.ntCoff
				border.width: 1
                border.color: Qt.darker(root.clrFona, 1.3)
                clip: true//Обрезаем лишний текст в прямоугольнике.
                color: maMenu.containsPress
                       ? Qt.darker(root.clrFona, 1.3) : root.clrFona
                Rectangle {
                    id: rctText
                    anchors.fill: rctMenu
                    anchors.margins: root.ntCoff/2
                    color: "transparent"
                }
				Text {
					id: txtText
                    color: maMenu.containsPress ? Qt.darker(root.clrTexta, 1.3) : root.clrTexta
                    anchors.left: rctText.left
                    anchors.verticalCenter: rctText.verticalCenter
                    opacity: root.pctTexta//Прозрачность текста.
                    text: modelData.menu
                    font.pixelSize: rctText.height-root.ntCoff
                }
                Component.onCompleted: {//Когда текст нарисовался, расчитываю его длину.
                    if(rctText.width > txtText.width){//Если длина строки больше длины текста, то...
                        for(var ltShag=txtText.font.pixelSize; ltShag<rctText.height-root.ntCoff; ltShag++){
                            if(txtText.width < rctText.width){//Если длина текста меньше динны строки
                                txtText.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                                if(txtText.width > rctText.width){//Но, если переборщили
                                    txtText.font.pixelSize--;//То уменьшаем размер шрифта и...
                                    return;//Выходим из увеличения шрифта.
                                }
                            }
                        }
                    }
                    else{//Если длина строки меньше длины текста, то...
                        for(let ltShag = txtText.font.pixelSize; ltShag > 0; ltShag--){//Цикл уменьшения
                            if(txtText.width > rctText.width)//Если текст дилиннее строки, то...
                                txtText.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
                        }
                    }
                }
				MouseArea {
					id: maMenu
					anchors.fill: rctMenu
					onClicked: {
                        root.clicked(modelData.nomer, modelData.menu)
					}
				}
				onWidthChanged: {//Если длина строки изменилась, то...
                    if(rctText.width > txtText.width){//Если длина строки больше длины текста, то...
                        for(var ltShag=txtText.font.pixelSize; ltShag<rctText.height-root.ntCoff; ltShag++){
                            if(txtText.width < rctText.width){//Если длина текста меньше динны строки
								txtText.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                                if(txtText.width > rctText.width){//Но, если переборщили
									txtText.font.pixelSize--;//То уменьшаем размер шрифта и...
									return;//Выходим из увеличения шрифта.
								}
							}
						}
					}
					else{//Если длина строки меньше длины текста, то...
						for(let ltShag = txtText.font.pixelSize; ltShag > 0; ltShag--){//Цикл уменьшения 
                            if(txtText.width > rctText.width)//Если текст дилиннее строки, то...
								txtText.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
						}
					}
				}
                onHeightChanged: {//Если изменилась высота, значит изменился размер Шрифта в StrMenu.
                    Qt.callLater(function () {//Делаем паузу на такт,иначе не успеет пересчитаться высота!
                        txtText.font.pixelSize = rctText.height-root.ntCoff
                        if(rctText.width > txtText.width){//Если длина строки больше длины текста, то...
                            for(var ltShag=txtText.font.pixelSize;ltShag<rctText.height-root.ntCoff;ltShag++){
                                if(txtText.width < rctText.width){//Если длина текста меньше динны строки
                                    txtText.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                                    if(txtText.width > rctText.width){//Но, если переборщили
                                        txtText.font.pixelSize--;//То уменьшаем размер шрифта и...
                                        return;//Выходим из увеличения шрифта.
                                    }
                                }
                            }
                        }
                        else{//Если длина строки меньше длины текста, то...
                            for(let ltShag = txtText.font.pixelSize; ltShag > 0; ltShag--){//Цикл уменьшения
                                if(txtText.width > rctText.width)//Если текст дилиннее строки, то...
                                    txtText.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
                            }
                        }
                    })
                }
			}
		}
        anchors.fill: root
        anchors.topMargin:root.ntCoff
        anchors.bottomMargin:root.ntCoff
        anchors.leftMargin:root.width/2//Отступ отлевого края половина длины экрана.
        anchors.rightMargin:root.ntCoff/2//Отступ от правого края пол коэффициента
        opacity: root.pctFona//Прозрачность фона.
		interactive: false//Запретить листать.

		delegate: cmpMenu
	}
    onNtWidthChanged: {//Пересчитывает высоту виджета при изменении ntWidth (масштаба).
        root.height = lsvMenu.count*(ntWidth*ntCoff+ntCoff)+ntCoff;//Выставляем высоту под размер меню.
    }
    onNtCoffChanged: {//Пересчитывает высоту виджета при изменении ntCoff (масштаба).
        root.height = lsvMenu.count*(ntWidth*ntCoff+ntCoff)+ntCoff;//Выставляем высоту под размер меню.
    }
	Component.onCompleted: {//Слот, кода всё представление отрисовалось.
        if(imyaMenu == "kobzone")//Если это главное Меню, то...
			lsvMenu.model = JSMenu.vrMenuKOBzone;//Перегружаем модель ListView с новыми данными.
		else{
            if(imyaMenu == "analizer")//Если это Анализ текста, то...
				lsvMenu.model = JSMenu.vrMenuAnalizer;//Перегружаем модель ListView с новыми данными.
			else{
                if(imyaMenu == "orfograf")//Если это редактор Орфографии, то...
					lsvMenu.model = JSMenu.vrMenuOrfograf;//Перегружаем модель ListView с новыми данными.
                else{
                    if(imyaMenu == "transcribe")//Это транскрибация аудио в текст
                        lsvMenu.model = JSMenu.vrMenuTranscribe;//Перегружаем модель ListView с данными
					else{
						if(imyaMenu == "settings")//Это настройки
							lsvMenu.model = JSMenu.vrSettings;//Перегружаем модель ListView с данными
					}
                }
            }
		}
        root.height = lsvMenu.count*(ntWidth*ntCoff+ntCoff)+ntCoff;//Выставляем высоту под размер меню.
	}
}
