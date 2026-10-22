import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Quiz de tres opciones. UP/DOWN mueve la selección y START responde; en
// pantalla táctil se puede tocar la opción. Tras responder, los ojos
// reaccionan, se pronuncia la palabra y otro toque pasa a la siguiente.
class JpQuizView extends WatchUi.View {

    const OPTIONS = 3;

    private var _category as Number;
    private var _pool as Array<Number>;
    private var _item as Number = -1;
    private var _options as Array<Number> = [] as Array<Number>;
    private var _selected as Number = 0;
    private var _answered as Boolean = false;
    private var _right as Boolean = false;
    private var _score as Number = 0;
    private var _count as Number = 0;
    private var _font as FontResource?;
    private var _speech as SpeechPlayer;
    private var _optionTops as Array<Number> = [] as Array<Number>;
    private var _optionH as Number = 0;

    function initialize(category as Number) {
        View.initialize();
        _category = category;
        _pool = JapaneseDeck.indicesFor(category);
        _speech = new SpeechPlayer(method(:onSpeaking), method(:onSpeechError));
        next();
    }

    function onShow() as Void {
        _font = WatchUi.loadResource(Rez.Fonts.JpFont) as FontResource;
    }

    function onHide() as Void {
        _font = null;
        _speech.stop();
    }

    function onSpeaking(speaking as Boolean) as Void {
    }

    function onSpeechError(code as Number) as Void {
    }

    function next() as Void {
        _speech.stop();
        _item = JpProgress.pick(_pool, _item);
        _options = [_item] as Array<Number>;
        while (_options.size() < OPTIONS && _options.size() < _pool.size()) {
            var candidate = _pool[JpProgress.random(_pool.size())];
            if (_options.indexOf(candidate) < 0 && label(candidate) != label(_item)) {
                _options.add(candidate);
            }
        }
        // Mezcla: la correcta no siempre arriba.
        for (var i = _options.size() - 1; i > 0; i--) {
            var j = JpProgress.random(i + 1);
            var tmp = _options[i];
            _options[i] = _options[j];
            _options[j] = tmp;
        }
        _selected = 0;
        _answered = false;
        WatchUi.requestUpdate();
    }

    function moveSelection(step as Number) as Boolean {
        if (_answered) {
            return false;
        }
        _selected = (_selected + step + _options.size()) % _options.size();
        WatchUi.requestUpdate();
        return true;
    }

    function primaryAction() as Void {
        if (_answered) {
            next();
            return;
        }
        _answered = true;
        _right = _options[_selected] == _item;
        _count++;
        if (_right) {
            _score++;
        }
        JpProgress.record(_item, _right);
        _speech.say(JapaneseDeck.spoken(_item));
        WatchUi.requestUpdate();
    }

    // Toque directo sobre una opción: la elige y responde.
    function tapAt(y as Number) as Boolean {
        if (_answered) {
            return false;
        }
        for (var i = 0; i < _optionTops.size(); i++) {
            if (y >= _optionTops[i] && y < _optionTops[i] + _optionH) {
                _selected = i;
                primaryAction();
                return true;
            }
        }
        return false;
    }

    // En hiragana se responde con romaji; en palabras, con el significado.
    function label(item as Number) as String {
        return _category == JapaneseDeck.KANA ? JapaneseDeck.romaji(item) : JapaneseDeck.meaning(item);
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var font = _font;
        if (font == null) {
            return;
        }

        dc.setColor(Theme.TEXT_SECONDARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 10 / 100, Graphics.FONT_XTINY, _score + "/" + _count,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var status = !_answered ? AssistantState.AVAILABLE : (_right ? AssistantState.AVAILABLE : AssistantState.ERROR);
        EyesRenderer.draw(dc, cx, h * 19 / 100, w * 5 / 100, status, 1);

        var jpLines = RoundText.wrap(dc, JapaneseDeck.jp(_item), font, w * 72 / 100);
        var lineH = dc.getFontHeight(font);
        var jpTop = h * 29 / 100;
        RoundText.draw(dc, jpLines, font, Graphics.COLOR_WHITE, jpTop, jpTop + jpLines.size() * lineH, 0);

        if (_answered && _category != JapaneseDeck.KANA) {
            dc.setColor(EyesRenderer.COLOR_EYE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, jpTop + jpLines.size() * lineH + h * 2 / 100, Graphics.FONT_XTINY,
                JapaneseDeck.romaji(_item), Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        var optFont = Graphics.FONT_XTINY;
        _optionH = dc.getFontHeight(optFont) + 12;
        var top = h * 49 / 100;
        var rowW = w * 68 / 100;
        _optionTops = [] as Array<Number>;
        for (var i = 0; i < _options.size(); i++) {
            var y = top + i * (_optionH + 6);
            _optionTops.add(y);
            var fill = Theme.SURFACE;
            var text = Theme.TEXT;
            if (_answered && _options[i] == _item) {
                fill = Theme.RIGHT;
            } else if (_answered && i == _selected) {
                fill = Theme.WRONG;
            } else if (!_answered && i == _selected) {
                fill = Theme.SURFACE_SELECTED;
            }
            dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(cx - rowW / 2, y, rowW, _optionH, _optionH / 2);
            if (!_answered && i == _selected) {
                dc.setColor(EyesRenderer.COLOR_RIM, Graphics.COLOR_TRANSPARENT);
                dc.drawRoundedRectangle(cx - rowW / 2, y, rowW, _optionH, _optionH / 2);
            }
            var lines = RoundText.wrap(dc, label(_options[i]), optFont, rowW - 24);
            dc.setColor(text, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y + _optionH / 2, optFont, lines[0] + (lines.size() > 1 ? "..." : ""),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        if (_answered) {
            dc.setColor(Theme.TEXT_HINT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 92 / 100, optFont, WatchUi.loadResource(Rez.Strings.JpHintNext) as String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class JpQuizDelegate extends WatchUi.BehaviorDelegate {

    private var _view as JpQuizView;

    function initialize(view as JpQuizView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onTap(event as WatchUi.ClickEvent) as Boolean {
        if (_view.tapAt(event.getCoordinates()[1])) {
            return true;
        }
        _view.primaryAction();
        return true;
    }

    function onSelect() as Boolean {
        _view.primaryAction();
        return true;
    }

    function onNextPage() as Boolean {
        return _view.moveSelection(1);
    }

    function onPreviousPage() as Boolean {
        return _view.moveSelection(-1);
    }
}
