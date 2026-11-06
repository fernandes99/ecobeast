"""Elu: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,40 m, ele tem 6 pixels de altura. As orelhas compridas e a cauda de folhas são o
que precisa sobreviver. A cabeça não desce, porque cobriria os pés, que têm um pixel: quem
se mexe é a cauda, o broto entre as orelhas e as patas.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig  # noqa: E402

PALETTE = {
    "E": (24, 56, 24),     # olho
    "G": (128, 196, 60),   # verde
    "D": (72, 148, 44),    # verde na sombra
    "Y": (196, 232, 112),  # verde claro
    "C": (252, 240, 196),  # creme
    "P": (232, 160, 140),  # orelha e focinho
    "T": (52, 120, 44),    # pata
}

HEAD_FRONT = [
    ".G...G.",
    ".GP.PG.",
    "GGYYYGG",
    "GECCCEG",
    ".CCPCC.",
]
HEAD_LOWER = [
    "G...G.",
    "GP.PG.",
    "GYYYGG",
    "GECCEG",
    "CCCPC.",
]
HEAD_SIDE = [
    "G.G...",
    "GPGP..",
    "GGGGG.",
    "GGGEC.",
    "GGCCCP",
]
HEADS = {
    "front": (HEAD_FRONT, 13, 26),
    "lower": (HEAD_LOWER, 15, 26),
    "side": (HEAD_SIDE, 14, 26),
    "upper": (recolored(HEAD_LOWER, "ECP", "GGD"), 15, 26),
    "back": (recolored(HEAD_FRONT, "ECP", "GGD"), 13, 26),
}
BODY_LOWER = [
    "GGG",
    "GYGG",
]
BODY_SIDE = [
    "GYYGG",
    "GGGGC",
]
BODIES = {
    "lower": (BODY_LOWER, 12, 29),
    "side": (BODY_SIDE, 11, 29),
    "upper": (BODY_LOWER, 12, 29),
}
FOOT = ["T"]
FAR = ["D"]
LEGS = {
    "front": [(14, 0, FOOT, 0), (18, 3, FOOT, 0)],
    "back": [(14, 0, FOOT, 0), (18, 3, FOOT, 0)],
    "side": [(13, 3, FAR, 1), (16, 0, FAR, 1), (11, 0, FOOT, 1), (18, 3, FOOT, 1)],
    "lower": [(15, 3, FAR, 1), (12, 0, FOOT, 1), (18, 3, FOOT, 1)],
    "upper": [(15, 3, FAR, 1), (12, 0, FOOT, 1), (18, 3, FOOT, 1)],
}
TAIL = [
    [
        ".G.",
        "GYG",
        "DG.",
    ],
    [
        "G..",
        "GYG",
        "DG.",
    ],
    [
        ".G.",
        "GYG",
        ".GD",
    ],
    [
        "..G",
        "GYG",
        ".GD",
    ],
]
TAIL_AT = {"front": (19, 27), "lower": (9, 27), "side": (8, 27), "upper": (10, 28), "back": (15, 28)}
SPROUT_AT = {"front": (16, 27), "lower": (17, 27), "side": (15, 26), "upper": (17, 27), "back": (16, 27)}
TRAITS = [
    {"frames": [["Y"], ["G"], ["Y"], ["D"]], "at": SPROUT_AT, "follows": "head", "walk": (0, 1, 2, 3, 0, 1)},
    # De trás, a cauda fica na frente de tudo; nos outros ângulos, atrás do corpo.
    {"frames": TAIL, "at": TAIL_AT, "behind": ("front", "lower", "side")},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, BODIES, LEGS, 31, TRAITS, idle_head=(0, 0, 0, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 0, 0, 0, 0, 0), walk_body=(0, 0, 0, 0, 0, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 0, 0)),
    )
