# Informe de validación de capacidades — Fase 1

Convierte las hipótesis de la sección 5 del plan en hechos. Cada fila
se marca **Confirmado**, **Descartado**, **Parcial** o **Pendiente**,
con la fuente.

**Reloj:** fēnix 8 47mm AMOLED\
**Identificador de producto:** `fenix847mm`\
**Firmware:** _por confirmar en el reloj_\
**SDK Connect IQ:** 9.3.0 (2026-10-20)\
**API Connect IQ del perfil del dispositivo:** 6.0.3

Fuentes:

- **SDK-doc:** documentación incluida en el SDK 9.3.0 (`doc/`).
- **Perfil:** `Devices/fenix847mm/compiler.json` y `simulator.json`.
- **Diag:** pantalla «Diagnóstico» de la app (`source/Diagnostics.mc`).

| # | Hipótesis | Resultado | Detalle | Fuente |
|---|---|---|---|---|
| 1 | No hay API de micrófono para apps de terceros | **Descartado** | `Toybox.Audio.Capture` existe desde API 6.0.3. Requiere el permiso `AudioInput`, solo en primer plano y solo en device apps (no watch faces, data fields ni widgets). Formatos: contenedor WAV u OGG, códec LPCM (16 bits) u Opus, de 8 a 44,1 kHz, mono o estéreo. Filtro opcional `FILTER_NREC` (ruido y eco). Simulador: Opus 16k mono, WAV/LPCM 16k mono y NREC aceptados. Falta confirmar en el reloj | SDK-doc, Diag (simulador) |
| 2 | Reproducción de audio desde una device app | **Confirmado (doc)** | `Toybox.Audio.Output` con el permiso `AudioOutput`. Acepta recursos, fuentes dinámicas y streaming. Falta probarlo en el reloj | SDK-doc |
| 3 | `makeWebRequest` sale por el teléfono | **Confirmado (doc)** | `Communications` usa BLE con el teléfono como puente. `:body` acepta `ByteArray`, así que se puede subir audio capturado | SDK-doc |
| 4 | Sin teléfono no hay red para la app | Pendiente | Probar con Bluetooth apagado | — |
| 5 | Cuota de `Application.Storage` | **Parcial** | Cada valor admite hasta 32 KB. Capacidad total de la app: 10 MB (`appStorageCapacity` del simulador). Escritura y lectura OK en el simulador. Falta confirmar en el reloj | SDK-doc, Perfil, Diag (simulador) |
| 6 | Memoria de la device app | **Confirmado** | `watchApp` 768 KB, `glance` 64 KB, `background` 64 KB, `watchFace` 128 KB. Archivo `.prg` de hasta 64 MB | Perfil |
| 7 | `TextPicker` disponible | **Confirmado (API)** | Aparece en la API del dispositivo. Falta probar su uso real | Perfil |
| 8 | Fuentes del sistema sin kana/kanji | **Descartado (simulador)** | «がんばりましょう» se ve correctamente con `FONT_XTINY`. El set `ww` incluye `Kosugi-Regular-Outdoor`. Falta confirmar en el reloj | Perfil, Diag (simulador) |
| 9 | Fuente personalizada CJK | **No necesaria** | La fila 8 pasó en el simulador | — |
| 10 | Intervalo mínimo en segundo plano | **Confirmado** | Eventos temporales separados por 5 min como mínimo y solo uno registrado a la vez. En device apps, si se usa un `Moment`, la restricción se reinicia al abrir la app | SDK-doc |
| 11 | Instalación por USB en macOS | **Confirmado** | El reloj se conecta por MTP (`091e:51b8`), solo directo al Mac y no a través de hub. `mtp-sendfile` falla; `tools/mtp_send.py` copia el archivo a `GARMIN/Apps` (ID 16777227). La app aparece en el reloj | Reloj |
| 12 | Toque y botones generan `onSelect` / `onNextPage` | **Confirmado (simulador)** | El cambio de estado funciona en el simulador. Falta probarlo en el reloj | Simulador |

## Datos del dispositivo

- Pantalla AMOLED redonda de 454×454 px, 16 bits por píxel.
- Icono del lanzador: 65×65 px.
- Botones: `enter` → `onSelect`, `up` → `previousPage` (mantener → `onMenu`), `down` → `nextPage`, `esc` → `onBack`.

## Impacto en el plan

1. **La voz vuelve al alcance.** Flujo posible: capturar Opus a 16 kHz
   mono en el reloj, enviarlo como `ByteArray` por `makeWebRequest`,
   transcribirlo y responder en el backend, y mostrar el texto en el
   reloj. Falta medir el tamaño de cada envío y la latencia a través
   del teléfono.
2. **Japonés:** probablemente no hace falta una fuente propia. Si Diag
   muestra bien la línea «JP», la fase 0.6 pierde su mayor riesgo.
3. **«Escuchar» (pronunciación):** es viable con `Audio.Output` y audio
   generado en el backend.
4. **`minApiLevel` sube a 6.0.3**, por lo que la app requiere firmware
   con Connect IQ 6.0.3 o posterior.

## Pendiente en el reloj real

- [ ] Abrir «Diagnóstico» y anotar los resultados de las filas 1, 5 y 8.
- [x] Probar instalación por USB (fila 11).
- [ ] Probar sin Bluetooth (fila 4).
- [ ] Anotar la versión de firmware.

## Comprobado en el reloj real (2026-10-22)

| Tema | Resultado |
|---|---|
| Captura de micrófono | **Confirmado.** Ogg/Opus 16 kHz mono, 12–44 KB por pregunta; Whisper transcribe bien. |
| Peticiones web vía iPhone | **Confirmado.** `makeWebRequest` con cuerpo binario (`:body`) funciona desde API 6.0.3. |
| Reproducción de audio | **Confirmado.** `Audio.Output` reproduce Ogg/Opus por el altavoz. |
| Tamaño de respuesta web | Una respuesta JSON de ~5 KB se recibe; una de ~27 KB no. La voz se envía en partes de ≤ ~9 KB. |
| Fuentes japonesas del sistema | **No disponibles en el reloj** (en el simulador sí se veían). Se usa una fuente BMFont propia. |
| `Complications` (sueño, etc.) | Solo para carátulas (`ComplicationSubscriber`); la app usa `ActivityMonitor`, `SensorHistory`, `UserProfile` y `Weather`. |
| Instalación por USB | Por MTP, conectado directo sin hub; la app se instala al desconectar. |
| Palabra de activación | No posible: el micrófono solo funciona con la app en primer plano. |
