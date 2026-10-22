import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _view as MainView;

    function initialize(view as MainView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :ask) {
            pushAskMenu();
        } else if (id == :note) {
            NotesMenu.push();
        } else if (id == :tasks) {
            TasksMenu.push();
        } else if (id == :japanese) {
            JapaneseMenu.push();
        } else if (id == :projects) {
            pushProjectsMenu();
        } else if (id == :status) {
            Nav.pushText(Rez.Strings.StatusTitle, statusBody());
        } else if (id == :diagnostics) {
            Nav.pushText(Rez.Strings.MenuDiagnostics, Diagnostics.report());
        } else if (id == :setup) {
            WatchUi.pushView(new SetupQrView(), new WatchUi.BehaviorDelegate(), WatchUi.SLIDE_LEFT);
        }
    }

    private function pushAskMenu() as Void {
        var menu = new WatchUi.Menu2({ :title => Rez.Strings.AskTitle });
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.AskVoice, null, :voice, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.AskWrite, null, :write, null));
        var questions = DemoData.questions();
        for (var i = 0; i < questions.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(questions[i], null, i, null));
        }
        WatchUi.pushView(menu, new AskMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    private function pushProjectsMenu() as Void {
        var menu = new WatchUi.Menu2({ :title => Rez.Strings.ProjectsTitle });
        var projects = DemoData.projects();
        for (var i = 0; i < projects.size(); i++) {
            menu.addItem(new WatchUi.MenuItem(projects[i][0] as String, projects[i][2] as String, i, null));
        }
        WatchUi.pushView(menu, new ProjectsMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    // Solo datos que la app conoce de verdad; nada de almacenamiento total.
    private function statusBody() as String {
        var phone = System.getDeviceSettings().phoneConnected
            ? Rez.Strings.PhoneConnected
            : Rez.Strings.PhoneDisconnected;
        return (WatchUi.loadResource(phone) as String) + "\n"
            + (WatchUi.loadResource(Rez.Strings.DataSource) as String) + "\n"
            + (WatchUi.loadResource(Rez.Strings.SyncStatus) as String) + "\n"
            + AssistantState.label(_view.getStatus());
    }
}

module Nav {
    function pushText(title as ResourceId, body as String) as Void {
        var view = new TextView(WatchUi.loadResource(title) as String, body);
        WatchUi.pushView(view, new TextViewDelegate(view), WatchUi.SLIDE_LEFT);
    }
}

class AskMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :voice) {
            Listen.push();
        } else if (id == :write) {
            WatchUi.pushView(new WatchUi.TextPicker(""), new AskPicker(), WatchUi.SLIDE_LEFT);
        } else {
            var view = new AnswerView(DemoData.questions()[id as Number]);
            WatchUi.pushView(view, new AnswerDelegate(view), WatchUi.SLIDE_LEFT);
        }
    }
}

class ProjectsMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var project = DemoData.projects()[item.getId() as Number];
        var body = (WatchUi.loadResource(Rez.Strings.LastUpdate) as String) + ": "
            + project[1] + "\n"
            + (WatchUi.loadResource(Rez.Strings.NextStep) as String) + ": "
            + project[2];
        var view = new TextView(project[0] as String, body);
        WatchUi.pushView(view, new TextViewDelegate(view), WatchUi.SLIDE_LEFT);
    }
}

class AskPicker extends WatchUi.TextPickerDelegate {

    function initialize() {
        TextPickerDelegate.initialize();
    }

    // Sustituye el picker por la respuesta.
    function onTextEntered(text as String, changed as Boolean) as Boolean {
        if (text.length() > 0) {
            var view = new AnswerView(text);
            WatchUi.switchToView(view, new AnswerDelegate(view), WatchUi.SLIDE_LEFT);
        }
        return true;
    }

    function onCancel() as Boolean {
        return true;
    }
}
