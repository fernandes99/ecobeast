"""Blizzvolt: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,90 m, ele tem 17 pixels de altura pela regra do mapa (creature-scale): 15 de desenho
e o contorno índigo por fora. É esguio e de pernas longas: a juba branca com as mechas azuis,
lilás e verde-água, a orelha de cristal e a orelha do raio, o olho azul sério embaixo da
sobrancelha e a cauda grossa enrolada para cima, com a ponta de cristal. A cauda balança, e
os raios do pelo piscam e trocam de lugar.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, swayed  # noqa: E402

PALETTE = {
    "o": (48, 52, 122),    # contorno
    "W": (246, 247, 255),  # pelo
    "w": (204, 210, 242),  # pelo na sombra
    "B": (112, 142, 232),  # mecha azul
    "b": (74, 92, 192),    # azul na sombra
    "L": (172, 150, 232),  # mecha lilás
    "T": (112, 220, 212),  # mecha verde-água
    "C": (196, 238, 255),  # cristal
    "c": (122, 192, 242),  # cristal na sombra
    "e": (40, 112, 222),   # olho
    "k": (52, 56, 118),    # sobrancelha e nariz
    "Y": (255, 210, 80),   # raio
}
OUTLINE = {"*": "o"}

TOP = 16
SIDE_HEAD = [
    "..C..Y..",
    ".cCBYY..",
    "BLWWWkk.",
    "BWWWWeW.",
    "TwWWWWWk",
    "BTWWWWw.",
    ".TBwWw..",
]
FRONT_HEAD = [
    ".C.....Y.",
    "BCB.L.BYB",
    "BWWWWWWWB",
    "WkeWWWekW",
    "TWWWkWWWT",
    "BTWWWWWTB",
    ".TBWWWBT.",
]
BACK_HEAD = recolored(FRONT_HEAD, "ek", "WW")
HEADS = {
    "front": (FRONT_HEAD, 12, TOP),
    "lower": (SIDE_HEAD, 18, TOP),
    "side": (SIDE_HEAD, 18, TOP),
    "upper": (recolored(SIDE_HEAD, "ek", "WW"), 18, TOP),
    "back": (BACK_HEAD, 12, TOP),
}
SIDE_BODY = [
    "B.L.B.T.....",
    "BWWBWWTWWWW.",
    "bBWWLWWBWWWw",
    "bbBWWWBWWWww",
    ".bbwwwwwww..",
]
FRONT_BODY = [
    "WWWWWWW",
    "wWWWWWw",
    "bwWWWwb",
    ".bwwwb.",
]
BACK_BODY = [
    "BWWLWWB",
    "bBWWWBb",
    "bbwWwbb",
    ".bwwwb.",
]
BODIES = {
    "front": (FRONT_BODY, 13, 23),
    "lower": (SIDE_BODY, 9, 21),
    "side": (SIDE_BODY, 9, 21),
    "upper": (SIDE_BODY, 9, 21),
    "back": (BACK_BODY, 13, 23),
}
LEGS_Y = 26
NEAR = ["WW", "WW", "wW", "wW", "WW"]
FAR = ["b", "b", "b", "b", "w"]
LEGS = {
    "front": [(14, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(14, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(11, 3, FAR, 1), (18, 0, FAR, 1), (10, 0, NEAR, 1), (17, 3, NEAR, 1)],
    "lower": [(11, 3, FAR, 1), (18, 0, FAR, 1), (10, 0, NEAR, 1), (17, 3, NEAR, 1)],
    "upper": [(11, 3, FAR, 1), (18, 0, FAR, 1), (10, 0, NEAR, 1), (17, 3, NEAR, 1)],
}
TAIL = swayed([
    "..cC.",
    ".cCCB",
    "BLBCb",
    "LBY.B",
    "BLB.B",
    ".BLB.",
    "..bBL",
])
TAIL_AT = {"front": (18, 19), "lower": (5, 16), "side": (5, 16), "upper": (5, 16), "back": (13, 16)}
BOLTS = [["Y..."], ["...Y"], [".Y.."], ["...."]]
BOLTS_AT = {"lower": (13, 23), "side": (13, 23), "upper": (13, 23), "back": (14, 24)}
TRAITS = [
    {"frames": TAIL, "at": TAIL_AT, "behind": ("front", "lower", "side", "upper")},
    {"frames": BOLTS, "at": BOLTS_AT, "walk": (0, 1, 2, 3, 0, 1)},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, BODIES, LEGS, LEGS_Y, TRAITS, idle_head=(0, 0, 1, 0), idle_body=(0, 0, 0, 0), walk_head=(1, 0, 0, 1, 0, 0), walk_body=(0, 0, 0, 0, 0, 0), foot_reach=(2, 1, -1, -2, -1, 1), foot_lift=(0, 0, 0, 0, 1, 1)),
        outline=OUTLINE,
    )
