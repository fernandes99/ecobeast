"""Ruvo: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,50 m, ele tem 11 pixels de altura pela regra do mapa (creature-scale): 9 de desenho
e o contorno marrom por fora, vermelho na chama. A cabeça de filhote, com as orelhas, o
focinho creme e a crista de fogo, fica com 6 deles; a chama da cauda balança atrás.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, rig, swayed  # noqa: E402

PALETTE = {
    "o": (92, 34, 18),     # contorno
    "q": (150, 34, 20),    # contorno da chama
    "R": (228, 106, 38),   # laranja
    "Y": (248, 162, 72),   # laranja na luz
    "r": (184, 66, 26),    # laranja na sombra
    "C": (248, 222, 176),  # creme
    "c": (222, 180, 134),  # creme na sombra
    "e": (52, 24, 14),     # olho
    "n": (204, 92, 92),    # focinho
    "P": (132, 42, 24),    # pata
    "F": (255, 220, 80),   # chama clara
    "y": (255, 152, 40),   # chama média
    "f": (234, 72, 36),    # chama forte
}
OUTLINE = {"*": "o", "F": "q", "y": "q", "f": "q"}

TOP = 22
HEADS = {
    "front": ([
        "RC.....CR",
        "RRRRRRRRR",
        "RYeYRYeYR",
        "RReCCCeRR",
        "rCCCnCCCr",
        ".cCCCCCc.",
    ], 12, TOP),
    "lower": ([
        "RC....CR",
        "RRRRRRRR",
        "RRYeYYeR",
        "rRReCCeC",
        ".rRCCCnC",
        "..rcCCC.",
    ], 13, TOP),
    "side": ([
        ".RC.....",
        "RRRR....",
        "RYYYR...",
        "RRRReCC.",
        "rRRCCCCn",
        ".rrcCCc.",
    ], 14, TOP),
    "upper": ([
        "RR....RR",
        "RRRRRRRR",
        "RYYYYYYR",
        "RRRRRRRR",
        "rRRRRRRR",
        ".rRRRRr.",
    ], 13, TOP),
    "back": ([
        "RR.....RR",
        "RRRRRRRRR",
        "RYYYYYYYR",
        "RRRRRRRRR",
        "rRRRRRRRr",
        ".rrRRRrr.",
    ], 12, TOP),
}
BODIES = {
    "front": (["rRCCCRr"], 13, 28),
    "lower": ([
        "RYRRR..",
        "rRRRCC.",
    ], 11, 27),
    "side": ([
        "RYYYRR..",
        "rRRRRCc.",
    ], 9, 27),
    "upper": ([
        "RYYRR..",
        "rRRRRR.",
    ], 11, 27),
    "back": (["rRRRRRr"], 13, 28),
}
FLAME = swayed([
    ".f.",
    "fyf",
    "yFy",
    "yFf",
    "fyf",
    ".f.",
])
FLAMES = {"front": (19, 23), "lower": (9, 23), "side": (6, 22), "upper": (9, 24), "back": (14, 25)}
CRESTS = {"front": (16, 22), "lower": (16, 22), "side": (15, 22), "upper": (16, 22), "back": (16, 22)}
CREST_MARKS = ["F", "y", "F", "f"]

LEGS_Y = 29
IDLE_HEAD = (0, 0, 1, 0)
WALK_HEAD = (1, 0, 0, 1, 0, 0)
FOOT_REACH = (1, 0, -1, -1, 0, 1)
FOOT_LIFT = (0, 0, 0, 0, 1, 1)
NEAR = ["RR", "PP"]
FAR = ["r", "P"]
SLIM = ["R", "P"]
LEGS = {
    "front": [(14, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(14, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(11, 3, FAR, 1), (15, 0, FAR, 1), (10, 0, SLIM, 1), (14, 3, SLIM, 1)],
    "lower": [(12, 3, FAR, 1), (11, 0, SLIM, 1), (15, 3, NEAR, 1)],
    "upper": [(16, 3, FAR, 1), (12, 0, SLIM, 1), (15, 3, SLIM, 1)],
}
TRAITS = [
    {"frames": [[mark] for mark in CREST_MARKS], "at": CRESTS, "follows": "head", "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": FLAME, "at": FLAMES, "behind": ("front", "lower", "side")},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, BODIES, LEGS, LEGS_Y, TRAITS, idle_head=IDLE_HEAD, idle_body=(0, 0, 0, 0), walk_head=WALK_HEAD, walk_body=(0, 0, 0, 0, 0, 0), foot_reach=FOOT_REACH, foot_lift=FOOT_LIFT),
        outline=OUTLINE,
    )
