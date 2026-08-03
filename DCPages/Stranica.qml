import QtQuick //2.15
import QtQuick.Controls //2.15 //Для Page
//СТРАНИЦА - шаблон страницы программы с Заголовком, Зоной и Тулбаром.
Page {
    id: root
    //Свойства.
	property int ntWidth: 8
	property int ntCoff: 8
	property color clrFona: "transparent"
	property color clrTexta: "grey"
    property color clrFaila: "yellow"
    property color clrRabOblasti: "lightblue"
	property alias textZagolovok:  txtStrZagolovok.text
	property alias textToolbar: txtStrToolbar.text
	property alias rctStrZagolovok: rctStrZagolovok
	property alias rctStrZona: rctStrZona
    property alias rctStrToolbar: rctStrToolbar
    property real zagolovokLevi: 1//Коэффициент ширины левой кнопки в заголовке.
    property real zagolovokPravi: 1//Коэффициент ширины правой кнопки в заголовке.
    property real toolbarLevi: 1//Коэффициент ширины левой кнопки в тулбар.
    property real toolbarPravi: 1//Коэффициент ширины правой кнопки в тулбар.
    //Функции.
    onNtWidthChanged: {//Если изменился размер Шрифта в StrMenu, то....
        Qt.callLater(function () {//Делаем паузу на такт,иначе не успеет пересчитаться размер Заголовка ВЕЗДЕ!
            txtStrZagolovok.font.pixelSize = rctStrZagolovokText.height//Задаём высоту шрифта изменённую, и...
            if(rctStrZagolovokText.width > txtStrZagolovok.width){//длина строки больше текста
                for(var ltShag=txtStrZagolovok.font.pixelSize;
                                                ltShag<rctStrZagolovokText.height; ltShag++){
                    if(txtStrZagolovok.width < rctStrZagolovokText.width){
                        txtStrZagolovok.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                        if(txtStrZagolovok.width > rctStrZagolovokText.width){//если переборщи
                            txtStrZagolovok.font.pixelSize--;//То уменьшаем размер шрифта и...
                            return;//Выходим из увеличения шрифта.
                        }
                    }
                }
            }
            else{//Если длина строки меньше длины текста, то...
                for(let ltShag = txtStrZagolovok.font.pixelSize; ltShag > 0; ltShag--){//Цикл
                    if(txtStrZagolovok.width > rctStrZagolovokText.width)//текст дилиннее стро
                        txtStrZagolovok.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
                }
            }
        })
    }

	Item{
		id: tmStr
        anchors.fill: parent
		Rectangle{
            id: rctStr
			anchors.fill: tmStr
			color: clrFona
			Rectangle {
                id: rctStrZagolovok
				width: rctStr.width
				height: root.ntWidth*root.ntCoff+root.ntCoff
				anchors.top: rctStr.top
				anchors.left: rctStr.left
				anchors.right: rctStr.right
                anchors.margins: root.ntCoff
				color: clrRabOblasti
				radius: (width/(root.ntWidth*root.ntCoff))/root.ntCoff
				Item {//Этот элемент невидимой кнопки, чтоб от неё отпозиционировался текст.
                    id: tmZagolovokKnopkaCleva
					height: rctStrZagolovok.height
                    width: height*root.zagolovokLevi//Длина левой кнопки в перерасчёта на коэффициент.
					anchors.top: rctStrZagolovok.top
                    anchors.left: rctStrZagolovok.left
                    anchors.bottom: rctStrZagolovok.bottom
				}
				Rectangle {
                    id: rctStrZagolovokText
                    height: rctStrZagolovok.height-root.ntCoff
                    anchors.left: tmZagolovokKnopkaCleva.right
                    anchors.right: tmZagolovokKnopkaCprava.left
                    anchors.verticalCenter: rctStrZagolovok.verticalCenter
					color: "transparent"
					Text {
                        id: txtStrZagolovok
						anchors.centerIn: rctStrZagolovokText
                        color: root.clrTexta
						text: ""
                        font.bold: true
						font.pixelSize: rctStrZagolovokText.height
						onTextChanged: {//Если изменился текст, втавили длинный текст.
							if(rctStrZagolovokText.width > txtStrZagolovok.width){//длина строки больше текста
                                for(var ltShag=txtStrZagolovok.font.pixelSize;
																ltShag<rctStrZagolovokText.height; ltShag++){
									if(txtStrZagolovok.width < rctStrZagolovokText.width){
										txtStrZagolovok.font.pixelSize = ltShag;//Увеличиваем размер шрифта
										if(txtStrZagolovok.width > rctStrZagolovokText.width){//если переборщи
											txtStrZagolovok.font.pixelSize--;//То уменьшаем размер шрифта и...
											return;//Выходим из увеличения шрифта.
										}
									}
								}
							}
							else{//Если длина строки меньше длины текста, то...
								for(let ltShag = txtStrZagolovok.font.pixelSize; ltShag > 0; ltShag--){//Цикл
									if(txtStrZagolovok.width > rctStrZagolovokText.width)//текст дилиннее стро
										txtStrZagolovok.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
								}
							}
						}
					}
                    onWidthChanged: {//Если длина строки изменилась, то...
                        if(rctStrZagolovokText.width > txtStrZagolovok.width){//длина строки больше текста, то
                            for(var ltShag=txtStrZagolovok.font.pixelSize; ltShag<rctStrZagolovokText.height;
                                                                                                    ltShag++){
                                if(txtStrZagolovok.width < rctStrZagolovokText.width){//длина текста меньше ст
                                    txtStrZagolovok.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                                    if(txtStrZagolovok.width > rctStrZagolovokText.width){//если переборщили
                                        txtStrZagolovok.font.pixelSize--;//То уменьшаем размер шрифта и...
                                        return;//Выходим из увеличения шрифта.
                                    }
                                }
                            }
                        }
                        else{//Если длина строки меньше длины текста, то...
                            for(let ltShag = txtStrZagolovok.font.pixelSize; ltShag > 0; ltShag--){//Цикл
                                if(txtStrZagolovok.width > rctStrZagolovokText.width)//текст дилиннее строки
                                    txtStrZagolovok.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
                            }
                        }
					}
				}
                Item {//Этот элемент невидимой кнопки, чтоб от неё отпозиционировался текст.
                    id: tmZagolovokKnopkaCprava
                    height: rctStrZagolovok.height
                    width: height*root.zagolovokPravi//Длина правой кнопки в перерасчёте на коэффициент.
                    anchors.top: rctStrZagolovok.top
                    anchors.right: rctStrZagolovok.right
                    anchors.bottom: rctStrZagolovok.bottom
                }
			}
			Rectangle {
                id: rctStrZona
				width: rctStr.width
				anchors.top: rctStrZagolovok.bottom
				anchors.left: rctStr.left
				anchors.right: rctStr.right
				anchors.bottom: rctStrToolbar.top
				anchors.margins: root.ntCoff
				radius: (width/(root.ntWidth*root.ntCoff))/root.ntCoff
				color: clrRabOblasti
			}
			Rectangle {
                id: rctStrToolbar
				width: rctStr.width
                height: root.ntWidth*root.ntCoff+root.ntCoff
				anchors.left: rctStr.left
				anchors.right: rctStr.right
				anchors.bottom: rctStr.bottom
                anchors.margins: root.ntCoff
				color: clrRabOblasti
				border.color: Qt.darker(clrRabOblasti, 1.3)
                border.width: root.ntCoff/4
				Item {//Этот элемент невидимой кнопки, чтоб от неё отпозиционировался текст.
                    id: tmToolbarKnopkaCleva
					height: rctStrToolbar.height
                    width: height*root.toolbarLevi//Длина левой кнопки в перерасчёта на коэффициент.
					anchors.top: rctStrToolbar.top
                    anchors.left: rctStrToolbar.left
                    anchors.bottom: rctStrToolbar.bottom
				} 
				Rectangle {
                    id: rctStrToolbarText
                    height: rctStrToolbar.height-root.ntCoff
                    anchors.left: tmToolbarKnopkaCleva.right
                    anchors.right: tmToolbarKnopkaCprava.left
                    anchors.verticalCenter: rctStrToolbar.verticalCenter
					color: "transparent"
                    Text {
                        id: txtStrToolbar
						anchors.centerIn: rctStrToolbarText
                        color: root.clrTexta
						text: ""
                        font.pixelSize: rctStrToolbarText.height
                        onTextChanged: {//Если длина строки изменилась, то...
                            if(rctStrToolbarText.width > txtStrToolbar.width){//длина строки больше текста, то
                                for(var ltShag=txtStrToolbar.font.pixelSize;ltShag<rctStrToolbarText.height;
                                                                                                    ltShag++){
                                    if(txtStrToolbar.width < rctStrToolbarText.width){//длина текста < страниц
                                        txtStrToolbar.font.pixelSize = ltShag;//Увеличиваем размер шрифта
                                        if(txtStrToolbar.width > rctStrToolbarText.width){//если переборщили
                                            txtStrToolbar.font.pixelSize--;//То уменьшаем размер шрифта и...
                                            return;//Выходим из увеличения шрифта.
                                        }
                                    }
                                }
                            }
                            else{//Если длина строки меньше длины текста, то...
                                for(let ltShag = txtStrToolbar.font.pixelSize; ltShag > 0; ltShag--){//Цикл
                                    if(txtStrToolbar.width > rctStrToolbarText.width)//текст дилиннее строки
                                        txtStrToolbar.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
                                }
                            }
                        }
					}
					onWidthChanged: {//Если длина строки изменилась, то...
						if(rctStrToolbarText.width > txtStrToolbar.width){//длина строки больше текста, то...
                            for(var ltShag=txtStrToolbar.font.pixelSize;ltShag<rctStrToolbarText.height;
                                                                                                    ltShag++){
								if(txtStrToolbar.width < rctStrToolbarText.width){//длина текста меньше страни
									txtStrToolbar.font.pixelSize = ltShag;//Увеличиваем размер шрифта
									if(txtStrToolbar.width > rctStrToolbarText.width){//если переборщили
										txtStrToolbar.font.pixelSize--;//То уменьшаем размер шрифта и...
										return;//Выходим из увеличения шрифта.
									}
								}
							}
						}
						else{//Если длина строки меньше длины текста, то...
							for(let ltShag = txtStrToolbar.font.pixelSize; ltShag > 0; ltShag--){//Цикл
								if(txtStrToolbar.width > rctStrToolbarText.width)//текст дилиннее строки
									txtStrToolbar.font.pixelSize = ltShag;//Уменьшаем размер шрифта.
							}
						}
					}
				} 
                Item {//Этот элемент невидимой кнопки, чтоб от неё отпозиционировался текст.
                    id: tmToolbarKnopkaCprava
                    height: rctStrToolbar.height
                    width: height*root.toolbarPravi//Длина правой кнопки в перерасчёте на коэффициент.
                    anchors.top: rctStrToolbar.top
                    anchors.right: rctStrToolbar.right
                    anchors.bottom: rctStrToolbar.bottom
                }
			}
		}
	}
}
