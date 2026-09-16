import QtQuick
// DCMarkdown.qml - Markdown -> HTML совместимый с Qt RichText
QtObject {
    id: root

    function _escape(s) {
        return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    }

    function _splitRow(row) {
        var t = row.trim()
        if (t.charAt(0) === '|') t = t.substring(1)
        if (t.length > 0 && t.charAt(t.length - 1) === '|') t = t.substring(0, t.length - 1)
        var parts = t.split('|')
        var out = []
        for (var i = 0; i < parts.length; i++) out.push(parts[i].trim())
        return out
    }

    function _inline(t) {
        if (!t) return ""
        // 1. защитить инлайн-код
        var codes = []
        t = t.replace(/`([^`\n]+?)`/g, function(m, c) {
            codes.push(c)
            return "␁" + (codes.length - 1) + "␁"
        })
        // 2. экранировать
        t = t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
        // 3. картинки ДО ссылок!
        t = t.replace(/!\[([^\]]*?)\]\(([^)\s]+?)\)/g, '<img src="$2" alt="$1" />')
        // 4. ссылки
        t = t.replace(/\[([^\]]+?)\]\(([^)\s]+?)\)/g, '<a href="$2" style="color:#2196F3;">$1</a>')
        // 5. жирный
        t = t.replace(/\*\*([^*\n]+?)\*\*/g, '<b style="color:#1a237e;">$1</b>')
        // 6. подчеркивание
        t = t.replace(/__([^_\n]+?)__/g, '<u>$1</u>')
        // 7. курсив (одиночный *)
        t = t.replace(/\*([^*\n]+?)\*/g, '<i>$1</i>')
        // 8. зачеркнутый
        t = t.replace(/~~([^~\n]+?)~~/g, '<s style="color:#757575;">$1</s>')
        // 9. emoji
        var emojiMap = {
            ':smile:': '😊', ':grin:': '😁', ':wink:': '😉', ':fire:': '🔥',
            ':heart:': '❤️', ':check:': '✅', ':cross:': '❌', ':star:': '⭐',
            ':warning:': '⚠️', ':info:': 'ℹ️', ':bulb:': '💡', ':rocket:': '🚀',
            ':tada:': '🎉', ':thumbsup:': '👍', ':thumbsdown:': '👎', ':eyes:': '👀',
            ':thinking:': '🤔', ':muscle:': '💪', ':brain:': '🧠', ':book:': '📖',
            ':memo:': '📝', ':computer:': '💻', ':hourglass:': '⏳', ':clock:': '🕐'
        }
        for (var k in emojiMap) {
            t = t.split(k).join(emojiMap[k])
        }
        // 10. вернуть инлайн-код
        t = t.replace(/␁(\d+)␁/g, function(m, idx) {
            var c = codes[parseInt(idx, 10)]
            c = c.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
            return '<code style="color:#c7254e; background-color:#f5f5f5;">' + c + '</code>'
        })
        return t
    }

    function _isListUl(s) { return /^[-*+]\s+.+/.test(s) }
    function _isListOl(s) { return /^\d+[\.\)]\s+.+/.test(s) }
    function _isLetter(s) { return /^[а-яА-ЯёЁa-zA-Z][\.\)]\s+.+/.test(s) }
    function _isBlock(s) {
        if (/^(#{1,4}\s|```|>)/.test(s)) return true
        if (/^(\*\*\*|---|___)\s*$/.test(s)) return true
        if (/^[-*+]\s+/.test(s)) return true
        if (/^\d+[\.\)]\s+/.test(s)) return true
        if (/^[а-яА-ЯёЁa-zA-Z][\.\)]\s+/.test(s)) return true
        return false
    }

    function toHtml(markdown) {
        if (!markdown) return ""
        var src = markdown.replace(/\r\n/g, '\n').replace(/\r/g, '\n').trim()
        if (src === "") return ""
        var lines = src.split('\n')
        var out = []
        var i = 0
        while (i < lines.length) {
            var line = lines[i]
            var tr = line.trim()
            // пустая строка - просто разделитель, НЕ <p></p>
            if (tr === "") { i++; continue }

            // код- fence
            if (tr.indexOf("```") === 0) {
                var lang = tr.substring(3).trim()
                var buf = []
                i++
                while (i < lines.length && lines[i].trim().indexOf("```") !== 0) { buf.push(lines[i]); i++ }
                i++ // закрывающий ```
                var code = _escape(buf.join('\n'))
                var label = lang !== "" ? '<div style="color:#666; font-size:small;">' + _escape(lang) + '</div>' : ""
                out.push('<pre style="background-color:#f5f5f5; margin-top:6px; margin-bottom:6px;">' + label + '<code>' + code + '</code></pre>')
                continue
            }
            // hr
            if (/^(\*\*\*|---|___)\s*$/.test(tr)) {
                out.push('<hr />'); i++; continue
            }
            // заголовки
            var mh = /^(#{1,4})\s*(.+)$/.exec(tr)
            if (mh) {
                var lv = mh[1].length
                out.push('<h' + lv + ' style="color:#2d4288; margin-top:10px; margin-bottom:4px;">' + _inline(mh[2]) + '</h' + lv + '>')
                i++; continue
            }
            // цитаты
            if (tr.charAt(0) === '>') {
                var qb = []
                while (i < lines.length && lines[i].trim().charAt(0) === '>') {
                    qb.push(lines[i].trim().replace(/^>\s?/, '')); i++
                }
                var qh = []
                for (var qi = 0; qi < qb.length; qi++) qh.push(_inline(qb[qi]))
                out.push('<blockquote style="color:#666; margin-top:6px; margin-bottom:6px; margin-left:8px;">' + qh.join('<br />') + '</blockquote>')
                continue
            }
            // таблицы
            if (tr.indexOf('|') !== -1 && (i + 1) < lines.length && lines[i+1].indexOf('-') !== -1 && /^\s*\|?[\s:\-|]+\|?\s*$/.test(lines[i+1])) {
                var head = _splitRow(tr)
                i += 2
                var rows = []
                while (i < lines.length && lines[i].indexOf('|') !== -1 && lines[i].trim() !== "") {
                    rows.push(_splitRow(lines[i].trim())); i++
                }
                var th = '<tr>'
                for (var hi = 0; hi < head.length; hi++) th += '<th style="background-color:#f0f0f0;">' + _inline(head[hi]) + '</th>'
                th += '</tr>'
                var tb = ''
                for (var ri = 0; ri < rows.length; ri++) {
                    tb += '<tr>'
                    for (var ci = 0; ci < rows[ri].length; ci++) tb += '<td>' + _inline(rows[ri][ci]) + '</td>'
                    tb += '</tr>'
                }
                out.push('<table border="1" cellspacing="0" cellpadding="6" width="100%">' + th + tb + '</table>')
                continue
            }
            // маркированный список - группируем, пустые строки внутри терпим
            if (_isListUl(tr)) {
                var items = []
                while (i < lines.length) {
                    var cur = lines[i]
                    var ctr = cur.trim()
                    if (ctr === "") {
                        var j = i + 1
                        while (j < lines.length && lines[j].trim() === "") j++
                        if (j < lines.length && _isListUl(lines[j].trim())) { i = j; continue }
                        else break
                    }
                    var mu = /^\s*[-*+]\s+(.+)$/.exec(cur)
                    if (mu) { items.push(mu[1]); i++ }
                    else break // смена типа (например 1.) - выходим, следующий блок разберет
                }
                var lis = ''
                for (var li = 0; li < items.length; li++) lis += '<li>' + _inline(items[li]) + '</li>'
                out.push('<ul style="margin-top:4px; margin-bottom:8px; margin-left:20px;">' + lis + '</ul>')
                continue
            }
            // нумерованный список - ТОЛЬКО цифры, буквы сюда не входят
            if (_isListOl(tr)) {
                var oitems = []
                while (i < lines.length) {
                    var cur2 = lines[i]
                    var ctr2 = cur2.trim()
                    if (ctr2 === "") {
                        var j2 = i + 1
                        while (j2 < lines.length && lines[j2].trim() === "") j2++
                        if (j2 < lines.length && _isListOl(lines[j2].trim())) { i = j2; continue }
                        else break
                    }
                    var mo = /^\s*\d+[\.\)]\s+(.+)$/.exec(cur2)
                    if (mo) { oitems.push(mo[1]); i++ }
                    else break
                }
                var olis = ''
                for (var oi = 0; oi < oitems.length; oi++) olis += '<li>' + _inline(oitems[oi]) + '</li>'
                out.push('<ol style="margin-top:4px; margin-bottom:8px; margin-left:20px;">' + olis + '</ol>')
                continue
            }
            // буквенная нумерация а) б) - это ЗАГОЛОВОК секции, а не буллет
            var ml = /^([а-яА-ЯёЁa-zA-Z])[\.\)]\s+(.+)$/.exec(tr)
            if (ml) {
                out.push('<p style="margin-top:10px; margin-bottom:4px;"><b>' + ml[1] + ') </b>' + _inline(ml[2]) + '</p>')
                i++; continue
            }
            // обычный параграф - клеим соседние строки через <br />
            var pb = [tr]
            i++
            while (i < lines.length) {
                var t2 = lines[i].trim()
                if (t2 === "") break
                if (_isBlock(t2)) break
                if (t2.indexOf('|') !== -1 && (i + 1) < lines.length && /---/.test(lines[i+1])) break
                pb.push(t2); i++
            }
            var ph = []
            for (var pi = 0; pi < pb.length; pi++) ph.push(_inline(pb[pi]))
            out.push('<p style="margin-top:6px; margin-bottom:4px;">' + ph.join('<br />') + '</p>')
        }
        return out.join('')
    }
}
