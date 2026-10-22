import Toybox.Application;
import Toybox.Audio;
import Toybox.Audio.Capture;
import Toybox.Lang;
import Toybox.Time;

// Fase 1: comprueba en el dispositivo real las hipótesis de
// docs/capability-validation.md (filas 1, 5, 8).
module Diagnostics {

    function report() as String {
        return "Mic Opus: " + yesNo(micFormat(Audio.CONTAINER_OGG, Audio.CODEC_OPUS)) + "\n"
            + "Mic WAV: " + yesNo(micFormat(Audio.CONTAINER_WAV, Audio.CODEC_LPCM)) + "\n"
            + "Filtro ruido: " + yesNo(hasNoiseFilter()) + "\n"
            + "Almacenamiento: " + storageCheck() + "\n"
            + "Tareas: " + Store.tasks().size() + " · Notas: " + Store.notes().size();
    }

    function micFormat(container as Audio.ContainerFormat, codec as Audio.Codec) as Boolean {
        try {
            return Capture.isFormatSupported({
                :containerFormat => container,
                :codec => codec,
                :frequency => Audio.FREQ_16_KHZ,
                :channels => Audio.CHANNEL_MONO
            });
        } catch (e) {
            return false;
        }
    }

    function hasNoiseFilter() as Boolean {
        try {
            return Capture.getSupportedFilters().indexOf(Capture.FILTER_NREC) >= 0;
        } catch (e) {
            return false;
        }
    }

    function storageCheck() as String {
        try {
            var stamp = Time.now().value();
            Storage.setValue("diag", stamp);
            return Storage.getValue("diag") == stamp ? "OK" : "lectura distinta";
        } catch (e) {
            return "falló";
        }
    }

    function yesNo(value as Boolean) as String {
        return value ? "sí" : "no";
    }
}
