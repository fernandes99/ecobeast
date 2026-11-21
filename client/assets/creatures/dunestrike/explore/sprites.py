"""Dunestrike: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,10 m, ele tem 20 pixels de altura pela regra do mapa (creature-scale): 18 de desenho e
o contorno marrom por fora. É o escorpião adulto, comprido e blindado: as placas de areia com
as faixas marrom-queimado e os espinhos, os olhos amarelos frios, as pinças grandes e
serrilhadas e a cauda alta em arco, com o ferrão amarelo pingando. No idle, o corpo respira e
a gota cresce e cai; no walk, as patas andam em grupos alternados e o corpo balança.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build  # noqa: E402

PALETTE = {
    "o": (58, 30, 16),     # contorno
    "S": (230, 190, 128),  # areia na luz
    "B": (194, 134, 72),   # carapaça ocre
    "D": (124, 70, 38),    # faixa marrom-queimado
    "d": (86, 48, 26),     # sombra
    "E": (255, 206, 40),   # olho
    "Y": (244, 170, 18),   # veneno
    "y": (196, 118, 10),   # veneno na sombra
    "W": (255, 236, 130),  # brilho do veneno
}
OUTLINE = {"*": "o"}

SIDE = [
    "....DBDBDB..................",
    "...BD....DBD................",
    "..DB.......BD...............",
    "..B.........DY..............",
    ".DB.........YW..............",
    ".BD.........YYy.............",
    ".DB.........................",
    ".BD.........................",
    "..DB....S..S..S......BSS....",
    "..BDBSBDBSBDBSBDS...BSSSSS..",
    "...DBSBDBSBDBSBSSBE.BSB..SSS",
    "...dBSBDBSBDBSBSSSSBSB......",
    "....dBDdBDdBDdBSSSBDBSB..BSS",
    ".....ddddddddddddddd.dBBBdd.",
    "......d..d..d..d..d....dd...",
]
SIDE_LEGS = [
    [".....d...d...d...d.........", "....d...d...d...d..........", "...d...d...d...d..........."],
    [".....d...d...d...d.........", ".....d...d...d...d.........", "......d...d...d...d........"],
]

FRONT = [
    "............DB............",
    "...........DBBD...........",
    "...........BYYB...........",
    "............YW............",
    "............y.............",
    "............DB............",
    "............BD............",
    "............DB............",
    "..SS.......SBDS.......SS..",
    ".SBBS....SBDBBDBS....SBBS.",
    "SBSSBS.SBSESBBSESBS.SBSSBS",
    "BS..SBBSBSBSSSSBSBSBBS..SB",
    "BSB.dBdBDBDBSSBDBDBdBd.BSB",
    ".dSBd..dddddddddddd..dBSd.",
    "..dd..d..d......d..d..dd..",
]
FRONT_LEGS = [
    [".....d..d.......d..d.....", "....d..d.........d..d....", "...d..d...........d..d..."],
    [".....d..d.......d..d.....", ".....d..d.......d..d.....", "....d..d.........d..d...."],
]
BACK = [row.replace("E", "B") for row in FRONT[:8]] + [
    "..SS.......SBDS.......SS..",
    ".SBBS....SBDBBDBS....SBBS.",
    "SBSSBS.SBDBDBDBDBS..SBSSBS",
    "BS..SBBSBDBDBDBDBSBBS..SB.",
    "BSB.dBdBDBDBDBDBDBdBd.BSB.",
    ".dSBd..dddddddddddd..dBSd.",
    "..dd..d..d......d..d..dd..",
]

VIEWS_ART = {
    "front": (FRONT, FRONT_LEGS, 3),
    "lower": ([row[:17] + ("E" if i == 10 else row[17]) + row[18:] for i, row in enumerate(SIDE)], SIDE_LEGS, 2),
    "side": (SIDE, SIDE_LEGS, 2),
    "upper": ([row.replace("E", "S") for row in SIDE], SIDE_LEGS, 2),
    "back": (BACK, FRONT_LEGS, 3),
}
TOP = 13
# A gota do ferrão: cheia, pingando, caindo e de volta.
DROPS = ("y", "W", ".", "y")
IDLE_BODY = (0, 0, 1, 0)
WALK_BODY = (0, 1, 0, 0, 1, 0)
WALK_LEGS = (0, 0, 0, 1, 1, 1)


def drawing(view, drop):
    rows, _legs, _left = VIEWS_ART[view]
    rows = list(rows)
    if view in ("front", "back"):
        rows[4] = rows[4].replace("y", drop)
    else:
        rows[5] = rows[5][:14] + drop + rows[5][15:]
    return rows


def stamp(canvas, view, body, legs, drop):
    rows = drawing(view, drop)
    _art, leg_frames, left = VIEWS_ART[view]
    canvas.stamp(leg_frames[legs], left, TOP + len(rows))
    canvas.stamp(rows, left, TOP + body)


def draw_idle(canvas, view, frame):
    stamp(canvas, view, IDLE_BODY[frame], 0, DROPS[frame])


def draw_walk(canvas, view, frame):
    stamp(canvas, view, WALK_BODY[frame], WALK_LEGS[frame], DROPS[frame % 4])


if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, {"idle": draw_idle, "walk": draw_walk}, outline=OUTLINE)
