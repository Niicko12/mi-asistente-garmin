import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

class MainView extends WatchUi.View {

    const TICK_MS = 250;

    private var _status as AssistantState.Status = AssistantState.AVAILABLE;
    private var _frame as Number = 1;
    private var _timer as Timer.Timer?;
    // Al abrir la app pasa directo a escuchar (una sola vez por sesión).
    private var _autoListen as Boolean = true;
    // Referencia para que el temporizador de un solo disparo no se libere.
    private var _listenTimer as Timer.Timer?;

    function initialize() {
        View.initialize();
    }

    function getStatus() as AssistantState.Status {
        return _status;
    }

    function setStatus(status as AssistantState.Status) as Void {
        _status = status;
        WatchUi.requestUpdate();
    }

    // El temporizador solo corre mientras la vista está visible.
    function onShow() as Void {
        var timer = new Timer.Timer();
        timer.start(method(:onTick), TICK_MS, true);
        _timer = timer;
        if (_autoListen) {
            _autoListen = false;
            var listenTimer = new Timer.Timer();
            listenTimer.start(method(:openListen), 50, false);
            _listenTimer = listenTimer;
        }
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function openListen() as Void {
        _listenTimer = null;
        Listen.push();
    }

    function onTick() as Void {
        _frame++;
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(Theme.TEXT_HINT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 9 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.DemoBadge) as String,
            Graphics.TEXT_JUSTIFY_CENTER);

        EyesRenderer.draw(dc, cx, h * 42 / 100, w * 14 / 100, _status, _frame);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 66 / 100, Graphics.FONT_SMALL,
            AssistantState.label(_status),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Theme.TEXT_HINT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 76 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.HintMenu) as String,
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, h * 82 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.HintState) as String,
            Graphics.TEXT_JUSTIFY_CENTER);
    }
}
