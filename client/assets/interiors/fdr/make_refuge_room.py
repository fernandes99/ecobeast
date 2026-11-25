"""Monta a sala 1, o Refúgio, como um hospital, com a folha `refuge`.

Uso: python make_refuge_room.py <saída.sql> [prévia.png]

Escreve o SQL que troca a sala 1 (mantendo o id) e, se pedida, uma prévia ampliada
(.specs/interiors/04-refuge-hospital.md).
"""

import sys
from pathlib import Path

from PIL import Image

CELL = 16
SHEET = "refuge"
SHEET_PATH = Path(__file__).with_name("refuge.png")
ROOM_ID = 1
NAME = "Refúgio"
WIDTH = 19
HEIGHT = 14
DOOR = (9, 13)
REFUGE_ACTION = 1
PREVIEW_SCALE = 3
LAYERS = ["floor", "floor_detail", "wall", "wall_detail"]
ROWS_PER_INSERT = 200

FLOOR = (0, 0)
WALL_COLUMNS = (8, 9, 10)
WALL_ROWS = (0, 1)
# A moldura do teto pelo lado aberto para a sala (N, S, L, O) e os cantos de dentro.
CEILING = {
    "n": (4, 0), "s": (4, 2), "e": (5, 1), "w": (3, 1),
    "ne": (5, 0), "nw": (3, 0), "se": (5, 2), "sw": (3, 2),
    "fill": (4, 1),
    "inner_se": (6, 0), "inner_sw": (7, 0), "inner_ne": (6, 1), "inner_nw": (7, 1),
}
DAIS = (0, 1)
RUG = (13, 0)
MAT = (13, 3)
SIGN_GREEN = (11, 0)

PIECES = {
    "machine": ((0, 8), (5, 2)),
    "bed": ((4, 4), (2, 2)),
    "cabinet_green": ((6, 4), (1, 2)),
    "cabinet_red": ((7, 4), (1, 2)),
    "cabinet_both": ((8, 4), (1, 2)),
    "drip": ((9, 4), (1, 1)),
    "plant_white": ((10, 4), (1, 2)),
    "plant_blue": ((11, 4), (1, 2)),
    "plant_red": ((12, 4), (1, 2)),
    "sofa_front": ((0, 6), (2, 2)),
    "sofa_back": ((2, 6), (2, 2)),
}

# (peça, x, y, quadrados bloqueados relativos, ação)
OBJECTS = [
    ("machine", 7, 2, [(0, 1), (1, 1), (2, 1), (3, 1), (4, 1)], REFUGE_ACTION),
    ("cabinet_both", 5, 2, [(0, 1)], None),
    ("cabinet_red", 13, 2, [(0, 1)], None),
    ("bed", 1, 3, [(0, 0), (1, 0), (0, 1), (1, 1)], None),
    ("bed", 3, 3, [(0, 0), (1, 0), (0, 1), (1, 1)], None),
    ("drip", 5, 4, [(0, 0)], None),
    ("bed", 1, 7, [(0, 0), (1, 0), (0, 1), (1, 1)], None),
    ("bed", 3, 7, [(0, 0), (1, 0), (0, 1), (1, 1)], None),
    ("drip", 5, 8, [(0, 0)], None),
    ("sofa_front", 14, 2, [(0, 1), (1, 1)], None),
    ("plant_blue", 17, 2, [(0, 1)], None),
    ("sofa_back", 14, 8, [(0, 1), (1, 1)], None),
    ("plant_white", 1, 11, [(0, 1)], None),
    ("plant_white", 17, 11, [(0, 1)], None),
    ("plant_red", 7, 11, [(0, 1)], None),
    ("plant_red", 11, 11, [(0, 1)], None),
]


def is_room(x: int, y: int) -> bool:
    if (x, y) == DOOR:
        return True
    return 1 <= x <= WIDTH - 2 and 1 <= y <= HEIGHT - 2


def ceiling_tile(x: int, y: int) -> tuple:
    open_sides = "".join(side for side, (dx, dy) in (("n", (0, -1)), ("s", (0, 1)), ("e", (1, 0)), ("w", (-1, 0))) if is_room(x + dx, y + dy))
    if open_sides:
        key = {"ns": "fill", "ew": "fill"}.get(open_sides, open_sides)
        return CEILING[key]
    for key, (dx, dy) in (("inner_se", (1, 1)), ("inner_sw", (-1, 1)), ("inner_ne", (1, -1)), ("inner_nw", (-1, -1))):
        if is_room(x + dx, y + dy):
            return CEILING[key]
    return CEILING["fill"]


def nine_slice(origin: tuple, x: int, y: int, w: int, h: int) -> int:
    def part(index: int, size: int) -> int:
        return 0 if index == 0 else 2 if index == size - 1 else 1

    return (origin[0] + part(x, w), origin[1] + part(y, h))


def build() -> tuple:
    tiles = {}
    for y in range(HEIGHT):
        for x in range(WIDTH):
            if not is_room(x, y):
                tiles[("wall", x, y)] = ceiling_tile(x, y)
            elif y in (1, 2):
                column = WALL_COLUMNS[0] if x == 1 else WALL_COLUMNS[2] if x == WIDTH - 2 else WALL_COLUMNS[1]
                tiles[("wall", x, y)] = (column, WALL_ROWS[y - 1])
            else:
                tiles[("floor", x, y)] = FLOOR

    def area(origin: tuple, left: int, top: int, w: int, h: int, sliced: bool = True) -> None:
        for dy in range(h):
            for dx in range(w):
                at = nine_slice(origin, dx, dy, w, h) if sliced else (origin[0] + dx, origin[1])
                tiles[("floor_detail", left + dx, top + dy)] = at

    area(DAIS, 6, 3, 7, 2)
    area(RUG, 13, 5, 5, 3)
    area(MAT, 8, 12, 3, 1)
    tiles[("wall_detail", 9, 1)] = SIGN_GREEN

    objects = []
    blocks = set()
    for name, x, y, blocked, action in OBJECTS:
        (col, row), (w, h) = PIECES[name]
        objects.append((x, y, col, row, w, h, action))
        for dx, dy in blocked:
            blocks.add((x + dx, y + dy))
    return tiles, objects, sorted(blocks, key=lambda cell: (cell[1], cell[0]))


def sql(tiles: dict, objects: list, blocks: list) -> str:
    lines = [
        f"-- A sala {ROOM_ID}, o Refúgio, como um hospital: make_refuge_room.py (.specs/interiors/04-refuge-hospital.md).",
        *(f'DELETE FROM "ecobeasts"."{table}" WHERE "interior_id" = {ROOM_ID};' for table in ("interior_tiles", "interior_objects", "interior_blocks", "interior_npcs")),
        f'UPDATE "ecobeasts"."interiors" SET "name" = \'{NAME}\', "width" = {WIDTH}, "height" = {HEIGHT}, '
        f'"door_x" = {DOOR[0]}, "door_y" = {DOOR[1]}, "updated_at" = CURRENT_TIMESTAMP WHERE "id" = {ROOM_ID};',
    ]
    ordered = sorted(tiles.items(), key=lambda item: (LAYERS.index(item[0][0]), item[0][2], item[0][1]))
    rows = [f"({ROOM_ID}, '{layer}', {x}, {y}, '{SHEET}', {col}, {row})" for (layer, x, y), (col, row) in ordered]
    for start in range(0, len(rows), ROWS_PER_INSERT):
        lines.append('INSERT INTO "ecobeasts"."interior_tiles" ("interior_id", "layer", "x", "y", "sheet", "col", "row") VALUES')
        lines.append(",\n".join(rows[start:start + ROWS_PER_INSERT]) + ";")
    lines.append('INSERT INTO "ecobeasts"."interior_objects" ("interior_id", "x", "y", "sheet", "col", "row", "width", "height", "action_type_id") VALUES')
    lines.append(",\n".join(
        f"({ROOM_ID}, {x}, {y}, '{SHEET}', {col}, {row}, {w}, {h}, {'NULL' if action is None else action})"
        for x, y, col, row, w, h, action in objects
    ) + ";")
    lines.append('INSERT INTO "ecobeasts"."interior_blocks" ("interior_id", "x", "y") VALUES')
    lines.append(",\n".join(f"({ROOM_ID}, {x}, {y})" for x, y in blocks) + ";")
    return "\n".join(lines) + "\n"


def preview(tiles: dict, objects: list, blocks: list, path: Path) -> None:
    sheet = Image.open(SHEET_PATH).convert("RGBA")
    out = Image.new("RGBA", (WIDTH * CELL, HEIGHT * CELL), (24, 22, 30, 255))

    def piece(col: int, row: int, w: int = 1, h: int = 1) -> Image.Image:
        return sheet.crop((col * CELL, row * CELL, (col + w) * CELL, (row + h) * CELL))

    for layer in ("floor", "floor_detail"):
        for (name, x, y), (col, row) in tiles.items():
            if name == layer:
                out.alpha_composite(piece(col, row), (x * CELL, y * CELL))
    sorted_items = []
    for (name, x, y), (col, row) in tiles.items():
        if name in ("wall", "wall_detail"):
            sorted_items.append(((y + 1) * CELL, LAYERS.index(name), piece(col, row), (x * CELL, y * CELL)))
    for x, y, col, row, w, h, _action in objects:
        sorted_items.append(((y + h) * CELL, 4, piece(col, row, w, h), (x * CELL, y * CELL)))
    for _foot, _order, image, at in sorted(sorted_items, key=lambda item: (item[0], item[1])):
        out.alpha_composite(image, at)
    out = out.resize((out.width * PREVIEW_SCALE, out.height * PREVIEW_SCALE), Image.NEAREST)
    out.save(path)


def main() -> None:
    if len(sys.argv) not in (2, 3):
        sys.exit("Uso: python make_refuge_room.py <saída.sql> [prévia.png]")
    tiles, objects, blocks = build()
    Path(sys.argv[1]).write_text(sql(tiles, objects, blocks), encoding="utf-8")
    if len(sys.argv) == 3:
        preview(tiles, objects, blocks, Path(sys.argv[2]))


if __name__ == "__main__":
    main()
