"""Grovequill: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,00 m, ele tem 15 pixels de altura. É uma ave-dinossauro esguia, sem asas, em duas
pernas escuras: a crista de folhas jogada para trás, o rosto, o pescoço comprido e o peito
creme, o bico claro, as folhas verde-azuladas nas costas e nos lados e a cauda longa de
folhas, sempre atrás dele. A crista e a cauda balançam no vento.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, rig, swayed  # noqa: E402

PALETTE = {
    "K": (0, 40, 40),      # contorno
    "G": (32, 144, 72),    # folha
    "g": (0, 96, 80),      # folha na sombra
    "L": (168, 208, 48),   # verde-limão
    "Y": (240, 220, 152),  # creme
    "y": (200, 176, 112),  # creme na sombra
    "E": (16, 56, 40),     # olho
    "B": (232, 196, 96),   # bico
    "F": (24, 56, 64),     # pernas
}

HEADS = {
    "front": ([
        "KGGGGGK",
        "KGYYYGK",
        "KYEYEYK",
        ".KYBYK.",
        "..KYK..",
        "..KYK..",
    ], 13, 18),
    "lower": ([
        "..KKKK..",
        ".KGGGGK.",
        ".KYEYEYK",
        "..KYYBBK",
        "..KYYK..",
        "..KYYK..",
    ], 13, 18),
    "side": ([
        "....KKKK..",
        "...KGGYYK.",
        "...KGYEYBB",
        "...KYYYYK.",
        "..KYYYK...",
        "..KYYK....",
        "..KYYK....",
    ], 13, 18),
    "upper": ([
        "..KKKK..",
        ".KGGGGK.",
        ".KGGGGYK",
        "..KGGYBK",
        "..KGGK..",
        "..KGGK..",
    ], 13, 18),
    "back": ([
        "KGGGGGK",
        "KGGgGGK",
        "KGgGgGK",
        ".KGGGK.",
        "..KGK..",
        "..KGK..",
    ], 13, 18),
}
BODIES = {
    "front": ([
        "..KYYYK..",
        ".KgYYYgK.",
        "KGgYYYgGK",
        "KgGYYYGgK",
        ".KgGyGgK.",
    ], 12, 23),
    "lower": ([
        "....KKYYK.",
        "..KGgGYYK.",
        ".KGgGGYYYK",
        ".KgGgGyYYK",
        "..KKgGyyK.",
    ], 8, 23),
    "side": ([
        "..KKGGGK...",
        ".KGgGLGGYK.",
        "KGgGGLGYYYK",
        "KgGgGGYYYK.",
        ".KKgGyyyK..",
    ], 7, 23),
    "upper": ([
        "....KKGGK.",
        "..KGgGGGK.",
        ".KGLGgGLGK",
        ".KgGLGgGGK",
        "..KKKKKKK.",
    ], 8, 23),
    "back": ([
        "..KGGGK..",
        ".KGLGLGK.",
        "KGgGGGgGK",
        "KgGLGLGgK",
        ".KKKKKKK.",
    ], 12, 23),
}
NEAR = ["F", "F", "F", "FF"]
LEGS = {
    "front": [(14, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(14, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(11, 3, NEAR, 1), (14, 0, NEAR, 1)],
    "lower": [(12, 3, NEAR, 0.5), (15, 0, NEAR, 0.5)],
    "upper": [(12, 3, NEAR, 0.5), (15, 0, NEAR, 0.5)],
}
CREST = swayed([
    ".L.G.L.",
    "GLGGGLG",
], (0, 0, 1, 0))
CREST_SIDE = swayed([
    "LGG....",
    ".GLGGL.",
], (0, -1, -1, 0))
TAIL_SIDE = [
    "....GG.....",
    "..GLLGG....",
    "GLLGGLLGG..",
    ".GGLLGGgGK.",
    "...GGLLGg..",
    ".....GG....",
]
TAIL_LOWER = [
    "...GG....",
    ".GLLGG...",
    "GLGGLLGK.",
    ".GGLLGGK.",
    "...GGG...",
]
TAIL_UPPER = [
    "..GG...",
    ".GLLG..",
    "GLGGLG.",
    "GLLGGL.",
    ".GG.GG.",
]
TAIL_BACK = [
    "...GLG...",
    "..GLGLG..",
    ".GLGGGLG.",
    "GLG.G.GLG",
]
TAIL_FRAMES = {
    "side": swayed(TAIL_SIDE, (0, 0, 1, 0)),
    "lower": swayed(TAIL_LOWER, (0, 0, 1, 0)),
    "upper": swayed(TAIL_UPPER, (0, 0, 1, 0)),
    "back": swayed(TAIL_BACK, (0, 0, 1, 0)),
}
TAIL_AT = {"side": (-1, 21), "lower": (1, 22), "upper": (3, 25), "back": (11, 26)}
CREST_AT = {"front": (12, 17), "back": (12, 17), "lower": (13, 17), "upper": (13, 17)}
CREST_SIDE_AT = {"side": (13, 17)}
TRAITS = [
    {"frames": TAIL_FRAMES, "at": TAIL_AT, "behind": ("lower", "side")},
    {"frames": CREST, "at": CREST_AT, "follows": "head"},
    {"frames": CREST_SIDE, "at": CREST_SIDE_AT, "follows": "head"},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 28, TRAITS))
