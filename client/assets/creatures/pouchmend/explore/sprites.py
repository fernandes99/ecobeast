"""Pouchmend: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,60 m, ela tem 28 pixels de altura pela regra do mapa (creature-scale): 26 de desenho e
o contorno marrom por fora. É a canguru médica, alta e magra: as orelhas compridas de miolo
rosado, a atadura creme na testa com as pontas soltas, os olhos amarelos cansados, a bolsa
de pano com as folhas e o filhote espiando, as ervas na cintura, as patas traseiras longas e
a cauda comprida no chão. No idle, as pontas da atadura balançam e o filhote se mexe; no walk,
ela se abaixa e estica nos pulos, com a cauda de apoio.
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
    "g": (66, 104, 44),    # erva na sombra
    "S": (226, 216, 190),  # bolsa de pano
    "s": (184, 170, 140),  # bolsa na sombra
}
OUTLINE = {"*": "o"}

SIDE = [
    "..........FR..........",
    ".........FRR..........",
    ".........FRRF.........",
    ".........FRRF.FR......",
    "..........FRFFRR......",
    "..........FRFFRF......",
    ".......aaAAAAAAF......",
    "......aa.AAAAAFF......",
    "......a..FffFFFFF.....",
    ".........FFYFFFFFP....",
    "..........FFFFCCF.....",
    "...........FCCC.......",
    "..........FFCCCF.FR...",
    ".........FFFCCSSFRF...",
    ".........FFfCSSSFYFF..",
    "........FFfPSSSSSFFG..",
    "........FffPSSGSSss...",
    "......GGFffFSSSSSss...",
    ".....GGgFfffsSGSSs....",
    "....ff..ffffFssss.....",
    "...ff...fffffFFF......",
    "..ff.....ffPPfFF......",
    ".ff.......fPP.fFF.....",
    "ff........PP...PP.....",
    "f........PPPP..PPPP...",
    ".........PPPPP.PPPPP..",
]
FRONT = [
    "....RF......FR....",
    "....RF......FR....",
    "....RFF....FFR....",
    ".....RF....FR.....",
    ".....FF....FF.....",
    ".....FFFFFFFF.....",
    ".aaAAAAAAAAAAA....",
    "aa..AAAAAAAAAA....",
    ".....FfFFFFfF.....",
    ".....FYFFFFYF.....",
    "......FFFPFF......",
    ".......FCCF.......",
    "......FFCCFFFR.R..",
    ".....FFCCCCFRFRF..",
    "....FPSSSSSFYFYF..",
    "...FPSSSSSSSFFFGG.",
    "...FFSSGSSSSSSs.G.",
    "..GGFSSSSSSGSSs...",
    "..GgFsSSSSSSSss...",
    "....FfsssssssF....",
    "....FFf.....fFF...",
    "....FFf.....fFF...",
    "....fPP.....PPf...",
    "....PP.......PP...",
    "...PPP.......PPP..",
    "..PPPP.......PPPP.",
]
BACK = [
    "....FF......FF....",
    "....FF......FF....",
    "....FFF....FFF....",
    ".....FF....FF.....",
    ".....FF....FF.....",
    ".....FFFFFFFF.....",
    "....AAAAAAAAAAAa..",
    "....AAAAAAAAAA.aa.",
    ".....FFFFFFFF.....",
    ".....FFFFFFFF.....",
    "......FFFFFF......",
    ".......FFFF.......",
    "......FFFFFFs.....",
    ".....FFFFFFsS.....",
    "....FFFFFFFFsS....",
    "...FFFFFFFFFFs....",
    "...FFFFFFFFFFF....",
    "..GGFFFFFFFFFF....",
    "..GgFFFFFFFFFF....",
    "....FfffFFfffF....",
    "....FFf.FF..fFF...",
    "....FFf.FF..fFF...",
    "....fPP.FF..PPf...",
    "....PP..FF...PP...",
    "...PPP..FFF..PPP..",
    "..PPPP...FF..PPPP.",
]
UPPER = [row.replace("Y", "F") for row in SIDE]
VIEWS_ART = {"front": (FRONT, 7), "lower": (SIDE, 5), "side": (SIDE, 5), "upper": (UPPER, 5), "back": (BACK, 7)}
TOP = 5


def posed(view, flutter, joey, crouch):
    rows = list(VIEWS_ART[view][0])
    if flutter:
        # A ponta solta da atadura sobe e encurta.
        if view == "back":
            rows[7] = rows[7].replace("aa", "a.")
        elif view == "front":
            rows[7] = rows[7].replace("aa", ".a", 1)
        else:
            rows[8] = rows[8].replace("a", ".")
    if joey and view in ("side", "lower", "front"):
        # O filhote abaixa as orelhas.
        rows[12] = rows[12].replace("R", "F")
    if crouch:
        # Abaixada para o pulo: a linha do pescoço some.
        rows = rows[:11] + rows[12:]
    return rows


def stamp(canvas, view, flutter, joey, crouch):
    rows = posed(view, flutter, joey, crouch)
    canvas.stamp(rows, VIEWS_ART[view][1], TOP + 26 - len(rows))


def draw_idle(canvas, view, frame):
    stamp(canvas, view, frame in (1, 2), frame == 2, False)


def draw_walk(canvas, view, frame):
    stamp(canvas, view, frame in (1, 2, 4, 5), frame in (2, 5), frame in (0, 3))


if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, {"idle": draw_idle, "walk": draw_walk}, outline=OUTLINE)
