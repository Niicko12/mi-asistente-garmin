import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;

// Recoge lo agregado desde el panel del teléfono (/api/sync): tareas y
// notas se suman a las del reloj y se confirman al servidor para que salgan
// de la bandeja; las tarjetas de japonés reemplazan la lista local.
// Se lanza al abrir el menú, como mucho una vez cada 2 minutos.
module PhoneSync {

    const MIN_INTERVAL_MS = 120000;

    var _client as PhoneSyncClient?;
    var _lastAt as Number = 0;

    function run() as Void {
        var now = System.getTimer();
        if (_client != null || (_lastAt != 0 && now - _lastAt < MIN_INTERVAL_MS)) {
            return;
        }
        if (!System.getDeviceSettings().phoneConnected) {
            return;
        }
        _lastAt = now;
        var client = new PhoneSyncClient();
        _client = client;
        client.start();
    }

    function finished() as Void {
        _client = null;
    }
}

class PhoneSyncClient {

    function initialize() {
    }

    function start() as Void {
        Communications.makeWebRequest(
            Secrets.API_URL + "/api/sync",
            null,
            {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => { "Authorization" => "Bearer " + Secrets.DEVICE_TOKEN },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onPulled)
        );
    }

    function onPulled(code as Number, data as Dictionary or String or Null) as Void {
        if (code != 200 || !(data instanceof Dictionary)) {
            PhoneSync.finished();
            return;
        }
        var cards = data["cards"];
        if (cards instanceof Array) {
            JpCustom.replace(cards as Array<Array>);
        }
        var tasks = take(data["tasks"], true);
        var notes = take(data["notes"], false);
        if (tasks.size() == 0 && notes.size() == 0) {
            PhoneSync.finished();
            return;
        }
        Communications.makeWebRequest(
            Secrets.API_URL + "/api/sync",
            { "tasks" => tasks, "notes" => notes },
            {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => "Bearer " + Secrets.DEVICE_TOKEN
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onAcked)
        );
    }

    function onAcked(code as Number, data as Dictionary or String or Null) as Void {
        PhoneSync.finished();
    }

    // Guarda cada [id, texto] y devuelve los ids guardados: lo que no cupo
    // se queda en la bandeja del servidor para la próxima vez.
    private function take(value, isTask as Boolean) as Array<Number> {
        var saved = [] as Array<Number>;
        if (!(value instanceof Array)) {
            return saved;
        }
        for (var i = 0; i < value.size(); i++) {
            var entry = value[i];
            if (entry instanceof Array && entry.size() == 2 && entry[0] instanceof Number && entry[1] instanceof String) {
                var ok = isTask ? Store.addTask(entry[1] as String) : Store.addNote(entry[1] as String);
                if (ok) {
                    saved.add(entry[0] as Number);
                }
            }
        }
        return saved;
    }
}
