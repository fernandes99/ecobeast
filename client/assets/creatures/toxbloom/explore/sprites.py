"""Toxbloom: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,0 m, ele tem 19 pixels de altura pela regra do mapa (creature-scale): 17 de desenho e o
contorno vinho por fora. É um sapo largo e baixo, verde de pintas rosa, de barriga creme e
queixo erguido, com os olhos laranja de pálpebra caída e a flor carmim e violeta aberta nas
costas, de miolo dourado. No idle, a flor balança e o néctar pinga das pétalas; no walk, ele
anda em pulinhos pesados: o corpo sobe 1 pixel, e as patas de trás esticam embaixo dele.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, mirrored, recolored, rig, swayed  # noqa: E402

PALETTE = {
    "o": (62, 26, 42),     # contorno
    "G": (170, 180, 42),   # pele
    "g": (112, 122, 32),   # pele na sombra
    "S": (218, 58, 106),   # pinta e dedo
    "C": (242, 218, 168),  # barriga
    "c": (206, 174, 134),  # barriga na sombra
    "R": (226, 74, 98),    # pétala
    "r": (162, 32, 72),    # pétala na sombra
    "V": (98, 26, 76),     # pétala violeta
    "Y": (250, 202, 74),   # miolo
    "L": (66, 106, 42),    # folha
    "E": (242, 138, 42),   # olho
    "k": (62, 26, 42),     # pálpebra e boca
    "N": (202, 228, 50),   # néctar
}
OUTLINE = {"*": "o", "R": "r", "Y": "r"}


def sized(drawing, width):
    assert all(len(row) == width for row in drawing), drawing
    return drawing


TOP = 14
FLOWER_FRONT = sized(mirrored([
    "...rr..Y.Y",
    ".rRRr.rYYY",
    "rRRRRrRRYY",
    "VrRRRRRRRR",
    "VVrRRRRRRR",
    ".VVrrRRRRR",
    "..LVVrrrrr",
]), 19)
FLOWER_SIDE = sized([
    "......Y.Y.Y....",
    "..rr.rYYYYr....",
    ".rRRrRRYYRRr...",
    "VrRRRRRRRRRRr..",
    "VVrRRRRRRRRrVV.",
    ".VVrrRRRRrrVVL.",
    "..LVVrrrrVVLL..",
], 15)
FLOWER_BACK = sized([
    "...rRRRYRRRr...",
    ".rRRRRYYYRRRRr.",
    "VrRRRRRYRRRRRrV",
    "VVrRRRRRRRRRrVV",
    "LVVrrRRRRRrrVVL",
    ".LVVVrrrrrVVVL.",
], 15)
FRONT_HEAD = sized([
    ".GkkkGGGkkkG.",
    "GGEEkGGGkEEGG",
    "GSGGGGGGGGGSG",
    "GGGGgkkkgGGGG",
    "gGCCCCCCCCCGg",
], 13)
SIDE_HEAD = sized([
    "..Gkkk..",
    ".GEEEkG.",
    "GGGGGGGG",
    "GSGGGkkk",
    "gGCCCCCc",
], 8)
BACK_HEAD = sized([
    "..GGGGGGGGG..",
    ".GSGGGGGGGSG.",
    "GGGGGSGGGGGGG",
    "GGSGGGGGGSGGG",
    "gGGGGGGGGGGGg",
], 13)
HEADS = {
    "front": (FRONT_HEAD, 10, TOP + 4),
    "lower": (FRONT_HEAD, 10, TOP + 4),
    "side": (SIDE_HEAD, 17, TOP + 5),
    "upper": (recolored(SIDE_HEAD, "EkC", "GgG"), 17, TOP + 5),
    "back": (BACK_HEAD, 10, TOP + 4),
}
FRONT_BODY = sized([
    "GSGGCCCCCCCCCGGSG",
    "GGGGCCCCCCCCCGGGG",
    "GSGgCCCCCCCCCgGSG",
    "gGSgcCCCCCCCcgSGg",
    "ggGgccCCCCCccgGgg",
    ".gg.gccccccc.gg..",
], 17)
SIDE_BODY = sized([
    "..GGGGGG....",
    ".GGSGGGGGG..",
    "GGGGGGSGGGG.",
    "GSGGGGGGGGCC",
    "GGGGSGGGGCCC",
    "gGGGGGGGgccc",
    ".gggggggccc.",
], 12)
BACK_BODY = sized([
    "GSGGGGGGGSGGGGSGG",
    "GGGGSGGGGGGGSGGGG",
    "GSGGGGGGSGGGGGGSG",
    "gGGGGSGGGGGSGGGGg",
    "ggGSGGGGGGGGGSGgg",
    ".gggggggggggggg..",
], 17)
BODIES = {
    "front": (FRONT_BODY, 8, TOP + 8),
    "lower": (FRONT_BODY, 8, TOP + 8),
    "side": (SIDE_BODY, 7, TOP + 8),
    "upper": (recolored(SIDE_BODY, "Cc", "Gg"), 7, TOP + 8),
    "back": (BACK_BODY, 8, TOP + 8),
}
LEGS_Y = TOP + 13
NEAR = ["GG", "gG", "SgS", "SSS"]
FAR = ["g", "g", "gg", "SS"]
HAUNCH = ["GGG", "GSG", "gGg", "SSSS"]
FORE = ["G", "G", "g", "SS"]
LEGS = {
    "front": [(8, 0, FAR, 0), (23, 0, FAR, 0), (10, 0, NEAR, 0), (20, 0, NEAR, 0)],
    "lower": [(8, 0, FAR, 0), (23, 0, FAR, 0), (10, 0, NEAR, 0), (20, 0, NEAR, 0)],
    "back": [(10, 0, NEAR, 0), (20, 0, NEAR, 0)],
    "side": [(21, 0, FORE, 0), (7, 0, HAUNCH, 1), (18, 0, FORE, 0)],
    "upper": [(21, 0, FORE, 0), (7, 0, HAUNCH, 1), (18, 0, FORE, 0)],
}
SWAY = (0, 1, 0, -1)
FLOWER = {
    "front": swayed(FLOWER_FRONT, SWAY),
    "lower": swayed(FLOWER_FRONT, SWAY),
    "side": swayed(FLOWER_SIDE, SWAY),
    "upper": swayed(FLOWER_SIDE, SWAY),
    "back": swayed(FLOWER_BACK, SWAY),
}
FLOWER_AT = {"front": (5, TOP), "lower": (5, TOP), "side": (5, TOP + 1), "upper": (5, TOP + 1), "back": (8, TOP + 1)}
DRIP = [["N.", "..", ".."], ["N.", "N.", ".."], [".N", "..", ".."], [".N", ".N", ".."]]
DRIP_AT = {"front": (8, TOP + 6), "lower": (8, TOP + 6), "side": (6, TOP + 7), "upper": (6, TOP + 7), "back": (9, TOP + 6)}
TRAITS = [
    {"frames": FLOWER, "at": FLOWER_AT, "follows": "body", "behind": ("front", "lower", "side", "upper")},
    {"frames": DRIP, "at": DRIP_AT, "follows": "body"},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, BODIES, LEGS, LEGS_Y, TRAITS, idle_head=(0, 0, 1, 0), idle_body=(0, 0, 0, 0), walk_head=(0, -1, -1, 0, -1, -1), walk_body=(0, -1, -1, 0, -1, -1), foot_reach=(0, -1, 0, 0, -1, 0), foot_lift=(0, 0, 0, 0, 0, 0)),
        outline=OUTLINE,
    )
