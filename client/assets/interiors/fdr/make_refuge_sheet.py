"""Monta a folha `refuge` das salas com as peças do Fantasy Dreamland Reborn.

Uso: python make_refuge_sheet.py <pasta Tilesets do pacote>

Copia, sem mudar os pixels, as peças das folhas Interior e Laboratory, cada uma no
menor retângulo de tiles de 16 px que a cabe, com o pé na borda de baixo e centrada na
largura (.specs/interiors/04-refuge-hospital.md).
"""

import sys
from pathlib import Path

from PIL import Image

CELL = 16
COLUMNS = 16
ROWS = 10
OUT = Path(__file__).with_name("refuge.png")
INTERIOR = "Interior/Sprites/FDR_Interior.png"
LAB = "Laboratory/Sprites/FDR_Laboratory_Tiles.png"

# Tiles copiados inteiros: nome -> (folha, coluna, linha, largura, altura em tiles, destino).
TILES = {
    "floor": (LAB, 12, 2, 1, 1, (0, 0)),
    "ceiling": (INTERIOR, 10, 7, 3, 3, (3, 0)),
    "wall": (INTERIOR, 12, 1, 3, 2, (8, 0)),
    "corners": (INTERIOR, 13, 7, 2, 2, (6, 0)),
    "rug": (INTERIOR, 0, 12, 3, 3, (13, 0)),
    "mat": (INTERIOR, 0, 15, 3, 1, (13, 3)),
}

# Peças recortadas pelos pixels: nome -> (folha, retângulo x0, y0, x1, y1, destino, espelhar).
PIECES = {
    "sign_green": (LAB, (337, 128, 351, 144), (11, 0), False),
    "sign_red": (LAB, (353, 128, 367, 144), (12, 0), False),
    "tank_cross": (LAB, (453, 96, 475, 128), (0, 4), False),
    "tank": (LAB, (485, 96, 507, 128), (2, 4), False),
    "bed": (LAB, (389, 193, 411, 224), (4, 4), False),
    "cabinet_green": (LAB, (320, 0, 336, 24), (6, 4), False),
    "cabinet_red": (LAB, (464, 32, 480, 56), (7, 4), False),
    "cabinet_both": (LAB, (432, 64, 448, 88), (8, 4), False),
    "drip": (LAB, (323, 128, 333, 143), (9, 4), False),
    "plant_white": (INTERIOR, (257, 160, 271, 184), (10, 4), False),
    "plant_blue": (INTERIOR, (273, 160, 287, 184), (11, 4), False),
    "plant_red": (INTERIOR, (305, 160, 319, 184), (12, 4), False),
    "pot_white": (INTERIOR, (257, 137, 271, 151), (13, 4), False),
    "pot_red": (INTERIOR, (305, 137, 319, 151), (14, 4), False),
    "sofa_front": (INTERIOR, (0, 364, 32, 384), (0, 6), False),
    "sofa_back": (INTERIOR, (32, 364, 64, 384), (2, 6), False),
    "sofa_left": (INTERIOR, (0, 384, 16, 416), (4, 6), False),
    "sofa_right": (INTERIOR, (16, 384, 32, 416), (5, 6), False),
}

# O estrado: as 9 partes da plataforma em cruz do laboratório (colunas 0 a 4, linhas 0 a
# 4), nas colunas 0 a 2 das linhas 1 a 3 da folha.
DAIS = [
    [(1, 0), (2, 0), (3, 0)],
    [(0, 2), (2, 2), (4, 2)],
    [(1, 4), (2, 4), (3, 4)],
]
DAIS_AT = (0, 1)

# A máquina de cura: três cápsulas, a do meio com a cruz, nas colunas 0 a 4 da linha 8.
MACHINE_AT = (0, 8)
MACHINE_CELLS = (5, 2)
MACHINE_PARTS = [("tank", 0), ("tank_cross", 29), ("tank", 58)]

def load(root: Path, sheet: str) -> Image.Image:
    return Image.open(root / sheet).convert("RGBA")


def paste_tiles(out: Image.Image, image: Image.Image, col: int, row: int, w: int, h: int, at: tuple) -> None:
    box = (col * CELL, row * CELL, (col + w) * CELL, (row + h) * CELL)
    out.paste(image.crop(box), (at[0] * CELL, at[1] * CELL))


def cells_for(width: int, height: int) -> tuple:
    return ((width + CELL - 1) // CELL, (height + CELL - 1) // CELL)


def paste_piece(out: Image.Image, piece: Image.Image, at: tuple) -> None:
    cols, rows = cells_for(piece.width, piece.height)
    x = at[0] * CELL + (cols * CELL - piece.width) // 2
    y = at[1] * CELL + rows * CELL - piece.height
    out.alpha_composite(piece, (x, y))


def build(root: Path) -> Image.Image:
    sheets = {name: load(root, name) for name in (INTERIOR, LAB)}
    out = Image.new("RGBA", (COLUMNS * CELL, ROWS * CELL), (0, 0, 0, 0))
    for sheet, col, row, w, h, at in TILES.values():
        paste_tiles(out, sheets[sheet], col, row, w, h, at)

    for row, parts in enumerate(DAIS):
        for col, (source_col, source_row) in enumerate(parts):
            paste_tiles(out, sheets[LAB], source_col, source_row, 1, 1, (DAIS_AT[0] + col, DAIS_AT[1] + row))

    pieces = {}
    for name, (sheet, rect, at, mirror) in PIECES.items():
        piece = sheets[sheet].crop(rect)
        if mirror:
            piece = piece.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        pieces[name] = piece
        paste_piece(out, piece, at)

    machine = Image.new("RGBA", (MACHINE_CELLS[0] * CELL, MACHINE_CELLS[1] * CELL), (0, 0, 0, 0))
    for name, x in MACHINE_PARTS:
        part = pieces[name]
        machine.alpha_composite(part, (x, machine.height - part.height))
    out.alpha_composite(machine, (MACHINE_AT[0] * CELL, MACHINE_AT[1] * CELL))
    return out


def main() -> None:
    if len(sys.argv) != 2:
        sys.exit("Uso: python make_refuge_sheet.py <pasta Tilesets do pacote>")
    build(Path(sys.argv[1])).save(OUT)
    print(f"Gravei {OUT}")


if __name__ == "__main__":
    main()
