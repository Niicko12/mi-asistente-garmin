import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Tarjetas: primero solo el japonés; un toque muestra lectura, romaji y
// significado; otro toque lo pronuncia por el altavoz. UP/DOWN cambia de tarjeta.
class JpCardView extends WatchUi.View {

    private var _title as String;
    private var _items as Array<Number>;
    private var _pos as Number = 0;
    private var _revealed as Boolean = false;
    private var _speaking as Boolean = false;
    private var _font as FontResource?;
    private var _speech as SpeechPlayer;

    function initialize(category as Number) {
        View.initialize();
        _title = JapaneseDeck.CATEGORIES[category];
        _items = JapaneseDeck.indicesFor(category);
        _speech = new SpeechPlayer(method(:onSpeaking), method(:onSpeechError));
    }

    function onShow() as Void {
        _font = WatchUi.loadResource(Rez.Fonts.JpFont) as FontResource;
    }

    // Libera la fuente al salir: los bitmaps de fuente ocupan memoria.
    function onHide() as Void {
        _font = null;
        _speech.stop();
    }

    function onSpeaking(speaking as Boolean) as Void {
        _speaking = speaking;
        WatchUi.requestUpdate();
    }

    function onSpeechError(code as Number) as Void {
        _speaking = false;
        WatchUi.requestUpdate();
    }

    function move(step as Number) as Void {
        var count = _items.size();
        _pos = (_pos + step + count) % count;
        _revealed = false;
        _speech.stop();
        _speaking = false;
        WatchUi.requestUpdate();
    }

    function primaryAction() as Void {
        if (!_revealed) {
            _revealed = true;
            JpProgress.practiced();
        } else {
            _speech.say(JapaneseDeck.spoken(_items[_pos]));
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var item = _items[_pos];

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var font = _font;
        if (font == null) {
            return;
        }

        dc.setColor(EyesRenderer.COLOR_RIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 14 / 100, Graphics.FONT_XTINY, _title.toUpper(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Panel de la tarjeta.
        var panelTop = h * 22 / 100;
        var panelH = h * 56 / 100;
        dc.setColor(Theme.SURFACE, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(w * 9 / 100, panelTop, w * 82 / 100, panelH, 22);
        if (_speaking) {
            dc.setPenWidth(3);
            dc.setColor(EyesRenderer.COLOR_EYE, Graphics.COLOR_TRANSPARENT);
            dc.drawRoundedRectangle(w * 9 / 100, panelTop, w * 82 / 100, panelH, 22);
            dc.setPenWidth(1);
        }

        var jpLines = RoundText.wrap(dc, JapaneseDeck.jp(item), font, w * 74 / 100);
        var jpTop = _revealed ? h * 27 / 100 : h * 38 / 100;
        RoundText.draw(dc, jpLines, font, Graphics.COLOR_WHITE, jpTop,
            jpTop + jpLines.size() * dc.getFontHeight(font), 0);

        if (_revealed) {
            var y = jpTop + jpLines.size() * dc.getFontHeight(font) + 4;
            var reading = JapaneseDeck.reading(item);
            if (reading.length() > 0) {
                var readingLines = RoundText.wrap(dc, reading, font, w * 74 / 100);
                RoundText.draw(dc, readingLines, font, Theme.TEXT_SECONDARY, y, y + readingLines.size() * dc.getFontHeight(font), 0);
                y += readingLines.size() * dc.getFontHeight(font);
            }
            dc.setColor(EyesRenderer.COLOR_EYE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y + h * 4 / 100, Graphics.FONT_SMALL, JapaneseDeck.romaji(item),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            var meaning = JapaneseDeck.meaning(item);
            if (meaning.length() > 0) {
                var lines = RoundText.wrap(dc, meaning, Graphics.FONT_XTINY, w * 70 / 100);
                var top = y + h * 9 / 100;
                RoundText.draw(dc, lines, Graphics.FONT_XTINY, Theme.TEXT_SECONDARY, top,
                    top + lines.size() * dc.getFontHeight(Graphics.FONT_XTINY), 0);
            }
        }

        var hint = _revealed ? Rez.Strings.JpHintListen : Rez.Strings.JpHintReveal;
        dc.setColor(Theme.TEXT_HINT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 84 / 100, Graphics.FONT_XTINY,
            (_pos + 1) + "/" + _items.size() + " · " + (WatchUi.loadResource(hint) as String),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class JpCardDelegate extends WatchUi.BehaviorDelegate {

    private var _view as JpCardView;

    function initialize(view as JpCardView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        _view.primaryAction();
        return true;
    }

    function onNextPage() as Boolean {
        _view.move(1);
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.move(-1);
        return true;
    }
}
