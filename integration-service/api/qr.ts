// GET /api/qr?c=123456 — QR en PNG que abre el panel ya enlazado
// (/api/setup#c=123456). El reloj lo descarga junto con el código de
// /api/pair: al escanearlo, el teléfono se enlaza sin escribir nada.
// Solo acepta 6 dígitos: no es un generador de QR genérico.

import QRCode from "qrcode";

export async function GET(request: Request): Promise<Response> {
  const url = new URL(request.url);
  const code = url.searchParams.get("c") ?? "";
  if (!/^\d{6}$/.test(code)) {
    return new Response("invalid code", { status: 400 });
  }
  const png = await QRCode.toBuffer(`${url.origin}/api/setup#c=${code}`, {
    errorCorrectionLevel: "M",
    margin: 2,
    scale: 6,
    color: { dark: "#000000", light: "#ffffff" },
  });
  return new Response(new Uint8Array(png), {
    headers: { "Content-Type": "image/png", "Cache-Control": "no-store" },
  });
}
