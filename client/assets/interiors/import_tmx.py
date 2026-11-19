"""Converte um mapa do Tiled com as folhas do Main Characters Home no SQL de uma sala.

Uso: python import_tmx.py <arquivo.tmx> <nome>

As camadas Floor, Tile Layer 6, Walls e Windows viram as camadas floor, floor_detail,
wall e wall_detail; Boxes, Objects1 e Objects2 viram objetos. As folhas são lidas ao
lado do .tmx (.specs/interiors/01-interior-data.md).
"""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image

CELL = 16
SOLID_PIXELS = 128
FLIP_BITS = 0x1FFFFFFF
TILE_LAYERS = {
    "Floor": "floor",
    "Tile Layer 6": "floor_detail",
    "Walls": "wall",
    "Windows": "wall_detail",
}
LAYER_ORDER = ["floor", "floor_detail", "wall", "wall_detail"]
OBJECT_LAYERS = ["Boxes", "Objects1", "Objects2"]
SHEETS = {
    "walls_floor.png": "walls_floor",
    "Interior.png": "interior",
    "Doors_windows_animation.png": "doors_windows",
}
ROWS_PER_INSERT = 200
RUG_SHEET = "interior"
RUG_ROWS = range(16, 23)


class Sheet:
    def __init__(self, slug, first_gid, columns, image):
        self.slug = slug
        self.first_gid = first_gid
        self.columns = columns
        self.image = image
        self._solid = {}

    def is_solid(self, col, row):
        key = (col, row)
        if key not in self._solid:
            tile = self.image.crop((col * CELL, row * CELL, col * CELL + CELL, row * CELL + CELL))
            alpha = tile.getchannel("A").tobytes()
            self._solid[key] = sum(1 for value in alpha if value > 0) >= SOLID_PIXELS
        return self._solid[key]


def read_sheets(root, folder):
    sheets = []
    for tileset in root.findall("tileset"):
        source = tileset.find("image").get("source")
        if source not in SHEETS:
            sys.exit(f"Folha desconhecida: {source}")
        image = Image.open(folder / source).convert("RGBA")
        sheets.append(Sheet(SHEETS[source], int(tileset.get("firstgid")), int(tileset.get("columns")), image))
    return sorted(sheets, key=lambda sheet: sheet.first_gid)


def tile_of(gid, sheets):
    gid &= FLIP_BITS
    owner = None
    for sheet in sheets:
        if gid >= sheet.first_gid:
            owner = sheet
    index = gid - owner.first_gid
    return owner, index % owner.columns, index // owner.columns


def read_layers(root, sheets):
    layers = {}
    for layer in root.findall("layer"):
        cells = {}
        data = layer.find("data")
        chunks = data.findall("chunk") or [data]
        for chunk in chunks:
            x0 = int(chunk.get("x", 0))
            y0 = int(chunk.get("y", 0))
            width = int(chunk.get("width", layer.get("width")))
            values = [int(value) for value in chunk.text.replace("\n", "").split(",") if value.strip()]
            for index, gid in enumerate(values):
                if gid:
                    cells[(x0 + index % width, y0 + index // width)] = tile_of(gid, sheets)
        layers[layer.get("name")] = cells
    return layers


def groups_of(cells):
    seen = set()
    groups = []
    for start in sorted(cells, key=lambda cell: (cell[1], cell[0])):
        if start in seen:
            continue
        seen.add(start)
        group = [start]
        queue = [start]
        while queue:
            x, y = queue.pop()
            sheet, col, row = cells[(x, y)]
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                other = (x + dx, y + dy)
                if other in seen or other not in cells:
                    continue
                other_sheet, other_col, other_row = cells[other]
                if other_sheet is sheet and other_col == col + dx and other_row == row + dy:
                    seen.add(other)
                    group.append(other)
                    queue.append(other)
        groups.append(group)
    return groups


def objects_of(cells):
    objects = []
    for group in groups_of(cells):
        xs = [x for x, _ in group]
        ys = [y for _, y in group]
        left, top = min(xs), min(ys)
        width, height = max(xs) - left + 1, max(ys) - top + 1
        if len(group) == width * height:
            objects.append(object_at(cells, left, top, width, height))
            continue
        members = set(group)
        for x in range(left, left + width):
            y = top
            while y < top + height:
                if (x, y) not in members:
                    y += 1
                    continue
                run = 0
                while (x, y + run) in members:
                    run += 1
                objects.append(object_at(cells, x, y, 1, run))
                y += run
    return sorted(objects, key=lambda item: (item["y"], item["x"]))


def object_at(cells, x, y, width, height):
    sheet, col, row = cells[(x, y)]
    return {"x": x, "y": y, "sheet": sheet.slug, "col": col, "row": row, "width": width, "height": height}


def convert(tmx_path):
    root = ET.parse(tmx_path).getroot()
    sheets = read_sheets(root, tmx_path.parent)
    layers = read_layers(root, sheets)
    used = [cell for cells in layers.values() for cell in cells]
    if not used:
        sys.exit("O mapa está vazio.")
    min_x = min(x for x, _ in used)
    min_y = min(y for _, y in used)
    width = max(x for x, _ in used) - min_x + 1
    height = max(y for _, y in used) - min_y + 1

    def local(cell):
        return (cell[0] - min_x, cell[1] - min_y)

    tiles = []
    for name, layer in TILE_LAYERS.items():
        for cell, (sheet, col, row) in layers.get(name, {}).items():
            x, y = local(cell)
            tiles.append({"layer": layer, "x": x, "y": y, "sheet": sheet.slug, "col": col, "row": row})

    # Um tapete do Tiled numa camada de objetos vai para o detalhe do chão, por baixo do Domador.
    rugs = {}
    objects = []
    for name in OBJECT_LAYERS:
        cells = {}
        for cell, tile in layers.get(name, {}).items():
            if tile[0].slug == RUG_SHEET and tile[2] in RUG_ROWS:
                rugs[local(cell)] = tile
            else:
                cells[local(cell)] = tile
        objects.extend(objects_of(cells))
    tiles = [tile for tile in tiles if not (tile["layer"] == "floor_detail" and (tile["x"], tile["y"]) in rugs)]
    for (x, y), (sheet, col, row) in rugs.items():
        tiles.append({"layer": "floor_detail", "x": x, "y": y, "sheet": sheet.slug, "col": col, "row": row})
    tiles.sort(key=lambda tile: (LAYER_ORDER.index(tile["layer"]), tile["y"], tile["x"]))

    blocks = set()
    for cell, (sheet, col, row) in layers.get("Walls", {}).items():
        if sheet.is_solid(col, row):
            blocks.add(local(cell))
    for item in objects:
        for x in range(item["x"], item["x"] + item["width"]):
            blocks.add((x, item["y"] + item["height"] - 1))

    floor = {local(cell) for cell in layers.get("Floor", {})}
    free = [cell for cell in floor if cell not in blocks]
    if not free:
        sys.exit("A sala não tem um quadrado de chão livre para a porta.")
    bottom = max(y for _, y in free)
    middle = (width - 1) / 2.0
    door = min((cell for cell in free if cell[1] == bottom), key=lambda cell: (abs(cell[0] - middle), cell[0]))
    return width, height, door, tiles, objects, sorted(blocks, key=lambda cell: (cell[1], cell[0]))


def text(value):
    return "'" + value.replace("'", "''") + "'"


def inserts(table, columns, rows):
    lines = []
    for first in range(0, len(rows), ROWS_PER_INSERT):
        chunk = rows[first:first + ROWS_PER_INSERT]
        values = ",\n    ".join("(" + ", ".join(row) + ")" for row in chunk)
        lines.append(f'  INSERT INTO "ecobeasts"."{table}" ({", ".join(columns)}) VALUES\n    {values};')
    return lines


def sql(name, width, height, door, tiles, objects, blocks):
    lines = [
        "DO $$",
        "DECLARE room integer;",
        "BEGIN",
        '  INSERT INTO "ecobeasts"."interiors" (name, width, height, door_x, door_y, updated_at)',
        f"    VALUES ({text(name)}, {width}, {height}, {door[0]}, {door[1]}, now()) RETURNING id INTO room;",
    ]
    lines += inserts(
        "interior_tiles",
        ["interior_id", "layer", "x", "y", "sheet", "col", "row"],
        [["room", text(t["layer"]), str(t["x"]), str(t["y"]), text(t["sheet"]), str(t["col"]), str(t["row"])] for t in tiles],
    )
    lines += inserts(
        "interior_objects",
        ["interior_id", "x", "y", "sheet", "col", "row", "width", "height"],
        [["room", str(o["x"]), str(o["y"]), text(o["sheet"]), str(o["col"]), str(o["row"]), str(o["width"]), str(o["height"])] for o in objects],
    )
    lines += inserts("interior_blocks", ["interior_id", "x", "y"], [["room", str(x), str(y)] for x, y in blocks])
    lines += ["END $$;"]
    return "\n".join(lines) + "\n"


def main():
    if len(sys.argv) != 3:
        print("Uso: python import_tmx.py <arquivo.tmx> <nome>", file=sys.stderr)
        sys.exit(2)
    width, height, door, tiles, objects, blocks = convert(Path(sys.argv[1]))
    if not (4 <= width <= 64 and 4 <= height <= 64):
        sys.exit(f"A sala tem {width}×{height} quadrados; o tamanho vai de 4 a 64.")
    sys.stdout.reconfigure(encoding="utf-8", newline="\n")
    sys.stdout.write(sql(sys.argv[2], width, height, door, tiles, objects, blocks))


if __name__ == "__main__":
    main()
