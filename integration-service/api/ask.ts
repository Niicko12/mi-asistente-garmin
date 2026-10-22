// POST /api/ask — pregunta escrita desde el reloj, respuesta resumida de Gemini.
//
// Autenticación: `Authorization: Bearer <DEVICE_TOKEN>`. La clave de Gemini
// vive solo aquí (GEMINI_API_KEY); nunca en el reloj.
//
// Cuerpo JSON:
//   { "q": "¿Qué tengo pendiente?", "tasks": ["..."], "notes": ["..."] }
// Respuesta:
//   { "answer": "..." }  |  { "error": "..." }

import {
  NotConfiguredError,
  authorized,
  answer,
  clean,
  json,
  strings,
  watchText,
  type Context,
} from "../lib/assistant.js";

const MAX_QUESTION = 500;

export async function POST(request: Request): Promise<Response> {
  if (!authorized(request)) {
    return json({ error: "unauthorized" }, 401);
  }

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return json({ error: "invalid json" }, 400);
  }

  const input = parse(body);
  if (!input) {
    return json({ error: "invalid request" }, 400);
  }

  try {
    const reply = clean((await answer(input, input.q)) ?? "");
    return reply ? json({ answer: reply }) : json({ error: "upstream error" }, 502);
  } catch (error) {
    if (error instanceof NotConfiguredError) {
      return json({ error: "server not configured" }, 500);
    }
    throw error;
  }
}

function parse(body: unknown): (Context & { q: string }) | null {
  if (typeof body !== "object" || body === null) return null;
  const { q, tasks, notes, watch } = body as Record<string, unknown>;
  if (typeof q !== "string") return null;
  const question = q.trim();
  if (!question || question.length > MAX_QUESTION) return null;
  return { q: question, tasks: strings(tasks), notes: strings(notes), watch: watchText(watch) };
}
