import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

// Quiz de tres opciones sobre el menú nativo (CustomMenu): el sistema se
// encarga del toque y de los botones (UP/DOWN mueven, START o un toque
// eligen), igual que en el resto de menús del reloj.
//
// La pregunta va en el título del menú. Al elegir se pasa a una pantalla de
// resultado (correcto o incorrecto, la palabra con su romaji y significado,
// y la pronunciación); cualquier toque o START pasa a la siguiente pregunta.
module JpQuizMenu {

    function open(category as Number) as Void {
        var session = new JpQuizSession(category);
        WatchUi.pushView(session.buildMenu(), new JpQuizDelegate(session), WatchUi.SLIDE_LEFT);
    }
}

// Estado de una ronda, sin pantalla, para poder probarlo.
class JpQuizRound {

    const OPTIONS = 3;

    var category as Number;
    var item as Number = -1;
    var options as Array<Number> = [] as Array<Number>;
    var chosen as Number = -1;
    var answered as Boolean = false;
    var right as Boolean = false;
    var score as Number = 0;
    var count as Number = 0;
    private var _pool as Array<Number>;

    function initialize(cat as Number) {
        category = cat;
        _pool = JapaneseDeck.indicesFor(cat);
        next();
    }

    function next() as Void {
        item = JpProgress.pick(_pool, item);
        options = [item] as Array<Number>;
        // Tope de intentos por si dos tarjetas comparten significado.
        var tries = 0;
        while (options.size() < OPTIONS && options.size() < _pool.size() && tries < 60) {
            tries++;
            var candidate = _pool[JpProgress.random(_pool.size())];
            if (options.indexOf(candidate) < 0 && !label(candidate).equals(label(item))) {
                options.add(candidate);
            }
        }
        // Mezcla: la correcta no siempre arriba.
        for (var i = options.size() - 1; i > 0; i--) {
            var j = JpProgress.random(i + 1);
            var tmp = options[i];
            options[i] = options[j];
            options[j] = tmp;
        }
        chosen = -1;
        answered = false;
        right = false;
    }

    function answer(index as Number) as Void {
        if (answered || index < 0 || index >= options.size()) {
            return;
        }
        chosen = index;
        answered = true;
        right = JpQuiz.isCorrect(options, index, item);
        count++;
        if (right) {
            score++;
        }
        JpProgress.record(item, right);
    }

    // En hiragana se responde con romaji; en palabras, con el significado.
    function label(candidate as Number) as String {
        return category == JapaneseDeck.KANA ? JapaneseDeck.romaji(candidate) : JapaneseDeck.meaning(candidate);
    }
}

class JpQuizSession {

    var round as JpQuizRound;
    var font as FontResource;
    private var _speech as SpeechPlayer;

    function initialize(category as Number) {
        round = new JpQuizRound(category);
        font = WatchUi.loadResource(Rez.Fonts.JpFont) as FontResource;
        _speech = new SpeechPlayer(method(:onSpeaking), method(:onSpeechError));
    }

    function buildMenu() as JpQuizMenuView {
        var h = System.getDeviceSettings().screenHeight;
        var menu = new JpQuizMenuView(self, h * 19 / 100);
        for (var i = 0; i < round.options.size(); i++) {
            menu.addItem(new JpQuizOption(i, self));
        }
        return menu;
    }

    function choose(index as Number) as Void {
        if (round.answered) {
            return;
        }
        round.answer(index);
        _speech.say(JapaneseDeck.spoken(round.item));
        WatchUi.switchToView(new JpQuizResultView(self), new JpQuizResultDelegate(self), WatchUi.SLIDE_IMMEDIATE);
    }

    function nextQuestion() as Void {
        _speech.stop();
        round.next();
        WatchUi.switchToView(buildMenu(), new JpQuizDelegate(self), WatchUi.SLIDE_LEFT);
    }

    function stop() as Void {
        _speech.stop();
    }

    function onSpeaking(speaking as Boolean) as Void {
    }

    function onSpeechError(code as Number) as Void {
    }
}

class JpQuizMenuView extends WatchUi.CustomMenu {

    private var _session as JpQuizSession;

    function initialize(session as JpQuizSession, itemHeight as Number) {
        CustomMenu.initialize(itemHeight, Graphics.COLOR_BLACK, {});
        _session = session;
    }

    // Título: aciertos, la palabra en japonés y, tras responder, el resultado.
    function drawTitle(dc as Dc) as Void {
        var round = _session.round;
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var face = JapaneseDeck.display(round.item);
        var faceFont = face.length() > 0 ? _session.font : Graphics.FONT_MEDIUM;
        if (face.length() == 0) {
            face = JapaneseDeck.romaji(round.item);
        }
        var lines = RoundText.wrap(dc, face, faceFont, w * 70 / 100);
        var lineH = dc.getFontHeight(faceFont);
        var top = h * 30 / 100;
        RoundText.draw(dc, lines, faceFont, Graphics.COLOR_WHITE, top, top + lines.size() * lineH, 0);

        dc.setColor(Theme.TEXT_SECONDARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 15 / 100, Graphics.FONT_XTINY, round.score + "/" + round.count,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class JpQuizOption extends WatchUi.CustomMenuItem {

    private var _index as Number;
    private var _session as JpQuizSession;

    function initialize(index as Number, session as JpQuizSession) {
        CustomMenuItem.initialize(index, {});
        _index = index;
        _session = session;
    }

    function draw(dc as Dc) as Void {
        var round = _session.round;
        var w = dc.getWidth();
        var h = dc.getHeight();
        var fill = Theme.SURFACE;
        var text = Theme.TEXT;
        if (isFocused()) {
            fill = EyesRenderer.COLOR_EYE;
            text = Graphics.COLOR_BLACK;
        }
        // El texto se parte en dos líneas si no cabe en una.
        // El área empieza a la izquierda de la pantalla y llega hasta el
        // borde redondo: la fila ocupa el 82 % para no quedar recortada.
        var rowH = h - 8;
        var rowW = w * 82 / 100;
        var cx = rowW / 2 + 2;
        dc.setColor(fill, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(2, 4, rowW, rowH, rowH / 2);
        var font = Graphics.FONT_XTINY;
        var lines = RoundText.wrap(dc, round.label(round.options[_index]), font, rowW - 28);
        if (lines.size() > 2) {
            lines = [lines[0], lines[1] + "..."] as Array<String>;
        }
        var lineH = dc.getFontHeight(font);
        var y = h / 2 - (lines.size() - 1) * lineH / 2;
        dc.setColor(text, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < lines.size(); i++) {
            dc.drawText(cx, y + i * lineH, font, lines[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}

class JpQuizDelegate extends WatchUi.Menu2InputDelegate {

    private var _session as JpQuizSession;

    function initialize(session as JpQuizSession) {
        Menu2InputDelegate.initialize();
        _session = session;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        _session.choose(item.getId() as Number);
    }

    function onBack() as Void {
        _session.stop();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

// Resultado de una respuesta. Sin zonas que tocar: cualquier toque, START o
// deslizar pasa a la siguiente pregunta; BACK vuelve a las categorías.
class JpQuizResultView extends WatchUi.View {

    private var _session as JpQuizSession;

    function initialize(session as JpQuizSession) {
        View.initialize();
        _session = session;
    }

    function onUpdate(dc as Dc) as Void {
        var round = _session.round;
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        EyesRenderer.draw(dc, cx, h * 15 / 100, w * 5 / 100,
            round.right ? AssistantState.AVAILABLE : AssistantState.ERROR, 1);
        dc.setColor(round.right ? EyesRenderer.COLOR_CALM : EyesRenderer.COLOR_ALERT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 26 / 100, Graphics.FONT_SMALL,
            WatchUi.loadResource(round.right ? Rez.Strings.JpRight : Rez.Strings.JpWrong) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var face = JapaneseDeck.display(round.item);
        var faceFont = face.length() > 0 ? _session.font : Graphics.FONT_MEDIUM;
        if (face.length() == 0) {
            face = JapaneseDeck.romaji(round.item);
        }
        var lines = RoundText.wrap(dc, face, faceFont, w * 72 / 100);
        var lineH = dc.getFontHeight(faceFont);
        var top = h * 34 / 100;
        RoundText.draw(dc, lines, faceFont, Graphics.COLOR_WHITE, top, top + lines.size() * lineH, 0);
        var y = top + lines.size() * lineH + h * 3 / 100;

        if (round.category != JapaneseDeck.KANA) {
            dc.setColor(EyesRenderer.COLOR_EYE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_XTINY, JapaneseDeck.romaji(round.item),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            y += dc.getFontHeight(Graphics.FONT_XTINY);
        }
        // La respuesta correcta en verde y, si falló, la elegida en rojo.
        dc.setColor(EyesRenderer.COLOR_CALM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, round.label(round.item),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        if (!round.right && round.chosen >= 0) {
            y += dc.getFontHeight(Graphics.FONT_XTINY);
            dc.setColor(EyesRenderer.COLOR_ALERT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, y, Graphics.FONT_XTINY,
                (WatchUi.loadResource(Rez.Strings.JpYouChose) as String) + " " + round.label(round.options[round.chosen]),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        dc.setColor(Theme.TEXT_SECONDARY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 84 / 100, Graphics.FONT_XTINY, round.score + "/" + round.count,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.TEXT_HINT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 91 / 100, Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.JpHintNext) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class JpQuizResultDelegate extends WatchUi.BehaviorDelegate {

    private var _session as JpQuizSession;

    function initialize(session as JpQuizSession) {
        BehaviorDelegate.initialize();
        _session = session;
    }

    function onSelect() as Boolean {
        _session.nextQuestion();
        return true;
    }

    function onTap(event as WatchUi.ClickEvent) as Boolean {
        _session.nextQuestion();
        return true;
    }

    function onNextPage() as Boolean {
        _session.nextQuestion();
        return true;
    }

    function onBack() as Boolean {
        _session.stop();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

// Reglas del quiz sin estado de pantalla, para poder probarlas.
module JpQuiz {

    // Texto que cabe en dos líneas de una opción (el área de la opción es
    // de unos 300 px en el fēnix 8 47mm).
    const MAX_LABEL_PX = 520;

    function isCorrect(options as Array<Number>, selected as Number, item as Number) as Boolean {
        return selected >= 0 && selected < options.size() && options[selected] == item;
    }
}
