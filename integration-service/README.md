# integration-service

Backend del reloj en Vercel (funciones Node.js). Guarda la clave de
Gemini; el reloj solo conoce `DEVICE_TOKEN`.

Producción: <https://mi-asistente-garmin.vercel.app>

## Endpoints

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| GET | `/api/health` | No | `{ "ok": true }` |
| GET | `/api/setup` | No | Guía de configuración en HTML (la abre el QR del reloj) |
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
