// GET /api/setup — panel y guía para el teléfono; lo abre el QR del reloj.
// La página no lleva datos. Se enlaza con el código de 6 dígitos que muestra
// el reloj bajo el QR (/api/pair) o con DEVICE_TOKEN; la sesión queda en el
// navegador y la página habla con /api/config. Desde aquí se agregan tareas,
// notas, preguntas rápidas, proyectos y tarjetas de japonés, y se ponen las
// claves de IA.

const PAGE = `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#05080a">
<title>Mi Asistente · Panel</title>
<style>
  :root { color-scheme: dark; --bg: #05080a; --card: #10171b; --line: #24323a; --text: #eef5f7; --muted: #9fb2b9; --accent: #5bc8e6; --bad: #f26b5b; --ok: #6cc79c; }
  * { box-sizing: border-box; }
  html { -webkit-text-size-adjust: 100%; }
  body { margin: 0; background: var(--bg); color: var(--text); font: 17px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
  main { max-width: 560px; margin: 0 auto; padding: 20px 16px 64px; }
  h1 { font-size: 26px; line-height: 1.2; margin: 0 0 6px; }
  h2 { font-size: 19px; margin: 0 0 4px; }
  section { background: var(--card); border-radius: 16px; padding: 16px; margin-top: 16px; }
  .sub { color: var(--muted); font-size: 15px; margin: 0 0 12px; }
  p { margin: 0; }
  ol { margin: 0; padding-left: 22px; } li { margin: 8px 0; }
  b { color: #fff; }
  label { display: block; font-size: 15px; color: var(--muted); margin: 0 0 4px; }
  input, select, button { font: inherit; font-size: 17px; color: inherit; }
  input, select { width: 100%; background: var(--bg); border: 1px solid var(--line); border-radius: 12px; padding: 12px; min-height: 48px; }
  input:focus, select:focus { outline: 2px solid var(--accent); border-color: transparent; }
  button { min-height: 48px; background: var(--accent); color: #031014; border: 0; border-radius: 12px; padding: 0 16px; font-weight: 650; cursor: pointer; white-space: nowrap; }
  button.ghost { background: transparent; color: var(--text); border: 1px solid var(--line); font-weight: 500; }
  button.small { min-height: 40px; padding: 0 12px; font-size: 15px; }
  button:disabled { opacity: .45; }
  .row { display: flex; gap: 8px; align-items: stretch; } .row > input, .row > select { flex: 1; min-width: 0; }
  .stack > * + * { margin-top: 10px; }
  #code { font-size: 28px; letter-spacing: .3em; text-align: center; font-variant-numeric: tabular-nums; }
  ul.items { list-style: none; margin: 12px 0 0; padding: 0; }
  ul.items li { display: flex; gap: 10px; align-items: center; justify-content: space-between; border-top: 1px solid var(--line); padding: 10px 0; margin: 0; }
  ul.items li span { min-width: 0; overflow-wrap: anywhere; }
  ul.items:empty::before { content: attr(data-empty); color: var(--muted); font-size: 15px; display: block; border-top: 1px solid var(--line); padding-top: 10px; }
  .key + .key { border-top: 1px solid var(--line); padding-top: 14px; margin-top: 14px; }
  .key .head { display: flex; justify-content: space-between; gap: 8px; align-items: baseline; margin-bottom: 8px; }
  .tag { font-size: 14px; color: var(--muted); white-space: nowrap; } .tag.on { color: var(--ok); }
  #msg { position: sticky; top: 8px; z-index: 2; display: none; padding: 12px 14px; border-radius: 12px; background: #13242b; border: 1px solid var(--accent); margin-top: 12px; }
  #msg.err { border-color: var(--bad); color: #ffd6d1; background: #2a1513; }
  .locked .needs { opacity: .45; pointer-events: none; }
  details summary { cursor: pointer; color: var(--accent); font-size: 15px; }
  #linked { display: flex; justify-content: space-between; align-items: center; gap: 8px; }
  [hidden] { display: none !important; }
</style>
</head>
<body>
<main id="app" class="locked">
  <h1>Mi Asistente</h1>
  <p class="sub">Panel del reloj fēnix 8: agrega cosas y configura las claves de IA.</p>
  <div id="msg" role="status"></div>

  <section id="login" class="stack">
    <h2>1. Enlazar con el reloj</h2>
    <p class="sub">En el reloj: menú → <b>Configurar (QR)</b>. Escribe el código de 6 dígitos que aparece bajo el QR.</p>
    <input id="code" inputmode="numeric" autocomplete="one-time-code" maxlength="6" placeholder="000000" aria-label="Código del reloj">
    <button id="pair">Enlazar</button>
    <details>
      <summary>Usar el DEVICE_TOKEN en su lugar</summary>
      <div class="row" style="margin-top:10px">
        <input id="token" type="password" autocomplete="off" placeholder="Token" aria-label="DEVICE_TOKEN">
        <button id="enter" class="ghost">Entrar</button>
      </div>
    </details>
  </section>
  <section id="linked" hidden>
    <span>✓ Enlazado con el reloj</span>
    <button id="logout" class="ghost small">Salir</button>
  </section>

  <section class="needs stack">
    <h2>Tareas y notas</h2>
    <p class="sub">El reloj las recoge al abrir su menú, con el iPhone cerca.</p>
    <select id="kind" aria-label="Tipo"><option value="addTask">Tarea</option><option value="addNote">Nota</option></select>
    <div class="row"><input id="text" maxlength="120" placeholder="Texto"><button id="add">Agregar</button></div>
    <ul class="items" id="inbox" data-empty="Nada pendiente de enviar al reloj."></ul>
  </section>

  <section class="needs stack">
    <h2>Preguntas rápidas</h2>
    <p class="sub">Aparecen en Preguntar para elegirlas sin hablar. Sin ninguna, se usan las de ejemplo.</p>
    <div class="row"><input id="question" maxlength="60" placeholder="¿Cómo dormí anoche?"><button id="addQuestion">Agregar</button></div>
    <ul class="items" id="questions" data-empty="Usando las de ejemplo."></ul>
  </section>

  <section class="needs stack">
    <h2>Proyectos</h2>
    <p class="sub">Se ven en el menú Proyectos del reloj.</p>
    <input id="ptitle" maxlength="40" placeholder="Nombre">
    <input id="plast" maxlength="60" placeholder="Último avance">
    <input id="pnext" maxlength="60" placeholder="Siguiente paso">
    <button id="addProject">Agregar proyecto</button>
    <ul class="items" id="projects" data-empty="Usando los de ejemplo."></ul>
  </section>

  <section class="needs stack">
    <h2>Tarjetas de japonés</h2>
    <p class="sub">Aparecen en Japonés → <b>Mis tarjetas</b>, también en el quiz.</p>
    <div class="row"><input id="seed" maxlength="40" placeholder="gato, neko o 猫"><button id="fill" class="ghost">Completar con IA</button></div>
    <div><label for="jp">Japonés</label><input id="jp" maxlength="20" placeholder="猫"></div>
    <div><label for="reading">Lectura en kana</label><input id="reading" maxlength="30" placeholder="ねこ"></div>
    <div><label for="romaji">Romaji</label><input id="romaji" maxlength="40" placeholder="neko"></div>
    <div><label for="meaning">Significado</label><input id="meaning" maxlength="22" placeholder="Gato"></div>
    <button id="addCard">Guardar tarjeta</button>
    <p class="sub">Si un kanji no está en la fuente del reloj, se muestra la lectura en kana.</p>
    <ul class="items" id="cards" data-empty="Todavía no hay tarjetas propias."></ul>
  </section>

  <section class="needs">
    <h2>Claves de IA</h2>
    <p class="sub">Se guardan cifradas y tienen prioridad sobre las de Vercel. Nunca se muestran completas.</p>
    <div id="keys"></div>
  </section>

  <section>
    <h2>Guía rápida</h2>
    <ol>
      <li>Garmin Connect abierto en el iPhone y el reloj <b>conectado</b>; Bluetooth, datos móviles y actualización en segundo plano activos.</li>
      <li>Asigna Mi Asistente a una tecla: <b>Ajustes → Sistema → Teclas de acceso rápido</b>.</li>
      <li>Al abrir la app escucha hasta 12 s; <b>toca</b> para terminar. Sube el volumen en <b>Ajustes → Sonido</b>.</li>
      <li><b>Estado</b> debe decir «Teléfono: conectado»; <b>Diagnóstico</b> revisa micrófono, altavoz y red.</li>
      <li><b>Quiz de japonés</b>: toca la opción, o mueve el resaltado cian con UP/DOWN y confirma con START.</li>
    </ol>
  </section>
</main>
<script>
const KEYS = { GROQ_API_KEY: "Groq · voz a texto y respuestas", GEMINI_API_KEY: "Gemini · respuestas y voz", NVIDIA_API_KEY: "NVIDIA · respaldo", GOOGLE_TTS_API_KEY: "Google Cloud TTS · voz de respaldo" };
const $ = (id) => document.getElementById(id);
let token = "";
try { token = localStorage.getItem("token") || ""; } catch {}

function say(text, bad) {
  const m = $("msg");
  m.textContent = text; m.className = bad ? "err" : ""; m.style.display = text ? "block" : "none";
  if (text && !bad) setTimeout(() => { if (m.textContent === text) say(""); }, 2500);
}

function setLinked(on) {
  $("app").classList.toggle("locked", !on);
  $("login").hidden = on; $("linked").hidden = !on;
}

async function call(path, method, body, auth = true) {
  const headers = { "Content-Type": "application/json" };
  if (auth) headers.Authorization = "Bearer " + token;
  const res = await fetch(path, { method, headers, body: body ? JSON.stringify(body) : undefined });
  const data = await res.json().catch(() => ({}));
  if (res.status === 401 && auth) { logout(); throw new Error("La sesión venció: vuelve a enlazar con el código del reloj"); }
  if (!res.ok) throw new Error(data.error || "Error " + res.status);
  return data;
}

function item(text, onRemove) {
  const li = document.createElement("li");
  const span = document.createElement("span"); span.textContent = text;
  const del = document.createElement("button"); del.className = "ghost small"; del.textContent = "Quitar";
  del.onclick = onRemove;
  li.append(span, del);
  return li;
}

function fill(id, entries) { $(id).replaceChildren(...entries); }

function render(state) {
  setLinked(true);
  if (!state.storage) say("Falta el almacenamiento (BLOB_READ_WRITE_TOKEN) en Vercel.", true);
  fill("inbox", [
    ...state.inbox.tasks.map((t) => item("Tarea · " + t.text, () => act({ action: "removeInbox", kind: "tasks", id: t.id }))),
    ...state.inbox.notes.map((n) => item("Nota · " + n.text, () => act({ action: "removeInbox", kind: "notes", id: n.id }))),
  ]);
  fill("questions", state.questions.map((q) => item(q.text, () => act({ action: "removeQuestion", id: q.id }))));
  fill("projects", state.projects.map((p) => item(p.title + (p.next ? " · sigue: " + p.next : ""), () => act({ action: "removeProject", id: p.id }))));
  fill("cards", state.cards.map((c) => item(c.jp + (c.reading ? " (" + c.reading + ")" : "") + " · " + c.romaji + " · " + c.meaning, () => act({ action: "removeCard", id: c.id }))));
  fill("keys", Object.entries(KEYS).map(([name, label]) => {
    const s = state.keys[name] || {};
    const box = document.createElement("div"); box.className = "key";
    const head = document.createElement("div"); head.className = "head";
    const title = document.createElement("b"); title.textContent = label;
    const tag = document.createElement("span"); tag.className = "tag" + (s.source ? " on" : "");
    tag.textContent = s.source === "panel" ? "panel " + s.hint : s.source === "env" ? "Vercel " + s.hint : "sin clave";
    head.append(title, tag);
    const row = document.createElement("div"); row.className = "row";
    const input = document.createElement("input"); input.type = "password"; input.autocomplete = "off"; input.placeholder = "Pegar clave nueva"; input.setAttribute("aria-label", label);
    const save = document.createElement("button"); save.textContent = "Guardar";
    save.onclick = () => input.value.trim() && act({ action: "setKey", name, value: input.value.trim() }, "Clave guardada");
    row.append(input, save);
    box.append(head, row);
    if (s.source === "panel") {
      const clear = document.createElement("button"); clear.className = "ghost small"; clear.textContent = "Quitar clave del panel"; clear.style.marginTop = "8px";
      clear.onclick = () => act({ action: "clearKey", name }, "Clave quitada");
      box.append(clear);
    }
    return box;
  }));
}

async function act(body, ok) {
  try { render(await call("/api/config", "POST", body)); if (ok) say(ok); return true; }
  catch (e) { say(e.message, true); return false; }
}

async function load() {
  if (!token) return setLinked(false);
  try { render(await call("/api/config", "GET")); } catch (e) { say(e.message, true); }
}

function remember(value) {
  token = value;
  try { localStorage.setItem("token", token); } catch {}
}

function logout() {
  token = ""; try { localStorage.removeItem("token"); } catch {}
  setLinked(false);
}

function clear(ids) { for (const id of ids) $(id).value = ""; }

$("pair").onclick = async () => {
  const code = $("code").value.replace(/\\D/g, "");
  if (code.length !== 6) return say("Escribe los 6 dígitos que muestra el reloj", true);
  try {
    const { session } = await call("/api/pair", "POST", { code }, false);
    remember(session); clear(["code"]); say("Enlazado");
    load();
  } catch (e) { say(e.message, true); }
};
$("code").addEventListener("input", () => { if ($("code").value.replace(/\\D/g, "").length === 6) $("pair").click(); });
$("enter").onclick = () => { remember($("token").value.trim()); clear(["token"]); load(); };
$("logout").onclick = logout;
$("add").onclick = async () => {
  const text = $("text").value.trim();
  if (text && await act({ action: $("kind").value, text }, "Agregado: el reloj lo recoge al abrir su menú")) clear(["text"]);
};
$("addQuestion").onclick = async () => {
  const text = $("question").value.trim();
  if (text && await act({ action: "addQuestion", text }, "Pregunta agregada")) clear(["question"]);
};
$("addProject").onclick = async () => {
  const body = { action: "addProject", title: $("ptitle").value.trim(), last: $("plast").value.trim(), next: $("pnext").value.trim() };
  if (await act(body, "Proyecto agregado")) clear(["ptitle", "plast", "pnext"]);
};
$("fill").onclick = async () => {
  const text = $("seed").value.trim();
  if (!text) return say("Escribe una palabra primero", true);
  $("fill").disabled = true; say("Completando...");
  try {
    const { card } = await call("/api/config", "POST", { action: "fillCard", text });
    for (const k of ["jp", "reading", "romaji", "meaning"]) $(k).value = card[k] || "";
    say("Revisa y guarda");
  } catch (e) { say(e.message, true); }
  $("fill").disabled = false;
};
$("addCard").onclick = async () => {
  const card = Object.fromEntries(["jp", "reading", "romaji", "meaning"].map((k) => [k, $(k).value.trim()]));
  if (await act({ action: "addCard", ...card }, "Tarjeta guardada")) clear(["seed", "jp", "reading", "romaji", "meaning"]);
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
