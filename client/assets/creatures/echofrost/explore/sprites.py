"""Echofrost: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,70 m e 46 kg, ele tem 25 pixels de altura, a mesma do Domador, e o corpo esguio. É
um arminho em pé, em duas patas, com as patas da frente junto ao peito, o cristal rosado
no peito e uma cauda larga de gelo, em forma de lua crescente, sempre atrás do corpo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, swayed  # noqa: E402

PALETTE = {
    "K": (32, 44, 100),    # contorno
    "W": (244, 246, 255),  # pelo
    "S": (200, 212, 242),  # pelo na sombra
    "B": (150, 190, 240),  # azul do pelo
    "L": (112, 190, 245),  # cristal
    "C": (205, 238, 255),  # brilho do cristal
    "D": (74, 120, 200),   # cristal na sombra
    "P": (232, 120, 180),  # coração do cristal
    "p": (255, 200, 225),  # brilho rosado
    "E": (22, 40, 100),    # olho
    "I": (60, 130, 225),   # íris
    "N": (232, 176, 176),  # orelha e focinho
}

HEAD_FRONT = [
    ".KK.....KK.",
    "KNNK...KNNK",
    "KNWWKKKWWNK",
    "KWWWWLWWWWK",
    "KWEIWWWEIWK",
    "KWEEWWWEEWK",
    ".KWWWNWWWK.",
    "..KWWWWWK..",
]
HEAD_LOWER = [
    ".KK.....KK.",
    "KNNK...KNNK",
    "KNWWKKKWWNK",
    "KWWWWWLWWWK",
    "KWWWEIWWEIK",
    "KWWWEEWWEEK",
    ".KWWWWWNWK.",
    "..KWWWWWK..",
]
HEAD_SIDE = [
    "...KK......",
    "..KNNK.....",
    "..KNWWKKK..",
    ".KWWWWWLWK.",
    "KWWWWWEIWWK",
    "KWWWWWEEWWN",
    ".KWWWWWWWK.",
    "..KWWWWKK..",
]
HEADS = {
    "front": (HEAD_FRONT, 11, 7),
    "lower": (HEAD_LOWER, 14, 7),
    "side": (HEAD_SIDE, 16, 7),
    "upper": (recolored(HEAD_LOWER, "IEN", "WWS"), 14, 7),
    "back": (recolored(HEAD_FRONT, "IEN", "WWS"), 11, 7),
}
BODY_FRONT = [
    "...KWWWK...",
    "...KWLWK...",
    "..KWWLWWK..",
    "..KWLCLWK..",
    ".KWWLPLWWK.",
    ".KWWLpLWWK.",
    ".KBWDLDWBK.",
    "KLBWWLWWBLK",
    "KLKWWWWWKLK",
    ".KKWWWWWKK.",
    ".KWWWSWWWK.",
    ".KWWWSWWWK.",
]
BODY_LOWER = [
    "....KWWWK..",
    "...KWWWLWK.",
    "...KWWLCLK.",
    "..KWWWLCLK.",
    "..KWWWLPLK.",
    "..KWWWLpLK.",
    "..KWWWDLDK.",
    ".KWWWWWLWLK",
    ".KWWWWKLKLK",
    ".KWWSWWKKK.",
    ".KWWSWWWWK.",
    ".KSWWWWWWK.",
]
BODY_SIDE = [
    "....KWWWWK.",
    "...KWWWWLK.",
    "...KWWWLCK.",
    "..KWWWWLPLK",
    "..KWWWWLpLK",
    "..KWWWWDLK.",
    ".KWWWWLWWLK",
    ".KWWWWWKLLK",
    ".KWWWSWKLK.",
    ".KWWWSWWK..",
    ".KWWSWWWWK.",
    ".KSWWWWWWK.",
]
BODY_UPPER = [
    "....KWWWK..",
    "...KWLWWWK.",
    "...KWWLWWK.",
    "..KWLWWWWK.",
    "..KWWLWWSK.",
    "..KLWWWLSK.",
    ".KWWLWWWSK.",
    ".KWWWWLWSK.",
    ".KWLWWWWWK.",
    ".KWWWSWWK..",
    ".KWSWWWWWK.",
    ".KSWWWWWWK.",
]
BODY_BACK = [
    "...KWWWK...",
    "...KWLWK...",
    "..KWWLWWK..",
    "..KWLWLWK..",
    ".KWWWLWWWK.",
    ".KWLWWWLWK.",
    ".KSWWLWWSK.",
    "KSWWLWLWWSK",
    "KWWWWWWWWWK",
    ".KWWWLWWWK.",
    ".KWWWWWWWK.",
    ".KWWSWSWWK.",
]
BODIES = {
    "front": (BODY_FRONT, 11, 15),
    "lower": (BODY_LOWER, 12, 15),
    "side": (BODY_SIDE, 14, 15),
    "upper": (BODY_UPPER, 12, 15),
    "back": (BODY_BACK, 11, 15),
}
NEAR = ["KWWK", "KWWK", "KWWK", "KBBK", "LLLL"]
FAR = ["KSSK", "KSSK", "KSSK", "KBBK", "DDDD"]
LEGS = {
    "front": [(12, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(12, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(18, 3, FAR, 1), (15, 0, NEAR, 1)],
    "lower": [(16, 3, FAR, 0.5), (13, 0, NEAR, 0.5)],
    "upper": [(16, 3, FAR, 0.5), (13, 0, NEAR, 0.5)],
}
TAIL = swayed([
    ".....KKKKKK...",
    "...KKLCCCLLKK.",
    "..KLCCLLLLCLLK",
    ".KLCLLDDKKKKK.",
    ".KCLLLDK......",
    "KLCLLLLK......",
    "KCLLLLDK......",
    "KCLLLLLK......",
    "KLCLLLLDK.....",
    "KLCCLLLDK...KK",
    ".KLCWLLLLKKKWW",
    ".KWWWWLLLWWWWW",
    "..KWWWWWWWWWSK",
    "...KKWWWWSKKK.",
    ".....KKKKK....",
])
CORE = [["P", "p"], ["p", "P"], ["P", "p"], ["p", "p"]]
TAIL_AT = {"front": (0, 13), "lower": (0, 13), "side": (1, 13), "upper": (0, 13), "back": (0, 13)}
CORE_AT = {"front": (16, 19), "lower": (19, 19), "side": (22, 18)}
TRAITS = [
    {"frames": CORE, "at": CORE_AT, "follows": "body"},
    {"frames": TAIL, "at": TAIL_AT, "behind": ("front", "lower", "side", "upper", "back")},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 27, TRAITS))
