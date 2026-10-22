import Toybox.Lang;
import Toybox.WatchUi;

class MainDelegate extends WatchUi.BehaviorDelegate {

    private var _view as MainView;

    function initialize(view as MainView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    // START o toque: abre el menú.
    function onSelect() as Boolean {
        var menu = new WatchUi.Menu2({ :title => Rez.Strings.MenuTitle });
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.MenuAsk, null, :ask, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.MenuNote, null, :note, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.MenuTasks, null, :tasks, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.MenuProjects, null, :projects, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.MenuJapanese, null, :japanese, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.MenuStatus, null, :status, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.MenuDiagnostics, null, :diagnostics, null));
        WatchUi.pushView(menu, new MainMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

    // Prototipo 0.1: recorrer los estados visuales con DOWN/UP o deslizando.
    function onNextPage() as Boolean {
        _view.setStatus(AssistantState.next(_view.getStatus()));
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.setStatus(AssistantState.previous(_view.getStatus()));
        return true;
    }
}
