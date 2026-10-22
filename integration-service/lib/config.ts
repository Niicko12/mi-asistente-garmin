// Configuración editable desde el panel del teléfono (/api/setup), guardada
// en un Blob privado como un único JSON:
//
//   - keys:  claves de IA puestas desde el panel. Cifradas con AES-256-GCM
//            usando una clave derivada de DEVICE_TOKEN: si se cambia el
//            token hay que volver a ponerlas. Tienen prioridad sobre las
//            variables de entorno, que quedan como respaldo.
//   - inbox: tareas y notas que esperan a que el reloj las recoja.
//   - cards: tarjetas de japonés propias; el reloj recibe la lista completa.

import { createCipheriv, createDecipheriv, createHash, randomBytes } from "node:crypto";
import { BlobPreconditionFailedError, get, put } from "@vercel/blob";

export const KEY_NAMES = ["GROQ_API_KEY", "GEMINI_API_KEY", "NVIDIA_API_KEY", "GOOGLE_TTS_API_KEY"] as const;
export type KeyName = (typeof KEY_NAMES)[number];

export interface InboxItem {
  id: number;
  text: string;
}

export interface Card {
  id: number;
  jp: string;
  reading: string;
  romaji: string;
  meaning: string;
}

export interface Config {
  keys: Partial<Record<KeyName, string>>;
  inbox: { tasks: InboxItem[]; notes: InboxItem[] };
  cards: Card[];
  nextId: number;
}

export const MAX_INBOX = 20;
export const MAX_CARDS = 60;

const PATH = "config/settings.json";
// Cada instancia de la función relee el Blob como mucho cada 30 s.
const CACHE_MS = 30_000;
let cache: { config: Config; at: number } | undefined;

function empty(): Config {
  return { keys: {}, inbox: { tasks: [], notes: [] }, cards: [], nextId: 1 };
}

export function storageConfigured(): boolean {
  return Boolean(process.env.BLOB_READ_WRITE_TOKEN);
}

async function read(): Promise<{ config: Config; etag?: string }> {
  if (!storageConfigured()) return { config: empty() };
  const result = await get(PATH, { access: "private", useCache: false });
  if (!result || result.statusCode !== 200) return { config: empty() };
  const text = await new Response(result.stream).text();
  return { config: { ...empty(), ...(JSON.parse(text) as Partial<Config>) }, etag: result.blob.etag };
}

export async function loadConfig(fresh = false): Promise<Config> {
  if (!fresh && cache && Date.now() - cache.at < CACHE_MS) return cache.config;
  const { config } = await read();
  cache = { config, at: Date.now() };
  return config;
}

// Lee, cambia y escribe con control de concurrencia (ETag); reintenta si
// otra petición escribió en medio.
export async function updateConfig(change: (config: Config) => void): Promise<Config> {
  for (let attempt = 0; attempt < 3; attempt++) {
    const { config, etag } = await read();
    change(config);
    try {
      await put(PATH, JSON.stringify(config), {
        access: "private",
        contentType: "application/json",
        addRandomSuffix: false,
        allowOverwrite: true,
        cacheControlMaxAge: 60,
        ...(etag ? { ifMatch: etag } : {}),
      });
      cache = { config, at: Date.now() };
      return config;
    } catch (error) {
      if (!(error instanceof BlobPreconditionFailedError)) throw error;
    }
  }
  throw new Error("config busy");
}

function cipherKey(): Buffer {
  return createHash("sha256").update(`mi-asistente-config:${process.env.DEVICE_TOKEN ?? ""}`).digest();
}

export function encrypt(value: string): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv("aes-256-gcm", cipherKey(), iv);
  const data = Buffer.concat([cipher.update(value, "utf8"), cipher.final()]);
  return [iv, cipher.getAuthTag(), data].map((b) => b.toString("base64")).join(".");
}

function decrypt(value: string): string | undefined {
  try {
    const [iv, tag, data] = value.split(".").map((p) => Buffer.from(p, "base64"));
    const decipher = createDecipheriv("aes-256-gcm", cipherKey(), iv);
    decipher.setAuthTag(tag);
    return Buffer.concat([decipher.update(data), decipher.final()]).toString("utf8");
  } catch {
    return undefined;
  }
}

// Clave de IA: la del panel si existe, si no la variable de entorno.
// Si el Blob falla, se sigue con las variables de entorno.
export async function apiKey(name: KeyName): Promise<string | undefined> {
  try {
    const stored = (await loadConfig()).keys[name];
    const value = stored ? decrypt(stored) : undefined;
    if (value) return value;
  } catch (error) {
    console.error("config error", error instanceof Error ? error.message.slice(0, 200) : error);
  }
  return process.env[name] || undefined;
}

export interface KeyStatus {
  source: "panel" | "env" | null;
  hint: string;
}

// Estado de cada clave para el panel: nunca la clave completa.
export function keyStatus(config: Config): Record<KeyName, KeyStatus> {
  const result = {} as Record<KeyName, KeyStatus>;
  for (const name of KEY_NAMES) {
    const stored = config.keys[name];
    const panel = stored ? decrypt(stored) : undefined;
    const value = panel ?? process.env[name];
    result[name] = {
      source: panel ? "panel" : value ? "env" : null,
      hint: value ? `…${value.slice(-4)}` : "",
    };
  }
  return result;
}
