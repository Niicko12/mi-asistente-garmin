import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Test;

(:test)
function quizCorrectOption(logger as Logger) as Boolean {
    var options = [12, 5, 30] as Array<Number>;
    Test.assert(JpQuiz.isCorrect(options, 1, 5));
    Test.assert(!JpQuiz.isCorrect(options, 0, 5));
    Test.assert(!JpQuiz.isCorrect(options, 3, 5));
    return true;
}

(:test)
function quizRowHitTest(logger as Logger) as Boolean {
    var tops = [222, 270, 318] as Array<Number>;
    var h = 42;
    Test.assertEqual(JpQuiz.rowAt(240, tops, h), 0);
    Test.assertEqual(JpQuiz.rowAt(266, tops, h), 0); // hueco: más cerca de la 1.ª
    Test.assertEqual(JpQuiz.rowAt(268, tops, h), 1);
    Test.assertEqual(JpQuiz.rowAt(330, tops, h), 2);
    Test.assertEqual(JpQuiz.rowAt(150, tops, h), -1);
    Test.assertEqual(JpQuiz.rowAt(400, tops, h), -1);
    return true;
}

// Cada palabra del mazo: la opción correcta se acepta en cualquier posición.
(:test)
function quizEveryItemValidates(logger as Logger) as Boolean {
    for (var item = 0; item < JapaneseDeck.ITEMS.size(); item++) {
        for (var pos = 0; pos < 3; pos++) {
            var shuffled = [-1, -2, -3] as Array<Number>;
            shuffled[pos] = item;
            Test.assert(JpQuiz.isCorrect(shuffled, pos, item));
            Test.assert(!JpQuiz.isCorrect(shuffled, (pos + 1) % 3, item));
        }
    }
    return true;
}

// Tarjetas del teléfono: se dibuja el japonés si la fuente lo tiene, si no
// la lectura en kana, y si tampoco, nada (la vista usa el romaji).
(:test)
function customCardsDisplay(logger as Logger) as Boolean {
    JpCustom.replace([
        [1, "猫", "ねこ", "neko", "Gato"],
        [2, "食べます", "たべます", "tabemasu", "Como (comer)"],
        [3, "Ｘ", "", "ekkusu", "Equis"]
    ] as Array<Array>);
    var items = JapaneseDeck.indicesFor(JapaneseDeck.CUSTOM);
    Test.assertEqual(items.size(), 3);
    Test.assertEqual(JapaneseDeck.category(items[0]), JapaneseDeck.CUSTOM);
    Test.assertEqual(JapaneseDeck.display(items[0]), "ねこ");
    Test.assertEqual(JapaneseDeck.display(items[1]), "食べます");
    Test.assertEqual(JapaneseDeck.display(items[2]), "");
    Test.assertEqual(JapaneseDeck.meaning(items[1]), "Como (comer)");
    Test.assert(JpQuiz.isCorrect([items[2], items[0], items[1]] as Array<Number>, 1, items[0]));
    JpCustom.replace([] as Array<Array>);
    return true;
}

// La vista real: se dibuja en un bitmap del tamaño de la pantalla y se toca
// el centro de la fila correcta en cada pregunta de cada categoría.
(:test)
function quizViewTapCorrectRow(logger as Logger) as Boolean {
    var bitmap = Graphics.createBufferedBitmap({ :width => 454, :height => 454 }).get() as Graphics.BufferedBitmap;
    var dc = bitmap.getDc();
    for (var cat = 0; cat <= JapaneseDeck.KANA; cat++) {
        var view = new JpQuizView(cat);
        view.onShow();
        for (var round = 0; round < 15; round++) {
            view.onUpdate(dc);
            var options = view.currentOptions();
            var correct = options.indexOf(view.currentItem());
            Test.assert(correct >= 0);
            view.tapAt(view.rowCenter(correct));
            if (!view.wasRight()) {
                logger.debug("falló cat " + cat + " item " + view.currentItem());
                return false;
            }
            view.onUpdate(dc);
            view.tapAt(view.rowCenter(0));
        }
    }
    return true;
}

// Un significado cortado ("Buenos días...") deja dos opciones iguales a la
// vista: todos deben caber completos en su fila.
(:test)
function quizLabelsFit(logger as Logger) as Boolean {
    var dc = (Graphics.createBufferedBitmap({ :width => 454, :height => 454 }).get() as Graphics.BufferedBitmap).getDc();
    var max = 454 * JpQuiz.ROW_PERCENT / 100 - JpQuiz.ROW_PADDING;
    var ok = true;
    for (var i = 0; i < JapaneseDeck.ITEMS.size(); i++) {
        var label = JapaneseDeck.category(i) == JapaneseDeck.KANA ? JapaneseDeck.romaji(i) : JapaneseDeck.meaning(i);
        if (dc.getTextWidthInPixels(label, Graphics.FONT_XTINY) > max) {
            logger.debug("no cabe: " + label);
            ok = false;
        }
    }
    return ok;
}
