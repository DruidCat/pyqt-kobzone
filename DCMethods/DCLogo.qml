import QtQuick //2.15
//Логотип ТМК
Item {
    id: root
    //Свойства.
    property int ntCoff: 1
    property string logoImya: "mentor"
	property real logoOpacity: 1
    //Настройки.
    width: ntCoff*14.6875
    height: ntCoff*14.6875
    Image {
        id: imgTMK
        source: {
            if(logoImya === "tmk")
                    return "qrc:/resources/images/tmk-color-1.svg"
			else if(logoImya === "tmk-ts")
					return "qrc:/resources/images/ts-rus-color.svg"
			else if(logoImya === "tmk-ts-o")
					return "qrc:/resources/images/ts-rus-orange.svg"
			else if(logoImya === "tmk-ts-o-1")
					return "qrc:/resources/images/ts-rus-orange-1.svg"
			else if(logoImya === "tmk-ts-bw-1")
					return "qrc:/resources/images/ts-rus-black-and-white-1.svg"
			else if(logoImya === "tmk-ts-bw-2")
					return "qrc:/resources/images/ts-rus-black-and-white-2.svg"
			else if (logoImya === "kobzone")
					return "qrc:/resources/images/logo.png"
        }
        sourceSize: Qt.size(232, 232)
        anchors.fill: root
        //Это свойство важно для качественного рендеринга SVG. Мы указываем исходный размер изображения.
        fillMode: Image.PreserveAspectFit//Сохраняем пропорции
        opacity: root.logoOpacity
    }
}
