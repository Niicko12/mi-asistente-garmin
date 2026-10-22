import Toybox.Application;
import Toybox.Lang;

// Persistencia local (MVP 0.2). Cada valor de Storage admite hasta 32 KB;
// los límites de abajo mantienen cada lista muy por debajo.
// Las escrituras devuelven false si el almacenamiento falla o está lleno.
module Store {

    const FORMAT_VERSION = 1;
    const MAX_LEN = 120;
    const MAX_NOTES = 20;
    const MAX_TASKS = 30;

    const KEY_VERSION = "v";
    const KEY_TASKS = "tasks";
    const KEY_NOTES = "notes";

    // Tareas: Array de [título, hecha].
    function tasks() as Array<Array> {
        migrate();
        var v = Storage.getValue(KEY_TASKS);
        return v == null ? ([] as Array<Array>) : v as Array<Array>;
    }

    function addTask(title as String) as Boolean {
        var list = tasks();
        if (list.size() >= MAX_TASKS) {
            return false;
        }
        list.add([clip(title), false]);
        return save(KEY_TASKS, list);
    }

    function setTaskDone(index as Number, done as Boolean) as Boolean {
        var list = tasks();
        if (index < 0 || index >= list.size()) {
            return false;
        }
        list[index][1] = done;
        return save(KEY_TASKS, list);
    }

    function removeDoneTasks() as Boolean {
        var kept = [] as Array<Array>;
        var list = tasks();
        for (var i = 0; i < list.size(); i++) {
            if (!(list[i][1] as Boolean)) {
                kept.add(list[i]);
            }
        }
        return save(KEY_TASKS, kept);
    }

    // Notas: Array<String>, la más reciente primero.
    function notes() as Array<String> {
        migrate();
        var v = Storage.getValue(KEY_NOTES);
        return v == null ? ([] as Array<String>) : v as Array<String>;
    }

    function addNote(text as String) as Boolean {
        var list = [clip(text)] as Array<String>;
        list.addAll(notes());
        if (list.size() > MAX_NOTES) {
            list = list.slice(0, MAX_NOTES);
        }
        return save(KEY_NOTES, list);
    }

    function deleteNote(index as Number) as Boolean {
        var list = notes();
        if (index < 0 || index >= list.size()) {
            return false;
        }
        list.remove(list[index]);
        return save(KEY_NOTES, list);
    }


    // Primera ejecución: guarda la versión del formato y tareas de ejemplo.
    function migrate() as Void {
        if (Storage.getValue(KEY_VERSION) != null) {
            return;
        }
        save(KEY_TASKS, [
            ["Estudiar japonés (N5)", false],
            ["Revisar código - app", false]
        ] as Array<Array>);
        save(KEY_VERSION, FORMAT_VERSION);
    }

    function clip(text as String) as String {
        return text.length() > MAX_LEN ? text.substring(0, MAX_LEN) as String : text;
    }

    function save(key as String, value as Application.PropertyValueType) as Boolean {
        try {
            Storage.setValue(key, value);
            return true;
        } catch (e) {
            return false;
        }
    }
}
