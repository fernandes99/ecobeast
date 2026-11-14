"""O idle da luta (board-battle/24) a partir do zip de folha única do PixelLab.

Uso, na raiz do repositório:
python -I .claude/skills/creature-sprites/scripts/idle_from_spritesheet.py <slug> <zip>

O PixelLab também exporta o personagem como uma folha só (`<nome>.png`) e um
`<nome>.json` com as linhas. Este script tira dela as 5 vistas do idle (south, north,
south-east, east e north-east, board-battle/17) e escreve só o
`client/assets/creatures/<slug>/battle/idle.png`, na célula do `walk.png` que já
existe: o desenho fica centrado no pivô do PixelLab, com os pés na linha dos pés do
walk. Serve para quando chega só o idle; com o zip completo, use o `battle_sheets.py`.
"""
import json
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from spritekit import read_png_bytes, write_png  # noqa: E402

ROOT = Path(__file__).resolve().parents[4]
DIRECTIONS = ("south", "north", "south-east", "east", "north-east")


class Problem(Exception):
    pass


def alpha(rows, x, y):
    return rows[y][x * 4 + 3]


def feet_line(width, height, rows, cell):
    """A linha mais baixa com algum pixel, em qualquer célula: a mesma conta do jogo."""
    lines = [y % cell for y in range(height) if any(alpha(rows, x, y) for x in range(width))]
    if not lines:
        raise Problem("o walk.png está vazio")
    return max(lines)


def build(slug, zip_path):
    archive = zipfile.ZipFile(zip_path)
    meta_name = next((n for n in archive.namelist() if n.endswith(".json")), None)
    if meta_name is None:
        raise Problem("o zip não tem o .json da folha")
    meta = json.loads(archive.read(meta_name))["spritesheet"]
    source = meta["cell_size"]["width"]
    _, _, sheet = read_png_bytes(archive.read(meta["path"]))
    idle_rows = {
        row["direction"]: row
        for row in meta["rows"]
        if row["type"] == "animation" and "idle" in row.get("animation", "").lower()
    }
    missing = [d for d in DIRECTIONS if d not in idle_rows]
    if missing:
        raise Problem("falta o idle %s" % ", ".join(missing))

    out = ROOT / "client/assets/creatures" / slug / "battle"
    walk_width, walk_height, walk_rows = read_png_bytes((out / "walk.png").read_bytes())
    cell = walk_height // 3 if walk_height % 3 == 0 and walk_height // 3 <= walk_width else walk_height // 5
    feet = feet_line(walk_width, walk_height, walk_rows, cell)

    bottom = 0
    for direction in DIRECTIONS:
        row = idle_rows[direction]["row"]
        for y in range(source):
            line = sheet[row * source + y]
            if any(line[x * 4 + 3] for x in range(idle_rows[direction]["frame_count"] * source)):
                bottom = max(bottom, y)
    left = source // 2 - cell // 2
    top = bottom - feet

    lines = []
    for direction in DIRECTIONS:
        info = idle_rows[direction]
        frames = []
        for frame in range(info["frame_count"]):
            cells = []
            for y in range(source):
                line = sheet[info["row"] * source + y][frame * source * 4:(frame + 1) * source * 4]
                inside = top <= y < top + cell
                for x in range(source):
                    if line[x * 4 + 3] and not (inside and left <= x < left + cell):
                        raise Problem("o idle %s, quadro %d, passa da célula de %d" % (direction, frame, cell))
                if inside:
                    cells.append(line[left * 4:(left + cell) * 4])
            if top < 0:
                cells = [bytes(cell * 4)] * -top + cells
            frames.append(cells)
        lines.append(frames)

    columns = max(len(frames) for frames in lines)
    rows = []
    for frames in lines:
        for y in range(cell):
            rows.append(b"".join(frame[y] for frame in frames) + bytes((columns - len(frames)) * cell * 4))
    write_png(out / "idle.png", cell * columns, cell * len(lines), rows)
    return out / "idle.png", {"cell": cell, "feet": feet, "idle": {d: idle_rows[d]["frame_count"] for d in DIRECTIONS}}


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    try:
        path, meta = build(sys.argv[1], sys.argv[2])
    except Problem as problem:
        print("FALHA:", problem)
        sys.exit(1)
    print("idle em", path)
    print(json.dumps(meta))


if __name__ == "__main__":
    main()
