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
        "Hiragana"
    ] as Array<String>;

    const KANA = 6;

    // [categoría, japonés, lectura en kana ("" si es igual), romaji, español]
    const ITEMS = [
        [0, "おはよう", "", "ohayou", "Buenos días (informal)"],
        [0, "おはようございます", "", "ohayou gozaimasu", "Buenos días (formal)"],
        [0, "こんにちは", "", "konnichiwa", "Hola / buenas tardes"],
        [0, "こんばんは", "", "konbanwa", "Buenas noches (saludo)"],
        [0, "おやすみなさい", "", "oyasuminasai", "Buenas noches (al dormir)"],
        [0, "ありがとう", "", "arigatou", "Gracias"],
        [0, "ありがとうございます", "", "arigatou gozaimasu", "Muchas gracias"],
        [0, "すみません", "", "sumimasen", "Disculpe"],
        [0, "ごめんなさい", "", "gomen nasai", "Perdón"],
        [0, "さようなら", "", "sayounara", "Adiós"],
        [0, "はじめまして", "", "hajimemashite", "Mucho gusto"],
        [0, "よろしくおねがいします", "", "yoroshiku onegaishimasu", "Encantado / cuento contigo"],

        [1, "はい", "", "hai", "Sí"],
        [1, "いいえ", "", "iie", "No"],
        [1, "わかりました", "", "wakarimashita", "Entendido"],
        [1, "わかりません", "", "wakarimasen", "No entiendo"],
        [1, "いくらですか", "", "ikura desu ka", "¿Cuánto cuesta?"],
        [1, "トイレはどこですか", "", "toire wa doko desu ka", "¿Dónde está el baño?"],
        [1, "もういちどおねがいします", "", "mou ichido onegaishimasu", "Otra vez, por favor"],
        [1, "がんばりましょう", "", "ganbarimashou", "¡Hagámoslo!"],
        [1, "いただきます", "", "itadakimasu", "Buen provecho (antes de comer)"],
        [1, "ごちそうさまでした", "", "gochisousama deshita", "Gracias por la comida"],
        [1, "だいじょうぶ", "", "daijoubu", "Está bien"],
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
        [3, "ごはん", "", "gohan", "Arroz / comida"],
        [3, "パン", "", "pan", "Pan"],
        [3, "魚", "さかな", "sakana", "Pescado"],
        [3, "肉", "にく", "niku", "Carne"],
        [3, "野菜", "やさい", "yasai", "Verduras"],
        [3, "果物", "くだもの", "kudamono", "Fruta"],
        [3, "卵", "たまご", "tamago", "Huevo"],
        [3, "コーヒー", "", "koohii", "Café"],
        [3, "おいしい", "", "oishii", "Delicioso"],

        [4, "食べます", "たべます", "tabemasu", "Comer"],
        [4, "飲みます", "のみます", "nomimasu", "Beber"],
        [4, "行きます", "いきます", "ikimasu", "Ir"],
        [4, "来ます", "きます", "kimasu", "Venir"],
        [4, "見ます", "みます", "mimasu", "Ver"],
        [4, "聞きます", "ききます", "kikimasu", "Escuchar"],
        [4, "読みます", "よみます", "yomimasu", "Leer"],
        [4, "書きます", "かきます", "kakimasu", "Escribir"],
        [4, "話します", "はなします", "hanashimasu", "Hablar"],
        [4, "勉強します", "べんきょうします", "benkyou shimasu", "Estudiar"],
        [4, "寝ます", "ねます", "nemasu", "Dormir"],
        [4, "起きます", "おきます", "okimasu", "Despertarse"],

        [5, "今日", "きょう", "kyou", "Hoy"],
        [5, "明日", "あした", "ashita", "Mañana (día)"],
        [5, "昨日", "きのう", "kinou", "Ayer"],
        [5, "今", "いま", "ima", "Ahora"],
        [5, "毎日", "まいにち", "mainichi", "Todos los días"],
        [5, "朝", "あさ", "asa", "Mañana (temprano)"],
        [5, "夜", "よる", "yoru", "Noche"],
        [5, "時間", "じかん", "jikan", "Tiempo / hora"],

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
        return ITEMS[item][0] as Number;
    }

    function jp(item as Number) as String {
        return ITEMS[item][1] as String;
    }

    function reading(item as Number) as String {
        return ITEMS[item][2] as String;
    }

    function romaji(item as Number) as String {
        return ITEMS[item][3] as String;
    }

    function meaning(item as Number) as String {
        return ITEMS[item][4] as String;
    }

    // Lo que se pronuncia: la lectura en kana si la hay, para que la voz no
    // dude con el kanji suelto.
    function spoken(item as Number) as String {
        var kana = reading(item);
        return kana.length() > 0 ? kana : jp(item);
    }

    function indicesFor(cat as Number) as Array<Number> {
        var result = [] as Array<Number>;
        for (var i = 0; i < ITEMS.size(); i++) {
            if (category(i) == cat) {
                result.add(i);
            }
        }
        return result;
    }
}
