// POST /api/speak — voz de la respuesta para el altavoz del reloj, por partes.
//
// Cuerpo JSON: { "text": "...", "part": 0, "provider": "edge" }
// Respuesta:   { "audio": "<Ogg/Opus en base64>", "part": 0, "parts": n, "provider": "..." }  |  { "error": "..." }
// `provider` (opcional) pide la misma voz que las partes anteriores.
//
// El reloj rechaza respuestas grandes (una de ~27 KB no sonó, una de ~5 KB
// sí), así que el texto se parte en frases cortas y el reloj pide una a una,
// pidiendo la siguiente mientras suena la actual.

import { authorized, json } from "../lib/assistant.js";
import { encodeOggOpus } from "../lib/ogg-opus.js";
import { synthesize, type Provider } from "../lib/speech.js";

const MAX_TEXT = 320;
const MAX_CHUNK = 70;
// ~1 KB/s de voz: cada parte de ~70 caracteres queda en ~6-8 KB.
const BITRATE = 8000;

export async function POST(request: Request): Promise<Response> {
  if (!authorized(request)) {
    return json({ error: "unauthorized" }, 401);
  }

  let body: { text?: unknown; part?: unknown; provider?: unknown };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return json({ error: "invalid json" }, 400);
  }
  const { text } = body;
  if (typeof text !== "string" || !text.trim() || text.length > MAX_TEXT) {
    return json({ error: "invalid request" }, 400);
  }
  const chunks = splitSpeech(text.trim(), MAX_CHUNK);
  const part = typeof body.part === "number" && Number.isInteger(body.part) ? body.part : 0;
  if (part < 0 || part >= chunks.length) {
    return json({ error: "invalid part" }, 400);
  }

  const prefer = typeof body.provider === "string" ? (body.provider as Provider) : undefined;
  const speech = await synthesize(chunks[part], prefer);
  if (!speech) {
    return json({ error: "tts unavailable" }, 502);
  }
  const ogg = encodeOggOpus(speech.pcm, speech.sampleRate, BITRATE);
  return json({ audio: ogg.toString("base64"), part, parts: chunks.length, provider: speech.provider });
}

// Frases completas cuando caben; si una frase es larga, se corta en comas o
// espacios. Así cada parte suena natural.
export function splitSpeech(text: string, max: number): string[] {
  const sentences = text.match(/[^.!?…]+[.!?…]*\s*/g) ?? [text];
  const chunks: string[] = [];
  let current = "";
  for (const raw of sentences) {
    const sentence = raw.trim();
    if (!sentence) continue;
    if (current && (current + " " + sentence).length <= max) {
      current += " " + sentence;
      continue;
    }
    if (current) chunks.push(current);
    current = sentence;
    while (current.length > max) {
      const comma = current.lastIndexOf(", ", max);
      const space = current.lastIndexOf(" ", max);
      const at = comma > max / 3 ? comma : space > max / 3 ? space : max;
      chunks.push(current.slice(0, at).replace(/,$/, "").trim());
      current = current.slice(at).replace(/^,?\s*/, "");
    }
  }
  if (current) chunks.push(current);
  return chunks;
}
