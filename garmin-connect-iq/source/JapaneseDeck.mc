import Toybox.Lang;

// Mazo N5 local. tools/make_font.py extrae de este archivo los caracteres
// japoneses para la fuente propia: tras cambiarlo, regenerar la fuente.
// El japonés va solo en la fuente propia; romaji y español en la del sistema.
module JapaneseDeck {

    const TITLE = "日本語";

    const CATEGORIES = [
        "Saludos",
        "Frases útiles",
        "Números",
        "Comida",
        "Verbos",
        "Tiempo",
        "Hiragana",
        "Mis tarjetas"
    ] as Array<String>;

    const KANA = 6;
    // Tarjetas del teléfono (JpCustom); el menú la oculta si no hay ninguna.
    const CUSTOM = 7;

    // [categoría, japonés, lectura en kana ("" si es igual), romaji, español]
// Los verbos van en forma cortés ます (presente/futuro): "como", no "comer";
// el infinitivo va entre paréntesis.
    const ITEMS = [
        [0, "おはよう", "", "ohayou", "Buenos días (informal)"],
        [0, "おはようございます", "", "ohayou gozaimasu", "Buenos días (formal)"],
        [0, "こんにちは", "", "konnichiwa", "Hola / buenas tardes"],
        [0, "こんばんは", "", "konbanwa", "Buenas noches (saludo)"],
        [0, "おやすみなさい", "", "oyasuminasai", "Buenas noches (al dormir)"],
        [0, "ありがとう", "", "arigatou", "Gracias"],
        [0, "ありがとうございます", "", "arigatou gozaimasu", "Muchas gracias"],
        [0, "すみません", "", "sumimasen", "Disculpe / perdone"],
        [0, "ごめんなさい", "", "gomennasai", "Perdón (disculpa)"],
        [0, "さようなら", "", "sayounara", "Adiós"],
        [0, "はじめまして", "", "hajimemashite", "Mucho gusto"],
        [0, "よろしくおねがいします", "", "yoroshiku onegaishimasu", "Un placer / cuento contigo"],

        [1, "はい", "", "hai", "Sí"],
        [1, "いいえ", "", "iie", "No"],
        [1, "わかりました", "", "wakarimashita", "Entendido"],
        [1, "わかりません", "", "wakarimasen", "No entiendo"],
        [1, "いくらですか", "", "ikura desu ka", "¿Cuánto cuesta?"],
        [1, "トイレはどこですか", "", "toire wa doko desu ka", "¿Dónde está el baño?"],
        [1, "もういちどおねがいします", "", "mou ichido onegaishimasu", "Otra vez, por favor"],
        [1, "がんばりましょう", "", "ganbarimashou", "¡Esforcémonos!"],
        [1, "いただきます", "", "itadakimasu", "Buen provecho (antes de comer)"],
        [1, "ごちそうさまでした", "", "gochisousama deshita", "Gracias por la comida"],
        [1, "だいじょうぶ", "", "daijoubu", "Estoy bien / tranquilo"],
        [1, "ちょっとまって", "", "chotto matte", "Espera un momento"],

        [2, "一", "いち", "ichi", "Uno"],
        [2, "二", "に", "ni", "Dos"],
        [2, "三", "さん", "san", "Tres"],
        [2, "四", "よん", "yon", "Cuatro"],
        [2, "五", "ご", "go", "Cinco"],
        [2, "六", "ろく", "roku", "Seis"],
        [2, "七", "なな", "nana", "Siete"],
        [2, "八", "はち", "hachi", "Ocho"],
        [2, "九", "きゅう", "kyuu", "Nueve"],
        [2, "十", "じゅう", "juu", "Diez"],
        [2, "百", "ひゃく", "hyaku", "Cien"],

        [3, "水", "みず", "mizu", "Agua"],
        [3, "お茶", "おちゃ", "ocha", "Té"],
        [3, "ごはん", "", "gohan", "Arroz cocido / comida"],
        [3, "パン", "", "pan", "Pan"],
        [3, "魚", "さかな", "sakana", "Pescado"],
        [3, "肉", "にく", "niku", "Carne"],
        [3, "野菜", "やさい", "yasai", "Verduras"],
        [3, "果物", "くだもの", "kudamono", "Fruta"],
        [3, "卵", "たまご", "tamago", "Huevo"],
        [3, "コーヒー", "", "koohii", "Café"],
        [3, "おいしい", "", "oishii", "Rico / delicioso"],

        [4, "食べます", "たべます", "tabemasu", "Como (comer)"],
        [4, "飲みます", "のみます", "nomimasu", "Bebo (beber)"],
        [4, "行きます", "いきます", "ikimasu", "Voy (ir)"],
        [4, "来ます", "きます", "kimasu", "Vengo (venir)"],
        [4, "見ます", "みます", "mimasu", "Veo (ver)"],
        [4, "聞きます", "ききます", "kikimasu", "Escucho (escuchar)"],
        [4, "読みます", "よみます", "yomimasu", "Leo (leer)"],
        [4, "書きます", "かきます", "kakimasu", "Escribo (escribir)"],
        [4, "話します", "はなします", "hanashimasu", "Hablo (hablar)"],
        [4, "勉強します", "べんきょうします", "benkyou shimasu", "Estudio (estudiar)"],
        [4, "寝ます", "ねます", "nemasu", "Me acuesto (dormir)"],
        [4, "起きます", "おきます", "okimasu", "Me levanto (despertar)"],

        [5, "今日", "きょう", "kyou", "Hoy"],
        [5, "明日", "あした", "ashita", "Mañana (día siguiente)"],
        [5, "昨日", "きのう", "kinou", "Ayer"],
        [5, "今", "いま", "ima", "Ahora"],
        [5, "毎日", "まいにち", "mainichi", "Todos los días"],
        [5, "朝", "あさ", "asa", "La mañana (horario)"],
        [5, "夜", "よる", "yoru", "Noche"],
        [5, "時間", "じかん", "jikan", "Tiempo (duración)"],

        [6, "あ", "", "a", ""], [6, "い", "", "i", ""], [6, "う", "", "u", ""], [6, "え", "", "e", ""], [6, "お", "", "o", ""],
        [6, "か", "", "ka", ""], [6, "き", "", "ki", ""], [6, "く", "", "ku", ""], [6, "け", "", "ke", ""], [6, "こ", "", "ko", ""],
        [6, "さ", "", "sa", ""], [6, "し", "", "shi", ""], [6, "す", "", "su", ""], [6, "せ", "", "se", ""], [6, "そ", "", "so", ""],
        [6, "た", "", "ta", ""], [6, "ち", "", "chi", ""], [6, "つ", "", "tsu", ""], [6, "て", "", "te", ""], [6, "と", "", "to", ""],
        [6, "な", "", "na", ""], [6, "に", "", "ni", ""], [6, "ぬ", "", "nu", ""], [6, "ね", "", "ne", ""], [6, "の", "", "no", ""],
        [6, "は", "", "ha", ""], [6, "ひ", "", "hi", ""], [6, "ふ", "", "fu", ""], [6, "へ", "", "he", ""], [6, "ほ", "", "ho", ""],
        [6, "ま", "", "ma", ""], [6, "み", "", "mi", ""], [6, "む", "", "mu", ""], [6, "め", "", "me", ""], [6, "も", "", "mo", ""],
        [6, "や", "", "ya", ""], [6, "ゆ", "", "yu", ""], [6, "よ", "", "yo", ""],
        [6, "ら", "", "ra", ""], [6, "り", "", "ri", ""], [6, "る", "", "ru", ""], [6, "れ", "", "re", ""], [6, "ろ", "", "ro", ""],
        [6, "わ", "", "wa", ""], [6, "を", "", "wo", ""], [6, "ん", "", "n", ""]
    ] as Array<Array>;

    function category(item as Number) as Number {
        return item >= JpCustom.BASE ? CUSTOM : ITEMS[item][0] as Number;
    }

    // Campo 1..4 de una tarjeta del mazo o del teléfono.
    function field(item as Number, index as Number) as String {
        if (item < JpCustom.BASE) {
            return ITEMS[item][index] as String;
        }
        var card = JpCustom.find(item);
        return card != null && card[index] instanceof String ? card[index] as String : "";
    }

    function jp(item as Number) as String {
        return field(item, 1);
    }

    function reading(item as Number) as String {
        return field(item, 2);
    }

    function romaji(item as Number) as String {
        return field(item, 3);
    }

    function meaning(item as Number) as String {
        return field(item, 4);
    }

    // Lo que se dibuja con la fuente japonesa: el japonés si la fuente tiene
    // todos sus caracteres, si no la lectura en kana, o "" si tampoco (entonces
    // la vista muestra el romaji con la fuente del sistema).
    function display(item as Number) as String {
        var text = jp(item);
        if (drawable(text)) {
            return text;
        }
        text = reading(item);
        return drawable(text) ? text : "";
    }

    function drawable(text as String) as Boolean {
        if (text.length() == 0) {
            return false;
        }
        var chars = text.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            if (JpCharset.CHARS.find(chars[i].toString()) == null) {
                return false;
            }
        }
        return true;
    }

    // Lo que se pronuncia: la lectura en kana si la hay, para que la voz no
    // dude con el kanji suelto.
    function spoken(item as Number) as String {
        var kana = reading(item);
        return kana.length() > 0 ? kana : jp(item);
    }

    function indicesFor(cat as Number) as Array<Number> {
        var result = [] as Array<Number>;
        if (cat == CUSTOM) {
            var cards = JpCustom.cards();
            for (var i = 0; i < cards.size(); i++) {
                result.add(JpCustom.BASE + (cards[i][0] as Number));
            }
            return result;
        }
        for (var i = 0; i < ITEMS.size(); i++) {
            if (category(i) == cat) {
                result.add(i);
            }
        }
        return result;
    }
}
