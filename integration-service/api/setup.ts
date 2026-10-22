// GET /api/setup — guía y panel para el teléfono; lo abre el QR del reloj.
// La página no lleva datos: pide el DEVICE_TOKEN, lo guarda en el
// navegador y habla con /api/config. Desde aquí se agregan tareas, notas y
// tarjetas de japonés al reloj y se ponen las claves de IA.

const PAGE = `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Mi Asistente · Panel</title>
<style>
  :root { color-scheme: dark; --bg: #05080a; --card: #10171b; --line: #1f2a30; --text: #e8f1f3; --muted: #93a6ad; --accent: #2fd6e8; --bad: #ff6b6b; --ok: #4ade80; }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--bg); color: var(--text); font: 16px/1.5 -apple-system, system-ui, sans-serif; }
  main { max-width: 560px; margin: 0 auto; padding: 24px 16px 64px; }
  h1 { font-size: 24px; margin: 0 0 4px; }
  h2 { font-size: 17px; color: var(--accent); margin: 28px 0 8px; }
  p.lead, .muted { color: var(--muted); }
  p.lead { margin: 0 0 8px; }
  .card { background: var(--card); border-radius: 14px; padding: 14px 16px; }
  ol { margin: 0; padding-left: 22px; } li { margin: 6px 0; }
  .note { color: var(--muted); font-size: 14px; margin: 8px 0 0; }
  b { color: #fff; }
  input, select, button { font: inherit; color: inherit; }
  input, select { width: 100%; background: var(--bg); border: 1px solid var(--line); border-radius: 10px; padding: 10px 12px; }
  input:focus, select:focus { outline: 2px solid var(--accent); border-color: transparent; }
  button { background: var(--accent); color: #031014; border: 0; border-radius: 10px; padding: 10px 14px; font-weight: 600; cursor: pointer; }
  button.ghost { background: transparent; color: var(--muted); border: 1px solid var(--line); font-weight: 500; }
  button:disabled { opacity: .5; }
  .row { display: flex; gap: 8px; align-items: center; } .row > input, .row > select { flex: 1; min-width: 0; }
  .stack > * + * { margin-top: 8px; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
  ul.items { list-style: none; margin: 10px 0 0; padding: 0; }
  ul.items li { display: flex; gap: 8px; align-items: center; justify-content: space-between; border-top: 1px solid var(--line); padding: 8px 0; margin: 0; }
  ul.items li span { min-width: 0; overflow-wrap: anywhere; }
  .key { border-top: 1px solid var(--line); padding: 10px 0; } .key:first-child { border-top: 0; padding-top: 0; }
  .tag { font-size: 13px; color: var(--muted); } .tag.on { color: var(--ok); }
  #msg { position: sticky; top: 8px; z-index: 1; display: none; padding: 10px 14px; border-radius: 10px; background: var(--card); border: 1px solid var(--line); margin-bottom: 12px; }
  #msg.err { border-color: var(--bad); color: var(--bad); }
  details summary { cursor: pointer; color: var(--accent); font-weight: 600; }
  [hidden] { display: none !important; }
</style>
</head>
<body>
<main>
  <h1>Mi Asistente · fēnix 8</h1>
  <p class="lead">Agrega cosas al reloj y configura las claves de IA desde el teléfono.</p>
  <div id="msg" role="status"></div>

  <section id="login" class="card stack">
    <label for="token">Token del dispositivo (DEVICE_TOKEN)</label>
    <input id="token" type="password" autocomplete="off" placeholder="El mismo que tiene Secrets.mc">
    <button id="enter">Entrar</button>
    <p class="note">Se guarda solo en este navegador.</p>
  </section>

  <div id="panel" hidden>
    <h2>Agregar al reloj</h2>
    <div class="card stack">
      <div class="row">
        <select id="kind" aria-label="Tipo"><option value="addTask">Tarea</option><option value="addNote">Nota</option></select>
      </div>
      <div class="row"><input id="text" maxlength="120" placeholder="Texto"><button id="add">Agregar</button></div>
      <p class="note">El reloj lo recoge al abrir el menú de la app, con el iPhone cerca.</p>
      <ul class="items" id="inbox"></ul>
    </div>

    <h2>Tarjetas de japonés</h2>
    <div class="card stack">
      <div class="row"><input id="seed" maxlength="40" placeholder="Palabra en japonés, romaji o español"><button id="fill" class="ghost">Completar con IA</button></div>
      <div class="grid">
        <input id="jp" maxlength="20" placeholder="Japonés (猫)">
        <input id="reading" maxlength="30" placeholder="Lectura (ねこ)">
        <input id="romaji" maxlength="40" placeholder="Romaji (neko)">
        <input id="meaning" maxlength="40" placeholder="Significado (Gato)">
      </div>
      <button id="addCard">Guardar tarjeta</button>
      <p class="note">Aparecen en Japonés → «Mis tarjetas». Los kanji que no están en la fuente del reloj se muestran con su lectura en kana.</p>
      <ul class="items" id="cards"></ul>
    </div>

    <h2>Claves de IA</h2>
    <div class="card" id="keys"></div>
    <p class="note">Se guardan cifradas. Si cambias DEVICE_TOKEN tendrás que volver a ponerlas. Sin clave en el panel se usa la variable de Vercel.</p>

    <p><button id="logout" class="ghost">Salir</button></p>
  </div>

  <h2>Guía</h2>
  <details class="card"><summary>Configurar el reloj y el teléfono</summary>
    <ol>
      <li>Abre <b>Garmin Connect</b> en el iPhone y confirma que el reloj aparece <b>conectado</b>.</li>
      <li>En Ajustes del iPhone → Garmin Connect: activa <b>Bluetooth</b>, <b>Datos móviles</b> y <b>Actualización en segundo plano</b>.</li>
      <li>Asigna Mi Asistente a una tecla: <b>Ajustes → Sistema → Teclas de acceso rápido</b>.</li>
      <li>Al abrir la app empieza a escuchar (hasta 12 s). <b>Toca</b> para terminar de hablar.</li>
      <li>Sube el volumen en <b>Ajustes → Sonido</b> para oír las respuestas.</li>
      <li>Menú → <b>Estado</b> debe decir <b>Teléfono: conectado</b>; <b>Diagnóstico</b> revisa micrófono, altavoz y red.</li>
      <li><b>Japonés</b>: en Tarjetas toca para ver lectura y significado, y otra vez para escuchar. En el Quiz toca la opción o usa UP/DOWN y START.</li>
    </ol>
  </details>
</main>
<script>
const KEYS = { GROQ_API_KEY: "Groq (voz a texto y respuestas)", GEMINI_API_KEY: "Gemini (respuestas y voz)", NVIDIA_API_KEY: "NVIDIA (respaldo)", GOOGLE_TTS_API_KEY: "Google Cloud TTS (voz de respaldo)" };
const $ = (id) => document.getElementById(id);
let token = "";
try { token = localStorage.getItem("token") || ""; } catch {}

function say(text, bad) {
  const m = $("msg");
  m.textContent = text; m.className = bad ? "err" : ""; m.style.display = text ? "block" : "none";
  if (text && !bad) setTimeout(() => { if (m.textContent === text) say(""); }, 2500);
}

async function call(method, body) {
  const res = await fetch("/api/config", {
    method, headers: { Authorization: "Bearer " + token, "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  if (res.status === 401) { logout(); throw new Error("Token no válido"); }
  if (!res.ok) throw new Error(data.error || "Error " + res.status);
  return data;
}

function item(text, onRemove) {
  const li = document.createElement("li");
  const span = document.createElement("span"); span.textContent = text;
  const del = document.createElement("button"); del.className = "ghost"; del.textContent = "Quitar";
  del.onclick = onRemove;
  li.append(span, del);
  return li;
}

function render(state) {
  $("login").hidden = true; $("panel").hidden = false;
  if (!state.storage) say("Falta el almacenamiento (BLOB_READ_WRITE_TOKEN) en Vercel: el panel es de solo lectura.", true);
  const inbox = $("inbox"); inbox.replaceChildren();
  for (const t of state.inbox.tasks) inbox.append(item("Tarea · " + t.text, () => act({ action: "removeInbox", kind: "tasks", id: t.id })));
  for (const n of state.inbox.notes) inbox.append(item("Nota · " + n.text, () => act({ action: "removeInbox", kind: "notes", id: n.id })));
  const cards = $("cards"); cards.replaceChildren();
  for (const c of state.cards) cards.append(item(c.jp + (c.reading ? " (" + c.reading + ")" : "") + " · " + c.romaji + " · " + c.meaning, () => act({ action: "removeCard", id: c.id })));
  const keys = $("keys"); keys.replaceChildren();
  for (const [name, label] of Object.entries(KEYS)) {
    const s = state.keys[name] || {};
    const box = document.createElement("div"); box.className = "key stack";
    const head = document.createElement("div"); head.className = "row";
    const title = document.createElement("b"); title.textContent = label; title.style.flex = "1";
    const tag = document.createElement("span"); tag.className = "tag" + (s.source ? " on" : "");
    tag.textContent = s.source === "panel" ? "panel " + s.hint : s.source === "env" ? "Vercel " + s.hint : "sin clave";
    head.append(title, tag);
    const row = document.createElement("div"); row.className = "row";
    const input = document.createElement("input"); input.type = "password"; input.autocomplete = "off"; input.placeholder = "Pegar clave nueva";
    const save = document.createElement("button"); save.textContent = "Guardar";
    save.onclick = () => input.value.trim() && act({ action: "setKey", name, value: input.value.trim() }, "Clave guardada");
    row.append(input, save);
    box.append(head, row);
    if (s.source === "panel") {
      const clear = document.createElement("button"); clear.className = "ghost"; clear.textContent = "Quitar clave del panel";
      clear.onclick = () => act({ action: "clearKey", name }, "Clave quitada");
      box.append(clear);
    }
    keys.append(box);
  }
}

async function act(body, ok) {
  try { render(await call("POST", body)); if (ok) say(ok); return true; }
  catch (e) { say(e.message, true); return false; }
}

async function load() {
  if (!token) return;
  try { render(await call("GET")); } catch (e) { say(e.message, true); }
}

function logout() {
  token = ""; try { localStorage.removeItem("token"); } catch {}
  $("panel").hidden = true; $("login").hidden = false;
}

$("enter").onclick = () => {
  token = $("token").value.trim();
  try { localStorage.setItem("token", token); } catch {}
  load();
};
$("logout").onclick = logout;
$("add").onclick = async () => {
  const text = $("text").value.trim();
  if (text && await act({ action: $("kind").value, text }, "Agregado")) $("text").value = "";
};
$("fill").onclick = async () => {
  const text = $("seed").value.trim();
  if (!text) return;
  $("fill").disabled = true; say("Completando...");
  try {
    const { card } = await call("POST", { action: "fillCard", text });
    for (const k of ["jp", "reading", "romaji", "meaning"]) $(k).value = card[k] || "";
    say("Revisa y guarda");
  } catch (e) { say(e.message, true); }
  $("fill").disabled = false;
};
$("addCard").onclick = async () => {
  const card = Object.fromEntries(["jp", "reading", "romaji", "meaning"].map((k) => [k, $(k).value.trim()]));
  if (await act({ action: "addCard", ...card }, "Tarjeta guardada")) {
    for (const k of ["seed", "jp", "reading", "romaji", "meaning"]) $(k).value = "";
  }
};
load();
</script>
</body>
</html>`;

export function GET(): Response {
  return new Response(PAGE, {
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "Referrer-Policy": "no-referrer",
      "X-Frame-Options": "DENY",
    },
  });
}
