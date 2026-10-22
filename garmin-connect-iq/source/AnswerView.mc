import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Pregunta escrita o sugerida: la envía al abrirse y muestra el avatar
// pensando hasta que llega la respuesta o el error.
class AnswerView extends WatchUi.View {

    const TICK_MS = 250;

    private var _question as String;
    private var _status as AssistantState.Status = AssistantState.THINKING;
    private var _panel as AnswerPanel = new AnswerPanel();
    private var _speech as SpeechPlayer;
    // Código del último fallo de voz; se muestra en lugar de la pista.
    private var _speechError as Number?;
    private var _sent as Boolean = false;
    private var _frame as Number = 1;
    private var _timer as Timer.Timer?;

    function initialize(question as String) {
        View.initialize();
        _question = question;
        _speech = new SpeechPlayer(method(:onSpeaking), method(:onSpeechError));
    }

    function onSpeechError(code as Number) as Void {
        _speechError = code;
        WatchUi.requestUpdate();
    }

    function onSpeaking(speaking as Boolean) as Void {
        if (_status == AssistantState.AVAILABLE || _status == AssistantState.SPEAKING) {
            _status = speaking ? AssistantState.SPEAKING : AssistantState.AVAILABLE;
            WatchUi.requestUpdate();
        }
    }

    function onShow() as Void {
        var timer = new Timer.Timer();
        timer.start(method(:onTick), TICK_MS, true);
        _timer = timer;
        if (!_sent) {
            _sent = true;
            AssistantApi.ask(_question, method(:onResponse));
        }
    }

    function onHide() as Void {
        _speech.stop();
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        _frame++;
        WatchUi.requestUpdate();
    }

    function scroll(step as Number) as Boolean {
        return _panel.scroll(step);
    }

    function onResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data instanceof Dictionary && data["answer"] instanceof String) {
            _status = AssistantState.AVAILABLE;
            _panel.setContent(_question, data["answer"] as String);
            _speech.say(data["answer"] as String);
        } else if (responseCode == Communications.BLE_CONNECTION_UNAVAILABLE) {
            _status = AssistantState.OFFLINE;
            _panel.setContent("", WatchUi.loadResource(Rez.Strings.ErrNoPhone) as String);
        } else if (responseCode == 401) {
            _status = AssistantState.ERROR;
            _panel.setContent("", WatchUi.loadResource(Rez.Strings.ErrAuth) as String);
        } else {
            _status = AssistantState.ERROR;
            _panel.setContent("", (WatchUi.loadResource(Rez.Strings.ErrGeneric) as String) + " (" + responseCode + ")");
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        var hint = _speechError != null
            ? (WatchUi.loadResource(Rez.Strings.SpeechError) as String) + " " + _speechError
            : null;
        _panel.draw(dc, _status, _frame, hint);
    }
}

class AnswerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as AnswerView;

    function initialize(view as AnswerView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onNextPage() as Boolean {
        return _view.scroll(1);
    }

    function onPreviousPage() as Boolean {
        return _view.scroll(-1);
    }
}
