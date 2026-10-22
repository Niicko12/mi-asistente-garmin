// Código compartido por los endpoints del reloj: autenticación, contexto,
// llamada a Gemini con modelo de respaldo y formato de respuesta.

import { timingSafeEqual } from "node:crypto";
import { GoogleGenAI, type GenerateContentConfig, type PartUnion } from "@google/genai";

export const MAX_ITEMS = 30;
export const MAX_ITEM_LEN = 120;
const MAX_ANSWER = 300;

export const SYSTEM = [
  "Eres Mi Asistente, un asistente personal mostrado en la pantalla de un reloj Garmin fēnix 8.",
  "Responde siempre en español, en 2 o 3 frases y como máximo 280 caracteres.",
  "Sin markdown, sin listas con viñetas, sin emojis.",
  // La fuente del sistema del reloj no tiene kana ni kanji.
  "Escribe el japonés solo en romaji, nunca con kana ni kanji.",
  "Usa las tareas y notas del usuario solo si son relevantes para la pregunta.",
  "Recibes los datos actuales del reloj (batería, pasos, pulso, Body Battery, estrés, sueño, clima y otros).",
  "Si preguntan por alguno, contesta con el valor exacto; si no está en los datos, di que el reloj no lo comparte.",
  "Reporta las métricas como datos del reloj; no diagnostiques ni interpretes emociones o salud.",
  // El usuario tiene otro asistente que despierta con esa palabra.
  "Nunca escribas la palabra «Monki» ni «monkey».",
].join(" ");

export interface Context {
  tasks: string[];
  notes: string[];
  watch?: string;
}

const MAX_WATCH = 1500;

export function watchText(value: unknown): string | undefined {
  return typeof value === "string" && value.trim() ? value.trim().slice(0, MAX_WATCH) : undefined;
}

let client: GoogleGenAI | undefined;

export class NotConfiguredError extends Error {}

// Modelo principal sin razonamiento largo (el reloj espera pocos segundos);
// el de respaldo rechaza thinkingConfig (400), así que va sin él.
// Gemini a veces retiene la petición casi un minuto sin error: cada intento
// tiene su límite de tiempo y, si se agota, pasa al siguiente.
export async function generate(parts: PartUnion[], config: GenerateContentConfig): Promise<string | null> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new NotConfiguredError();
  client ??= new GoogleGenAI({ apiKey });

  const attempts = [
    { model: process.env.GEMINI_MODEL ?? "gemini-flash-latest", thinkingBudget: 0 as number | undefined, timeoutMs: 12_000 },
    { model: process.env.GEMINI_FALLBACK_MODEL ?? "gemini-flash-lite-latest", thinkingBudget: undefined, timeoutMs: 15_000 },
  ];
  for (const { model, thinkingBudget, timeoutMs } of attempts) {
    try {
      const result = await client.models.generateContent({
        model,
        contents: parts,
        config: {
          systemInstruction: SYSTEM,
          maxOutputTokens: 512,
          ...config,
          abortSignal: AbortSignal.timeout(timeoutMs),
          ...(thinkingBudget === undefined ? {} : { thinkingConfig: { thinkingBudget } }),
        },
      });
      return result.text ?? null;
    } catch (error) {
      console.error("gemini error", model, error);
      // Saturación o fallo temporal de Google: probar el modelo de respaldo.
      if (!isTransient(error)) break;
    }
  }
  return null;
}

function isTransient(error: unknown): boolean {
  const { status, name } = error as { status?: number; name?: string };
  return status === 429 || status === 500 || status === 503 || name === "TimeoutError" || name === "AbortError";
}

// Proveedores con API compatible con OpenAI, en orden, como en Monki:
// Groq primero por rapidez, luego NVIDIA. Gemini queda al final.
const GROQ_URL = "https://api.groq.com/openai/v1";

interface ChatProvider {
  name: string;
  url: string;
  apiKey: string | undefined;
  model: string;
  extra: Record<string, unknown>;
}

function chatProviders(): ChatProvider[] {
  return [
    {
      name: "groq",
      url: GROQ_URL,
      apiKey: process.env.GROQ_API_KEY,
      model: process.env.GROQ_MODEL ?? "openai/gpt-oss-120b",
      extra: { reasoning_effort: "low" },
    },
    {
      name: "nvidia",
      url: "https://integrate.api.nvidia.com/v1",
      apiKey: process.env.NVIDIA_API_KEY,
      model: process.env.NVIDIA_MODEL ?? "nvidia/nemotron-3.5-lightning-30b-a3b",
      extra: {},
    },
  ];
}

export async function openAiChat(prompt: string): Promise<string | null> {
  for (const provider of chatProviders()) {
    if (!provider.apiKey) continue;
    const text = await chatWith(provider, prompt);
    if (text) return text;
  }
  return null;
}

async function chatWith(provider: ChatProvider, prompt: string): Promise<string | null> {
  try {
    const res = await fetch(`${provider.url}/chat/completions`, {
      method: "POST",
      headers: { Authorization: `Bearer ${provider.apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: provider.model,
        max_tokens: 512,
        messages: [
          { role: "system", content: SYSTEM },
          { role: "user", content: prompt },
        ],
        ...provider.extra,
      }),
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) {
      console.error(`${provider.name} chat`, res.status, (await res.text()).slice(0, 300));
      return null;
    }
    const data = (await res.json()) as { choices?: { message?: { content?: string | null } }[] };
    return data.choices?.[0]?.message?.content?.trim() || null;
  } catch (error) {
    console.error(`${provider.name} chat`, error);
    return null;
  }
}

// Con silencio Whisper inventa frases de cierre de video; se descartan.
// Groq reporta no_speech_prob 0 aun con silencio, así que no basta.
const PHANTOM = [/gracias por ver/i, /suscr[ií]bete/i, /amara\.org/i, /subt[ií]tulos/i, /^\W*(muchas )?gracias\W*$/i];
const NO_SPEECH = 0.5;

// Devuelve el texto, "" si no hubo voz, o null si la transcripción falló.
export async function groqTranscribe(audio: Buffer, mimeType: string): Promise<string | null> {
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey) return null;
  const form = new FormData();
  const ext = mimeType === "audio/wav" ? "wav" : "ogg";
  form.append("file", new Blob([new Uint8Array(audio)], { type: mimeType }), `pregunta.${ext}`);
  form.append("model", process.env.GROQ_STT_MODEL ?? "whisper-large-v3-turbo");
  form.append("language", "es");
  form.append("response_format", "verbose_json");
  try {
    const res = await fetch(`${GROQ_URL}/audio/transcriptions`, {
      method: "POST",
      headers: { Authorization: `Bearer ${apiKey}` },
      body: form,
      signal: AbortSignal.timeout(10_000),
    });
    if (!res.ok) {
      console.error("groq stt", res.status, (await res.text()).slice(0, 300));
      return null;
    }
    const data = (await res.json()) as { text?: string; segments?: { no_speech_prob?: number }[] };
    const text = data.text?.trim() ?? "";
    const silent = (data.segments ?? []).every((s) => (s.no_speech_prob ?? 0) > NO_SPEECH);
    if (!text || silent || PHANTOM.some((re) => re.test(text))) return "";
    return text;
  } catch (error) {
    console.error("groq stt", error);
    return null;
  }
}

// Por costumbre se dice "hey monki" (la palabra de la Anbernic); se quita
// para que la respuesta no la repita.
const WAKE_PREFIX = /^\s*((o?hey|ey|hei|oye)?[\s,]*(monk[iey]+|mon ?qui|monky)|hei ?mo\w*[\s,.!]*aqu[ií])[\s,.!]*/i;

export function stripWakeWord(text: string): string {
  const stripped = text.replace(WAKE_PREFIX, "").trim();
  return stripped ? stripped.charAt(0).toUpperCase() + stripped.slice(1) : stripped;
}

// Respuesta a una pregunta en texto: Groq, NVIDIA y, si fallan, Gemini.
export async function answer(context: Context, question: string): Promise<string | null> {
  const prompt = `${contextText(context)}\nPregunta: ${question}`;
  return (await openAiChat(prompt)) ?? (await generate([prompt], {}));
}

export function contextText({ tasks, notes, watch }: Context): string {
  const today = new Date().toLocaleDateString("es-MX", {
    weekday: "long",
    day: "numeric",
    month: "long",
    timeZone: "America/Mexico_City",
  });
  return [
    `Hoy es ${today}.`,
    `Tareas pendientes: ${tasks.length ? tasks.join("; ") : "ninguna"}.`,
    `Notas recientes: ${notes.length ? notes.join("; ") : "ninguna"}.`,
    `Datos del reloj: ${watch ?? "no disponibles"}.`,
  ].join("\n");
}

export function strings(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter((v): v is string => typeof v === "string")
    .slice(0, MAX_ITEMS)
    .map((v) => v.slice(0, MAX_ITEM_LEN));
}

// La pantalla es pequeña: quita markdown residual y recorta.
export function clean(text: string, max = MAX_ANSWER): string {
  const plain = text.replace(/[*_#`>]/g, "").replace(/\s+/g, " ").trim();
  return plain.length > max ? plain.slice(0, max - 1) + "…" : plain;
}

export function authorized(request: Request): boolean {
  const expected = process.env.DEVICE_TOKEN;
  const header = request.headers.get("authorization") ?? "";
  if (!expected || !header.startsWith("Bearer ")) return false;
  const given = Buffer.from(header.slice(7));
  const want = Buffer.from(expected);
  return given.length === want.length && timingSafeEqual(given, want);
}

export function json(data: object, status = 200): Response {
  return Response.json(data, { status });
}
