import Toybox.Lang;

// Colores compartidos por todas las pantallas, al estilo de la interfaz
// nativa del fēnix 8: fondo negro puro (AMOLED) y paneles gris neutro.
// Los colores del asistente (verde, cian, rojo) viven en EyesRenderer.
module Theme {

    const SURFACE = 0x1A1A1A;
    const SURFACE_SELECTED = 0x2C2C2C;
    const TRACK = 0x2A2A2A;

    const TEXT = 0xFFFFFF;
    const TEXT_SECONDARY = 0xAAAAAA;
    const TEXT_HINT = 0x777777;

    const RIGHT = 0x2E6B50;
    const WRONG = 0x6B2E2A;
}
