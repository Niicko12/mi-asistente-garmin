import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Lang;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;
import Toybox.Weather;

// Resumen de los datos del reloj que viaja con cada pregunta, para que el
// asistente pueda contestar "¿cuánta batería tengo?" o "¿cómo dormí?".
// Solo lo que el SDK expone a apps; cada dato se omite si no está.
module WatchData {

    function snapshot() as String {
        var parts = [] as Array<String>;
        addTime(parts);
        addBattery(parts);
        addActivity(parts);
        addHeart(parts);
        addHistory(parts);
        addProfile(parts);
        addWeather(parts);
        var result = "";
        for (var i = 0; i < parts.size(); i++) {
            result += (i > 0 ? "; " : "") + parts[i];
        }
        return result;
    }

    function addTime(parts as Array<String>) as Void {
        var now = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        parts.add("Hora " + now.hour.format("%02d") + ":" + now.min.format("%02d")
            + ", " + now.day_of_week + " " + now.day + " " + now.month);
    }

    function addBattery(parts as Array<String>) as Void {
        var stats = System.getSystemStats();
        var text = "Batería " + stats.battery.format("%d") + "%";
        if (stats has :batteryInDays && stats.batteryInDays != null) {
            text += " (~" + stats.batteryInDays.format("%d") + " días)";
        }
        if (stats.charging) {
            text += ", cargando";
        }
        parts.add(text);
    }

    function addActivity(parts as Array<String>) as Void {
        var info = ActivityMonitor.getInfo();
        if (info.steps != null) {
            var steps = "Pasos " + info.steps;
            if (info.stepGoal != null) {
                steps += " de " + info.stepGoal;
            }
            parts.add(steps);
        }
        if (info.calories != null) {
            parts.add("Calorías " + info.calories + " kcal");
        }
        if (info.distance != null) {
            parts.add("Distancia hoy " + (info.distance / 100000.0).format("%.1f") + " km");
        }
        if (info has :floorsClimbed && info.floorsClimbed != null) {
            parts.add("Pisos subidos " + info.floorsClimbed);
        }
        if (info has :activeMinutesWeek && info.activeMinutesWeek != null) {
            var week = "Minutos de intensidad semana " + info.activeMinutesWeek.total;
            if (info.activeMinutesWeekGoal != null) {
                week += " de " + info.activeMinutesWeekGoal;
            }
            parts.add(week);
        }
        if (info has :stressScore && info.stressScore != null) {
            parts.add("Estrés " + info.stressScore + "/100");
        }
        if (info has :respirationRate && info.respirationRate != null) {
            parts.add("Respiración " + info.respirationRate + " rpm");
        }
        if (info has :timeToRecovery && info.timeToRecovery != null && info.timeToRecovery > 0) {
            parts.add("Tiempo de recuperación " + info.timeToRecovery + " h");
        }
    }

    function addHeart(parts as Array<String>) as Void {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentHeartRate != null) {
            parts.add("Pulso actual " + info.currentHeartRate + " lpm");
        }
    }

    function addHistory(parts as Array<String>) as Void {
        if (!(Toybox has :SensorHistory)) {
            return;
        }
        if (SensorHistory has :getBodyBatteryHistory) {
            var value = latest(SensorHistory.getBodyBatteryHistory({ :period => 1 }));
            if (value != null) {
                parts.add("Body Battery " + value.format("%d"));
            }
        }
        if (SensorHistory has :getOxygenSaturationHistory) {
            var value = latest(SensorHistory.getOxygenSaturationHistory({ :period => 1 }));
            if (value != null) {
                parts.add("SpO2 " + value.format("%d") + "%");
            }
        }
    }

    function latest(iterator as SensorHistory.SensorHistoryIterator) as Numeric or Null {
        var sample = iterator.next();
        return sample != null ? sample.data : null;
    }

    function addProfile(parts as Array<String>) as Void {
        var profile = UserProfile.getProfile();
        if (profile.restingHeartRate != null) {
            parts.add("Pulso en reposo " + profile.restingHeartRate + " lpm");
        }
        if (profile has :vo2maxRunning && profile.vo2maxRunning != null) {
            parts.add("VO2máx carrera " + profile.vo2maxRunning);
        }
        if (profile.sleepTime != null && profile.wakeTime != null) {
            parts.add("Horario de sueño " + clock(profile.sleepTime.value()) + " a " + clock(profile.wakeTime.value()));
        }
    }

    function addWeather(parts as Array<String>) as Void {
        if (!(Toybox has :Weather)) {
            return;
        }
        var now = Weather.getCurrentConditions();
        if (now == null) {
            return;
        }
        var text = "Clima";
        if (now.observationLocationName != null) {
            text += " en " + now.observationLocationName;
        }
        if (now.temperature != null) {
            text += " " + now.temperature.format("%d") + "°C";
        }
        var condition = conditionText(now.condition);
        if (condition != null) {
            text += ", " + condition;
        }
        if (now.highTemperature != null && now.lowTemperature != null) {
            text += ", máx " + now.highTemperature.format("%d") + "° mín " + now.lowTemperature.format("%d") + "°";
        }
        if (now.precipitationChance != null) {
            text += ", lluvia " + now.precipitationChance + "%";
        }
        parts.add(text);

        var position = now.observationLocationPosition;
        if (position != null && Weather has :getSunrise) {
            var sunrise = Weather.getSunrise(position, Time.now());
            var sunset = Weather.getSunset(position, Time.now());
            if (sunrise != null && sunset != null) {
                parts.add("Amanecer " + momentClock(sunrise) + ", atardecer " + momentClock(sunset));
            }
        }
    }

    function conditionText(condition as Number or Null) as String or Null {
        switch (condition) {
            case Weather.CONDITION_CLEAR:
                return "despejado";
            case Weather.CONDITION_MOSTLY_CLEAR:
            case Weather.CONDITION_PARTLY_CLEAR:
            case Weather.CONDITION_PARTLY_CLOUDY:
                return "parcialmente nublado";
            case Weather.CONDITION_MOSTLY_CLOUDY:
            case Weather.CONDITION_CLOUDY:
                return "nublado";
            case Weather.CONDITION_DRIZZLE:
            case Weather.CONDITION_LIGHT_RAIN:
            case Weather.CONDITION_SCATTERED_SHOWERS:
            case Weather.CONDITION_SHOWERS:
                return "lluvia ligera";
            case Weather.CONDITION_RAIN:
            case Weather.CONDITION_HEAVY_RAIN:
                return "lluvia";
            case Weather.CONDITION_THUNDERSTORMS:
                return "tormentas";
            case Weather.CONDITION_FOG:
            case Weather.CONDITION_HAZY:
                return "niebla o bruma";
            case Weather.CONDITION_WINDY:
                return "ventoso";
            case Weather.CONDITION_HAIL:
                return "granizo";
            default:
                return null;
        }
    }

    // Segundos desde medianoche a "HH:MM".
    function clock(seconds as Number) as String {
        return (seconds / 3600).format("%02d") + ":" + ((seconds % 3600) / 60).format("%02d");
    }

    function momentClock(moment as Time.Moment) as String {
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d");
    }
}
