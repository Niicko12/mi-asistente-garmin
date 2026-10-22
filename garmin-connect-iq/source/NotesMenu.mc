import Toybox.Lang;
import Toybox.WatchUi;

// Notas rápidas guardadas en el reloj, la más reciente primero.
// Se crean con plantillas o escribiendo con TextPicker.
module NotesMenu {

    function push() as Void {
        var menu = new WatchUi.Menu2({ :title => Rez.Strings.NoteTitle });
        fill(menu);
        WatchUi.pushView(menu, new NotesDelegate(menu), WatchUi.SLIDE_LEFT);
    }

    function fill(menu as WatchUi.Menu2) as Void {
        while (menu.deleteItem(0) != null) {
        }
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.NewNote, null, :new, null));
        var list = Store.notes();
        for (var i = 0; i < list.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(list[i], null, i, null));
        }
    }

    // Plantillas: menos escritura en la muñeca.
    function pushNewNote(menu as WatchUi.Menu2) as Void {
        var picker = new WatchUi.Menu2({ :title => Rez.Strings.NewNote });
        picker.addItem(new WatchUi.MenuItem(Rez.Strings.WriteNote, null, :write, null));
        var templates = [Rez.Strings.TplIdea, Rez.Strings.TplTodo, Rez.Strings.TplRemember] as Array<ResourceId>;
        for (var i = 0; i < templates.size(); i++) {
            picker.addItem(new WatchUi.MenuItem(templates[i], null, templates[i], null));
        }
        WatchUi.pushView(picker, new NoteTemplateDelegate(menu), WatchUi.SLIDE_LEFT);
    }
}

class NotesDelegate extends WatchUi.Menu2InputDelegate {

    private var _menu as WatchUi.Menu2;

    function initialize(menu as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :new) {
            NotesMenu.pushNewNote(_menu);
        } else {
            var index = id as Number;
            var view = new TextView(WatchUi.loadResource(Rez.Strings.NoteTitle) as String,
                Store.notes()[index]);
            WatchUi.pushView(view, new NoteDetailDelegate(view, _menu, index), WatchUi.SLIDE_LEFT);
        }
    }
}

// Plantilla elegida: abre el TextPicker con el texto inicial.
class NoteTemplateDelegate extends WatchUi.Menu2InputDelegate {

    private var _menu as WatchUi.Menu2;

    function initialize(menu as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var initial = id == :write ? "" : WatchUi.loadResource(id as ResourceId) as String;
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.pushView(new WatchUi.TextPicker(initial), new NewNotePicker(_menu), WatchUi.SLIDE_LEFT);
    }
}

class NewNotePicker extends WatchUi.TextPickerDelegate {

    private var _menu as WatchUi.Menu2;

    function initialize(menu as WatchUi.Menu2) {
        TextPickerDelegate.initialize();
        _menu = menu;
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        if (text.length() > 0 && Store.addNote(text)) {
            NotesMenu.fill(_menu);
        }
        return true;
    }

    function onCancel() as Boolean {
        return true;
    }
}

// Detalle de una nota: UP/DOWN desplaza, START o toque la borra.
class NoteDetailDelegate extends TextViewDelegate {

    private var _menu as WatchUi.Menu2;
    private var _index as Number;

    function initialize(view as TextView, menu as WatchUi.Menu2, index as Number) {
        TextViewDelegate.initialize(view);
        _menu = menu;
        _index = index;
    }

    function onSelect() as Boolean {
        var prompt = WatchUi.loadResource(Rez.Strings.DeleteNote) as String;
        WatchUi.pushView(new WatchUi.Confirmation(prompt), new DeleteNoteConfirm(_menu, _index),
            WatchUi.SLIDE_IMMEDIATE);
        return true;
    }
}

class DeleteNoteConfirm extends WatchUi.ConfirmationDelegate {

    private var _menu as WatchUi.Menu2;
    private var _index as Number;

    function initialize(menu as WatchUi.Menu2, index as Number) {
        ConfirmationDelegate.initialize();
        _menu = menu;
        _index = index;
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES && Store.deleteNote(_index)) {
            NotesMenu.fill(_menu);
            // La confirmación se cierra sola; cerrar también el detalle.
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        return true;
    }
}
