import QtQuick
//DCFontSize - невизуальный помощник (счётчик размера шрифта) для любого текста.
//Считает font.pixelSize так, чтобы текст влезал в заданную ширину с отступом
//с обеих сторон: при нехватке ширины шрифт уменьшается до ntMin, при широком
//контейнере растёт только до базового ntBazovy и не выше.
//Применение: положить экземпляр рядом с Text (можно внутрь той же рамки),
//задать strTekst/ntBazovy/ntOtstup и привязать ширину (width или ntShirina)
//к доступной ширине текста; в Text затем: font.pixelSize: экземпляр.ntShrift.
Item {
	id: root
	width: 0//Помощник ничего не рисует, но width можно привязать к рамке.
	height: 0
	//Настройки.
	property string strTekst: ""//Измеряемый текст (тот же, что у Text).
	property int ntBazovy: 24//Размер шрифта, когда ширины текста хватает с запасом (база).
	property int ntMin: 8//Минимальный размер, ниже шрифт не уменьшается (читаемость).
	property int ntOtstup: 0//Отступ с каждой стороны от края доступной ширины.
	property int ntShirina: width//Доступная для текста ширина.
	//Результат: готовый размер шрифта (присвоить в Text font.pixelSize).
	//Важно: Math.floor, а не Math.round — округление вверх предсказывало шрифт,
	//при котором текст вылезал за ширину (замер: 126 случаев из 581, до 9 px).
	//floor всегда даёт размер, при котором текст гарантированно влезает.
	property int ntShrift: Math.floor(Math.max(ntMin, ntBazovy * Math.min(1,
		(ntShirina - ntOtstup * 2) / Math.max(1, mtZamer.width))))
	TextMetrics {//Замер ширины текста базовым шрифтом, без переноса строк.
		//Важно: mtZamer.width, а не paintedWidth — у TextMetrics его нет.
		id: mtZamer
		text: root.strTekst
		font.pixelSize: root.ntBazovy
	}
}
