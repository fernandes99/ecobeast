"""Eagrow: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,00 m, ele tem 15 pixels de altura. É uma ave de rapina esguia, em duas pernas escuras,
com a crista alta de folhas jogada para trás, o rosto e o peito creme, a sobrancelha verde,
o bico verde e curvo, a asa verde-limão junto ao corpo e a cauda longa de folhas, sempre
atrás dele. A crista e a cauda balançam no vento.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, rig, swayed  # noqa: E402

PALETTE = {
    "K": (0, 48, 24),      # contorno
    "G": (0, 144, 0),      # folha
    "g": (0, 96, 0),       # folha na sombra
    "L": (168, 192, 24),   # verde-limão
    "l": (120, 144, 24),   # verde-limão na sombra
    "Y": (240, 216, 120),  # creme
    "y": (200, 168, 72),   # creme na sombra
    "E": (24, 24, 24),     # olho
    "F": (56, 56, 48),     # pernas
}

HEAD_FRONT = [
    "KGGYGGK",
    "KYEGEYK",
    ".KYGYK.",
    "..KYK..",
]
HEAD_LOWER = [
    ".KGGGGK.",
    "KYEYYEGG",
    "KYYYYYKG",
    ".KYYYK..",
]
HEAD_SIDE = [
    ".KGGGGK",
    "KYYYEGG",
    "KYYYYKG",
    ".KYYYK.",
]
HEAD_UPPER = [
    ".KGGGGK.",
    "KGYYYYKG",
    "KyYYYYK.",
    ".KyyyK..",
]
HEAD_BACK = [
    "KGGGGGK",
    "KGGgGGK",
    ".KYYYK.",
    "..KyK..",
]
HEADS = {
    "front": (HEAD_FRONT, 13, 20),
    "lower": (HEAD_LOWER, 14, 20),
    "side": (HEAD_SIDE, 15, 20),
    "upper": (HEAD_UPPER, 14, 20),
    "back": (HEAD_BACK, 13, 20),
}
BODY_FRONT = [
    "..KYYYK..",
    ".KGYYYGK.",
    "KLGGYGGLK",
    "KlLYYYLlK",
    ".KKyyyKK.",
]
BODY_LOWER = [
    "...KYYYK.",
    "..KGYYYGK",
    ".KLLGYGGK",
    "KlLLYYYLK",
    ".KKKyyyK.",
]
BODY_SIDE = [
    ".....KYYK.",
    "...KKGYYYK",
    ".KLLLGGYYK",
    ".KlLLLLyyK",
    "..KKKKKKK.",
]
BODY_UPPER = [
    "...KGGGK.",
    "..KLGGGLK",
    ".KLLGGGLK",
    "KlLLGGLlK",
    ".KKKKKKK.",
]
BODY_BACK = [
    "..KGGGK..",
    ".KLGGGLK.",
    "KLLGGGLLK",
    "KlLLGLLlK",
    ".KKKKKKK.",
]
BODIES = {
    "front": (BODY_FRONT, 12, 24),
    "lower": (BODY_LOWER, 12, 24),
    "side": (BODY_SIDE, 11, 24),
    "upper": (BODY_UPPER, 12, 24),
    "back": (BODY_BACK, 12, 24),
}
NEAR = ["F", "F", "FF"]
LEGS = {
    "front": [(14, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(14, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(17, 3, NEAR, 1), (15, 0, NEAR, 1)],
    "lower": [(17, 3, NEAR, 0.5), (14, 0, NEAR, 0.5)],
    "upper": [(17, 3, NEAR, 0.5), (14, 0, NEAR, 0.5)],
}
CREST = swayed([
    ".G.L.G.",
    "GLGGGLG",
    ".GGLGG.",
], (0, 0, 1, 0))
CREST_SIDE = swayed([
    "GLG.....",
    ".GLGGG..",
    "..GGLGG.",
], (0, -1, -1, 0))
TAIL_SIDE = [
    ".....GG....",
    "..GGLLGG...",
    "GLLGGLLGK..",
    ".GGLLGGGK..",
    "...GGLLG...",
    ".....GG....",
]
TAIL_LOWER = [
    "...GG.....",
    ".GGLLG....",
    "GLLGGLG...",
    ".GGLLGG...",
    "...GGG....",
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
TAIL_AT = {"side": (3, 24), "lower": (5, 24), "upper": (8, 26), "back": (11, 26)}
CREST_AT = {"front": (12, 17), "back": (12, 17), "lower": (13, 17), "upper": (13, 17)}
CREST_SIDE_AT = {"side": (12, 17)}
TRAITS = [
    {"frames": TAIL_FRAMES, "at": TAIL_AT, "behind": ("lower", "side")},
    {"frames": CREST, "at": CREST_AT, "follows": "head"},
    {"frames": CREST_SIDE, "at": CREST_SIDE_AT, "follows": "head"},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 29, TRAITS))
