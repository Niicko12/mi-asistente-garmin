import Toybox.Audio;
import Toybox.Audio.Capture;
import Toybox.Lang;

// Graba la pregunta en Ogg/Opus 16 kHz mono (~2 KB/s) con Toybox.Audio.Capture.
// Solo funciona con la app en primer plano. Al detenerse entrega el audio
// completo, o null si hubo un error.
class VoiceRecorder {

    private var _chunks as Array<ByteArray> = [] as Array<ByteArray>;
    private var _onDone as Method(audio as ByteArray or Null) as Void;
    private var _finished as Boolean = false;

    function initialize(onDone as Method(audio as ByteArray or Null) as Void) {
        _onDone = onDone;
    }

    function start() as Boolean {
        var filters = [] as Array<Capture.Filter>;
        if (Capture.getSupportedFilters().indexOf(Capture.FILTER_NREC) >= 0) {
            filters.add(Capture.FILTER_NREC);
        }
        try {
            Capture.initializeAudioCapture(self, {
                :format => {
                    :containerFormat => Audio.CONTAINER_OGG,
                    :codec => Audio.CODEC_OPUS,
                    :frequency => Audio.FREQ_16_KHZ,
                    :channels => Audio.CHANNEL_MONO
                },
                :windowFilledBehavior => Capture.WINDOW_FILLED_CONTINUE,
                :filters => filters
            });
            Capture.start();
            return true;
        } catch (e) {
            return false;
        }
    }

    // Al detener, Capture entrega lo pendiente a onData y luego llama onComplete.
    function stop() as Void {
        if (Capture.getState() == Capture.CAPTURE_CAPTURING) {
            Capture.stop();
        }
    }

    function isRecording() as Boolean {
        return Capture.getState() == Capture.CAPTURE_CAPTURING;
    }

    function onData(audioData as ByteArray) as Void {
        _chunks.add(audioData);
    }

    function onError(error as Capture.Error) as Void {
        finish(null);
    }

    function onComplete() as Void {
        var audio = []b;
        for (var i = 0; i < _chunks.size(); i++) {
            audio.addAll(_chunks[i]);
        }
        _chunks = [] as Array<ByteArray>;
        finish(audio);
    }

    private function finish(audio as ByteArray or Null) as Void {
        if (!_finished) {
            _finished = true;
            _onDone.invoke(audio);
        }
    }
}
