"""Puffcoo: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,30 m, ela tem 4 pixels de altura, e sobram só a bolinha cinza, a barriga clara, os
olhos, o bico laranja e os pés. O corpo não sobe nem desce: quem se mexe são as asinhas,
que batem, e os pés, em passinhos curtos de pombo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig  # noqa: E402

PALETTE = {
    "E": (24, 24, 48),     # olho
    "G": (144, 144, 168),  # penas
    "L": (184, 184, 204),  # barriga
    "D": (96, 96, 124),    # asa e cauda
    "O": (224, 136, 48),   # bico
    "F": (232, 96, 64),    # pés
}

HEAD_FRONT = [
    "..GGG..",
    ".GEOEG.",
    ".GLLLG.",
]
HEAD_LOWER = [
    "..GGG..",
    ".GGEOE.",
    ".GGLLG.",
]
HEAD_SIDE = [
    "..GGG..",
    ".GGGEO.",
    "DGGLLG.",
]
HEAD_BACK = [
    "..GGG..",
    ".GGGGG.",
    ".GGDGG.",
]
HEADS = {
    "front": (HEAD_FRONT, 13, 28),
    "lower": (HEAD_LOWER, 13, 28),
    "side": (HEAD_SIDE, 12, 28),
    "upper": (recolored(HEAD_LOWER, "EOL", "GGG"), 13, 28),
    "back": (HEAD_BACK, 13, 28),
}
LEG = ["F"]
LEGS = {
    "front": [(15, 0, LEG, 1), (17, 3, LEG, 1)],
    "lower": [(15, 0, LEG, 1), (17, 3, LEG, 1)],
    "side": [(14, 0, LEG, 1), (16, 3, LEG, 1)],
    "upper": [(15, 0, LEG, 1), (17, 3, LEG, 1)],
    "back": [(15, 0, LEG, 1), (17, 3, LEG, 1)],
}
DOWN = [".", "D"]
UP = ["D", "."]
FLAP = [DOWN, UP, DOWN, DOWN]
FLAP_LATE = [DOWN, DOWN, UP, DOWN]
LEFT_WING_AT = {"front": (13, 29), "lower": (13, 29), "upper": (13, 29), "back": (13, 29)}
RIGHT_WING_AT = {"front": (19, 29), "lower": (19, 29), "upper": (19, 29), "back": (19, 29)}
SIDE_WING_AT = {"side": (14, 29)}
TRAITS = [
    {"frames": FLAP, "at": LEFT_WING_AT},
    {"frames": FLAP_LATE, "at": RIGHT_WING_AT},
    {"frames": FLAP, "at": SIDE_WING_AT},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, LEGS, 31, TRAITS, idle_head=(0, 0, 0, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 0, 0, 0, 0, 0), walk_body=(0, 0, 0, 0, 0, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 0, 0)),
    )
