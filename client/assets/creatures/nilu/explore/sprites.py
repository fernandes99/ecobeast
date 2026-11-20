"""Nilu: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,30 m, ela tem 8 pixels de altura pela regra do mapa (creature-scale): 6 de desenho e
o contorno azul-marinho por fora. Cabem a concha azul com a ponta clara, o rosto creme com
os olhos e a boca, as pinças dos lados e as patinhas. O corpo não sobe nem desce: quem se
mexe é a ponta, que brilha, e as patas, que correm para os lados, como as de um caranguejo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig  # noqa: E402

PALETTE = {
    "o": (22, 40, 98),     # contorno
    "B": (44, 120, 224),   # concha
    "D": (28, 76, 172),    # concha na sombra e patas
    "L": (120, 212, 255),  # ponta e pinças
    "W": (226, 248, 255),  # brilho da ponta
    "C": (248, 240, 224),  # rosto
    "c": (206, 196, 184),  # rosto na sombra
    "e": (20, 30, 70),     # olho
    "m": (226, 104, 120),  # boca
}
OUTLINE = {"*": "o"}

TOP = 25
FRONT = [
    "....BLB....",
    "..BBBBBBB..",
    ".LDDDDDDDL.",
    "LL.CeCeC.LL",
    "LL.cCmCc.LL",
]
LOWER = [
    "....BLB....",
    "..BBBBBBB..",
    ".LBDDDDDDL.",
    "LL.BCeCeCLL",
    ".L.DcCmCcLL",
]
SIDE = [
    "...BLB...",
    ".BBBBBBB.",
    "BBDDDDDDL",
    "DDDDCeC.L",
    ".DDDcmC.L",
]
BACK = [
    "....BLB....",
    "..BBBBBBB..",
    ".LBBBBBBBL.",
    "LL.DDDDD.LL",
    "LL.DDDDD.LL",
]
HEADS = {
    "front": (FRONT, 11, TOP),
    "lower": (LOWER, 11, TOP),
    "side": (SIDE, 12, TOP),
    "upper": (recolored(LOWER, "Cecm", "DDDD"), 11, TOP),
    "back": (BACK, 11, TOP),
}
LEG = ["D"]
LEGS = {
    "front": [(13, 0, LEG, 1), (15, 3, LEG, 1), (17, 0, LEG, 1), (19, 3, LEG, 1)],
    "lower": [(13, 0, LEG, 1), (15, 3, LEG, 1), (17, 0, LEG, 1), (19, 3, LEG, 1)],
    "side": [(13, 0, LEG, 1), (15, 3, LEG, 1), (17, 0, LEG, 1)],
    "upper": [(13, 0, LEG, 1), (15, 3, LEG, 1), (17, 0, LEG, 1), (19, 3, LEG, 1)],
    "back": [(13, 0, LEG, 1), (15, 3, LEG, 1), (17, 0, LEG, 1), (19, 3, LEG, 1)],
}
TIP_AT = {"front": (16, TOP), "lower": (16, TOP), "side": (16, TOP), "upper": (16, TOP), "back": (16, TOP)}
TRAITS = [{"frames": [["L"], ["W"], ["W"], ["B"]], "at": TIP_AT}]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, LEGS, 30, TRAITS, idle_head=(0, 0, 0, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 0, 0, 0, 0, 0), walk_body=(0, 0, 0, 0, 0, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 0, 0)),
        outline=OUTLINE,
    )
