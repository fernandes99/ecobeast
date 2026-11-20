"""Puffcoo: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,30 m, ela tem 8 pixels de altura pela regra do mapa (creature-scale): 6 de desenho e
o contorno cinza-escuro por fora. Cabem a bolinha cinza com a luz no alto da cabeça, a
barriga clara, os olhos, o bico laranja, as asinhas e os pés. O corpo não sobe nem desce:
quem se mexe são as asinhas, que batem, e os pés, em passinhos curtos de pombo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig  # noqa: E402

PALETTE = {
    "o": (46, 46, 76),     # contorno
    "G": (144, 146, 174),  # penas
    "H": (184, 186, 208),  # penas na luz
    "L": (204, 204, 222),  # barriga
    "D": (100, 102, 134),  # asa e cauda
    "e": (24, 24, 48),     # olho
    "O": (228, 140, 52),   # bico
    "F": (232, 98, 64),    # pés
}
OUTLINE = {"*": "o", "O": "q", "F": "q"}
PALETTE["q"] = (120, 48, 30)

TOP = 25
FRONT = [
    "..GHHHG..",
    ".GHGGGGG.",
    "GGeGOGeGG",
    "GGLLLLLGG",
    ".GGLLLGG.",
]
LOWER = [
    "..GHHHG..",
    ".GGHGGGG.",
    "GGGeGGeOO",
    "GGGLLLLG.",
    ".GGLLLGG.",
]
SIDE = [
    "...GHHG..",
    "..GHGGGG.",
    "DGGGGGeOO",
    "DDGGLLLG.",
    ".DGGLLG..",
]
BACK = [
    "..GHHHG..",
    ".GHGGGGG.",
    "GGGGGGGGG",
    "GGGGDGGGG",
    ".GGDDDGG.",
]
HEADS = {
    "front": (FRONT, 12, TOP),
    "lower": (LOWER, 12, TOP),
    "side": (SIDE, 11, TOP),
    "upper": (recolored(LOWER, "eOL", "GGG"), 12, TOP),
    "back": (BACK, 12, TOP),
}
LEG = ["F"]
LEGS = {
    "front": [(14, 0, LEG, 1), (18, 3, LEG, 1)],
    "lower": [(14, 0, LEG, 1), (17, 3, LEG, 1)],
    "side": [(14, 0, LEG, 1), (16, 3, LEG, 1)],
    "upper": [(14, 0, LEG, 1), (17, 3, LEG, 1)],
    "back": [(14, 0, LEG, 1), (18, 3, LEG, 1)],
}
DOWN = [".", "D"]
UP = ["D", "."]
FLAP = [DOWN, UP, DOWN, DOWN]
FLAP_LATE = [DOWN, DOWN, UP, DOWN]
LEFT_WING_AT = {"front": (11, 27), "lower": (11, 27), "upper": (11, 27), "back": (11, 27)}
RIGHT_WING_AT = {"front": (21, 27), "back": (21, 27)}
SIDE_WING_AT = {"side": (15, 27)}
TRAITS = [
    {"frames": FLAP, "at": LEFT_WING_AT},
    {"frames": FLAP_LATE, "at": RIGHT_WING_AT},
    {"frames": [["D", "D"], ["DD", ".."], ["D", "D"], ["D", "D"]], "at": SIDE_WING_AT},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, LEGS, 30, TRAITS, idle_head=(0, 0, 0, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 0, 0, 0, 0, 0), walk_body=(0, 0, 0, 0, 0, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 0, 0)),
        outline=OUTLINE,
    )
