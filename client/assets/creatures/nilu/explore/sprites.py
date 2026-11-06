"""Nilu: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,30 m, ela tem 4 pixels de altura, e sobram só a concha azul, a ponta clara, os
olhos e as pinças. O corpo não sobe nem desce: quem se mexe é a ponta, que brilha, e as
patas, que correm para os lados, como as de um caranguejo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig  # noqa: E402

PALETTE = {
    "E": (20, 30, 70),     # olho
    "B": (44, 120, 224),   # concha
    "D": (28, 72, 168),    # concha na sombra e patas
    "L": (120, 212, 255),  # ponta e pinças
    "W": (220, 246, 255),  # brilho da ponta
    "C": (248, 240, 224),  # rosto
}

HEAD_FRONT = [
    ".BBBBB.",
    "LBECEBL",
    "L.....L",
]
HEAD_LOWER = [
    ".BBBBB.",
    "LBBECEL",
    "L.....L",
]
HEAD_SIDE = [
    ".BBBB..",
    "DBBBECL",
    "......L",
]
HEADS = {
    "front": (HEAD_FRONT, 13, 29),
    "lower": (HEAD_LOWER, 13, 29),
    "side": (HEAD_SIDE, 13, 29),
    "upper": (recolored(HEAD_LOWER, "EC", "DB"), 13, 29),
    "back": (recolored(HEAD_FRONT, "EC", "DD"), 13, 29),
}
LEG = ["D"]
LEGS = {
    "front": [(15, 0, LEG, 1), (17, 3, LEG, 1)],
    "lower": [(15, 0, LEG, 1), (17, 3, LEG, 1)],
    "side": [(14, 0, LEG, 1), (16, 3, LEG, 1)],
    "upper": [(15, 0, LEG, 1), (17, 3, LEG, 1)],
    "back": [(15, 0, LEG, 1), (17, 3, LEG, 1)],
}
TIP_AT = {"front": (16, 28), "lower": (16, 28), "side": (15, 28), "upper": (16, 28), "back": (16, 28)}
TRAITS = [{"frames": [["L"], ["W"], ["L"], ["B"]], "at": TIP_AT}]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, LEGS, 31, TRAITS, idle_head=(0, 0, 0, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 0, 0, 0, 0, 0), walk_body=(0, 0, 0, 0, 0, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 0, 0)),
    )
