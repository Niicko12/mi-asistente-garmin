import Toybox.Application;
import Toybox.Lang;

// Tarjetas de japonés agregadas desde el panel del teléfono (/api/setup).
// Cada una es [id, japonés, lectura, romaji, español]: mismas posiciones
// que JapaneseDeck.ITEMS a partir de la 1. En el mazo se identifican como
// BASE + id, así el progreso de una tarjeta no cambia si se borran otras.
module JpCustom {

    const KEY = "jp_custom";
    const BASE = 10000;

    var _cache as Array<Array>? = null;

    function cards() as Array<Array> {
        var cached = _cache;
        if (cached != null) {
            return cached;
        }
        var value = Storage.getValue(KEY);
        var list = value instanceof Array ? value as Array<Array> : [] as Array<Array>;
        _cache = list;
        return list;
    }

    // El servidor manda la lista completa: reemplaza la del reloj.
    function replace(list as Array<Array>) as Boolean {
        _cache = null;
        return Store.save(KEY, list as Application.PropertyValueType);
    }

    function find(item as Number) as Array? {
        var list = cards();
        for (var i = 0; i < list.size(); i++) {
            if (list[i][0] == item - BASE) {
                return list[i];
            }
        }
        return null;
    }
}
