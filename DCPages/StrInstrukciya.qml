import QtQuick//5.15
import QtQuick.Controls//Drawer

import DCButtons 1.0//Импортируем кнопки
import DCMethods 1.0//Импортируем методы написанные мной.
//Страница с отображением инструкций
Item {
    id: root
    //Свойства.
    property int ntWidth: 2
    property int ntCoff: 8
    property color clrTexta: "Orange"
	property color clrFona: "Black"
    property color clrPolzunka: "Grey"
    property alias zagolovokX: tmZagolovok.x
	property alias zagolovokY: tmZagolovok.y
	property alias zagolovokWidth: tmZagolovok.width
	property alias zagolovokHeight: tmZagolovok.height
	property alias zonaX: tmZona.x
	property alias zonaY: tmZona.y
	property alias zonaWidth: tmZona.width
	property alias zonaHeight: tmZona.height
	property alias toolbarX: tmToolbar.x
	property alias toolbarY: tmToolbar.y
	property alias toolbarWidth: tmToolbar.width
	property alias toolbarHeight: tmToolbar.height
	property alias radiusZona: txdZona.radius
    property real tapZagolovokLevi: 1
    property real tapZagolovokPravi: 1
    property real tapToolbarLevi: 1
    property real tapToolbarPravi: 1
    property string strInstrukciya: "obavtore"
    property bool isFileDialogFailVibor: true;//true - выбор файлов, false - выбор папки
	property string pythonVersion: "3.11";//Это версия Python, которая придёт из вне
	property string qtVersion: "6.8";//Это версия Qt которая приходит из вне.
    property bool isMobile: false//true - мобильная платформа.
    //Настройки.
	anchors.fill: parent//Растянется по Родителю.
    focus: true;//Чтоб работали горячие клавиши.
    //Сигналы.
	signal clickedNazad();//Сигнал нажатия кнопки Назад
    signal signalZagolovok(var strZagolovok);//Сигнал, когда передаём новую надпись в Заголовок.
    //Функуции.
    Keys.onPressed: (event) => {//Это запись для Qt6, для Qt5 нужно удалить event =>
        if(event.modifiers & Qt.ControlModifier){//Если нажат "Ctrl"
            if (event.key === Qt.Key_B){//Если нажата клавиша В, то...
                fnClickedSidebar();//Функция открытия/закрытия боковой панели.
                event.accepted = true;//Завершаем обработку эвента.
            }
        } else if(event.modifiers & Qt.AltModifier){//Если нажат "Alt"
            if (event.key === Qt.Key_Left){//Если нажата клавиша стрелка влево, то...
                if(knopkaNazad.visible)//Если кнопка Назад видимая, то...
                    fnClickedNazad();//Функция нажатия кнопки Назад
                event.accepted = true;//Завершаем обработку эвента.
            }
        } else {
            if (event.key === Qt.Key_F1){//Если нажата F1, то...
                fnClickedSidebar();//Функция открытия/закрытия боковой панели.
                event.accepted = true
            }
        }
    }
    function fnClickedNazad(){//Функция нажатия кнопки Назад
        drwSidebar.close();//Закрываем боковую панели при закрытии инструкции.
        root.clickedNazad();//Закрываем Инструкцию.
    }
    function fnClickedSidebar(){//Функция нажатия кнопки SideBar.
        if(drwSidebar.position){//Если боковая панель открыта, то...
            drwSidebar.close()//Закрываем её
            root.focus = true//Чтоб горячие клавиши работали.
        }
        else//Если боковая панель закрыта, то...
            drwSidebar.open()//Открываем её.
    }
    Item {//Данные Заголовок
		id: tmZagolovok
        DCKnopkaNazad {
            id: knopkaNazad
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            anchors.verticalCenter: tmZagolovok.verticalCenter; anchors.left:tmZagolovok.left
            clrKnopki: root.clrTexta
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff; tapWidth: tapHeight*root.tapZagolovokLevi
            onClicked: fnClickedNazad();//Функция нажатия кнопки Назад.
        }
        DCKnopkaInfo {
            id: knopkaInfo
            opened: false//По умолчанию, бордюр с радиусом
            ntWidth: root.ntWidth; ntCoff: root.ntCoff
            anchors.verticalCenter: tmZagolovok.verticalCenter; anchors.right: tmZagolovok.right
            clrKnopki: root.clrTexta
            tapHeight: root.ntWidth*root.ntCoff+root.ntCoff; tapWidth: tapHeight*root.tapZagolovokPravi
            onClicked: fnClickedSidebar();//Функция нажатия кнопки SideBar.
        }
    }
    Item {//Данные Зона
		id: tmZona
        clip: true//Обрезаем всё что выходит за пределы этой области. Это для листания нужно.
        DCTextEdit {//Модуль просмотра текста, прокрутки и редактирования.
            id: txdZona
            ntWidth: root.ntWidth
            ntCoff: root.ntCoff
            anchors.rightMargin: drwSidebar.position * drwSidebar.width - drwSidebar.position * root.ntCoff
            readOnly: true//Запрещено редактировать текст
            textEdit.selectByMouse: false//Запрещаем выделять текст, то нужно для свайпа Android
			textEdit.textFormat: TextEdit.AutoText//Формат АВТОМАТИЧЕСКИ определяется. Предпочтителен HTML4
            pixelSize: root.ntWidth/2*root.ntCoff//размер шрифта текста в два раза меньше.
            text: 	""//По умолчанию пустая строка.
            radius: root.ntCoff/4//Радиус возьмём из настроек элемента qml через property
            clrFona: root.clrFona//Цвет фона рабочей области
            clrTexta: root.clrTexta//Цвет текста
            clrPolzunka: root.clrPolzunka//Цвет ползунка scrollbar, когда он не активен
            clrBorder: root.clrTexta//Цвет бардюра при редактировании текста.
			italic: true//Текст курсивом.
		}
    }
    Item {//Данные Тулбар
		id: tmToolbar
    }
    Drawer {
        id: drwSidebar
        //Свойства
        property int minSidebarWidth: 200//Минимум ширины боковой панели
        property int maxSidebarWidth: root.width * 0.8//Максимум ширины боковой панели
        property int sidebarWidth: root.isMobile//Если мобила, ширина на весь экран, если нет,то данные из Реестра
                                   ? root.width : Math.max(minSidebarWidth, 220)
                                   //? root.width : Math.max(minSidebarWidth, cppqml.untInstrukciyaWidth)
        //Настройки
        edge: Qt.RightEdge
        modal: false
        dim: false
        closePolicy: Drawer.CloseOnEscape//Закрываем боковую панель только при нажати Escape, другие политики выкл
        clip: true//Обрезать всё лишнее.
        //width: 330
        width: sidebarWidth//ВАЖНО! ширина боковой панели зависит только от sidebarWidth.
        height: tmZona.height//Высота боковой панели по высоте инструкции.
        y: root.ntWidth * root.ntCoff + 3 * root.ntCoff//координату по Y брал из расчёта Stranica.qml
        interactive: true//false -  панель не реагирует на свайпы.
        //Функции
        onPositionChanged: {//Если позиция изменяется у боковой панели, то...
            knopkaInfo.opened = position//Передаём сигнал кнопке,для отображения нужной позиции инверсивно
        }
        onOpened: {//Если боковая панель открылась, то...
            lsvInstrukcii.forceActiveFocus()//Делаем фокус на списке, чтоб листался список.
        }
        Rectangle {//Прямоугольник узкой полоски интерфейса справа
            id: rctBorder
            anchors.top: drwSidebar.top
            x: drwSidebar.width-root.ntCoff
            width: root.ntCoff
            height: drwSidebar.height
            color: root.clrPolzunka
        }
        Rectangle {//Прямоугольник заголовка, для информации и кнопки закрыть.
            id: rctZagolovok
            anchors.top: drwSidebar.top
            anchors.right: rctBorder.left
            width: drwSidebar.width - rctBorder.width - rctRuchka.width
            height: root.ntCoff*(root.ntWidth-1)+root.ntCoff
            color: root.clrFona
            border.color: root.clrTexta
            border.width: root.ntCoff/4
            DCKnopkaZakrit {
                id: knopkaZakrit
                ntWidth: (root.ntWidth-1)
                ntCoff: root.ntCoff
                visible: true
                anchors.verticalCenter: rctZagolovok.verticalCenter
                anchors.right: rctZagolovok.right
                clrKnopki: root.clrTexta
                clrFona: root.clrFona
                tapHeight: (root.ntWidth-1)*root.ntCoff+root.ntCoff
                tapWidth: tapHeight
                onClicked: drwSidebar.close();//Метод обрабатывающий кнопку Закрыть боковую панель.
            }
            Label {//Текст вписанный в границы, отображает имя заголовка.
                id: lblZagolovok
                anchors.top: rctZagolovok.top
                anchors.right: knopkaZakrit.left
                width: drwSidebar.width - rctBorder.width - rctRuchka.width - knopkaZakrit.width
                height: rctZagolovok.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: root.clrTexta
                //font.capitalization: Font.AllUppercase//СЛОВА ЗАГЛАВНЫМИ БУКВАМИ
                font.bold: true//Жирный текст.
                font.pixelSize: root.ntCoff*(root.ntWidth-1)
                elide: Text.ElideRight//Обрезаем текст по правой стороне точками (...)
                text: qsTr("Инструкции")
            }
        }
        Rectangle {//Прямоугольник всей оставшейся боковой панели.
            id: rctSidebar
            anchors.top: rctZagolovok.bottom
            anchors.right: rctBorder.left
            width: drwSidebar.width - rctBorder.width - rctRuchka.width
            height: drwSidebar.height-rctZagolovok.height
            color: root.clrFona
            clip: true//Обязательно обрезать всё, что не помещается в этот прямоугольник.
            ListView {
                id: lsvInstrukcii
                anchors.fill: rctSidebar
                model: mdlInstrukcii
                focus: true//ListView должен получать фокус
                clip: true
                keyNavigationEnabled: true//разрешаем стандартную навигацию
                currentIndex: -1//начальное значение — ничего не выбрано
                delegate: Rectangle {
                    //Свойства
                    readonly property color clrRow: (index % 2 === 0)
                                                    ? root.clrFona
                                                    : Qt.tint(root.clrFona, Qt.rgba(1, 1, 1, 0.22))
                    //Настройки
                    width: lsvInstrukcii.width - (srbVertical.visible ? srbVertical.width : 0)
                    height: txtInstrukciya.font.pixelSize + root.ntCoff
                    color: (lsvInstrukcii.currentIndex === index) ? root.clrPolzunka : clrRow
                    Text {
                        id: txtInstrukciya
                        anchors.fill: parent
                        anchors.leftMargin: root.ntCoff
                        anchors.rightMargin: root.ntCoff
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        color: (lsvInstrukcii.currentIndex === index) ? root.clrFona : root.clrTexta
                        font.pixelSize: (root.ntWidth<=2) ? root.ntCoff*(root.ntWidth-1)
                                                          : root.ntCoff*(root.ntWidth-2)
                        text: title
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            lsvInstrukcii.currentIndex = index;//Присваемваем индекс выбранного элемента.
                            fnInstrukciya(key)//Функция загружающая заголовок и инструкцию по ключу.
                        }
                    }
                }
                Keys.onPressed: (event) => {//Обработка клавиш на уровне ListView
                    if(event.modifiers & Qt.ControlModifier){//Если нажат "Ctrl"
                        if (event.key === Qt.Key_B){//Если нажата клавиша В, то...
                            fnClickedSidebar();//Функция открытия/закрытия боковой панели.
                            event.accepted = true;//Завершаем обработку эвента.
                        }
                    } else {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (currentIndex !== -1) {
                                const cnKluch = mdlInstrukcii.get(currentIndex).key
                                fnInstrukciya(cnKluch)//Функция загружающая заголовок и инструкцию по ключу.
                            }
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up){//Если нажата стрелка вниз, то...
                            decrementCurrentIndex();//Убавляем от индекса.
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down){//Если нажата стрелка вверх, то...
                            incrementCurrentIndex()//Прибавляем к индексу.
                            event.accepted = true
                        } else if (event.key === Qt.Key_F1){//Если нажата F1, то...
                            fnClickedSidebar();//Функция открытия/закрытия боковой панели.
                            event.accepted = true
                        }
                    }
                }
                ScrollBar.vertical: ScrollBar {//Вертикальный скролл бар.
                    id: srbVertical
                    policy: ScrollBar.AsNeeded
                }
            }
            ListModel {//Список всех инструкций: ключ, название, заголовок)
                id: mdlInstrukcii
                ListElement { key: "hotkey"; title: "Горячие клавиши"; zagolovok: "ГОРЯЧИЕ КЛАВИШИ" }
                ListElement { key: "analiz"; title: "Анализ документов"; zagolovok: "ИНСТРУКЦИЯ ПО АНАЛИЗУ ДОКУМЕНТОВ" }
                ListElement { key: "menu"; title: "Меню"; zagolovok: "ОПИСАНИЕ НАСТРОЕК МЕНЮ" }
                ListElement { key: "oprilojenii"; title: "О приложении"; zagolovok: "О ПРИЛОЖЕНИИ" }
                ListElement { key: "oqt"; title: "О Qt"; zagolovok: "О QT" }
                ListElement { key: "filedialog"; title: "Проводник"; zagolovok: "ИНСТРУКЦИЯ ПО ПРОВОДНИКУ" }
                ListElement { key: "katalog"; title: "Каталог документов";
                                                    zagolovok: "ИНСТРУКЦИЯ ПО СОЗДАНИЮ КАТАЛОГА ДОКУМЕНТОВ" }
                ListElement { key: "jurnal"; title: "Журнал"; zagolovok: "ИНСТРУКЦИЯ ПО ЖУРНАЛУ" }
                ListElement { key: "animaciya"; title: "Анимация"; zagolovok: "ИНСТРУКЦИЯ ПО АНИМАЦИИ" }
            }
        }
        Rectangle {//Прямоугольник ручки, за которую можно тянуть размер боковой панели, для изменения её размеров
            id: rctRuchka
            anchors.top: drwSidebar.top
            anchors.right: rctSidebar.left
            width: (root.ntWidth < 3) ? 3 : root.ntWidth//В зависимости от параметра, изменяется толщина ручки.
            height: drwSidebar.height
            color: Qt.darker(root.clrTexta, 1.3)
            border.color: root.clrTexta
            border.width: (root.ntWidth < 5) ? 1 : root.ntCoff/4//Чтоб была видна оконтовка ручки.
            MouseArea {
                id: maRuchka
                //Свойства
                property bool isDrag: false//Свойство перетаскивания. true - началось перетаскивание.
                property real lastX//Переменная хранящаа предыдущее положение мыши
                //Настройки
                anchors.fill: rctRuchka
                hoverEnabled: true//При наведении изменение
                cursorShape: Qt.SizeHorCursor//Курсор в виде изменения горизонтального размера.
                //Функции
                onPressed: (mouse) => {//Если нажали на ручку
                    if (root.isMobile) return//Если мобильное устройство, то выходим
                    drwSidebar.interactive = false;//Отключаем свайп Drawer. ВАЖНО!
                    isDrag = true//Взводим флаг при нажатии на ручку, идёт изменение размеров.
                    lastX = mouse.x//Запоминаем первоначальное положение боковой панели по координатам мыши.
                    mouse.accepted = true//Завершаем обработку эвента.
                }
                onReleased: {//Если отпустили кнопку мышки
                    drwSidebar.interactive = true;//Включаем свайп Drawer. ВАЖНО!
                    isDrag = false//При отпускании мыши Окончание перетаскивания
                    //cppqml.untInstrukciyaWidth = drwSidebar.sidebarWidth//Записываем в реестр ширину панели.
                }
                onCanceled: {
                    drwSidebar.interactive = true;//Включаем свайп Drawer. ВАЖНО!
                    isDrag = false//Окончание перетаскивания
                    //cppqml.untInstrukciyaWidth = drwSidebar.sidebarWidth//Записываем в реестр ширину панели.
                }
                onPositionChanged: (mouse) => {//Если позиция меняется, то...
                    if (!isDrag || root.isMobile) return//Если не перетаскиваем ручку или мобильное устройство,вых
                    const dX = mouse.x - lastX//Дельта Х относительно предыдущей точки Х
                    lastX = mouse.x//Запоминаем положение мыши по Х.
                    if (dX === 0) return//Если дельта не изменилась, ничего не делаем
                    let ltWidth = drwSidebar.sidebarWidth - dX//Новые размеры ширины боковой панели.
                    ltWidth=Math.max(drwSidebar.minSidebarWidth,Math.min(drwSidebar.maxSidebarWidth, ltWidth))
                    drwSidebar.sidebarWidth = ltWidth//Изменяем ширину боковой панели на новую ширину
                }
            }
        }
        Rectangle {//Оконтовка поверх всех прямоугольников
            anchors.top: drwSidebar.top
            anchors.right: rctSidebar.right
            height: drwSidebar.height
            width: rctSidebar.width
            color: "transparent"
            border.color: root.clrTexta
            border.width: root.ntCoff/4
        }
    }
    onStrInstrukciyaChanged: {//Если переменная поменялась, то...
        fnInstrukciya(root.strInstrukciya)//Функция загружающая заголовок и инструкцию по ключу.
    }
    Component.onCompleted: {//Когда страница отрисовалась, то...
        fnInstrukciya(root.strInstrukciya)//Функция загружающая заголовок и инструкцию по ключу.
		txdZona.fnFocus()//Фокусируем, для листания инструкции по горячим клавишам.
    }
    function fnInstrukciya(strKluch){//Функция загружающая заголовок и инструкцию по ключу.
        root.strInstrukciya = strKluch
        for (var vrShag = 0; vrShag < mdlInstrukcii.count; ++vrShag){//Цикл перебора модели.
            if(mdlInstrukcii.get(vrShag).key === strKluch){//Если есть равенство с ключом, то...
                root.signalZagolovok(mdlInstrukcii.get(vrShag).zagolovok)//передаём заголовок в заголовок.
                lsvInstrukcii.currentIndex = vrShag;//Подсвечиваем в списке.
            }
        }
        if (root.isMobile) drwSidebar.close()//Если мобильное устройство, то закрываем боковую панель.
        if (strKluch === "oprilojenii"){//Если это анотация Об приложении Любимая КОБзона, то...
            //Любые пробелы и табы в тексте отобразятся в приложении.
			txdZona.text = qsTr("
				<html>
					<body>
<p><center><font color=\"white\">.<img src = \"qrc:/resources/images/logo_small.png\">.</font></center></p>
<p><center>Приложение: <b>Любимая КОБзона</b></center></p>
<p><center>Версия: <b>")+ Qt.application.version + qsTr("</b></center></p>
<p><center>Сайт: <a href=\"https://vk.ru/druidcat\">DruidCat</a></center></p>
<p><center>Приложение использует Qt ") + root.qtVersion + qsTr("</b></center></p>
<p><center>Приложение использует Python ") + root.pythonVersion + qsTr("</b></center></p>
<p><center>Приложение использует LM Studio для работы с языковыми моделями</b></center></p>
<p><center>Лицензия: <b>GPLv3</b></center></p>
<p><center>Git URL: <a href=\"https://github.com/DruidCat/pyqt-kobzone\">\
github.com/DruidCat/pyqt-kobzone</a></center></p>
<p><center>Адресс электронной почты: <a href=\"mailto:druidcat@yandex.ru\">druidcat@yandex.ru</a></center></p>
<p><center>&copy;2026. Разработчик <b>Синебрюхов Сергей Владимирович</b></center></p>
<p><center><b>Доверь рутинную работу нейросети. Высвободи в своей жизни время, чтоб сделать на самом деле \
что то важное в своей жизни!</b></center></p>
<p>Распознавайте аудиозаписи ваших разговоров, встреч, лекций, выступлений, переводя их в текст. Используйте \
для этого инструмент ТРАНСКРИБАЦИЯ.</p>
<p>Чтоб отредактировать неверно распознанный текс нейросетью, используйте инструмент ИСПРАВЛЕНИЕ ТЕКСТА.</p>
<p>Для анализа текстов используйте инструмент НЕЙРО АНАЛИЗ ДОКУМЕНТОВ. Задавай конкретные вопросы нейросети. \
И она проанализирует документы и выдаст ту информацию, которая лично вам необходима.</p>
<p>От разработки и создания данного приложения мной было получено огромное удовольствие. Надеюсь оно вам \
понравится, и принесёт пользу.</p>
					</body>
                </html>"
            );
        } else if(strKluch === "filedialog"){//Если это Инструкция Проводника, то...
            txdZona.text = qsTr("
                <html>
                    <body>
<p>В Проводнике выбирайте PDF документы, которые хотите добавить или открыть в приложение.</p>
<p>Навигация в проводнике возможна в пределах вашей дамашней дериктории. Если документы расположены в другой \
дериктории или на другом накопителе, то заранее переместите их в домашнюю дерикторию.</p>
<p><b>ФУНКЦИОНАЛ:</b></p>
<ol>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaNazad.png\"> - Вернуться в предыдущую папку.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaZakrit.png\"> - Закрыть ваш проводник.</p>
<ol>
<p>или</p>
</ol>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaOk.png\"> - Выбрать папку.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaNastroiki.png\"> - Меню вашего проводника.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaInfo.png\"> - Инструкция по проводнику.</p>
<p><b>[..]</b> - Вернуться в предыдущую папку.</p>
<p><b>[папка]</b> - Квадратными скобками обозначаются папки.</p>
<p><b>док.pdf</b> - Документ который можно добавить или открыть в приложение.</p>
</ol>
                    </body>
                </html>"
            );
        } else if(strKluch === "oqt"){
            txdZona.text = qsTr("
                <html>
                    <body>
<p><center><img src = \"qrc:/resources/images/Qt_logo_2016.png\"></center></p>
<p>This program uses Qt version ") + root.qtVersion + qsTr(".</p>
<p>Qt is a C++ toolkit for cross-platform application development.</p>
<p>Qt provides single-source portability across all major desktop operating systems. It is also available \
for embedded Linux and other embedded and mobile operating systems.</p>
<p>Qt is available under multiple licensing options designed to accommodate the needs of our various \
users.</p>
<p>Qt licensed under our commercial license agreement is appropriate for development of \
proprietary/commercial software where you do not want to share any source code with third parties or \
otherwise cannot comply with the terms of GNU (L)GPL.</p>
<p>Qt licensed under GNU (L)GPL is appropriate for the development of Qt applications provided you can \
comply with the terms and conditions of the respective licenses.</p>
<p>Please see <a href=\"http://qt.io/licensing/\">qt.io/licensing</a> for an overview of Qt licensing.</p>
<p>Copyright (C) 2025 The Qt Company Ltd and other contributors.</p>
<p>Qt and the Qt logo are trademarks of The Qt Company Ltd.</p>
<p>Qt is The Qt Company Ltd product developed as an open source project. \
See <a href=\"http://qt.io\">qt.io</a> for more information.</p>
                    </body>
                </html>"
            );
        } else if(strKluch === "animaciya"){
            txdZona.text = qsTr("
                <html>
                    <body>
<p>Данная страница необходима для создания анимированных заставок обучающих роликов.</p>
<p>Введёный вами текск будет увеличиваться вместе с логотипом компании. Данную анимацию можно снять \
приложением захвата экрана, например ShareX. И добавить на этапе монтажа в обучающий ролик.</p>
<p><b>ФУНКЦИОНАЛ:</b></p>
<ol>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaNazad.png\"> - Вернуться в Меню программы Ментор.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaInfo.png\"> - Инструкция по анимации.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaSozdat.png\"> - Добавить текст, который будет увеличиваться \
с логотипом.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaNastroiki.png\"> - Меню анимации.</p>
</ol>
<p><b>ГОРЯЧИЕ КЛАВИШИ:</b></p>
<ol>
<p><b>[Alt Стрелка влево]</b> - Закрыть окно анимации.</p>
<p><b>[F1]</b> - Инструкция.</p>
<p><b>[Ctrl N]</b> или <b>[Shift I]</b> - Режим добавления текста анимации.</p>
<p><b>[Ctrl S]</b> или <b>[Enter]</b> - Сохранить текст анимации.</p>
<p><b>[Пробел]</b> - Старт анимации.</p>
<p><b>[Escape]</b> - Отмена действия.</p>
</ol>
<p><b>МЕНЮ:</b></p>
<ol>
<p><b>[Добавить]</b> - Добавить текс, который будет увеличиваться с логотипом.</p>
<p><b>[Старт]</b> - Старт анимации.</p>
<p><b>[Без рамки]</b> - Без рамки.</p>
<p><b>[Рамка 16:9]</b> - Показ рамки для съёмки видео в пропорции экрана 16:9.</p>
<p><b>[Закрыть]</b> - Закрыть приложение Ментор.</p>
</ol>
                    </body>
                </html>"
            );
        } else if(strKluch === "hotkey"){
            txdZona.text = qsTr("
                <html>
                    <body>
<p><b>МЕНТОР:</b></p>
<ol>
<p><b>[F1]</b> - Описание.</p>
<p><b>[Alt F]</b> или <b>[Alt Стрелка влево]</b> - Настройки.</p>
<p><b>[Alt Стрелка влево]</b> - Нажитие кнопки влево.</p>
<p><b>[Alt Стрелка вправо]</b> - Нажитие кнопки вправо.</p>
<p><b>[Стрелка вверх]</b> или <b>[K]</b> - Листание списка вверх.</p>
<p><b>[Стрелка вниз]</b> или <b>[J]</b> - Листание списка вниз.</p>
<p><b>[PgUp]</b> - Листание страницы вверх.</p>
<p><b>[PgDn]</b> - Листание страницы вниз.</p>
<p><b>[Home]</b> - Переход на первыю страницу.</p>
<p><b>[End]</b> - Переход на последнюю страницу.</p>
<p><b>[Enter]</b> или <b>[Пробел]</b> - Выбор элемента.</p>
<p><b>[Ctrl N]</b> или <b>[Shift I]</b> - Создать новый элемент.</p>
<p><b>[Ctrl S]</b> или <b>[Enter]</b> - Сохранить изменения в элементе.</p>
<p><b>[Escape]</b> - Отмена действия.</p>
</ol>
<p><b>ПРОСМОТРЩИК ДОКУМЕНТОВ МЕНТОРPDF:</b></p>
<ol>
<p><b>[Alt Стрелка влево]</b> - Закрыть окно менторPDF.</p>
<p><b>[F1]</b> - Инструкция.</p>
<p><b>[PgUp]</b> - Страница вверх.</p>
<p><b>[PgDn]</b> - Страница вниз.</p>
<p><b>[Ctrl +]</b> - Масштаб увеличить.</p>
<p><b>[Ctrl -]</b> - Масштаб уменьшить.</p>
<p><b>[Ctrl F]</b> - Включить режим поиска.</p>
<p><b>[Ctrl S]</b> или <b>[Enter]</b> - Начать поиск.</p>
<p><b>[Escape]</b> - Отмена поиска.</p>
<p><b>[F3]</b> или <b>[Enter]</b> - Поиск следующий.</p>
<p><b>[Shift F3]</b> - Поиск предыдущий.</p>
<p><b>[Shift Ctrl +]</b> - Поворот документа по часовой стрелки.</p>
<p><b>[Shift Ctrl -]</b> - Поворот документа против часовой стрелки.</p>
<p><b>[Shift Ctrl N]</b> - Ввод номера страницы.</p>
<p><b>БОКОВАЯ ПАНЕЛЬ:</b></p>
<ol>
<p><b>[Ctrl T]</b> - Миниатюры страниц.</p>
<p><b>[Ctrl B]</b> - Закладки.</p>
<p><b>[Alt F]</b> - Результаты поиска.</p>
<p><b>[Стрелка вверх]</b> - Вверх по элементам страниц, закладок или найдено.</p>
<p><b>[Стрелка вниз]</b> - Вниз по элементам страниц, закладок или найдено.</p>
<p><b>[Enter]</b> или <b>[Пробел]</b> - Выбор элемента в страницах, закладках или найдено.</p>
<p><b>[Tab]</b> - Выбор вкладки страница, закладки или найдено.</p>
</ol>
</ol>
<p><b>ОПИСАНИЕ:</b></p>
<ol>
<p><b>[Ctrl F]</b> - Навигатор.</p>
<p><b>[Ctrl N]</b> или <b>[Shift I]</b> - Режим редактирования текста.</p>
<p><b>[Ctrl S]</b> - Сохранить изменения текста.</p>
<p><b>[Стрелка вверх]</b> или <b>[K]</b> - Листание текста вверх.</p>
<p><b>[Стрелка вниз]</b> или <b>[J]</b> - Листание текста вниз.</p>
<p><b>[PgUp]</b> - Страница вверх.</p>
<p><b>[PgDn]</b> - Страница вниз.</p>");
        } else if(strKluch === "menu"){
            txdZona.text = qsTr("
                <html>
                    <body>")
+ qsTr("<p><b>горячие клавиши</b></p>
<p>- описание всех горячих клавиш в приложении.</p>
<p><b>шрифт</b></p>
<p>- [маленький] размер шрифта.</p>
<p>- [средний] размер шрифта.</p>
<p>- [большой] размер шрифта.</p>")
+ qsTr("<p><b>о приложении</b></p>
<p>- краткая информация о приложении и его создатиле.</p>
<p><b>о Qt</b></p>
<p>- информация о фреймворке, на котором написано приложение.</p>");
        } else if(strKluch === "katalog"){
            txdZona.text = qsTr("
                <html>
                    <body>
<p>Данный функционал создаёт на устройстве структурированные папки с документами как в приложении.</p>
<p><b>Создать</b> или <img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaSozdat.png\"></p>
<p>- запускает создание каталога документов в заданной дерриктории.</p>
<p><b>Открыть папку</b></p>
<p>- открывает заданную деррикторию, в которой создастся или создался каталог с документами.</p>
<p><b>Задать папку сохранения</b></p>
<p>- задать деррикторию, в которой будет создаваться каталог с документами.</p>
<p><b>Информационное окно копирования</b></p>
<p>- во время создания каталога документов, можно посмотреть, какие документы и куда скопировались.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaInfo.png\"> - Инструкция по созданию каталога документов.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaNastroiki.png\"> - Меню создания каталогов.</p>
<p><b>ГОРЯЧИЕ КЛАВИШИ:</b></p>
<ol>
<p><b>[Ctrl N]</b> - Создать каталог документов.</p>
<p><b>[Стрелка вверх]</b> или <b>[K]</b> - Листание текста вверх.</p>
<p><b>[Стрелка вниз]</b> или <b>[J]</b> - Листание текста вниз.</p>
<p><b>[PgUp]</b> - Страница вверх.</p>
<p><b>[PgDn]</b> - Страница вниз.</p>
<p><b>[Escape]</b> - Отмена создания каталога.</p>
</ol>
                    </body>
                </html>"
            );
        } else if(strKluch === "jurnal"){//Если это Инструкция Журнал, то...
            txdZona.text = qsTr("
                <html>
                    <body>
<p>В журнале отображаются ошибки, которые возникли при работе приложения.</p>
<p>Так же в журнале фиксируются действия пользователя, такие как создание, переименование или удаление \
каталогов. Добавление, переименование, удаление или открытие документов.</p>
<p>Данная активность записывается и в дальнейшем может быть просмотрена в журнале для анализа.</p>
<p><b>ФУНКЦИОНАЛ:</b></p>
<ol>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaNazad.png\"> - Выйти из журнала.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaInfo.png\"> - Инструкция о журнале.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaPoisk.png\"> - Показать данные журнала за:</p>
<ol>
<p><b>[Неделя]</b> - Отображение 7 дней активности пользователя.</p>
<p><b>[Месяц]</b> - Отображение 30 дней активности пользователя.</p>
<p><b>[Год]</b> - Отображение 365 дней активности пользователя.</p>
</ol>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaNastroiki.png\"> - Меню журнала.</p>
</ol>
<p><b>ГОРЯЧИЕ КЛАВИШИ:</b></p>
<ol>
<p><b>[F1]</b> - Инструкция.</p>
<p><b>[Alt Стрелка влево]</b> - Закрыть журнал.</p>
<p><b>[Ctrl F]</b> - Сортировка по неделе, месяцу, году:</p>
<ol>
<p><b>[Стрелка вверх]</b> - Листание элементов сортировки.</p>
<p><b>[Стрелка вниз]</b> - Листание элементов сортировки.</p>
<p><b>[Enter]</b> - Выбор элемента сортировки.</p>
<p><b>[Escape]</b> - Закрыть карусель сортировки.</p>
</ol>
</ol>
                    </body>
                </html>"
            );
        } else if(strKluch === "analiz"){//Если это Инструкция по Анализу Документов, то...
            txdZona.text = qsTr("
                <html>
                    <body>
<p>В менторPDF отображаются документы формата pdf. Которые можно листать, изменять масштаб и вести поиск.</p>
<p><b>ФУНКЦИОНАЛ:</b></p>
<ol>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaNazad.png\"> - Выйти из документа.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaSidebar_2.png\"> - Боковую панель закрыть.</p>
<ol>
<p>или</p>
</ol>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaSidebar.png\"> - Боковую панель открыть, где:</p>
<ol>
    <p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaInfo.png\"> - Инструкция для менторPDF.</p>
    <p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaZakrit.png\"> - Закрыть боковую панель.</p>
    <p><b>[Страницы]</b> - Миниатюры страниц документа.</p>
    <p><b>[Закладки]</b> - Закладки документа, если они существуют.</p>
    <p><b>[Найдено]</b> - Результаты поиска по документу.</p>
</ol>
<p>НАЗВАНИЕ ДОКУМЕНТА - название открытого документа.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaPovorotPo.png\"> - Поворот документа по часовой стрелке.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaPovorotProtiv.png\"> - Поворот документа против часовой \
стрелки.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaPoisk.png\"> - Поиск по документу.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaMinus.png\">НОМЕР СТРАНИЦЫ \
<img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaPlus.png\"> - Номер открытой страницы, который можно изменить \
кнопками плюс или минус. Или ввести нужную страницу и нажать Enter.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaMinus_2.png\">МАСШТАБ%\
<img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaPlus_2.png\"> - Масштаб открытого документа, который можно \
изменить вручную.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaVidelit_2.png\"> - Перемещение мышкой pdf документа.</p>
<p><img src = \"qrc:/resources/images/DCButtons/24x24/DCKnopkaVidelit_1.png\"> - Выделение текста в pdf документе.</p>
<p><b>Навигация по документу</b></p>
<ol>
    <p><b>[Стрелки]</b> - Перемещение по странице документа.</p>
    <p><b>[PgUp]</b> - Переход на страницу вверх.</p>
    <p><b>[PgDn]</b> - Переход на страницу вниз.</p>
    <p><b>[Home]</b> - Переход в начало документа.</p>
    <p><b>[End]</b> - Переход на конец документа.</p>
</ol>
</ol>
                    </body>
                </html>"
            );
        }
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
//<ol>строки или строка, которые будут с отступом tab.</ol>
//<a href=\"http://ya.ru\">Яндекс</a> - форма записи ссылок.
//<p><img src = \"qrc:/resources/images/Qt_logo_2016.png\"></p> - Вставка изображения
//<p><center>.<img src = \"images/Qt_logo_2016.png\"></center></p> - Изображение по центру (поставь точку).
//&lt; - это символ <
//&gt; - это символ >
