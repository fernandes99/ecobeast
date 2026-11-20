"""Seedlet: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,40 m, ele tem 10 pixels de altura pela regra do mapa (creature-scale): 8 de desenho e
o contorno verde-escuro por fora. Cabem a crista de folhas, a cabeça de filhote com o rosto
creme e os olhos, as patas escuras e a cauda de folha, que balança. No walk, as patas andam
em diagonal, como as do Ruvo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, rig, swayed  # noqa: E402

PALETTE = {
    "o": (26, 62, 38),     # contorno
    "G": (98, 186, 60),    # folha
    "g": (46, 132, 74),    # folha na sombra
    "Y": (194, 230, 80),   # folha na luz
    "C": (246, 234, 178),  # creme
    "c": (214, 196, 136),  # creme na sombra
    "e": (18, 52, 34),     # olho
    "m": (190, 120, 90),   # boca
    "T": (36, 80, 92),     # pata
}
OUTLINE = {"*": "o"}

TOP = 23
HEADS = {
    "front": ([
        ".Y..G..Y.",
        ".GY.G.YG.",
        "GgGGYGGgG",
        "GCeCCCeCG",
        "CCeCCCeCC",
        ".cCCmCCc.",
    ], 12, TOP),
    "lower": ([
        ".Y..G.Y.",
        ".GY.GYG.",
        "GgGGGYGG",
        "GGCeCCeC",
        "gCCeCCeC",
        ".gcCCmC.",
    ], 13, TOP),
    "side": ([
        "Y.G....",
        "GYGG...",
        "gGGGYG.",
        "GGGCeCC",
        "gGCCeCC",
        ".gcCCm.",
    ], 14, TOP),
    "upper": ([
        ".Y..G.Y.",
        ".GY.GYG.",
        "GgGGGYGG",
        "GGGGGGGG",
        "gGGGGGGG",
        ".ggGGGg.",
    ], 13, TOP),
    "back": ([
        ".Y..G..Y.",
        ".GY.G.YG.",
        "GgGGYGGgG",
        "GGGGGGGGG",
        "gGGGGGGGg",
        ".ggGGGgg.",
    ], 12, TOP),
}
BODIES = {
    "front": (["CCCCC"], 14, 29),
    "lower": ([
        "GGGCC..",
        "gGCCc..",
    ], 11, 28),
    "side": ([
        "YGGGGC.",
        "gGGCCc.",
    ], 9, 28),
    "upper": ([
        "GYGGG..",
        "gGGGg..",
    ], 11, 28),
    "back": (["gGGGg"], 14, 29),
}
LEAF = swayed([
    "Y.",
    "GY",
    "gG",
    ".g",
])
LEAVES = {"front": (19, 24), "lower": (8, 24), "side": (6, 23), "upper": (9, 25), "back": (14, 26)}

LEGS_Y = 29
FOOT_REACH = (1, 0, -1, -1, 0, 1)
FOOT_LIFT = (0, 0, 0, 0, 1, 1)
NEAR = ["T", "T"]
FAR = ["T", "T"]
LEGS = {
    "front": [(14, 0, NEAR, 0), (18, 3, NEAR, 0)],
    "back": [(14, 0, NEAR, 0), (18, 3, NEAR, 0)],
    "side": [(11, 3, FAR, 1), (15, 0, FAR, 1), (10, 0, NEAR, 1), (14, 3, NEAR, 1)],
    "lower": [(12, 3, FAR, 1), (11, 0, NEAR, 1), (15, 3, NEAR, 1)],
    "upper": [(16, 3, FAR, 1), (12, 0, NEAR, 1), (15, 3, NEAR, 1)],
}
TRAITS = [
    {"frames": LEAF, "at": LEAVES, "behind": ("front", "lower", "side")},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, BODIES, LEGS, LEGS_Y, TRAITS, idle_head=(0, 0, 1, 0), idle_body=(0, 0, 0, 0), walk_head=(1, 0, 0, 1, 0, 0), walk_body=(0, 0, 0, 0, 0, 0), foot_reach=FOOT_REACH, foot_lift=FOOT_LIFT),
        outline=OUTLINE,
    )
