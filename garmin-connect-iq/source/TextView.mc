import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Vista genérica: título y cuerpo partido por palabras dentro del círculo,
// con desplazamiento por líneas (UP/DOWN o deslizar).
class TextView extends WatchUi.View {

    private var _title as String;
    private var _body as String;
    private var _lines as Array<String>?;
    private var _first as Number = 0;
    private var _visible as Number = 1;

    function initialize(title as String, body as String) {
        View.initialize();
        _title = title;
        _body = body;
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

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var font = Graphics.FONT_XTINY;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(EyesRenderer.COLOR_RIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 16 / 100, Graphics.FONT_SMALL, _title,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var lines = _lines;
        if (lines == null) {
            lines = RoundText.wrap(dc, _body, font, w * 70 / 100);
            _lines = lines;
        }
        var top = h * 27 / 100;
        var bottom = h * 82 / 100;
        _visible = RoundText.visibleCount(dc, font, top, bottom);
        RoundText.draw(dc, lines, font, Graphics.COLOR_WHITE, top, bottom, _first);
    }
}

class TextViewDelegate extends WatchUi.BehaviorDelegate {

    private var _textView as TextView;

    function initialize(view as TextView) {
        BehaviorDelegate.initialize();
        _textView = view;
    }

    function onNextPage() as Boolean {
        return _textView.scroll(1);
    }

    function onPreviousPage() as Boolean {
        return _textView.scroll(-1);
    }
}
