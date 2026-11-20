"""Prayling: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,40 m, ele tem 10 pixels de altura pela regra do mapa (creature-scale): 8 de desenho e
o contorno marrom-escuro por fora. Cabem a cabeça triangular marrom com os dois olhos verdes
enormes, as antenas, o peito creme com as patas da frente dobradas, o abdômen comprido atrás
e as 4 patas finas. As antenas mexem a cada quadro.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig  # noqa: E402

PALETTE = {
    "o": (54, 32, 18),     # contorno
    "B": (142, 94, 52),    # marrom
    "L": (194, 142, 84),   # marrom na luz
    "D": (98, 62, 34),     # marrom na sombra e antenas
    "C": (230, 210, 172),  # peito
    "G": (156, 222, 46),   # olho
    "k": (52, 110, 22),    # pupila
}
OUTLINE = {"*": "o"}

TOP = 24
FRONT = [
    "GGBLLLBGG",
    "GkBBLBBkG",
    ".BBBCBBB.",
    "...BCB...",
]
LOWER = [
    ".GGBLLGG",
    ".GkBLBkG",
    "..BBBCB.",
    "....BC..",
]
SIDE = [
    "..BLB.",
    ".BBBGG",
    "..BBGk",
    "...BC.",
]
BACK = recolored(FRONT, "GkC", "BDB")
HEADS = {
    "front": (FRONT, 12, TOP),
    "lower": (LOWER, 12, TOP),
    "side": (SIDE, 14, TOP),
    "upper": (recolored(LOWER, "GkC", "BDB"), 11, TOP),
    "back": (BACK, 12, TOP),
}
BODIES = {
    "front": (["LDCCCDL"], 13, 28),
    "lower": ([
        "BBBLDCD.",
    ], 10, 28),
    "side": ([
        "BLLBBBDLC.",
    ], 9, 28),
    "upper": ([
        "BLLBBDB.",
    ], 10, 28),
    "back": (["DBLLLBD"], 13, 28),
}
ANTENNAE = {
    "front": [["D.......D"], [".D.....D."], ["D.......D"], ["D......D."]],
    "lower": [["D......D"], [".D.....D"], ["D......D"], ["D.....D."]],
    "side": [["DD...."], [".DD..."], ["DD...."], ["D.D..."]],
    "upper": [["D......D"], [".D.....D"], ["D......D"], ["D.....D."]],
    "back": [["D.......D"], [".D.....D."], ["D.......D"], ["D......D."]],
}
ANTENNAE_AT = {"front": (12, 23), "lower": (12, 23), "side": (13, 23), "upper": (11, 23), "back": (12, 23)}

LEGS_Y = 29
LEG = ["D", "D"]
OUT_LEFT = [".D", "D."]
OUT_RIGHT = ["D.", ".D"]
LEGS = {
    "front": [(12, 0, OUT_LEFT, 0), (15, 3, LEG, 0), (17, 0, LEG, 0), (19, 3, OUT_RIGHT, 0)],
    "back": [(12, 0, OUT_LEFT, 0), (15, 3, LEG, 0), (17, 0, LEG, 0), (19, 3, OUT_RIGHT, 0)],
    "side": [(11, 3, LEG, 1), (15, 0, LEG, 1), (12, 0, LEG, 1), (16, 3, LEG, 1)],
    "lower": [(11, 3, LEG, 1), (14, 0, LEG, 1), (12, 0, LEG, 1), (16, 3, LEG, 1)],
    "upper": [(12, 3, LEG, 1), (15, 0, LEG, 1), (11, 0, LEG, 1), (16, 3, LEG, 1)],
}
TRAITS = [
    {"frames": ANTENNAE, "at": ANTENNAE_AT, "follows": "head", "walk": (0, 1, 2, 3, 0, 1)},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, BODIES, LEGS, LEGS_Y, TRAITS, idle_head=(0, 0, 0, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 0, 0, 0, 0, 0), walk_body=(0, 0, 0, 0, 0, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 1, 1)),
        outline=OUTLINE,
    )
