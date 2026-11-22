"""Fuzzap: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,25 m, ele tem 8 pixels de altura pela regra do mapa (creature-scale): 6 de desenho e
o contorno índigo por fora. É uma bola de pelo branco de pontas lavanda, espetada em cima,
com os olhos azuis grandes, as patinhas curtas e a cauda fofa atrás. O raio amarelo do pelo
pisca e troca de lugar a cada quadro; o corpo não sobe nem desce.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig  # noqa: E402

PALETTE = {
    "o": (58, 60, 130),    # contorno
    "W": (246, 247, 255),  # pelo
    "L": (180, 182, 238),  # ponta lavanda
    "l": (126, 128, 206),  # lavanda na sombra
    "e": (36, 92, 210),    # olho
    "Y": (255, 214, 80),   # raio
}
OUTLINE = {"*": "o"}

TOP = 25
FRONT = [
    "L.WLW.L",
    "LWWWWWL",
    "WeWWWeW",
    "lWWWWWl",
]
LOWER = [
    "L.WL.W.",
    "LWWWWWL",
    "WWeWWeW",
    "lWWWWWl",
]
SIDE = [
    "LW.WL",
    "WWWWWL",
    "WWWWeW",
    "lWWWWW",
]
BACK = [
    "L.WLW.L",
    "LWLWLWL",
    "WLWWWLW",
    "lWWLWWl",
]
HEADS = {
    "front": (FRONT, 13, TOP),
    "lower": (LOWER, 13, TOP),
    "side": (SIDE, 14, TOP),
    "upper": (recolored(LOWER, "e", "W"), 13, TOP),
    "back": (BACK, 13, TOP),
}
BODIES = {
    "front": (["lLWWWLl"], 13, 29),
    "lower": (["lLWWWLl"], 13, 29),
    "side": (["lLWWWWl"], 13, 29),
    "upper": (["lLWWWLl"], 13, 29),
    "back": (["lLWWWLl"], 13, 29),
}
LEG = ["l"]
LEGS = {
    "front": [(14, 0, LEG, 0), (18, 3, LEG, 0)],
    "back": [(14, 0, LEG, 0), (18, 3, LEG, 0)],
    "side": [(14, 3, LEG, 1), (18, 0, LEG, 1), (15, 0, LEG, 1), (19, 3, LEG, 1)],
    "lower": [(14, 3, LEG, 1), (15, 0, LEG, 1), (18, 3, LEG, 1)],
    "upper": [(14, 3, LEG, 1), (15, 0, LEG, 1), (18, 3, LEG, 1)],
}
TAIL = [["LW", "WL"], ["WL", "LW"], ["LW", "WL"], ["WL", "LW"]]
TAIL_AT = {"front": (19, 27), "lower": (11, 27), "side": (12, 27), "upper": (11, 27), "back": (15, 29)}
BOLT = [["Y.", ".Y"], ["..", ".."], [".Y", "Y."], ["Y.", "Y."]]
BOLT_AT = {"front": (18, 25), "lower": (17, 25), "side": (15, 25), "upper": (17, 25), "back": (14, 25)}
TRAITS = [
    {"frames": TAIL, "at": TAIL_AT, "behind": ("front", "lower", "side", "upper")},
    {"frames": BOLT, "at": BOLT_AT, "walk": (0, 2, 3, 0, 2, 3)},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, BODIES, LEGS, 30, TRAITS, idle_head=(0, 0, 0, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 0, 0, 0, 0, 0), walk_body=(0, 0, 0, 0, 0, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 0, 0)),
        outline=OUTLINE,
    )
