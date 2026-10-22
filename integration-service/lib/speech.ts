// Texto a voz con respaldo, como en Monki: si un proveedor falla se usa el
// siguiente, y el que se quedó sin cuota se salta un rato.
//
//   Gemini TTS ─▶ Google Cloud TTS (solo con GOOGLE_TTS_API_KEY) ─▶ Edge TTS (sin clave)
//
// Todos devuelven PCM de 16 bits mono y su frecuencia; ogg-opus.ts lo codifica.

import { GoogleGenAI } from "@google/genai";
import { MPEGDecoder } from "mpg123-decoder";
import { MsEdgeTTS, OUTPUT_FORMAT } from "msedge-tts";
import { apiKey as configuredKey } from "./config.js";

export type Provider = "gemini" | "google" | "edge";
type Rate = 8000 | 12000 | 16000 | 24000 | 48000;

export interface Speech {
  pcm: Buffer;
  sampleRate: Rate;
  provider: Provider;
}

const ORDER: Provider[] = ["gemini", "google", "edge"];
// Tras un 429 el proveedor se salta 10 minutos (por instancia de la función).
const COOLDOWN_MS = 10 * 60_000;
const cooldownUntil = new Map<Provider, number>();

class QuotaError extends Error {}

const JAPANESE = /[぀-ヿ一-鿿]/;

// `prefer`: el proveedor de las partes anteriores de la misma respuesta,
// para que la voz no cambie a mitad de la frase.
export async function synthesize(text: string, prefer?: Provider): Promise<Speech | null> {
  const order = prefer && ORDER.includes(prefer) ? [prefer, ...ORDER.filter((p) => p !== prefer)] : ORDER;
  const japanese = JAPANESE.test(text);
  for (const provider of order) {
    if ((cooldownUntil.get(provider) ?? 0) > Date.now()) continue;
    try {
      const result = await PROVIDERS[provider](text, japanese);
      if (result) return { ...result, provider };
    } catch (error) {
      if (error instanceof QuotaError) {
        cooldownUntil.set(provider, Date.now() + COOLDOWN_MS);
      }
      console.error("tts error", provider, error instanceof Error ? error.message.slice(0, 200) : error);
    }
  }
  return null;
}

type Synth = (text: string, japanese: boolean) => Promise<{ pcm: Buffer; sampleRate: Rate } | null>;

const PROVIDERS: Record<Provider, Synth> = { gemini, google, edge };

let geminiClient: { sdk: GoogleGenAI; key: string } | undefined;

async function gemini(text: string): Promise<{ pcm: Buffer; sampleRate: Rate } | null> {
  const apiKey = await configuredKey("GEMINI_API_KEY");
  if (!apiKey) return null;
  if (geminiClient?.key !== apiKey) geminiClient = { sdk: new GoogleGenAI({ apiKey }), key: apiKey };
  // Los mismos modelos que usa Monki.
  const models = [process.env.GEMINI_TTS_MODEL ?? "gemini-3.8-flash-lite-tts", "gemini-3.1-flash-tts-preview"];
  // Otra voz que la de Monki (Charon), para distinguir a los dos asistentes.
  const voiceName = process.env.TTS_VOICE ?? "Kore";
  let quota = 0;
  for (const model of [...new Set(models)]) {
    try {
      const result = await geminiClient.sdk.models.generateContent({
        model,
        contents: text,
        config: {
          responseModalities: ["AUDIO"],
          speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName } } },
          abortSignal: AbortSignal.timeout(12_000),
        },
      });
      const part = result.candidates?.[0]?.content?.parts?.find((p) => p.inlineData?.data);
      const data = part?.inlineData?.data;
      if (!data) continue;
      const rate = Number(/rate=(\d+)/.exec(part?.inlineData?.mimeType ?? "")?.[1] ?? 24000);
      return { pcm: Buffer.from(data, "base64"), sampleRate: validRate(rate) };
    } catch (error) {
      if ((error as { status?: number }).status === 429) quota++;
      else throw error;
    }
  }
  if (quota === models.length) throw new QuotaError("gemini sin cuota");
  return null;
}

async function google(text: string, japanese: boolean): Promise<{ pcm: Buffer; sampleRate: Rate } | null> {
  const apiKey = await configuredKey("GOOGLE_TTS_API_KEY");
  if (!apiKey) return null;
  const voice = japanese
    ? { languageCode: "ja-JP", name: process.env.GOOGLE_TTS_VOICE_JA ?? "ja-JP-Neural2-B" }
    : { languageCode: "es-US", name: process.env.GOOGLE_TTS_VOICE ?? "es-US-Neural2-A" };
  const res = await fetch(`https://texttospeech.googleapis.com/v1/text:synthesize?key=${apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      input: { text },
      voice,
      audioConfig: { audioEncoding: "LINEAR16", sampleRateHertz: 24000 },
    }),
    signal: AbortSignal.timeout(10_000),
  });
  if (res.status === 429) throw new QuotaError("google sin cuota");
  if (!res.ok) throw new Error(`google ${res.status}: ${(await res.text()).slice(0, 200)}`);
  const data = (await res.json()) as { audioContent?: string };
  if (!data.audioContent) return null;
  // LINEAR16 llega como WAV: se quita la cabecera de 44 bytes.
  const wav = Buffer.from(data.audioContent, "base64");
  return { pcm: wav.subarray(44), sampleRate: 24000 };
}

// Servicio de lectura en voz alta de Microsoft Edge: sin clave ni cuota,
// pero no oficial (puede dejar de funcionar). Solo entrega MP3: se decodifica.
async function edge(text: string, japanese: boolean): Promise<{ pcm: Buffer; sampleRate: Rate } | null> {
  const voice = japanese
    ? process.env.EDGE_TTS_VOICE_JA ?? "ja-JP-NanamiNeural"
    : process.env.EDGE_TTS_VOICE ?? "es-MX-DaliaNeural";
  const tts = new MsEdgeTTS();
  try {
    await tts.setMetadata(voice, OUTPUT_FORMAT.AUDIO_24KHZ_48KBITRATE_MONO_MP3);
    const { audioStream } = tts.toStream(text);
    const chunks: Buffer[] = [];
    for await (const chunk of audioStream) chunks.push(chunk as Buffer);
    const mp3 = Buffer.concat(chunks);
    if (mp3.length === 0) return null;
    return await decodeMp3(mp3);
  } finally {
    tts.close();
  }
}

async function decodeMp3(mp3: Buffer): Promise<{ pcm: Buffer; sampleRate: Rate }> {
  const decoder = new MPEGDecoder();
  await decoder.ready;
  try {
    const { channelData, samplesDecoded, sampleRate } = decoder.decode(new Uint8Array(mp3));
    const mono = channelData[0];
    const pcm = Buffer.alloc(samplesDecoded * 2);
    for (let i = 0; i < samplesDecoded; i++) {
      const s = Math.max(-1, Math.min(1, mono[i]));
      pcm.writeInt16LE(Math.round(s * 32767), i * 2);
    }
    return { pcm, sampleRate: validRate(sampleRate) };
  } finally {
    decoder.free();
  }
}

function validRate(rate: number): Rate {
  return ([8000, 12000, 16000, 24000, 48000] as const).find((r) => r === rate) ?? 24000;
}
