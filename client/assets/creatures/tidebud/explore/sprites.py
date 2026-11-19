"""Tidebud: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,40 m, ele tem 6 pixels de altura. Sobram a crista de folhas, a cabeça verde-azulada de
olhos escuros, o focinho amarelo, a barriga creme, as nadadeiras de folha e a cauda enrolada,
que encosta no chão. Sem patas, ele flutua: a parte de cima balança, a cauda empurra no
walk, e uma faísca azul pisca na crista.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import VIEWS, build, rig  # noqa: E402

PALETTE = {
    "G": (24, 144, 104),   # verde-azulado
    "g": (0, 96, 88),      # verde-azulado na sombra
    "L": (160, 208, 56),   # folha
    "Y": (240, 220, 150),  # barriga creme
    "y": (208, 184, 112),  # creme na sombra
    "E": (16, 40, 48),     # olho
    "B": (232, 196, 72),   # focinho
    "S": (120, 208, 248),  # cristal
    "s": (184, 240, 255),  # faísca
}

HEADS = {
    "front": ([
        "L.G.L",
        "GEYEG",
        "LYBYL",
        ".GYG.",
    ], 14, 26),
    "lower": ([
        "L.G.L.",
        ".GEYEB",
        "LGYYY.",
        ".GYY..",
    ], 13, 26),
    "side": ([
        "LL.L..",
        ".GGEYB",
        "LGYY..",
        ".GYY..",
    ], 13, 26),
    "upper": ([
        "L.G.L.",
        ".GGGGB",
        "LGSGG.",
        ".GgG..",
    ], 13, 26),
    "back": ([
        "L.G.L",
        "GGGGG",
        "LGSGL",
        ".GgG.",
    ], 14, 26),
}
CURL = [".gGy.", "..gg."]
PUSH = ["..gGy", ".gg.."]
CURL_BACK = [".gGg.", "..gg."]
PUSH_BACK = [".gGg.", ".gg.."]
TAIL = {
    "front": [[".gYg.", "..gg."]] * 4,
    "lower": [CURL, CURL, PUSH, CURL],
    "side": [CURL, CURL, PUSH, CURL],
    "upper": [CURL_BACK, CURL_BACK, PUSH_BACK, CURL_BACK],
    "back": [CURL_BACK] * 4,
}
TAIL_AT = {"front": (14, 30), "lower": (13, 30), "side": (13, 30), "upper": (13, 30), "back": (14, 30)}
SPARK = [["s"], ["."], ["S"], ["."]]
SPARK_AT = {"front": (16, 26), "lower": (15, 26), "side": (15, 26), "upper": (15, 26), "back": (16, 26)}
TRAITS = [
    {"frames": TAIL, "at": TAIL_AT, "behind": VIEWS, "walk": (0, 2, 2, 0, 2, 2)},
    {"frames": SPARK, "at": SPARK_AT, "follows": "head", "walk": (0, 1, 2, 3, 0, 1)},
]
NO_LEGS = {view: [] for view in VIEWS}

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, NO_LEGS, 31, TRAITS, idle_head=(0, 0, 1, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 1, 1, 0, 1, 1), walk_body=(0, 0, 0, 0, 0, 0)),
    )
