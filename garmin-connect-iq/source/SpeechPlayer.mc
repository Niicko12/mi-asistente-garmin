import Toybox.Audio;
import Toybox.Audio.Output;
import Toybox.Lang;
import Toybox.StringUtil;

// Dice la respuesta en voz alta por el altavoz del reloj. El reloj rechaza
// respuestas web grandes, así que /api/speak entrega la voz por partes
// (Ogg/Opus en base64): mientras suena una parte se pide la siguiente.
// Avisa con onSpeaking(true/false) para que la cara mueva la boca, y con
// onError(código) si la voz no se pudo pedir o reproducir.
class SpeechPlayer {

    // Códigos propios (los de red son los de Communications, negativos o HTTP).
    const ERR_DECODE = 1;
    const ERR_PLAYBACK = 2;

    private var _onSpeaking as Method(speaking as Boolean) as Void;
    private var _onError as Method(code as Number) as Void;
    private var _active as Boolean = false;
    private var _text as String = "";
    private var _parts as Number = 1;
    private var _nextPart as Number = 0;
    private var _inFlight as Boolean = false;
    private var _playing as Boolean = false;
    private var _pending as ByteArray?;
    private var _provider as String = "";

    function initialize(onSpeaking as Method(speaking as Boolean) as Void,
                        onError as Method(code as Number) as Void) {
        _onSpeaking = onSpeaking;
        _onError = onError;
    }

    function say(text as String) as Void {
        stop();
        _active = true;
        _text = text;
        _parts = 1;
        _nextPart = 0;
        _provider = "";
        request();
    }

    // Al salir de la pantalla o al preguntar otra vez: cortar todo.
    function stop() as Void {
        _active = false;
        _pending = null;
        _playing = false;
        if (Output.getState() == Output.PLAYBACK_PLAYING) {
            Output.registerStateChangeHandler(null);
            Output.stop();
        }
    }

    private function request() as Void {
        _inFlight = true;
        AssistantApi.speak(_text, _nextPart, _provider, method(:onResponse));
        _nextPart++;
    }

    function onResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        _inFlight = false;
        if (!_active) {
            return;
        }
        if (responseCode != 200 || !(data instanceof Dictionary) || !(data["audio"] instanceof String)) {
            _active = false;
            finishIfIdle();
            _onError.invoke(responseCode);
            return;
        }
        var parts = data["parts"];
        if (parts instanceof Number) {
            _parts = parts;
        }
        var provider = data["provider"];
        if (provider instanceof String) {
            _provider = provider;
        }
        var bytes = decode(data["audio"] as String);
        if (bytes == null) {
            _active = false;
            finishIfIdle();
            _onError.invoke(ERR_DECODE);
            return;
        }
        if (_playing) {
            _pending = bytes;
        } else {
            play(bytes);
        }
    }

    private function decode(audio as String) as ByteArray? {
        try {
            return StringUtil.convertEncodedString(audio, {
                :fromRepresentation => StringUtil.REPRESENTATION_STRING_BASE64,
                :toRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY
            }) as ByteArray;
        } catch (e) {
            return null;
        }
    }

    private function play(bytes as ByteArray) as Void {
        try {
            var builder = new Output.DynamicAudioSourceBuilder({
                :format => {
                    :containerFormat => Audio.CONTAINER_OGG,
                    :codec => Audio.CODEC_OPUS,
                    :frequency => Audio.FREQ_24_KHZ,
                    :channels => Audio.CHANNEL_MONO
                }
            });
            builder.append(bytes);
            Output.registerStateChangeHandler(method(:onStateChange));
            Output.play(builder.complete(), 0);
            _playing = true;
            _onSpeaking.invoke(true);
        } catch (e) {
            _active = false;
            _playing = false;
            finishIfIdle();
            _onError.invoke(ERR_PLAYBACK);
            return;
        }
        // Pedir la siguiente parte mientras suena esta.
        if (_nextPart < _parts && !_inFlight) {
            request();
        }
    }

    function onStateChange(newState as Output.PlaybackState) as Void {
        if (newState == Output.PLAYBACK_PLAYING) {
            return;
        }
        _playing = false;
        if (newState == Output.PLAYBACK_ERROR) {
            var error = Output.getError();
            _active = false;
            finishIfIdle();
            _onError.invoke(error != null ? 100 + (error as Number) : ERR_PLAYBACK);
            return;
        }
        var pending = _pending;
        if (_active && pending != null) {
            _pending = null;
            play(pending);
        } else {
            finishIfIdle();
        }
    }

    // La boca se cierra cuando ya no suena nada ni falta ninguna parte.
    private function finishIfIdle() as Void {
        if (!_playing && (_pending == null) && (!_active || (!_inFlight && _nextPart >= _parts))) {
            Output.registerStateChangeHandler(null);
            _onSpeaking.invoke(false);
        }
    }
}
