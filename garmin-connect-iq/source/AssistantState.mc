import Toybox.Lang;
import Toybox.WatchUi;

// Estados operativos del asistente. Expresan el estado de la app,
// nunca una inferencia sobre las emociones del usuario.
module AssistantState {

    enum Status {
        AVAILABLE,
        THINKING,
        OFFLINE,
        ERROR,
        LISTENING,
        SPEAKING
    }

    // Estados que recorre el prototipo con UP/DOWN (sin LISTENING).
    const COUNT = 4;

    function next(status as Status) as Status {
        return ((status + 1) % COUNT) as Status;
    }

    function previous(status as Status) as Status {
        return ((status + COUNT - 1) % COUNT) as Status;
    }

    function label(status as Status) as String {
        switch (status) {
            case THINKING:
                return WatchUi.loadResource(Rez.Strings.StateThinking) as String;
            case OFFLINE:
                return WatchUi.loadResource(Rez.Strings.StateOffline) as String;
            case ERROR:
                return WatchUi.loadResource(Rez.Strings.StateError) as String;
            case LISTENING:
                return WatchUi.loadResource(Rez.Strings.StateListening) as String;
            case SPEAKING:
                return WatchUi.loadResource(Rez.Strings.StateSpeaking) as String;
            default:
                return WatchUi.loadResource(Rez.Strings.StateAvailable) as String;
        }
    }
}
