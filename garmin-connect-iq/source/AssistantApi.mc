import Toybox.Communications;
import Toybox.Lang;

// Cliente del backend (integration-service). La petición sale por el
// teléfono vía Garmin Connect; la clave de Gemini nunca está en el reloj.
module AssistantApi {

    const MAX_CONTEXT_NOTES = 5;

    function ask(question as String,
                 callback as Method(responseCode as Number, data as Dictionary or String or Null) as Void) as Void {
        Communications.makeWebRequest(
            Secrets.API_URL + "/api/ask",
            {
                "q" => question,
                "tasks" => pendingTasks(),
                "notes" => recentNotes(),
                "watch" => WatchData.snapshot()
            },
            {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => "Bearer " + Secrets.DEVICE_TOKEN
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            callback
        );
    }

    // Pregunta hablada: el audio va en el cuerpo y el contexto en la URL
    // (Connect IQ codifica los parámetros cuando hay :body).
    function askAudio(audio as ByteArray,
                      callback as Method(responseCode as Number, data as Dictionary or String or Null) as Void) as Void {
        Communications.makeWebRequest(
            Secrets.API_URL + "/api/ask-audio",
            {
                "tasks" => join(pendingTasks()),
                "notes" => join(recentNotes()),
                "watch" => WatchData.snapshot()
            },
            {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => { "Authorization" => "Bearer " + Secrets.DEVICE_TOKEN },
                :body => audio,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            callback
        );
    }

    // Voz de la respuesta, una parte a la vez: Ogg/Opus en base64 dentro del JSON.
    // `provider`: el de la primera parte, para que la voz no cambie a la mitad.
    function speak(text as String, part as Number, provider as String,
                   callback as Method(responseCode as Number, data as Dictionary or String or Null) as Void) as Void {
        Communications.makeWebRequest(
            Secrets.API_URL + "/api/speak",
            { "text" => text, "part" => part, "provider" => provider },
            {
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :headers => {
                    "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                    "Authorization" => "Bearer " + Secrets.DEVICE_TOKEN
                },
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            callback
        );
    }

    // Separador "|", el que espera /api/ask-audio.
    function join(items as Array<String>) as String {
        var result = "";
        for (var i = 0; i < items.size(); i++) {
            result += (i > 0 ? "|" : "") + items[i];
        }
        return result;
    }

    // Contexto mínimo: solo títulos de tareas pendientes y notas recientes.
    function pendingTasks() as Array<String> {
        var result = [] as Array<String>;
        var list = Store.tasks();
        for (var i = 0; i < list.size(); i++) {
            if (!(list[i][1] as Boolean)) {
                result.add(list[i][0] as String);
            }
        }
        return result;
    }

    function recentNotes() as Array<String> {
        var list = Store.notes();
        return list.size() > MAX_CONTEXT_NOTES ? list.slice(0, MAX_CONTEXT_NOTES) : list;
    }
}
