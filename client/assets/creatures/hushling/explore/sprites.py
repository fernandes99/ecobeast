"""Hushling: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,30 m, ele tem 4 pixels de altura, e sobram só o corpo branco comprido, as orelhas
rosadas, os olhos e os cristais. O corpo não sobe nem desce: quem se mexe são as patas e
os cristais do pelo, que brilham, e a ponta azul da cauda.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig  # noqa: E402

PALETTE = {
    "E": (28, 48, 112),    # olho
    "W": (240, 244, 255),  # pelo
    "S": (192, 208, 240),  # pelo na sombra
    "P": (232, 168, 168),  # orelha e focinho
    "L": (120, 192, 240),  # cristal e cauda
    "C": (208, 240, 255),  # brilho do cristal
    "D": (96, 120, 176),   # patas
}

HEAD_FRONT = [
    ".WP.PW.",
    ".WEWEW.",
    "L.WPW..",
]
HEAD_LOWER = [
    ".....WP.W.",
    "L...WWEWE.",
    "LSWWWWWWP.",
]
HEAD_SIDE = [
    ".......WP..",
    "L..L..WWWEP",
    "LSWWWWWWWW.",
]
HEAD_BACK = [
    ".WS.SW.",
    ".WWWWW.",
    "..SLS..",
]
HEADS = {
    "front": (HEAD_FRONT, 13, 28),
    "lower": (HEAD_LOWER, 12, 28),
    "side": (HEAD_SIDE, 11, 28),
    "upper": (recolored(HEAD_LOWER, "EP", "WS"), 12, 28),
    "back": (HEAD_BACK, 13, 28),
}
LEG = ["D"]
LEGS = {
    "front": [(15, 0, LEG, 1), (17, 3, LEG, 1)],
    "lower": [(14, 0, LEG, 1), (18, 3, LEG, 1)],
    "side": [(14, 0, LEG, 1), (19, 3, LEG, 1)],
    "upper": [(14, 0, LEG, 1), (18, 3, LEG, 1)],
    "back": [(15, 0, LEG, 1), (17, 3, LEG, 1)],
}
CRYSTAL_AT = {"front": (16, 28), "lower": (15, 29), "side": (15, 29), "upper": (15, 29), "back": (16, 28)}
TAIL_TIP_AT = {"front": (13, 30), "lower": (12, 29), "side": (11, 29), "upper": (12, 29), "back": (16, 30)}
TRAITS = [
    {"frames": [["L"], ["C"], ["L"], ["S"]], "at": CRYSTAL_AT},
    {"frames": [["L"], ["L"], ["C"], ["L"]], "at": TAIL_TIP_AT},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, LEGS, 31, TRAITS, idle_head=(0, 0, 0, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 0, 0, 0, 0, 0), walk_body=(0, 0, 0, 0, 0, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 0, 0)),
    )
