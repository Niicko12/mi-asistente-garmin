# integration-service

Backend del reloj en Vercel (funciones Node.js). Guarda las claves de IA;
el reloj solo conoce `DEVICE_TOKEN`.

Producción: <https://mi-asistente-garmin.vercel.app>

## Endpoints

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/api/health` | No | `{ "ok": true }` |
| GET | `/api/setup` | No | Panel y guía en HTML (lo abre el QR del reloj); pide el token y usa `/api/config` |
| POST | `/api/pair` | `Bearer DEVICE_TOKEN` (reloj) / ninguna (panel) | Reloj: `{ code }` de 6 dígitos, 10 min y 5 intentos. Panel: `{ code }` → `{ session }` |
| GET | `/api/config` | `Bearer DEVICE_TOKEN` o sesión | Estado del panel: claves (solo origen y últimos 4 caracteres), bandeja y tarjetas |
| POST | `/api/config` | `Bearer DEVICE_TOKEN` o sesión | `{ action, ... }`: `setKey`, `clearKey`, `addTask`, `addNote`, `removeInbox`, `addCard`, `removeCard`, `addQuestion`, `removeQuestion`, `addProject`, `removeProject`, `fillCard` |
| GET | `/api/sync` | `Bearer DEVICE_TOKEN` | El reloj recoge `{ tasks: [[id, texto]], notes, cards: [[id, jp, lectura, romaji, significado]], questions: [texto], projects: [[nombre, último, siguiente]] }` |
| POST | `/api/sync` | `Bearer DEVICE_TOKEN` | `{ tasks: [id], notes: [id] }`: confirma lo guardado y lo quita de la bandeja |
| POST | `/api/ask` | `Bearer DEVICE_TOKEN` | `{ q, tasks?, notes? }` → `{ answer }` (≤ 300 caracteres) |
| POST | `/api/ask-audio?tasks=a\|b&notes=x` | `Bearer DEVICE_TOKEN` | Cuerpo: audio Ogg/Opus o WAV → `{ transcript, answer }` |

Errores: `401 unauthorized`, `400 invalid request`, `500 server not configured`
(falta `GEMINI_API_KEY`), `502 upstream error` (falló Gemini).

## Variables de entorno (Production)

| Variable | Obligatoria | Uso |
|---|---|---|
| `GEMINI_API_KEY` | Sí | Clave de Google AI Studio |
| `DEVICE_TOKEN` | Sí | Debe coincidir con `Secrets.DEVICE_TOKEN` del reloj |
| `GROQ_API_KEY` | Recomendada | Groq responde primero (Whisper + `openai/gpt-oss-120b`); Gemini queda de respaldo |
| `NVIDIA_API_KEY` | No | Segundo proveedor si Groq falla |
| `GEMINI_MODEL` | No | Por defecto `gemini-flash-latest` |
| `NVIDIA_MODEL` | No | Por defecto `nvidia/nemotron-3.5-lightning-30b-a3b` |
| `GROQ_MODEL` / `GROQ_STT_MODEL` | No | Por defecto `openai/gpt-oss-120b` / `whisper-large-v3-turbo` |
| `BLOB_READ_WRITE_TOKEN` | Para el panel | La crea `vercel blob create-store mi-asistente-config --access private`; sin ella el panel es de solo lectura |

Las claves de IA (`GROQ_API_KEY`, `GEMINI_API_KEY`, `NVIDIA_API_KEY`,
`GOOGLE_TTS_API_KEY`) también se pueden poner desde el panel. Se guardan
cifradas en `config/settings.json` del Blob privado, con una clave derivada
de `DEVICE_TOKEN`, y tienen prioridad sobre las variables de entorno. Al
rotar `DEVICE_TOKEN` hay que volver a ponerlas en el panel.

```bash
vercel env add GEMINI_API_KEY production   # pide el valor; no lo pegues en chats
vercel deploy --prod
```

Rotar el token: cambiar `DEVICE_TOKEN` en Vercel, actualizar
`garmin-connect-iq/source/Secrets.mc`, recompilar e instalar.

## Probar

```bash
T=$(cat ../.device_token)
curl -s -X POST https://mi-asistente-garmin.vercel.app/api/ask \
  -H "Authorization: Bearer $T" -H 'Content-Type: application/json' \
  -d '{"q":"¿Qué tengo pendiente?","tasks":["Estudiar japonés"]}'
```
