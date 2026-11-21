"""Hopling: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,60 m, ele tem 13 pixels de altura pela regra do mapa (creature-scale): 11 de desenho e
o contorno marrom por fora. Cabem as orelhas compridas de miolo rosado, a atadura creme na
testa com a ponta solta, os olhos amarelos meio fechados, a barriga creme, as patas
traseiras grandes, a cauda no chão e o maço de ervas na pata. No idle, uma orelha mexe e a
ponta da atadura balança; no walk, ele se abaixa e estica nos pulinhos.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build  # noqa: E402

PALETTE = {
    "o": (74, 38, 22),     # contorno
    "F": (226, 140, 70),   # pelo laranja
    "f": (184, 100, 50),   # pelo na sombra
    "C": (242, 224, 190),  # barriga creme
    "P": (134, 72, 44),    # pata marrom
    "R": (232, 150, 140),  # miolo da orelha
    "A": (238, 228, 204),  # atadura
    "a": (196, 182, 150),  # atadura na sombra
    "Y": (244, 200, 40),   # olho
    "G": (104, 150, 62),   # erva
}
OUTLINE = {"*": "o"}

SIDE = [
    "....FR.....",
    "...FRFR....",
    "..aAAAAF...",
    "...FFYFFF..",
    "....FFCFP..",
    "....FCCPG..",
    "...fFCCFGG.",
    "..ffFCCF...",
    ".ffffFFf...",
    "ff..fPPf...",
    "f...PPPPP..",
]
FRONT = [
    ".RF...FR.",
    ".RF...FR.",
    "aAAAAAAA.",
    ".FYFFFYF.",
    "..FFPFF..",
    "..FCCCFG.",
    ".PFCCCPGG",
    "..FCCCF..",
    "..fFCFf..",
    "..fF.Ff..",
    ".PPP.PPP.",
]
BACK = [
    ".FF...FF.",
    ".FF...FF.",
    ".AAAAAAAa",
    ".FFFFFFF.",
    "..FFFFF..",
    "..FFFFF..",
    ".PFFFFFP.",
    "..FFFFF..",
    "..fFFFf..",
    "..fFFFf..",
    ".PPPFPPP.",
]
UPPER = [row.replace("Y", "F") for row in SIDE]
LOWER = [row[:4] + ("Y" if i == 3 else row[4]) + row[5:] for i, row in enumerate(SIDE)]
VIEWS_ART = {"front": (FRONT, 12), "lower": (LOWER, 11), "side": (SIDE, 11), "upper": (UPPER, 11), "back": (BACK, 12)}
TOP = 20


def posed(view, ear, crouch):
    rows = list(VIEWS_ART[view][0])
    if ear:
        # A ponta de uma orelha cai um pixel, e a da atadura sobe.
        rows[0] = rows[0].replace("R", ".", 1) if view in ("side", "lower", "upper") else rows[0][:1] + "." + rows[0][2:]
        rows[2] = ("A" if rows[2][0] == "a" else rows[2][0]) + rows[2][1:]
    if crouch:
        # Abaixado para o pulo: o pescoço some, e o corpo encosta nas patas.
        rows = [rows[0], rows[1], rows[2], rows[3]] + rows[5:]
    return rows


def stamp(canvas, view, ear, crouch):
    rows = posed(view, ear, crouch)
    canvas.stamp(rows, VIEWS_ART[view][1], TOP + 11 - len(rows))


def draw_idle(canvas, view, frame):
    stamp(canvas, view, frame == 2, False)


def draw_walk(canvas, view, frame):
    stamp(canvas, view, frame in (1, 4), frame in (0, 3))


if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, {"idle": draw_idle, "walk": draw_walk}, outline=OUTLINE)
