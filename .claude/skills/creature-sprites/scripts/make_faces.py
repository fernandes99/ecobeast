"""Recorta o rosto de cada Ecobeast do front.png (.specs/creature-faces/01-face-art.md).

Uso, da raiz: python -I .claude/skills/creature-sprites/scripts/make_faces.py

Para cada client/assets/creatures/<slug>/front.png, recorta o quadrado do rosto guardado em
client/assets/creatures/faces.json ({"slug": [x, y, lado]}, em pixels do front de 512) e grava
<slug>/face.png com 128×128, o fundo transparente e o alfa só em 0 ou 255. Um slug sem
quadrado ganha um calculado pela figura, gravado no arquivo; um quadrado gravado nunca muda.
Grava também a folha art-source/creature-faces/faces_sheet.png, com todos os rostos e os slugs,
para conferir (fora de client/, para o Godot não a levar para o jogo).
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[4]
CREATURES = ROOT / "client" / "assets" / "creatures"
BOXES = CREATURES / "faces.json"
SHEET = ROOT / "art-source" / "creature-faces" / "faces_sheet.png"
FACE = 128
SOLID = 128
# O quadrado calculado: o lado é esta parte da altura da figura, e o topo fica acima dela.
SIDE_OF_HEIGHT = 0.45
TOP_GAP = 4
SHEET_COLUMNS = 8
LABEL = 16
SHEET_BACK = (47, 134, 214, 255)
LABEL_COLOR = (255, 255, 255, 255)


def figure_box(alpha):
    w, h = alpha.size
    px = alpha.load()
    xs, ys = [], []
    for y in range(h):
        for x in range(w):
            if px[x, y] >= SOLID:
                xs.append(x)
                ys.append(y)
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def guess_box(front):
    """O lado é 45% da altura da figura, com o topo 4 px acima dela e centrado no meio
    dos pixels do terço de cima, onde a cabeça costuma estar."""
    alpha = front.getchannel("A")
    left, top, right, bottom = figure_box(alpha)
    side = round((bottom - top) * SIDE_OF_HEIGHT)
    px = alpha.load()
    third = top + (bottom - top) // 3
    total, count = 0, 0
    for y in range(top, third):
        for x in range(left, right):
            if px[x, y] >= SOLID:
                total += x
                count += 1
    center = total / count if count else (left + right) / 2
    x = round(center - side / 2)
    y = top - TOP_GAP
    x = max(0, min(front.width - side, x))
    y = max(0, min(front.height - side, y))
    return [x, y, side]


def cut_face(front, square):
    x, y, side = square
    face = front.crop((x, y, x + side, y + side)).resize((FACE, FACE), Image.LANCZOS)
    alpha = face.getchannel("A").point(lambda a: 255 if a >= SOLID else 0)
    face.putalpha(alpha)
    return face


def fits(front, square):
    x, y, side = square
    return side > 0 and x >= 0 and y >= 0 and x + side <= front.width and y + side <= front.height


def main():
    boxes = json.loads(BOXES.read_text(encoding="utf-8")) if BOXES.exists() else {}
    faces = []
    for folder in sorted(p for p in CREATURES.iterdir() if (p / "front.png").exists()):
        slug = folder.name
        front = Image.open(folder / "front.png").convert("RGBA")
        if slug not in boxes:
            boxes[slug] = guess_box(front)
            print(f"{slug}: quadrado calculado {boxes[slug]}")
        if not fits(front, boxes[slug]):
            print(f"{slug}: o quadrado {boxes[slug]} sai do front; rosto não gravado")
            continue
        face = cut_face(front, boxes[slug])
        face.save(folder / "face.png")
        faces.append((slug, face))
    BOXES.write_text(
        "{\n" + ",\n".join(f'\t"{slug}": {json.dumps(boxes[slug])}' for slug in sorted(boxes)) + "\n}\n",
        encoding="utf-8", newline="\n")
    rows = (len(faces) + SHEET_COLUMNS - 1) // SHEET_COLUMNS
    sheet = Image.new("RGBA", (SHEET_COLUMNS * FACE, rows * (FACE + LABEL)), SHEET_BACK)
    draw = ImageDraw.Draw(sheet)
    for index, (slug, face) in enumerate(faces):
        cx = index % SHEET_COLUMNS * FACE
        cy = index // SHEET_COLUMNS * (FACE + LABEL)
        sheet.alpha_composite(face, (cx, cy))
        draw.text((cx + 4, cy + FACE + 2), slug, fill=LABEL_COLOR)
    SHEET.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(SHEET)
    print(f"{len(faces)} rostos; folha em {SHEET.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
