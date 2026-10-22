import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

// Pregunta por voz: escucha al abrirse, envía el audio al backend y muestra
// lo que entendió y la respuesta. No hay palabra de activación: se abre con
// un acceso directo del reloj o desde el menú.
class ListenView extends WatchUi.View {

    const TICK_MS = 250;
    const MAX_LISTEN_MS = 12000;
    // Menos de esto es un toque accidental, no una pregunta.
    const MIN_AUDIO_BYTES = 600;

    private var _status as AssistantState.Status = AssistantState.LISTENING;
    private var _panel as AnswerPanel = new AnswerPanel();
    private var _speech as SpeechPlayer;
    // Código del último fallo de voz; se muestra en lugar de la pista.
    private var _speechError as Number?;
    private var _frame as Number = 1;
    private var _listenTicks as Number = 0;
    private var _started as Boolean = false;
    private var _discard as Boolean = false;
    private var _timer as Timer.Timer?;
    private var _recorder as VoiceRecorder?;

    function initialize() {
        View.initialize();
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
        if (!_started) {
            _started = true;
            listen();
        }
    }

    // El micrófono solo funciona en primer plano: al salir se corta.
    function onHide() as Void {
        _speech.stop();
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        if (_recorder != null) {
            _discard = true;
            _recorder.stop();
        }
    }

    // START o toque: termina de escuchar, o vuelve a preguntar.
    function primaryAction() as Void {
        if (_status == AssistantState.LISTENING) {
            stopListening();
        } else if (_status != AssistantState.THINKING) {
            listen();
        }
    }

    function scroll(step as Number) as Boolean {
        return _status != AssistantState.LISTENING && _panel.scroll(step);
    }

    function listen() as Void {
        _speech.stop();
        _speechError = null;
        _panel.setContent("", "");
        _listenTicks = 0;
        var recorder = new VoiceRecorder(method(:onAudio));
        if (recorder.start()) {
            _recorder = recorder;
            show(AssistantState.LISTENING, "");
        } else {
            show(AssistantState.ERROR, WatchUi.loadResource(Rez.Strings.ErrMic) as String);
        }
    }

    function stopListening() as Void {
        if (_recorder != null) {
            _recorder.stop();
        }
    }

    function onTick() as Void {
        _frame++;
        if (_status == AssistantState.LISTENING) {
            _listenTicks++;
            if (_listenTicks * TICK_MS >= MAX_LISTEN_MS) {
                stopListening();
            }
        }
        WatchUi.requestUpdate();
    }

    function onAudio(audio as ByteArray or Null) as Void {
        _recorder = null;
        if (_discard) {
            _discard = false;
            show(AssistantState.ERROR, WatchUi.loadResource(Rez.Strings.ErrNotHeard) as String);
            return;
        }
        if (audio == null || audio.size() < MIN_AUDIO_BYTES) {
            show(AssistantState.ERROR, WatchUi.loadResource(Rez.Strings.ErrNotHeard) as String);
            return;
        }
        show(AssistantState.THINKING, "");
        AssistantApi.askAudio(audio, method(:onResponse));
    }

    function onResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data instanceof Dictionary && data["answer"] instanceof String) {
            var transcript = data["transcript"];
            show(AssistantState.AVAILABLE, data["answer"] as String);
            _panel.setContent(transcript instanceof String ? transcript : "", data["answer"] as String);
            // Solo se dice en voz alta una respuesta real, no "no te escuché".
            if (transcript instanceof String && transcript.length() > 0) {
                _speech.say(data["answer"] as String);
            }
        } else if (responseCode == Communications.BLE_CONNECTION_UNAVAILABLE) {
            show(AssistantState.OFFLINE, WatchUi.loadResource(Rez.Strings.ErrNoPhone) as String);
        } else if (responseCode == 401) {
            show(AssistantState.ERROR, WatchUi.loadResource(Rez.Strings.ErrAuth) as String);
        } else {
            show(AssistantState.ERROR,
                (WatchUi.loadResource(Rez.Strings.ErrGeneric) as String) + " (" + responseCode + ")");
        }
    }

    private function show(status as AssistantState.Status, text as String) as Void {
        _status = status;
        _panel.setContent("", text);
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        if (_status == AssistantState.LISTENING) {
            drawListening(dc, w, h, cx);
            return;
        }

        var hint = _speechError != null
            ? (WatchUi.loadResource(Rez.Strings.SpeechError) as String) + " " + _speechError
            : WatchUi.loadResource(Rez.Strings.HintAskAgain) as String;
        _panel.draw(dc, _status, _frame, hint);
    }

    // Aro que se vacía con el tiempo que queda para hablar.
    private function drawListening(dc as Dc, w as Number, h as Number, cx as Number) as Void {
        var color = EyesRenderer.colorFor(AssistantState.LISTENING);
        var elapsed = _listenTicks * TICK_MS;
        var remaining = 360 - (elapsed * 360 / MAX_LISTEN_MS);
        dc.setPenWidth(6);
        dc.setColor(Theme.TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, h / 2, w / 2 - 5);
        if (remaining > 0) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, h / 2, w / 2 - 5, Graphics.ARC_CLOCKWISE, 90, 90 - remaining);
        }
        dc.setPenWidth(1);

        EyesRenderer.draw(dc, cx, h * 40 / 100, w * 12 / 100, AssistantState.LISTENING, _frame);

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 68 / 100, Graphics.FONT_SMALL, AssistantState.label(AssistantState.LISTENING),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Theme.TEXT_HINT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 79 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.HintStopListening) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class ListenDelegate extends WatchUi.BehaviorDelegate {

    private var _view as ListenView;

    function initialize(view as ListenView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        _view.primaryAction();
        return true;
    }

    function onNextPage() as Boolean {
        return _view.scroll(1);
    }

    function onPreviousPage() as Boolean {
        return _view.scroll(-1);
    }
}

module Listen {
    function push() as Void {
        var view = new ListenView();
        WatchUi.pushView(view, new ListenDelegate(view), WatchUi.SLIDE_UP);
    }
}
