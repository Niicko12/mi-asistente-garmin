import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Pantalla de respuesta compartida por la pregunta escrita y la hablada:
// ojos arriba, lo que entendió en gris, la respuesta partida por palabras
// (con desplazamiento) y una pista corta abajo.
class AnswerPanel {

    private var _transcript as String = "";
    private var _text as String = "";
    private var _quoteLines as Array<String>?;
    private var _lines as Array<String>?;
    private var _first as Number = 0;
    private var _visible as Number = 1;

    function setContent(transcript as String, text as String) as Void {
        _transcript = transcript;
        _text = text;
        _quoteLines = null;
        _lines = null;
        _first = 0;
    }

    function scroll(step as Number) as Boolean {
        var lines = _lines;
        if (lines == null || lines.size() <= _visible) {
            return false;
        }
        _first = RoundText.clampFirst(_first + step, _visible, lines.size());
        WatchUi.requestUpdate();
        return true;
    }

    function draw(dc as Dc, status as AssistantState.Status, frame as Number, hint as String?) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var font = Graphics.FONT_XTINY;
        var lineH = dc.getFontHeight(font);

        // Mientras piensa, la cara ocupa el centro como al escuchar.
        if (status == AssistantState.THINKING) {
            EyesRenderer.draw(dc, cx, h * 40 / 100, w * 12 / 100, status, frame);
            dc.setColor(EyesRenderer.colorFor(status), Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 70 / 100, Graphics.FONT_SMALL, AssistantState.label(status),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        EyesRenderer.draw(dc, cx, h * 19 / 100, w * 8 / 100, status, frame);

        var top = h * 34 / 100;
        if (_transcript.length() > 0) {
            var quote = _quoteLines;
            if (quote == null) {
                quote = RoundText.wrap(dc, "«" + _transcript + "»", font, w * 66 / 100);
                if (quote.size() > 2) {
                    quote = quote.slice(0, 2);
                    quote[1] = quote[1] + "...";
                }
                _quoteLines = quote;
            }
            RoundText.draw(dc, quote, font, Theme.TEXT_SECONDARY, top, top + quote.size() * lineH, 0);
            top += quote.size() * lineH + lineH / 3;
        }

        var lines = _lines;
        if (lines == null) {
            lines = RoundText.wrap(dc, _text, font, w * 70 / 100);
            _lines = lines;
        }
        var bottom = hint != null ? h * 79 / 100 : h * 84 / 100;
        _visible = RoundText.visibleCount(dc, font, top, bottom);
        RoundText.draw(dc, lines, font, Graphics.COLOR_WHITE, top, bottom, _first);

        if (hint != null) {
            dc.setColor(Theme.TEXT_HINT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 86 / 100, font, hint,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
