import Toybox.Graphics;
import Toybox.Lang;

// Cara al estilo Monki (Anbernic): ojos cuadrados redondeados con brillo,
// boca simple y un color plano por estado. Solo primitivas, sin bitmaps,
// para ahorrar memoria. `frame` avanza con el temporizador de cada vista.
module EyesRenderer {

    const COLOR_RIM = 0x6CC79C;
    const COLOR_EYE = 0x5BC8E6;

    const COLOR_CALM = 0x6CC79C;
    const COLOR_LISTEN = 0x5BC8E6;
    const COLOR_OFF = 0x5C6560;
    const COLOR_ALERT = 0xF26B5B;
    const COLOR_DIM = 0x2A3A44;

    const BLINK_EVERY = 16;

    function colorFor(status as AssistantState.Status) as Number {
        switch (status) {
            case AssistantState.LISTENING:
            case AssistantState.THINKING:
                return COLOR_LISTEN;
            case AssistantState.OFFLINE:
                return COLOR_OFF;
            case AssistantState.ERROR:
                return COLOR_ALERT;
            default:
                return COLOR_CALM;
        }
    }

    // `size` escala toda la cara: cada ojo mide size * 1.4 de ancho.
    function draw(dc as Dc, cx as Number, cy as Number, size as Number,
                  status as AssistantState.Status, frame as Number) as Void {
        var eye = size * 14 / 10;
        var dx = eye * 70 / 100;
        var color = colorFor(status);
        var mouthY = cy + eye / 2 + eye * 28 / 100;
        var pen = eye / 14 + 1;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        switch (status) {
            case AssistantState.LISTENING: {
                // Ojos que "respiran" mientras escucha y boca en "o".
                var grow = (frame % 4 < 2) ? 0 : eye / 14;
                drawEyePair(dc, cx, cy, dx, eye + grow, eye + grow, color);
                dc.setPenWidth(pen);
                dc.drawCircle(cx, mouthY, eye / 9 + 2);
                break;
            }
            case AssistantState.THINKING: {
                var w = eye * 82 / 100;
                drawEyePair(dc, cx + eye / 8, cy - eye / 8, dx, w, eye * 62 / 100, color);
                var r = eye / 14 + 2;
                for (var i = 0; i < 3; i++) {
                    dc.setColor(i == frame % 3 ? color : COLOR_DIM, Graphics.COLOR_TRANSPARENT);
                    dc.fillCircle(cx + (i - 1) * eye / 3, mouthY, r);
                }
                break;
            }
            case AssistantState.SPEAKING: {
                // Boca que se abre y cierra mientras suena la voz.
                drawEyePair(dc, cx, cy, dx, eye, eye, color);
                var openings = [eye / 10, eye / 4, eye / 6] as Array<Number>;
                var mh = openings[frame % 3];
                var mw = eye * 36 / 100;
                dc.fillRoundedRectangle(cx - mw / 2, mouthY - mh / 2, mw, mh, mh / 2);
                break;
            }
            case AssistantState.OFFLINE:
                dc.fillRoundedRectangle(cx - dx - eye / 2, cy - eye / 16, eye, eye / 8, eye / 16);
                dc.fillRoundedRectangle(cx + dx - eye / 2, cy - eye / 16, eye, eye / 8, eye / 16);
                break;
            case AssistantState.ERROR:
                drawAngryEyes(dc, cx, cy, dx, eye);
                drawArc(dc, cx, mouthY, eye * 30 / 100, pen, false);
                break;
            default: {
                var h = (frame % BLINK_EVERY == 0) ? eye / 8 : eye;
                drawEyePair(dc, cx, cy, dx, eye, h, color);
                drawArc(dc, cx, mouthY, eye * 30 / 100, pen, true);
                break;
            }
        }
        dc.setPenWidth(1);
    }

    function drawEyePair(dc as Dc, cx as Number, cy as Number, dx as Number,
                         w as Number, h as Number, color as Number) as Void {
        var r = (w < h ? w : h) * 30 / 100;
        var x = [cx - dx - w / 2, cx + dx - w / 2];
        for (var i = 0; i < 2; i++) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x[i], cy - h / 2, w, h, r);
            // Brillo: solo con el ojo abierto.
            if (h > w / 3) {
                dc.setColor(glint(color), Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(x[i] + w * 26 / 100, cy - h / 2 + h * 25 / 100, w / 10 + 1);
                dc.fillCircle(x[i] + w * 44 / 100, cy - h / 2 + h * 37 / 100, w / 22 + 1);
            }
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
    }

    // Ojos de "molesto": la parte de arriba baja hacia el centro.
    function drawAngryEyes(dc as Dc, cx as Number, cy as Number, dx as Number, eye as Number) as Void {
        var top = cy - eye / 2;
        var bottom = cy + eye / 2;
        var drop = eye * 38 / 100;
        var lx = cx - dx - eye / 2;
        var rx = cx + dx - eye / 2;
        dc.fillPolygon([[lx, top], [lx + eye, top + drop], [lx + eye, bottom], [lx, bottom]]);
        dc.fillPolygon([[rx, top + drop], [rx + eye, top], [rx + eye, bottom], [rx, bottom]]);
    }

    // Sonrisa (smile = true) o boca triste, como arco de circunferencia.
    function drawArc(dc as Dc, cx as Number, y as Number, r as Number, pen as Number, smile as Boolean) as Void {
        dc.setPenWidth(pen);
        if (smile) {
            dc.drawArc(cx, y - r, r, Graphics.ARC_COUNTER_CLOCKWISE, 215, 325);
        } else {
            dc.drawArc(cx, y + r, r, Graphics.ARC_COUNTER_CLOCKWISE, 35, 145);
        }
    }

    // Mezcla el color con blanco a la mitad: brillo sin canal alfa.
    function glint(color as Number) as Number {
        return ((color >> 1) & 0x7F7F7F) + 0x808080;
    }
}
