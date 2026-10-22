"""Genera una fuente BMFont (.fnt + .png) con los caracteres japoneses que
usa la app. Connect IQ no trae glifos japoneses en el fēnix 8.

Uso:
    python make_font.py <fuente.ttf> <JapaneseDeck.mc> <dir_salida> [tamaño] [JpCharset.mc]

Requiere Pillow. Incluye todo el hiragana y el katakana (para las tarjetas
que se agregan desde el teléfono) más los kanji de JapaneseDeck.mc, así que
basta con volver a ejecutarlo al cambiar el mazo. Con JpCharset.mc escribe
también la lista de caracteres, que el reloj usa para saber qué puede dibujar.
"""
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

CJK = re.compile(r"[　-ヿ㐀-鿿＀-￯]")
NAME = "jp"
PAD = 1


def main():
    ttf, deck, out_dir = sys.argv[1:4]
    size = int(sys.argv[4]) if len(sys.argv) > 4 else 34

    kana = [chr(c) for c in range(0x3041, 0x3097)] + [chr(c) for c in range(0x30A1, 0x30FB)] + ["ー", "、", "。"]
    chars = sorted(set(CJK.findall(open(deck, encoding="utf-8").read())) | set(kana))
    if not chars:
        sys.exit("no se encontraron caracteres japoneses en " + deck)

    font = ImageFont.truetype(ttf, size)
    try:
        font.set_variation_by_name("Medium")
    except (OSError, ValueError):
        pass
    ascent, descent = font.getmetrics()

    glyphs = []
    for ch in chars:
        x0, y0, x1, y1 = font.getbbox(ch, anchor="la")
        glyphs.append((ch, x0, y0, max(1, x1 - x0), max(1, y1 - y0), round(font.getlength(ch))))

    # Atlas en filas, ancho fijo.
    atlas_w = 512
    x = y = row_h = 0
    placed = []
    for g in glyphs:
        w, h = g[3], g[4]
        if x + w + PAD > atlas_w:
            x, y, row_h = 0, y + row_h + PAD, 0
        placed.append((g, x, y))
        x += w + PAD
        row_h = max(row_h, h)
    atlas_h = y + row_h + PAD

    img = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    for (ch, gx0, gy0, w, h, adv), px, py in placed:
        draw.text((px - gx0, py - gy0), ch, font=font, fill=(255, 255, 255, 255), anchor="la")

    os.makedirs(out_dir, exist_ok=True)
    png = NAME + "_0.png"
    img.save(os.path.join(out_dir, png))

    lines = [
        f'info face="NotoSansJP" size={size} bold=0 italic=0 charset="" unicode=1 '
        f"stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing={PAD},{PAD}",
        f"common lineHeight={ascent + descent} base={ascent} scaleW={atlas_w} "
        f"scaleH={atlas_h} pages=1 packed=0",
        f'page id=0 file="{png}"',
        f"chars count={len(placed)}",
    ]
    for (ch, gx0, gy0, w, h, adv), px, py in placed:
        lines.append(
            f"char id={ord(ch)} x={px} y={py} width={w} height={h} "
            f"xoffset={gx0} yoffset={gy0} xadvance={adv} page=0 chnl=15"
        )
    open(os.path.join(out_dir, NAME + ".fnt"), "w", encoding="utf-8").write("\n".join(lines) + "\n")
    if len(sys.argv) > 5:
        source = (
            "import Toybox.Lang;\n\n"
            "// Generado por tools/make_font.py: caracteres que tiene la fuente JpFont.\n"
            "module JpCharset {\n"
            f'    const CHARS = "{"".join(chars)}";\n'
            "}\n"
        )
        open(sys.argv[5], "w", encoding="utf-8").write(source)
    print(f"{len(chars)} glifos, atlas {atlas_w}x{atlas_h}: {''.join(chars)}")


if __name__ == "__main__":
    main()
