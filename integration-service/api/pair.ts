// POST /api/pair — enlazar el panel del teléfono sin escribir DEVICE_TOKEN.
//
// Reloj, con `Authorization: Bearer <DEVICE_TOKEN>` y sin cuerpo:
//   → { code: "123456" }  (vale 10 minutos y 5 intentos)
// Panel, sin autenticación: { code: "123456" }
//   → { session }  token de sesión para /api/config  |  401 { error }

import { authorized, json } from "../lib/assistant.js";
import { claimPairCode, newPairCode, storageConfigured } from "../lib/config.js";

export async function POST(request: Request): Promise<Response> {
  if (!storageConfigured()) return json({ error: "storage not configured" }, 503);
  if (authorized(request)) {
    return json({ code: await newPairCode() });
  }
  let code = "";
  try {
    const body = (await request.json()) as { code?: unknown };
    code = typeof body.code === "string" ? body.code.replace(/\D/g, "").slice(0, 6) : "";
  } catch {
    return json({ error: "invalid json" }, 400);
  }
  const session = code.length === 6 ? await claimPairCode(code) : null;
  return session
    ? json({ session })
    : json({ error: "Código no válido o vencido: abre de nuevo Configurar (QR) en el reloj" }, 401);
}
