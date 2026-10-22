// GET/POST /api/config — lo que usa el panel del teléfono (/api/setup).
//
// Autenticación: `Authorization: Bearer <DEVICE_TOKEN>` o la sesión que da
// /api/pair a cambio del código de 6 dígitos del reloj.
//
// GET  → { storage, keys: { NOMBRE: { source, hint } }, inbox, cards, questions, projects }
// POST { action, ... } → el mismo estado actualizado, o { card } en fillCard.
//   setKey { name, value } · clearKey { name }
//   addTask { text } · addNote { text } · removeInbox { kind, id }
//   addCard { jp, reading, romaji, meaning } · removeCard { id }
//   addQuestion { text } · removeQuestion { id }
//   addProject { title, last, next } · removeProject { id }
//   fillCard { text }: la IA completa lectura, romaji y significado.

import { authorized, generate, json } from "../lib/assistant.js";
import {
  KEY_NAMES,
  MAX_CARDS,
  MAX_INBOX,
  MAX_PROJECTS,
  MAX_QUESTIONS,
  encrypt,
  keyStatus,
  loadConfig,
  storageConfigured,
  updateConfig,
  validSession,
  type Card,
  type Config,
  type KeyName,
} from "../lib/config.js";

const MAX_TEXT = 120;
// meaning: lo que cabe en una fila del quiz del reloj.
const LIMITS = { jp: 20, reading: 30, romaji: 40, meaning: 22 };

function view(config: Config): object {
  return {
    storage: storageConfigured(),
    keys: keyStatus(config),
    inbox: config.inbox,
    cards: config.cards,
    questions: config.questions,
    projects: config.projects,
  };
}

async function allowed(request: Request): Promise<boolean> {
  if (authorized(request)) return true;
  const header = request.headers.get("authorization") ?? "";
  return header.startsWith("Bearer ") && validSession(header.slice(7));
}

export async function GET(request: Request): Promise<Response> {
  if (!(await allowed(request))) return json({ error: "unauthorized" }, 401);
  return json(view(await loadConfig(true)));
}

export async function POST(request: Request): Promise<Response> {
  if (!(await allowed(request))) return json({ error: "unauthorized" }, 401);
  if (!storageConfigured()) return json({ error: "storage not configured" }, 503);

  let body: Record<string, unknown>;
  try {
    body = (await request.json()) as Record<string, unknown>;
  } catch {
    return json({ error: "invalid json" }, 400);
  }
  const text = (key: string, max = MAX_TEXT) =>
    typeof body[key] === "string" ? (body[key] as string).trim().slice(0, max) : "";

  if (body.action === "fillCard") {
    const card = await fillCard(text("text", 40));
    return card ? json({ card }) : json({ error: "no pude completar la tarjeta" }, 502);
  }

  let error: string | undefined;
  const config = await updateConfig((c) => {
    switch (body.action) {
      case "setKey": {
        const name = text("name") as KeyName;
        const value = text("value", 300);
        if (!KEY_NAMES.includes(name) || !value) error = "clave no válida";
        else c.keys[name] = encrypt(value);
        break;
      }
      case "clearKey":
        delete c.keys[text("name") as KeyName];
        break;
      case "addTask":
      case "addNote": {
        const list = body.action === "addTask" ? c.inbox.tasks : c.inbox.notes;
        const value = text("text");
        if (!value) error = "texto vacío";
        else if (list.length >= MAX_INBOX) error = "bandeja llena: abre la app en el reloj para recogerla";
        else list.push({ id: c.nextId++, text: value });
        break;
      }
      case "removeInbox": {
        const kind = body.kind === "notes" ? "notes" : "tasks";
        c.inbox[kind] = c.inbox[kind].filter((item) => item.id !== body.id);
        break;
      }
      case "addCard": {
        const card: Card = {
          id: c.nextId++,
          jp: text("jp", LIMITS.jp),
          reading: text("reading", LIMITS.reading),
          romaji: text("romaji", LIMITS.romaji).toLowerCase(),
          meaning: text("meaning", LIMITS.meaning),
        };
        if (!card.jp || !card.romaji || !card.meaning) error = "faltan japonés, romaji o significado";
        else if (c.cards.length >= MAX_CARDS) error = `máximo ${MAX_CARDS} tarjetas`;
        else if (c.cards.some((other) => other.meaning.toLowerCase() === card.meaning.toLowerCase()))
          error = "ya hay una tarjeta con ese significado (el quiz no podría distinguirlas)";
        else c.cards.push(card);
        break;
      }
      case "removeCard":
        c.cards = c.cards.filter((card) => card.id !== body.id);
        break;
      case "addQuestion": {
        const value = text("text", 60);
        if (!value) error = "texto vacío";
        else if (c.questions.length >= MAX_QUESTIONS) error = `máximo ${MAX_QUESTIONS} preguntas`;
        else c.questions.push({ id: c.nextId++, text: value });
        break;
      }
      case "removeQuestion":
        c.questions = c.questions.filter((q) => q.id !== body.id);
        break;
      case "addProject": {
        const project = { id: c.nextId++, title: text("title", 40), last: text("last", 60), next: text("next", 60) };
        if (!project.title) error = "falta el nombre del proyecto";
        else if (c.projects.length >= MAX_PROJECTS) error = `máximo ${MAX_PROJECTS} proyectos`;
        else c.projects.push(project);
        break;
      }
      case "removeProject":
        c.projects = c.projects.filter((p) => p.id !== body.id);
        break;
      default:
        error = "acción no válida";
    }
  });
  return error ? json({ error }, 400) : json(view(config));
}

const CARD_SYSTEM = [
  "Eres profesor de japonés para hispanohablantes, nivel N5.",
  "Recibes una palabra o frase en japonés, romaji o español y devuelves solo JSON:",
  '{"jp": japonés natural con kanji si es habitual, "reading": lectura en hiragana o "" si jp ya es solo kana,',
  '"romaji": romaji Hepburn en minúsculas con vocales largas como ou/uu, "meaning": significado en español de máximo 22 caracteres}.',
  "Si es un verbo usa la forma cortés ます y traduce conjugado con el infinitivo entre paréntesis, por ejemplo «Como (comer)».",
].join(" ");

async function fillCard(input: string): Promise<Omit<Card, "id"> | null> {
  if (!input) return null;
  try {
    const raw = await generate([input], { systemInstruction: CARD_SYSTEM, responseMimeType: "application/json" });
    const data = JSON.parse(raw ?? "") as Record<string, unknown>;
    const field = (key: keyof typeof LIMITS) =>
      typeof data[key] === "string" ? (data[key] as string).trim().slice(0, LIMITS[key]) : "";
    const card = { jp: field("jp"), reading: field("reading"), romaji: field("romaji"), meaning: field("meaning") };
    return card.jp && card.romaji && card.meaning ? card : null;
  } catch (error) {
    console.error("fillCard", error instanceof Error ? error.message.slice(0, 200) : error);
    return null;
  }
}
