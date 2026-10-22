import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Progreso de japonés guardado en el reloj: racha de días, aciertos y
// fallos por palabra. Las palabras falladas salen más en el quiz.
module JpProgress {

    const KEY_MISSES = "jp_miss";
    const KEY_OK = "jp_ok";
    const KEY_TOTAL = "jp_total";
    const KEY_STREAK = "jp_streak";
    const KEY_LAST = "jp_last";
    const KEY_CARD = "jp_card";

    const MAX_WEIGHT = 7;

    var _seeded as Boolean = false;

    function record(item as Number, right as Boolean) as Void {
        var misses = missMap();
        var count = misses[item];
        var current = count instanceof Number ? count : 0;
        if (right) {
            if (current > 0) {
                misses[item] = current - 1;
            }
            Store.save(KEY_OK, number(KEY_OK) + 1);
        } else {
            misses[item] = current + 1;
        }
        Store.save(KEY_MISSES, misses);
        Store.save(KEY_TOTAL, number(KEY_TOTAL) + 1);
        touchStreak();
    }

    // Tarjetas vistas también cuentan para la racha del día.
    function practiced() as Void {
        touchStreak();
    }

    // Elige una palabra al azar; las que fallaste pesan más.
    function pick(pool as Array<Number>, avoid as Number) as Number {
        seed();
        var misses = missMap();
        var total = 0;
        var weights = [] as Array<Number>;
        for (var i = 0; i < pool.size(); i++) {
            var weight = pool[i] == avoid && pool.size() > 1 ? 0 : weightFor(misses, pool[i]);
            weights.add(weight);
            total += weight;
        }
        var roll = Math.rand() % total;
        for (var i = 0; i < pool.size(); i++) {
            roll -= weights[i];
            if (roll < 0) {
                return pool[i];
            }
        }
        return pool[pool.size() - 1];
    }

    function random(limit as Number) as Number {
        seed();
        return Math.rand() % limit;
    }

    function summary() as String {
        var ok = number(KEY_OK);
        var total = number(KEY_TOTAL);
        var pct = total > 0 ? ok * 100 / total : 0;
        var pending = 0;
        var misses = missMap();
        var keys = misses.keys();
        for (var i = 0; i < keys.size(); i++) {
            var value = misses[keys[i]];
            if (value instanceof Number && value > 0) {
                pending++;
            }
        }
        return "Racha: " + currentStreak() + " días\n"
            + "Aciertos: " + ok + " de " + total + " (" + pct + "%)\n"
            + "Para repasar: " + pending + " palabras";
    }

    function currentStreak() as Number {
        var last = number(KEY_LAST);
        return (last == today() || last == yesterday()) ? number(KEY_STREAK) : 0;
    }

    function lastCard() as Number {
        return number(KEY_CARD);
    }

    function saveCard(position as Number) as Void {
        Store.save(KEY_CARD, position);
    }

    function touchStreak() as Void {
        var last = number(KEY_LAST);
        var now = today();
        if (last == now) {
            return;
        }
        Store.save(KEY_STREAK, last == yesterday() ? number(KEY_STREAK) + 1 : 1);
        Store.save(KEY_LAST, now);
    }

    function weightFor(misses as Dictionary, item as Number) as Number {
        var count = misses[item];
        var weight = 1 + (count instanceof Number ? count * 2 : 0);
        return weight > MAX_WEIGHT ? MAX_WEIGHT : weight;
    }

    function missMap() as Dictionary {
        var value = Storage.getValue(KEY_MISSES);
        return value instanceof Dictionary ? value : {};
    }

    function number(key as String) as Number {
        var value = Storage.getValue(key);
        return value instanceof Number ? value : 0;
    }

    function today() as Number {
        return ymd(Time.today());
    }

    function yesterday() as Number {
        return ymd(Time.today().subtract(new Time.Duration(Gregorian.SECONDS_PER_DAY)) as Time.Moment);
    }

    function ymd(moment as Time.Moment) as Number {
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        return (info.year as Number) * 10000 + (info.month as Number) * 100 + (info.day as Number);
    }

    function seed() as Void {
        if (!_seeded) {
            Math.srand(System.getTimer());
            _seeded = true;
        }
    }
}
