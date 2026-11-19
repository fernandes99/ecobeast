"""Seedlet: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,40 m, ele tem 6 pixels de altura. Sobram a crista de folhas verde-limão, a cabeça
grande verde com o rosto creme e os olhos escuros, o corpo creme, as quatro patas de pés
escuros e a cauda com a ponta em folha. Só a cabeça desce: em 6 pixels, descer o corpo
esconderia as patas. A crista e a folha da cauda balançam.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, rig  # noqa: E402

PALETTE = {
    "L": (176, 216, 48),   # verde-limão
    "G": (72, 168, 48),    # folha
    "g": (0, 104, 72),     # folha na sombra
    "C": (240, 216, 144),  # creme
    "c": (200, 176, 104),  # creme na sombra
    "E": (0, 48, 48),      # olho e pé
    "F": (24, 64, 64),     # pé de longe
}

HEADS = {
    "front": ([
        "gGGGGGg",
        "gCECECg",
        ".CCCCC.",
    ], 13, 27),
    "lower": ([
        "gGGGGG",
        "gECCEC",
        ".cCCCC",
    ], 14, 27),
    "side": ([
        "gGGGG.",
        "gGCCEC",
        ".gCCCC",
    ], 15, 27),
    "upper": ([
        "gGGGGG",
        "gGGGGC",
        ".gGGCC",
    ], 14, 27),
    "back": ([
        "gGGGGGg",
        "gGGgGGg",
        ".gGGGg.",
    ], 13, 27),
}
BODIES = {
    "front": (["CCC"], 15, 30),
    "lower": (["gGGC", "GCCC"], 12, 29),
    "side": (["gGG", "gCCC"], 12, 29),
    "upper": (["gGGG", "GGGC"], 12, 29),
    "back": (["GGG"], 15, 30),
}
CREST = {
    "front": [".L.L.", "L.L.L", ".L.L.", ".LL.L"],
    "lower": ["L.L.", ".L.L", "L.L.", "L..L"],
    "side": ["LL..", "L.L.", "LL..", ".LL."],
    "upper": ["L.L.", ".L.L", "L.L.", "L..L"],
    "back": [".L.L.", "L.L.L", ".L.L.", ".LL.L"],
}
CREST_AT = {"front": (14, 26), "lower": (15, 26), "side": (15, 26), "upper": (15, 26), "back": (14, 26)}
TAIL_LEAF = [
    ["LG", "Gg"],
    ["L.", "Gg"],
    ["LG", "Gg"],
    [".G", "Gg"],
]
TAIL_AT = {"front": (20, 27), "lower": (10, 27), "side": (10, 27), "upper": (10, 27), "back": (15, 27)}
TAIL_STEM = {"front": (20, 29), "lower": (11, 29), "side": (11, 29), "upper": (11, 29), "back": (16, 29)}

LEGS_Y = 30
WALK_HEAD = (1, 0, 0, 1, 0, 0)
FOOT_REACH = (1, 0, -1, -1, 0, 1)
FOOT_LIFT = (0, 0, 0, 0, 1, 1)
NEAR = ["C", "E"]
FAR = ["c", "F"]
LEGS = {
    "front": [(14, 0, NEAR, 0), (18, 3, NEAR, 0)],
    "back": [(14, 0, NEAR, 0), (18, 3, NEAR, 0)],
    "side": [(13, 3, FAR, 1), (15, 0, FAR, 1), (12, 0, NEAR, 1), (16, 3, NEAR, 1)],
    "lower": [(16, 3, FAR, 1), (12, 0, NEAR, 1), (17, 3, NEAR, 1)],
    "upper": [(16, 3, FAR, 1), (12, 0, NEAR, 1), (17, 3, NEAR, 1)],
}
TRAITS = [
    {"frames": [["c"]] * 4, "at": TAIL_STEM, "behind": ("front", "lower", "side")},
    {"frames": TAIL_LEAF, "at": TAIL_AT, "behind": ("front", "lower", "side"), "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": {view: [[row] for row in rows] for view, rows in CREST.items()}, "at": CREST_AT, "follows": "head", "walk": (0, 1, 2, 3, 0, 1)},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, BODIES, LEGS, LEGS_Y, TRAITS, idle_head=(0, 1, 1, 0), idle_body=(0, 0, 0, 0), walk_head=WALK_HEAD, walk_body=(0, 0, 0, 0, 0, 0), foot_reach=FOOT_REACH, foot_lift=FOOT_LIFT),
    )
