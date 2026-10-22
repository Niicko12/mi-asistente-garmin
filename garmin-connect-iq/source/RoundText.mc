import Toybox.Graphics;
import Toybox.Lang;

// Texto para pantalla redonda. Las fuentes del fēnix 8 son grandes, así que
// en vez de recortar con "..." se parte por palabras en un ancho seguro
// dentro del círculo y se desplaza por líneas con UP/DOWN.
module RoundText {

    function wrap(dc as Dc, text as String, font as Graphics.FontType, maxWidth as Number) as Array<String> {
        var lines = [] as Array<String>;
        var chars = text.toCharArray();
        var line = "";
        var word = "";
        for (var i = 0; i <= chars.size(); i++) {
            var c = i < chars.size() ? chars[i] : '\n';
            if (c == ' ' || c == '\n') {
                // Japonés y palabras muy largas: sin espacios, se parte por caracteres.
                if (word.length() > 1 && dc.getTextWidthInPixels(word, font) > maxWidth) {
                    if (line.length() > 0) {
                        lines.add(line);
                        line = "";
                    }
                    var pieces = splitChars(dc, word, font, maxWidth);
                    for (var p = 0; p < pieces.size() - 1; p++) {
                        lines.add(pieces[p]);
                    }
                    word = pieces[pieces.size() - 1];
                }
                if (word.length() > 0) {
                    var candidate = line.length() == 0 ? word : line + " " + word;
                    if (line.length() == 0 || dc.getTextWidthInPixels(candidate, font) <= maxWidth) {
                        line = candidate;
                    } else {
                        lines.add(line);
                        line = word;
                    }
                    word = "";
                }
                if (c == '\n' && line.length() > 0) {
                    lines.add(line);
                    line = "";
                }
            } else {
                word += c.toString();
            }
        }
        return lines;
    }

    function splitChars(dc as Dc, word as String, font as Graphics.FontType, maxWidth as Number) as Array<String> {
        var pieces = [] as Array<String>;
        var chars = word.toCharArray();
        var piece = "";
        for (var i = 0; i < chars.size(); i++) {
            var next = piece + chars[i].toString();
            if (piece.length() > 0 && dc.getTextWidthInPixels(next, font) > maxWidth) {
                pieces.add(piece);
                piece = chars[i].toString();
            } else {
                piece = next;
            }
        }
        pieces.add(piece);
        return pieces;
    }

    // Líneas que caben entre top y bottom con la fuente dada.
    function visibleCount(dc as Dc, font as Graphics.FontType, top as Number, bottom as Number) as Number {
        var count = (bottom - top) / dc.getFontHeight(font);
        return count < 1 ? 1 : count;
    }

    // Dibuja las líneas desde `first`, centradas verticalmente en la franja
    // cuando caben todas, y un indicador a la derecha cuando hay más.
    function draw(dc as Dc, lines as Array<String>, font as Graphics.FontType, color as Number,
                  top as Number, bottom as Number, first as Number) as Void {
        var cx = dc.getWidth() / 2;
        var lineH = dc.getFontHeight(font);
        var visible = visibleCount(dc, font, top, bottom);
        var shown = lines.size() - first < visible ? lines.size() - first : visible;
        var y = top;
        if (lines.size() <= visible) {
            y = top + ((bottom - top) - shown * lineH) / 2;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < shown; i++) {
            dc.drawText(cx, y + i * lineH, font, lines[first + i], Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (lines.size() > visible) {
            drawScrollbar(dc, first, visible, lines.size());
        }
    }

    // Arco en el borde derecho: la parte clara indica qué se está viendo.
    function drawScrollbar(dc as Dc, first as Number, visible as Number, total as Number) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var r = cx - 8;
        var span = 60;
        var start = span / 2;
        dc.setPenWidth(4);
        dc.setColor(Theme.TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, start, start - span);
        var thumb = span * visible / total;
        if (thumb < 8) {
            thumb = 8;
        }
        var maxFirst = total - visible;
        var offset = maxFirst > 0 ? (span - thumb) * first / maxFirst : 0;
        dc.setColor(Theme.TEXT_SECONDARY, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, start - offset, start - offset - thumb);
        dc.setPenWidth(1);
    }

    function clampFirst(first as Number, visible as Number, total as Number) as Number {
        var maxFirst = total - visible;
        if (maxFirst < 0) {
            maxFirst = 0;
        }
        return first < 0 ? 0 : (first > maxFirst ? maxFirst : first);
    }
}
