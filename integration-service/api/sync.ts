// GET/POST /api/sync — el reloj recoge lo agregado desde el panel.
//
// Autenticación: `Authorization: Bearer <DEVICE_TOKEN>`.
//
// GET → { tasks: [[id, texto]], notes: [[id, texto]], cards: [[id, jp, lectura, romaji, significado]] }
//   Listas de listas: el reloj las guarda tal cual en Storage.
// POST { tasks: [id], notes: [id] } → { ok: true }
//   Confirma lo que el reloj guardó; se quita de la bandeja. Las tarjetas no
//   se confirman: el reloj reemplaza las suyas por la lista completa.

import { authorized, json } from "../lib/assistant.js";
import { loadConfig, storageConfigured, updateConfig } from "../lib/config.js";

export async function GET(request: Request): Promise<Response> {
  if (!authorized(request)) return json({ error: "unauthorized" }, 401);
  const config = await loadConfig(true);
  return json({
    tasks: config.inbox.tasks.map((t) => [t.id, t.text]),
    notes: config.inbox.notes.map((n) => [n.id, n.text]),
    cards: config.cards.map((c) => [c.id, c.jp, c.reading, c.romaji, c.meaning]),
  });
}

export async function POST(request: Request): Promise<Response> {
  if (!authorized(request)) return json({ error: "unauthorized" }, 401);
  if (!storageConfigured()) return json({ ok: true });
  let body: { tasks?: unknown; notes?: unknown };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return json({ error: "invalid json" }, 400);
  }
  const ids = (value: unknown) => new Set(Array.isArray(value) ? value.filter((v) => typeof v === "number") : []);
  const tasks = ids(body.tasks);
  const notes = ids(body.notes);
  if (tasks.size || notes.size) {
    await updateConfig((c) => {
      c.inbox.tasks = c.inbox.tasks.filter((t) => !tasks.has(t.id));
      c.inbox.notes = c.inbox.notes.filter((n) => !notes.has(n.id));
    });
  }
  return json({ ok: true });
}
