// POST /api/ask-audio — pregunta hablada desde el reloj.
//
// Cuerpo: audio Ogg/Opus crudo, tal como lo graba Toybox.Audio.Capture.
// Connect IQ no deja elegir el Content-Type de un cuerpo binario, así que el
// formato se detecta por la firma "OggS". El contexto viaja en la URL:
//   ?tasks=a|b|c&notes=x|y
// Orden: Whisper (Groq) + respuesta en texto; si falla, Gemini con el audio.
// Respuesta:
//   { "transcript": "...", "answer": "..." }  |  { "error": "..." }

import { Type } from "@google/genai";
import {
  MAX_ITEMS,
  NotConfiguredError,
  answer,
  authorized,
  clean,
  contextText,
  generate,
  groqTranscribe,
  json,
  strings,
  stripWakeWord,
  watchText,
} from "../lib/assistant.js";

const NOT_HEARD = "No te escuché. Toca para intentarlo otra vez.";

// ~20 s de Opus a 16 kHz pesan unos 40 KB; esto deja margen.
const MAX_AUDIO_BYTES = 512 * 1024;

const INSTRUCTION =
  "El audio adjunto es una pregunta o pedido del usuario, hablado en español. " +
  "Devuelve en transcript lo que dijo, palabra por palabra, y en answer tu respuesta. " +
  "Si el audio está vacío o no se entiende, transcript vacío y answer pidiendo que lo repita.";

export async function POST(request: Request): Promise<Response> {
  if (!authorized(request)) {
    return json({ error: "unauthorized" }, 401);
  }

  const audio = Buffer.from(await request.arrayBuffer());
  if (audio.length === 0 || audio.length > MAX_AUDIO_BYTES) {
    return json({ error: "invalid audio size" }, 400);
  }
  const mimeType = detectMime(audio);
  if (!mimeType) {
    return json({ error: "unsupported audio" }, 415);
  }

  const url = new URL(request.url);
  const context = {
    tasks: strings(split(url.searchParams.get("tasks"))),
    notes: strings(split(url.searchParams.get("notes"))),
    watch: watchText(url.searchParams.get("watch")),
  };

  try {
    // Ruta rápida: Whisper de Groq transcribe y luego se responde en texto.
    const raw = await groqTranscribe(audio, mimeType);
    const transcript = raw ? stripWakeWord(raw) : raw;
    if (transcript === "") {
      return json({ transcript: "", answer: NOT_HEARD });
    }
    if (transcript) {
      const reply = clean((await answer(context, transcript)) ?? "");
      if (reply) return json({ transcript: clean(transcript, 160), answer: reply });
    }

    // Respaldo: Gemini escucha el audio directamente.
    const text = await generate(
      [
        `${contextText(context)}\n${INSTRUCTION}`,
        { inlineData: { mimeType, data: audio.toString("base64") } },
      ],
      {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            transcript: { type: Type.STRING },
            answer: { type: Type.STRING },
          },
          required: ["transcript", "answer"],
        },
      },
    );
    const parsed = parseReply(text);
    return parsed ? json(parsed) : json({ error: "upstream error" }, 502);
  } catch (error) {
    if (error instanceof NotConfiguredError) {
      return json({ error: "server not configured" }, 500);
    }
    throw error;
  }
}

function detectMime(audio: Buffer): string | null {
  const magic = audio.subarray(0, 4).toString("latin1");
  if (magic === "OggS") return "audio/ogg";
  if (magic === "RIFF") return "audio/wav";
  return null;
}

function split(value: string | null): string[] {
  return value ? value.split("|").slice(0, MAX_ITEMS) : [];
}

function parseReply(text: string | null): { transcript: string; answer: string } | null {
  if (!text) return null;
  try {
    const data = JSON.parse(text) as { transcript?: unknown; answer?: unknown };
    if (typeof data.answer !== "string") return null;
    const answer = clean(data.answer);
    if (!answer) return null;
    return {
      transcript: clean(typeof data.transcript === "string" ? data.transcript : "", 160),
      answer,
    };
  } catch {
    return null;
  }
}
