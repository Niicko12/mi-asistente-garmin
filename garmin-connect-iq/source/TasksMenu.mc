import Toybox.Lang;
import Toybox.WatchUi;

// Lista de tareas guardadas en el reloj. Seleccionar una tarea la marca
// como hecha o pendiente.
module TasksMenu {

    function push() as Void {
        var menu = new WatchUi.Menu2({ :title => Rez.Strings.TasksTitle });
        fill(menu);
        WatchUi.pushView(menu, new TasksDelegate(menu), WatchUi.SLIDE_LEFT);
    }

    // Vacía y vuelve a llenar el menú para que los índices sigan a Store.
    function fill(menu as WatchUi.Menu2) as Void {
        while (menu.deleteItem(0) != null) {
        }
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.NewTask, null, :new, null));
        var list = Store.tasks();
        for (var i = 0; i < list.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(list[i][0] as String,
                subLabel(list[i][1] as Boolean), i, null));
        }
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.PurgeDone, null, :purge, null));
    }

    function subLabel(done as Boolean) as String {
        return WatchUi.loadResource(done ? Rez.Strings.TaskDone : Rez.Strings.TaskPending) as String;
    }
}

class TasksDelegate extends WatchUi.Menu2InputDelegate {

    private var _menu as WatchUi.Menu2;

    function initialize(menu as WatchUi.Menu2) {
        Menu2InputDelegate.initialize();
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :new) {
            WatchUi.pushView(new WatchUi.TextPicker(""), new NewTaskPicker(_menu), WatchUi.SLIDE_LEFT);
        } else if (id == :purge) {
            Store.removeDoneTasks();
            TasksMenu.fill(_menu);
            WatchUi.requestUpdate();
        } else {
            var index = id as Number;
            var done = !(Store.tasks()[index][1] as Boolean);
            if (Store.setTaskDone(index, done)) {
                item.setSubLabel(TasksMenu.subLabel(done));
                WatchUi.requestUpdate();
            }
        }
    }
}

class NewTaskPicker extends WatchUi.TextPickerDelegate {

    private var _menu as WatchUi.Menu2;

    function initialize(menu as WatchUi.Menu2) {
        TextPickerDelegate.initialize();
        _menu = menu;
    }

    function onTextEntered(text as String, changed as Boolean) as Boolean {
        if (text.length() > 0 && Store.addTask(text)) {
            TasksMenu.fill(_menu);
        }
        return true;
    }

    function onCancel() as Boolean {
        return true;
    }
}
