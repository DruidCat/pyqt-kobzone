import QtQuick

// DCMarkdown.qml - компонент для конвертации Markdown в HTML
QtObject {
    id: root
    
    function toHtml(markdown) {
        if (!markdown) return ""
        
        // ✅ ЗАЩИТА ОТ "ЛЕСЕНКИ" — очищаем лишние пробелы/табуляции в начале и конце
        let html = markdown.trim()
        
        // ========== ШАГ 0: ЭКРАНИРОВАНИЕ HTML (защита от XSS) ==========
        // Сохраняем блоки кода отдельно, чтобы не экранировать их содержимое
        let codeBlocks = []
        let codeBlockPlaceholder = "___CODE_BLOCK_PLACEHOLDER___"
        
        // Временно заменяем блоки кода на плейсхолдеры
        html = html.replace(/```([\s\S]+?)```/g, function(match, code) {
            codeBlocks.push(code)
            return codeBlockPlaceholder + (codeBlocks.length - 1) + codeBlockPlaceholder
        })
        
        // ========== ШАГ 1: ЗАГОЛОВКИ (обрабатываем ПЕРЕД жирным текстом!) ==========
        // ### Заголовок ИЛИ ###Заголовок (с пробелом и без)
        // Также поддерживает: # a. Текст, # 1. Текст
        html = html.replace(/^#### ?(.+)$/gm, '<h4 style="color: #2d4288; margin-top: 12px; margin-bottom: 6px; font-size: 1.1em;">$1</h4>')
        html = html.replace(/^### ?(.+)$/gm, '<h3 style="color: #2d4288; margin-top: 16px; margin-bottom: 8px; font-size: 1.3em;">$1</h3>')
        html = html.replace(/^## ?(.+)$/gm, '<h2 style="color: #2d4288; margin-top: 20px; margin-bottom: 10px; font-size: 1.5em;">$1</h2>')
        html = html.replace(/^# ?(.+)$/gm, '<h1 style="color: #2d4288; margin-top: 24px; margin-bottom: 12px; font-size: 1.8em;">$1</h1>')
        
        // ========== ШАГ 2: БЛОКИ КОДА (восстанавливаем из плейсхолдеров) ==========
        html = html.replace(new RegExp(codeBlockPlaceholder + "(\\d+)" + codeBlockPlaceholder, "g"), function(match, index) {
            let code = codeBlocks[parseInt(index)]
            
            // Проверяем, указан ли язык (например, ```python)
            let language = ""
            let codeContent = code
            
            let firstLine = code.split('\n')[0].trim()
            if (firstLine && !firstLine.includes(' ') && firstLine.length < 20) {
                language = firstLine
                codeContent = code.substring(code.indexOf('\n') + 1)
            }
            
            // Экранируем HTML внутри кода
            codeContent = codeContent
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
            
            let langLabel = language ? `<span style="font-size: 0.8em; color: #666; display: block; margin-bottom: 4px;">${language}</span>` : ""
            
            return '<pre style="background-color: #f5f5f5; padding: 12px; border-radius: 6px; overflow-x: auto; margin: 12px 0; border-left: 4px solid #2d4288;">' +
                   langLabel +
                   '<code style="color: #333; font-family: \'Courier New\', monospace; font-size: 0.9em;">' + codeContent + '</code></pre>'
        })
        
        // ========== ШАГ 3: ЖИРНЫЙ ТЕКСТ ==========
        // **текст** → <b>текст</b>
        html = html.replace(/\*\*(.+?)\*\*/g, '<b style="color: #1a237e; font-weight: 600;">$1</b>')
        
        // ========== ШАГ 4: КУРСИВ ==========
        // *текст* → <i>текст</i>
        html = html.replace(/\*(.+?)\*/g, '<i style="color: #424242;">$1</i>')
        
        // ========== ШАГ 5: ЗАЧЁРКНУТЫЙ ==========
        // ~~текст~~ → <s>текст</s>
        html = html.replace(/~~(.+?)~~/g, '<s style="color: #757575;">$1</s>')
        
        // ========== ШАГ 6: ПОДЧЁРКНУТЫЙ (опционально) ==========
        // __текст__ → <u>текст</u>
        html = html.replace(/__(.+?)__/g, '<u style="color: #1a237e;">$1</u>')
        
        // ========== ШАГ 7: ИНЛАЙН КОД ==========
        // `код` → <code>код</code>
        html = html.replace(/`(.+?)`/g, function(match, code) {
            // Экранируем HTML
            code = code.replace(/</g, '&lt;').replace(/>/g, '&gt;')
            return '<code style="background-color: #f5f5f5; padding: 2px 6px; border-radius: 3px; color: #c7254e; font-family: \'Courier New\', monospace; font-size: 0.9em;">' + code + '</code>'
        })
        
        // ========== ШАГ 8: СПИСКИ (поддержка - и *) ==========
        // - элемент ИЛИ * элемент → <li>элемент</li>
        html = html.replace(/^[*\-+] (.+)$/gm, '<li style="margin-bottom: 4px;">$1</li>')
        
        // Группируем <li> в <ul>
        html = html.replace(/(<li[^>]*>.*?<\/li>\n?)+/g, function(match) {
            // Проверяем, не обёрнуто ли уже
            if (match.includes('<ul>') || match.includes('<ol>')) return match
            return '<ul style="margin-left: 24px; margin-top: 8px; margin-bottom: 8px; padding-left: 0; list-style-type: disc;">' + match + '</ul>'
        })
        
        // ========== ШАГ 9: НУМЕРОВАННЫЕ СПИСКИ ==========
        // 1. элемент → <li>элемент</li>
        html = html.replace(/^\d+\. (.+)$/gm, '<li style="margin-bottom: 4px;">$1</li>')
        
        // Группируем <li> в <ol> (только если ещё не обёрнуто в <ul>)
        html = html.replace(/(<li[^>]*>.*?<\/li>\n?)+/g, function(match) {
            if (match.includes('<ul>') || match.includes('<ol>')) return match
            return '<ol style="margin-left: 24px; margin-top: 8px; margin-bottom: 8px; padding-left: 0;">' + match + '</ol>'
        })
        
        // ========== ШАГ 10: ЦИТАТЫ ==========
        // > текст → <blockquote>текст</blockquote>
        html = html.replace(/^> (.+)$/gm, '<blockquote style="border-left: 4px solid #2d4288; padding-left: 12px; margin-left: 0; margin-right: 0; color: #666; margin-top: 8px; margin-bottom: 8px; font-style: italic; background-color: #f9f9f9; padding: 8px 12px; border-radius: 4px;">$1</blockquote>')
        
        // ========== ШАГ 11: ГОРИЗОНТАЛЬНАЯ ЛИНИЯ ==========
        // --- или *** или ___ → <hr>
        html = html.replace(/^(\*\*\*|---|___)$/gm, '<hr style="border: none; border-top: 2px solid #e0e0e0; margin: 20px 0;">')
        
        // ========== ШАГ 12: ССЫЛКИ ==========
        // [текст](url) → <a href="url">текст</a>
        html = html.replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2" style="color: #2196F3; text-decoration: underline;">$1</a>')
        
        // ========== ШАГ 13: ИЗОБРАЖЕНИЯ (опционально) ==========
        // ![alt](url) → <img src="url" alt="alt">
        html = html.replace(/!\[(.+?)\]\((.+?)\)/g, '<img src="$2" alt="$1" style="max-width: 100%; height: auto; border-radius: 8px; margin: 12px 0;">')
        
        // ========== ШАГ 14: ТАБЛИЦЫ ==========
        // | Заголовок 1 | Заголовок 2 |
        // |-------------|-------------|
        // | Ячейка 1    | Ячейка 2    |
        html = html.replace(/(\|.+\|\n)+/g, function(match) {
            let rows = match.trim().split('\n')
            if (rows.length < 2) return match
            
            let tableHtml = '<table style="border-collapse: collapse; width: 100%; margin: 12px 0;">'
            
            // Заголовок
            let headerCells = rows[0].split('|').filter(cell => cell.trim())
            tableHtml += '<thead><tr style="background-color: #f5f5f5;">'
            headerCells.forEach(cell => {
                tableHtml += '<th style="border: 1px solid #ddd; padding: 8px; text-align: left; font-weight: 600;">' + cell.trim() + '</th>'
            })
            tableHtml += '</tr></thead>'
            
            // Проверяем, есть ли строка-разделитель (|---|---|)
            let startRow = 1
            if (rows[1] && rows[1].includes('---')) {
                startRow = 2
            }
            
            // Тело таблицы
            tableHtml += '<tbody>'
            for (let i = startRow; i < rows.length; i++) {
                let cells = rows[i].split('|').filter(cell => cell.trim())
                if (cells.length === 0) continue
                
                tableHtml += '<tr>'
                cells.forEach(cell => {
                    tableHtml += '<td style="border: 1px solid #ddd; padding: 8px;">' + cell.trim() + '</td>'
                })
                tableHtml += '</tr>'
            }
            tableHtml += '</tbody></table>'
            
            return tableHtml
        })
        
        // ========== ШАГ 15: EMOJI (базовый набор) ==========
        const emojiMap = {
            ':smile:': '😊',
            ':grin:': '😁',
            ':wink:': '😉',
            ':fire:': '🔥',
            ':heart:': '❤️',
            ':check:': '✅',
            ':cross:': '❌',
            ':star:': '⭐',
            ':warning:': '⚠️',
            ':info:': 'ℹ️',
            ':bulb:': '💡',
            ':rocket:': '🚀',
            ':tada:': '🎉',
            ':thumbsup:': '👍',
            ':thumbsdown:': '👎',
            ':eyes:': '👀',
            ':thinking:': '🤔',
            ':muscle:': '💪',
            ':brain:': '🧠',
            ':book:': '📖',
            ':memo:': '📝',
            ':computer:': '💻',
            ':hourglass:': '⏳',
            ':clock:': '🕐'
        }
        
        for (let emoji in emojiMap) {
            html = html.replace(new RegExp(emoji.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&'), 'g'), emojiMap[emoji])
        }
        
        // ========== ШАГ 16: ПЕРЕНОСЫ СТРОК ==========
        // Двойной перенос → <br><br>
        html = html.replace(/\n\n/g, '<br><br>')
        
        // Одинарный перенос → <br> (для корректного отображения списков)
        html = html.replace(/\n/g, '<br>')
        
        // ========== ШАГ 17: ОЧИСТКА ЛИШНИХ <br> ==========
        // Убираем <br> перед закрывающими тегами блочных элементов
        html = html.replace(/<br>(\s*<\/(h[1-6]|ul|ol|li|blockquote|pre|div|table|tr|td|th)>)/g, '$1')
        
        // Убираем <br> после открывающих тегов блочных элементов
        html = html.replace(/(<(h[1-6]|ul|ol|li|blockquote|pre|div|table|tr|td|th)[^>]*>)\s*<br>/g, '$1')
        
        // ✅ ЗАЩИТА ОТ "ЛЕСЕНКИ" — обёртываем в <div> с сбросом отступов
        return '<div style="margin: 0; padding: 0; line-height: 1.6; font-family: system-ui, -apple-system, sans-serif;">' + html + '</div>'
    }
}
