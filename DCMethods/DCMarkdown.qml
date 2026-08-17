import QtQuick
//DCMarkdown.qml - компонент для конвертации Markdown в HTML
QtObject {
	id: root
	function toHtml(markdown) {//Функция конвертации Markdown в HTML
		if (!markdown) return ""
		
		let html = markdown
		
		//Заголовки: ### Заголовок → <h3>Заголовок</h3>//Обрабатываем как с пробелом, и без: #Текст и # Текст
		html = html.replace(/^### ?(.+)$/gm, '<h3 style="color: #2d4288; margin-top: 16px; margin-bottom: 8px;">$1</h3>')
		html = html.replace(/^## ?(.+)$/gm, '<h2 style="color: #2d4288; margin-top: 20px; margin-bottom: 10px;">$1</h2>')
		html = html.replace(/^# ?(.+)$/gm, '<h1 style="color: #2d4288; margin-top: 24px; margin-bottom: 12px;">$1</h1>')
		
		//Жирный текст: **текст** → <b>текст</b>
		html = html.replace(/\*\*(.+?)\*\*/g, '<b style="color: #1a237e;">$1</b>')
		
		//Курсив: *текст* → <i>текст</i>
		html = html.replace(/\*(.+?)\*/g, '<i>$1</i>')
		
		//Зачёркнутый: ~~текст~~ → <s>текст</s>
		html = html.replace(/~~(.+?)~~/g, '<s>$1</s>')
		
		//Код: `код` → <code>код</code>
		html = html.replace(/`(.+?)`/g, '<code style="background-color: #f5f5f5; padding: 2px 4px; border-radius: 3px; color: #c7254e;">$1</code>')
		
		//Списки: - элемент → <ul><li>элемент</li></ul>
		html = html.replace(/^- (.+)$/gm, '<li>$1</li>')
		html = html.replace(/(<li>.*<\/li>\n?)+/g, '<ul style="margin-left: 20px;">$&</ul>')
		
		//Нумерованные списки: 1. элемент → <ol><li>элемент</li></ol>
		html = html.replace(/^\d+\. (.+)$/gm, '<li>$1</li>')
		html = html.replace(/(<li>.*<\/li>\n?)+/g, function(match) {
			if (match.includes('<ul>')) return match
			return '<ol style="margin-left: 20px;">' + match + '</ol>'
		})
		
		//Цитаты: > текст → <blockquote>текст</blockquote>
		html = html.replace(/^> (.+)$/gm, '<blockquote style="border-left: 4px solid #2d4288; padding-left: 12px; margin-left: 0; color: #666;">$1</blockquote>')
		
		//Горизонтальная линия: --- → <hr>
		html = html.replace(/^---$/gm, '<hr style="border: none; border-top: 2px solid #e0e0e0; margin: 16px 0;">')
		
		//Переносы строк: двойной перенос → <br><br>
		html = html.replace(/\n\n/g, '<br><br>')
		
		//Ссылки: [текст](url) → <a href="url">текст</a>
		html = html.replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2" style="color: #2196F3; text-decoration: underline;">$1</a>')
		
		return '<p style="margin: 0; line-height: 1.6;">' + html + '</p>'
	}
}
