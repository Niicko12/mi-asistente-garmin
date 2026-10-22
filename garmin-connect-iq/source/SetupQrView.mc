import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// QR del panel del teléfono y, debajo, el código de 6 dígitos para
// enlazarlo. Al abrir la pantalla se pide un código a /api/pair (vale 10
// minutos) y luego /api/qr, un QR que ya lo lleva: al escanearlo el teléfono
// queda enlazado sin escribir nada. Mientras tanto, o sin conexión, se
// muestra el QR fijo de /api/setup.
// Los bitmaps traen su margen blanco; el fondo negro no estorba al lector.
class SetupQrView extends WatchUi.View {

    private var _qr as BitmapResource?;
    private var _linkQr as BitmapResource or Graphics.BitmapReference or Null = null;
    private var _code as String? = null;
    private var _failed as Boolean = false;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        _qr = WatchUi.loadResource(Rez.Drawables.SetupQr) as BitmapResource;
        _linkQr = null;
        _code = null;
        _failed = false;
        Communications.makeWebRequest(
            Secrets.API_URL + "/api/pair",
            {},
            {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => "Bearer " + Secrets.DEVICE_TOKEN
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onCode)
        );
    }

    function onHide() as Void {
        _qr = null;
        _linkQr = null;
    }

    function onCode(code as Number, data as Dictionary or String or Null) as Void {
        var value = data instanceof Dictionary ? data["code"] : null;
        if (code == 200 && value instanceof String && value.length() == 6) {
            _code = value.substring(0, 3) + " " + value.substring(3, 6);
            Communications.makeImageRequest(
                Secrets.API_URL + "/api/qr",
                { "c" => value },
                {
                    :maxWidth => 222,
                    :maxHeight => 222,
                    :dithering => Communications.IMAGE_DITHERING_NONE,
                    :packingFormat => Communications.PACKING_FORMAT_PNG
                },
                method(:onLinkQr)
            );
        } else {
            _failed = true;
        }
        WatchUi.requestUpdate();
    }

    function onLinkQr(code as Number, image as WatchUi.BitmapResource or Graphics.BitmapReference or Null) as Void {
        if (code == 200 && image != null) {
            _linkQr = image;
            WatchUi.requestUpdate();
        }
    }

    function onUpdate(dc as Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        dc.setColor(EyesRenderer.COLOR_RIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 11 / 100, Graphics.FONT_XTINY,
            WatchUi.loadResource(Rez.Strings.SetupTitle) as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var qrBottom = h * 43 / 100;
        var qr = _linkQr != null ? _linkQr : _qr;
        if (qr != null) {
            var top = h * 43 / 100 - qr.getHeight() / 2;
            dc.drawBitmap(cx - qr.getWidth() / 2, top, qr);
            qrBottom = top + qr.getHeight();
        }

        // Código grande y, debajo, una línea corta: el borde redondo recorta
        // las líneas largas cerca del fondo.
        var code = _code;
        var label = code != null ? code
            : (WatchUi.loadResource(_failed ? Rez.Strings.SetupNoCode : Rez.Strings.SetupLoading) as String);
        dc.setColor(code != null ? Graphics.COLOR_WHITE : Theme.TEXT_SECONDARY, Graphics.COLOR_TRANSPARENT);
        var codeFont = code != null ? Graphics.FONT_MEDIUM : Graphics.FONT_XTINY;
        var codeY = qrBottom + dc.getFontHeight(codeFont) / 2 + 6;
        dc.drawText(cx, codeY, codeFont, label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        if (code != null) {
            dc.setColor(Theme.TEXT_HINT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, codeY + dc.getFontHeight(codeFont) / 2 + dc.getFontHeight(Graphics.FONT_XTINY) / 2 + 2,
                Graphics.FONT_XTINY, WatchUi.loadResource(Rez.Strings.SetupHint) as String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
