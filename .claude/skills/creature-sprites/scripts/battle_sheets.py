"""As folhas da luta de um Ecobeast (board-battle/07), a partir do zip do PixelLab.

Uso, na raiz do repositório: python -I .claude/skills/creature-sprites/scripts/battle_sheets.py <slug>

Lê `art-source/<slug>/pixellab.zip` (o zip do personagem, como o PixelLab exporta) e
escreve em `client/assets/creatures/<slug>/battle/`:

- `idle.png`: as linhas south (de frente) e north (de costas) e, quando o zip tem o
  idle de lado (board-battle/17), mais south-east, east e north-east;
- `walk.png`: as linhas south-east, east e north-east e, quando o zip tem o walk de
  frente e de costas (board-battle/17), mais south e north.

Células quadradas, do maior canvas do PixelLab; uma linha pode ter menos quadros que
outra, e o resto dela fica vazio. O jogo tira da própria imagem o tamanho da célula, os
quadros de cada linha e a linha dos pés. Todas as vistas olham para a direita: a
esquerda é a mesma arte espelhada no jogo.

Por padrão, o idle sai da animação com "idle" no nome e o walk da com "walk". Um
`art-source/<slug>/battle.json` troca a fonte de uma vista: o nome de outra animação,
ou "rotation" para a imagem parada daquela direção. Exemplo:
{"idle": {"north": "rotation"}}
"""
import json
import sys
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from spritekit import read_png_bytes, write_png  # noqa: E402

ROOT = Path(__file__).resolve().parents[4]
SHEETS = {
    "idle": ("south", "north"),
    "walk": ("south-east", "east", "north-east"),
}
# As vistas a mais de cada folha (board-battle/17), depois das de sempre: entram todas
# juntas, ou nenhuma. O idle de lado e o walk de frente e de costas.
EXTRA = {
    "idle": ("south-east", "east", "north-east"),
    "walk": ("south", "north"),
}
ROTATION = "rotation"


class Problem(Exception):
    pass


def load_sources(archive):
    """{(animação em minúsculas, direção): [nomes dos quadros]} e {direção: rotação}."""
    animations = {}
    rotations = {}
    for name in sorted(archive.namelist()):
        parts = name.split("/")
        if not name.endswith(".png"):
            continue
        if len(parts) >= 3 and parts[-2] == "rotations":
            rotations[parts[-1][:-4]] = name
        elif len(parts) >= 5 and parts[-4] == "animations":
            animations.setdefault((parts[-3].lower(), parts[-2]), []).append(name)
    return animations, rotations


def pick(sheet, direction, animations, rotations, overrides):
    """Os nomes dos quadros de uma vista, conforme o battle.json ou o padrão."""
    choice = overrides.get(sheet, {}).get(direction)
    if choice == ROTATION:
        if direction not in rotations:
            raise Problem("falta a imagem parada %s (rotations/%s.png)" % (direction, direction))
        return [rotations[direction]]
    names = sorted({animation for animation, _ in animations})
    if choice is not None:
        wanted = [choice.lower()]
    else:
        wanted = [animation for animation in names if sheet in animation]
    for animation in wanted:
        if (animation, direction) in animations:
            return animations[(animation, direction)]
    raise Problem("falta o %s %s: animações no zip: %s" % (sheet, direction, ", ".join(names) or "nenhuma"))


def read_frames(archive, names):
    frames = []
    for name in names:
        width, height, rows = read_png_bytes(archive.read(name))
        if width != height:
            raise Problem("%s não é quadrado (%d × %d)" % (name, width, height))
        frames.append((width, rows))
    return frames


def padded(size, rows, cell):
    """O quadro no meio de uma célula maior: o PixelLab aumenta o canvas pelas bordas."""
    margin = (cell - size) // 2
    empty = bytes(cell * 4)
    out = [empty] * margin
    for row in rows:
        out.append(bytes(margin * 4) + row + bytes((cell - size - margin) * 4))
    out += [empty] * (cell - size - margin)
    return out


def feet_line(cell_rows):
    """A última linha com algum pixel, em todos os quadros: onde os pés pisam."""
    bottom = 0
    for rows in cell_rows:
        for y, row in enumerate(rows):
            if any(row[x] for x in range(3, len(row), 4)):
                bottom = max(bottom, y)
    return bottom


def sheet_rows(lines, cell, columns):
    """As linhas de pixels da folha: uma linha da folha por vista, um quadro por coluna."""
    out = []
    for frames in lines:
        for y in range(cell):
            row = b"".join(frame[y] for frame in frames)
            out.append(row + bytes((columns - len(frames)) * cell * 4))
    return out


def build(slug):
    source = ROOT / "art-source" / slug
    archive_path = source / "pixellab.zip"
    if not archive_path.exists():
        raise Problem("falta %s" % archive_path.relative_to(ROOT))
    overrides_path = source / "battle.json"
    overrides = json.loads(overrides_path.read_text(encoding="utf-8")) if overrides_path.exists() else {}
    archive = zipfile.ZipFile(archive_path)
    animations, rotations = load_sources(archive)

    directions_of = dict(SHEETS)
    for sheet, extra in EXTRA.items():
        present = []
        for direction in extra:
            try:
                pick(sheet, direction, animations, rotations, overrides)
                present.append(direction)
            except Problem:
                pass
        if len(present) == len(extra):
            directions_of[sheet] = SHEETS[sheet] + extra
        elif present:
            missing = [d for d in extra if d not in present]
            raise Problem("o %s precisa de %s juntas; falta %s" % (sheet, ", ".join(extra), ", ".join(missing)))

    chosen = {}
    for sheet, directions in directions_of.items():
        chosen[sheet] = [read_frames(archive, pick(sheet, d, animations, rotations, overrides)) for d in directions]
    cell = max(size for lines in chosen.values() for frames in lines for size, _ in frames)
    cells = {
        sheet: [[padded(size, rows, cell) for size, rows in frames] for frames in lines]
        for sheet, lines in chosen.items()
    }
    feet = feet_line(frame for lines in cells.values() for frames in lines for frame in frames)

    out = ROOT / "client/assets/creatures" / slug / "battle"
    out.mkdir(parents=True, exist_ok=True)
    meta = {"cell": cell, "feet": feet}
    # Um quadro vazio confundiria o jogo, que conta os quadros pelas células preenchidas.
    for sheet, lines in cells.items():
        for direction, frames in zip(directions_of[sheet], lines):
            if any(not any(row[x] for row in frame for x in range(3, len(row), 4)) for frame in frames):
                raise Problem("o %s %s tem um quadro vazio" % (sheet, direction))
    for sheet, lines in cells.items():
        columns = max(len(frames) for frames in lines)
        write_png(out / (sheet + ".png"), cell * columns, cell * len(lines), sheet_rows(lines, cell, columns))
        meta[sheet] = dict(zip(directions_of[sheet], (len(frames) for frames in lines)))
    return out, meta


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    try:
        out, meta = build(sys.argv[1])
    except Problem as problem:
        print("FALHA:", problem)
        sys.exit(1)
    print("folhas em", out)
    print(json.dumps(meta))


if __name__ == "__main__":
    main()
