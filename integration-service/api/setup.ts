// GET /api/setup — guía de configuración para abrir en el teléfono desde el
// QR que muestra el reloj. Sin autenticación: no expone tokens ni claves.

const PAGE = `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Configurar Mi Asistente</title>
<style>
  :root { color-scheme: dark; --bg: #05080a; --card: #10171b; --text: #e8f1f3; --muted: #93a6ad; --accent: #2fd6e8; }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--bg); color: var(--text); font: 16px/1.5 -apple-system, system-ui, sans-serif; }
  main { max-width: 560px; margin: 0 auto; padding: 24px 16px 48px; }
  h1 { font-size: 24px; margin: 0 0 4px; }
  h2 { font-size: 17px; color: var(--accent); margin: 28px 0 8px; }
  p.lead { color: var(--muted); margin: 0 0 8px; }
  ol { margin: 0; padding-left: 22px; }
  li { margin: 6px 0; }
  .card { background: var(--card); border-radius: 14px; padding: 14px 16px; }
  .note { color: var(--muted); font-size: 14px; margin-top: 8px; }
  b { color: #fff; }
</style>
</head>
<body>
<main>
  <h1>Mi Asistente · fēnix 8</h1>
  <p class="lead">Pasos para dejar el asistente listo en el reloj.</p>

  <h2>1. Teléfono</h2>
  <div class="card"><ol>
    <li>Abre <b>Garmin Connect</b> en el iPhone y confirma que el reloj aparece <b>conectado</b>.</li>
    <li>En Ajustes del iPhone → Garmin Connect: activa <b>Bluetooth</b>, <b>Datos móviles</b> y <b>Actualización en segundo plano</b>.</li>
    <li>Deja Garmin Connect abierto o en segundo plano: las preguntas viajan por el teléfono.</li>
  </ol></div>

  <h2>2. Reloj</h2>
  <div class="card"><ol>
    <li>Asigna Mi Asistente a una tecla: <b>Ajustes → Sistema → Teclas de acceso rápido</b>.</li>
    <li>Al abrir la app empieza a escuchar (hasta 12 s). <b>Toca</b> para terminar de hablar.</li>
    <li>La primera vez, acepta el permiso de <b>micrófono</b> si el reloj lo pide.</li>
    <li>Sube el volumen del altavoz en <b>Ajustes → Sonido</b> para oír las respuestas.</li>
  </ol></div>

  <h2>3. Comprobar</h2>
  <div class="card"><ol>
    <li>Menú → <b>Estado</b>: debe decir <b>Teléfono: conectado</b>.</li>
    <li>Menú → <b>Diagnóstico</b>: revisa micrófono, altavoz y red.</li>
    <li>Pregunta algo corto, por ejemplo «¿cuántos pasos llevo?».</li>
  </ol>
  <p class="note">Si aparece «Token no válido», el token de Secrets.mc no coincide con DEVICE_TOKEN del servidor.</p></div>

  <h2>4. Japonés</h2>
  <div class="card"><ol>
    <li>Menú → <b>Japonés → Tarjetas</b>: toca para ver lectura, romaji y significado; toca otra vez para escucharla.</li>
    <li><b>Quiz</b>: UP/DOWN elige y START responde. Las que fallas se repiten más.</li>
    <li>Los verbos están en forma cortés ます: <b>たべます</b> = «como»; el infinitivo va entre paréntesis.</li>
  </ol></div>
</main>
</body>
</html>`;

export function GET(): Response {
  return new Response(PAGE, {
    headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "public, max-age=3600" },
  });
}
