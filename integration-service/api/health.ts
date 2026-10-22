// GET /api/health — comprobación sin autenticación. No expone configuración.
export function GET(): Response {
  return Response.json({ ok: true });
}
