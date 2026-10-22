import Toybox.Lang;
import Toybox.WatchUi;

// Menú de japonés: tarjetas por categoría, quiz por categoría, quiz de
// hiragana y progreso.
module JapaneseMenu {

    function push() as Void {
        var menu = new WatchUi.Menu2({ :title => Rez.Strings.MenuJapanese });
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.JpCards, Rez.Strings.JpCardsSub, :cards, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.JpQuiz, Rez.Strings.JpQuizSub, :quiz, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.JpKana, Rez.Strings.JpKanaSub, :kana, null));
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.JpProgress,
            (WatchUi.loadResource(Rez.Strings.JpStreak) as String) + " " + JpProgress.currentStreak(), :progress, null));
        WatchUi.pushView(menu, new JapaneseMenuDelegate(), WatchUi.SLIDE_LEFT);
    }

    function pushCategories(mode as Symbol) as Void {
        var title = mode == :cards ? Rez.Strings.JpCards : Rez.Strings.JpQuiz;
        var menu = new WatchUi.Menu2({ :title => title });
        for (var i = 0; i < JapaneseDeck.CATEGORIES.size(); i++) {
            if (i != JapaneseDeck.KANA) {
                menu.addItem(new WatchUi.MenuItem(JapaneseDeck.CATEGORIES[i],
                    JapaneseDeck.indicesFor(i).size() + " " + (WatchUi.loadResource(Rez.Strings.JpItems) as String), i, null));
            }
        }
        WatchUi.pushView(menu, new JpCategoryDelegate(mode), WatchUi.SLIDE_LEFT);
    }

    function openCards(category as Number) as Void {
        var view = new JpCardView(category);
        WatchUi.pushView(view, new JpCardDelegate(view), WatchUi.SLIDE_LEFT);
    }

    function openQuiz(category as Number) as Void {
        var view = new JpQuizView(category);
        WatchUi.pushView(view, new JpQuizDelegate(view), WatchUi.SLIDE_LEFT);
    }
}

class JapaneseMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :cards || id == :quiz) {
            JapaneseMenu.pushCategories(id as Symbol);
        } else if (id == :kana) {
            JapaneseMenu.openQuiz(JapaneseDeck.KANA);
        } else if (id == :progress) {
            Nav.pushText(Rez.Strings.JpProgress, JpProgress.summary());
        }
    }
}

class JpCategoryDelegate extends WatchUi.Menu2InputDelegate {

    private var _mode as Symbol;

    function initialize(mode as Symbol) {
        Menu2InputDelegate.initialize();
        _mode = mode;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var category = item.getId() as Number;
        if (_mode == :cards) {
            JapaneseMenu.openCards(category);
        } else {
            JapaneseMenu.openQuiz(category);
        }
    }
}
