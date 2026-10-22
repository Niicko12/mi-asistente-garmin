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


// Un significado cortado ("Buenos días...") deja dos opciones iguales a la
// vista: todos deben caber completos en las dos líneas de su opción.
(:test)
function quizLabelsFit(logger as Logger) as Boolean {
    var dc = (Graphics.createBufferedBitmap({ :width => 454, :height => 454 }).get() as Graphics.BufferedBitmap).getDc();
    var max = JpQuiz.MAX_LABEL_PX;
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

// Cada categoría: elegir la opción correcta acierta y una distinta falla,
// sea cual sea su posición en el menú.
(:test)
function quizRoundAnswers(logger as Logger) as Boolean {
    for (var cat = 0; cat <= JapaneseDeck.KANA; cat++) {
        var round = new JpQuizRound(cat);
        for (var n = 0; n < 15; n++) {
            var correct = round.options.indexOf(round.item);
            Test.assert(correct >= 0);
            Test.assertEqual(round.options.size(), 3);
            var wrong = (correct + 1) % round.options.size();
            if (n % 2 == 0) {
                round.answer(correct);
                Test.assert(round.right);
            } else {
                round.answer(wrong);
                Test.assert(!round.right);
            }
            round.answer(correct);  // una segunda elección no cambia el resultado
            Test.assertEqual(round.right, n % 2 == 0);
            round.next();
        }
    }
    return true;
}
