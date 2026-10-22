import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// QR con la guía de configuración (/api/setup) para escanear con el iPhone.
// El bitmap ya trae su margen blanco; el fondo negro no estorba al lector.
class SetupQrView extends WatchUi.View {

    private var _qr as BitmapResource?;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        _qr = WatchUi.loadResource(Rez.Drawables.SetupQr) as BitmapResource;
    }

    function onHide() as Void {
        _qr = null;
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(EyesRenderer.COLOR_RIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 12 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.SetupTitle) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var qr = _qr;
        if (qr != null) {
            dc.drawBitmap(cx - qr.getWidth() / 2, h / 2 - qr.getHeight() / 2, qr);
        }

        dc.setColor(Theme.TEXT_HINT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 88 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.SetupHint) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
