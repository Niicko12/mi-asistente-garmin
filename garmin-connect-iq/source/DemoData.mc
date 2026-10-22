import Toybox.Application;
import Toybox.Lang;

// Preguntas sugeridas y proyectos. Los del panel del teléfono (PhoneSync)
// tienen prioridad; sin ninguno se usan los de ejemplo de abajo.
module DemoData {

    const KEY_QUESTIONS = "questions";
    const KEY_PROJECTS = "projects";

    function questions() as Array<String> {
        var stored = Storage.getValue(KEY_QUESTIONS);
        return stored instanceof Array && stored.size() > 0 ? stored as Array<String> : QUESTIONS;
    }

    // Cada proyecto: [nombre, último avance, siguiente paso].
    function projects() as Array<Array> {
        var stored = Storage.getValue(KEY_PROJECTS);
        if (stored instanceof Array && stored.size() > 0) {
            return stored as Array<Array>;
        }
        var result = [] as Array<Array>;
        for (var i = 0; i < PROJECT_TITLES.size(); i++) {
            result.add([PROJECT_TITLES[i], PROJECT_LAST[i], PROJECT_NEXT[i]]);
        }
        return result;
    }

    const QUESTIONS = [
        "¿Qué tengo pendiente?",
        "¿Qué hago primero hoy?",
        "Dame una frase en japonés"
    ] as Array<String>;


    const PROJECT_TITLES = [
        "Mi Asistente Garmin",
        "Proyecto Japón"
    ] as Array<String>;

    const PROJECT_LAST = [
        "Plan v0.2 revisado",
        "Vocabulario N5"
    ] as Array<String>;

    const PROJECT_NEXT = [
        "Validar capacidades",
        "Pruebas de API"
    ] as Array<String>;
}
