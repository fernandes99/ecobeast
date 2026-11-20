"""Tidebud: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,40 m, ele tem 10 pixels de altura pela regra do mapa (creature-scale): 8 de desenho e
o contorno verde-escuro por fora. Cabem a crista de folhas, a cabeça verde-azulada de olhos
escuros, o focinho amarelo, a barriga creme, as nadadeiras de folha e a cauda enrolada, que
encosta no chão. Sem patas, ele flutua: a parte de cima balança, a cauda empurra no walk,
e uma faísca azul pisca na crista.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import VIEWS, build, rig  # noqa: E402

PALETTE = {
    "o": (14, 62, 56),     # contorno
    "G": (30, 150, 112),   # verde-azulado
    "g": (6, 104, 92),     # verde-azulado na sombra
    "L": (164, 212, 60),   # folha
    "Y": (242, 222, 152),  # barriga creme
    "y": (210, 186, 114),  # creme na sombra
    "E": (16, 40, 48),     # olho
    "B": (234, 196, 72),   # focinho
    "S": (120, 208, 248),  # faísca
    "s": (200, 244, 255),  # faísca clara
}
OUTLINE = {"*": "o"}

TOP = 23
HEADS = {
    "front": ([
        "L.LGL.L",
        ".GGGGG.",
        "GEYYYEG",
        "LGYBYGL",
        ".GYYYG.",
    ], 13, TOP),
    "lower": ([
        "L.L.L..",
        ".GGGGG.",
        "LGGEYEB",
        ".GYYYB.",
        "LgGYY..",
    ], 13, TOP),
    "side": ([
        "L.LL...",
        ".GGGG..",
        "LGGEYBB",
        ".GGYY..",
        "LgYY...",
    ], 13, TOP),
    "upper": ([
        "L.L.L..",
        ".GGGGG.",
        "LGGGGGB",
        ".GgGGG.",
        "LgGGG..",
    ], 13, TOP),
    "back": ([
        "L.LGL.L",
        ".GGGGG.",
        "GGGGGGG",
        "LGgggGL",
        ".GgGgG.",
    ], 13, TOP),
}
BODIES = {
    "front": (["LGYGL"], 14, 28),
    "lower": (["LgYY"], 14, 28),
    "side": (["LgYY"], 14, 28),
    "upper": (["LgGg"], 14, 28),
    "back": (["LgGgL"], 14, 28),
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
TAIL_AT = {"front": (14, 29), "lower": (13, 29), "side": (13, 29), "upper": (13, 29), "back": (14, 29)}
SPARK = [["s"], ["S"], ["s"], ["L"]]
SPARK_AT = {"front": (16, TOP), "lower": (14, TOP), "side": (14, TOP), "upper": (14, TOP), "back": (16, TOP)}
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
        rig(HEADS, BODIES, NO_LEGS, 30, TRAITS, idle_head=(0, 0, 1, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 1, 1, 0, 1, 1), walk_body=(0, 0, 0, 0, 0, 0)),
        outline=OUTLINE,
    )
