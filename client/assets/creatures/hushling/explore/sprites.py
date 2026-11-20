"""Hushling: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,30 m, ele tem 8 pixels de altura pela regra do mapa (creature-scale): 6 de desenho e
o contorno azul-acinzentado por fora. Cabem o corpo branco comprido, as orelhas rosadas,
os olhos azuis, os cristais do pelo e a ponta azul da cauda. O corpo não sobe nem desce:
quem se mexe são as patas, os cristais, que brilham, e a ponta da cauda.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig  # noqa: E402

PALETTE = {
    "o": (70, 84, 132),    # contorno
    "W": (242, 246, 252),  # pelo
    "S": (196, 208, 230),  # pelo na sombra
    "P": (234, 160, 172),  # orelha
    "B": (112, 176, 240),  # cristal
    "b": (178, 220, 252),  # cristal brilhando
    "e": (30, 56, 120),    # olho
    "n": (214, 136, 150),  # focinho
}
OUTLINE = {"*": "o"}

TOP = 25
FRONT = [
    "WP...PW",
    "WWWBWWW",
    "WeWWWeW",
    ".WWnWW.",
]
LOWER = [
    "WP..PW.",
    "WWWBWW.",
    "WWeWWeW",
    ".SWWWnW",
]
SIDE = [
    "PW..",
    "WWWW",
    "WWeWn",
    "SWWW.",
]
BACK = [
    "WP...PW",
    "WWWBWWW",
    "WWWWWWW",
    ".SWWWS.",
]
HEADS = {
    "front": (FRONT, 13, TOP),
    "lower": (LOWER, 14, TOP),
    "side": (SIDE, 17, TOP),
    "upper": (recolored(LOWER, "en", "WW"), 13, TOP),
    "back": (BACK, 13, TOP),
}
BODIES = {
    "front": (["SWWWS"], 14, 29),
    "lower": ([
        "WWWW...",
        "SWWWW..",
    ], 11, 28),
    "side": ([
        "WWWWWWWS",
        "SWWWWWWW",
    ], 10, 28),
    "upper": ([
        "WWWW...",
        "SWWWW..",
    ], 12, 28),
    "back": (["SWWWS"], 14, 29),
}
LEG = ["S"]
LEGS = {
    "front": [(14, 0, LEG, 0), (18, 3, LEG, 0)],
    "back": [(14, 0, LEG, 0), (18, 3, LEG, 0)],
    "side": [(11, 3, LEG, 1), (16, 0, LEG, 1), (12, 0, LEG, 1), (17, 3, LEG, 1)],
    "lower": [(12, 3, LEG, 1), (13, 0, LEG, 1), (17, 3, LEG, 1)],
    "upper": [(13, 3, LEG, 1), (14, 0, LEG, 1), (17, 3, LEG, 1)],
}
TAIL = [["bb", ".B"], ["bB", ".b"], ["Bb", ".b"], ["bb", ".b"]]
TAIL_AT = {"front": (19, 27), "lower": (9, 27), "side": (8, 27), "upper": (10, 27), "back": (15, 29)}
SPARKS = [["B.B"], ["b.B"], ["B.b"], ["b.b"]]
SPARKS_AT = {"lower": (12, 28), "side": (12, 28), "upper": (13, 28)}
TRAITS = [
    {"frames": TAIL, "at": TAIL_AT, "behind": ("front", "lower", "side")},
    {"frames": SPARKS, "at": SPARKS_AT},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, BODIES, LEGS, 30, TRAITS, idle_head=(0, 0, 0, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 0, 0, 0, 0, 0), walk_body=(0, 0, 0, 0, 0, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 0, 0)),
        outline=OUTLINE,
    )
