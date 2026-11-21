"""Sandlurk: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,40 m, ele tem 10 pixels de altura pela regra do mapa (creature-scale): 8 de desenho e
o contorno marrom por fora. Cabem o corpo achatado e largo de areia com as faixas
marrom-queimado, os olhos amarelos, as pinças grossas na frente, a cauda curta enrolada para
cima e o ferrão com a gota de veneno amarela. No idle, a cauda balança e a gota pisca; no
walk, as patas andam em lados alternados e a cauda balança.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build  # noqa: E402

PALETTE = {
    "o": (62, 34, 18),     # contorno
    "S": (232, 196, 136),  # areia na luz
    "B": (198, 140, 78),   # carapaça ocre
    "D": (128, 74, 40),    # faixa marrom-queimado
    "d": (92, 54, 30),     # sombra
    "E": (255, 206, 40),   # olho
    "Y": (244, 170, 18),   # veneno
    "W": (255, 232, 120),  # brilho do veneno
}
OUTLINE = {"*": "o"}

# O ferrão balança: cada quadro troca as linhas 0 a 2 (a cauda curvada e a gota).
SIDE_TAILS = [
    [".BDBD...........", "D....DY.........", "B......W........"],
    [".BDBD...........", "D....DY.........", "B..............."],
    [".BDBDB..........", "D.....DY........", "B.......W......."],
    [".BDBD...........", "D....DY.........", "B......W........"],
]
SIDE_BODY = [
    "D...SSSBE.......",
    ".DBDBDBSSB..SS..",
    ".dBDBDBSSSBSBBS.",
    "..ddddddddd.d.d.",
]
SIDE_LEGS = ["..d.d.d.d.d.....", "...d.d.d.d.d...."]

FRONT_TAILS = [
    ["......D......", ".....DYD.....", "......B......"],
    ["......D......", ".....DWD.....", "......B......"],
    [".......D.....", "......DYD....", "......B......"],
    ["......D......", ".....DYD.....", "......B......"],
]
FRONT_BODY = [
    "...SBDBDBS...",
    "SS.BESSSEB.SS",
    "BSBSBSSSBSBSB",
    "dDd.ddddd.dDd",
]
FRONT_LEGS = [".d.d.d.d.d.d.", "d.d.d...d.d.d"]
BACK_BODY = [
    "...BDBDBDB...",
    "SS.BDBDBDB.SS",
    "BSBSBDBDBSBSB",
    "dDd.ddddd.dDd",
]

VIEWS_ART = {
    "front": (FRONT_TAILS, FRONT_BODY, FRONT_LEGS, 10),
    "lower": (SIDE_TAILS, SIDE_BODY, SIDE_LEGS, 8),
    "side": (SIDE_TAILS, SIDE_BODY, SIDE_LEGS, 8),
    "upper": (SIDE_TAILS, [row.replace("E", "S") for row in SIDE_BODY], SIDE_LEGS, 8),
    "back": (FRONT_TAILS, BACK_BODY, FRONT_LEGS, 10),
}
TOP = 23
WALK_TAIL = (0, 1, 2, 3, 2, 1)
WALK_LEGS = (0, 0, 0, 1, 1, 1)


def drawing(view, tail, legs):
    tails, body, leg_rows, _left = VIEWS_ART[view]
    rows = tails[tail] + body + [leg_rows[legs]]
    if view == "lower":
        # Na diagonal descendo, os dois olhos aparecem.
        rows[3] = rows[3][:6] + "E" + rows[3][7:]
    return rows


def draw_idle(canvas, view, frame):
    canvas.stamp(drawing(view, frame, 0), VIEWS_ART[view][3], TOP)


def draw_walk(canvas, view, frame):
    canvas.stamp(drawing(view, WALK_TAIL[frame], WALK_LEGS[frame]), VIEWS_ART[view][3], TOP)


if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, {"idle": draw_idle, "walk": draw_walk}, outline=OUTLINE)
