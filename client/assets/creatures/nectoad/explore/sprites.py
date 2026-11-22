"""Nectoad: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,35 m, ele tem 9 pixels de altura pela regra do mapa (creature-scale): 7 de desenho e o
contorno vinho por fora. É um sapinho verde de pintas rosa, agachado, com os olhos laranja
de pálpebra caída, a gola de pétalas rosa no pescoço, a barriga creme e os dedos rosa. No
idle, a garganta infla e uma gota de néctar brilha nas costas; no walk, ele anda em pulinhos:
o corpo sobe, e as patas de trás esticam embaixo dele.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig  # noqa: E402

PALETTE = {
    "o": (66, 30, 44),     # contorno
    "G": (178, 196, 44),   # pele
    "g": (118, 136, 30),   # pele na sombra
    "S": (220, 64, 112),   # pinta e dedo
    "C": (242, 218, 152),  # barriga
    "P": (244, 120, 140),  # pétala
    "p": (196, 52, 96),    # pétala na sombra
    "E": (244, 150, 44),   # olho
    "k": (66, 30, 44),     # pálpebra
    "N": (214, 236, 70),   # néctar
}
OUTLINE = {"*": "o"}

TOP = 24
FRONT = [
    ".GE...EG.",
    "GGkGGGkGG",
    "SGGCCCGGS",
]
SIDE = [
    "..GGE..",
    ".SGGkGG",
    "GGGGGCC",
]
BACK = [
    ".GG...GG.",
    "GSGGGGGSG",
    "GGGSGGGGG",
]
HEADS = {
    "front": (FRONT, 12, TOP),
    "lower": (FRONT, 12, TOP),
    "side": (SIDE, 13, TOP),
    "upper": (recolored(SIDE, "Ek", "GG"), 13, TOP),
    "back": (BACK, 12, TOP),
}
RUFF = ["PpPPpPpPPpP"]
BODIES = {
    "front": (RUFF + ["..GCCCCCG..", "..gGCCCGg.."], 11, TOP + 3),
    "lower": (RUFF + ["..GCCCCCG..", "..gGCCCGg.."], 11, TOP + 3),
    "side": (["pPPpPPpP", "gSGGCC..", "ggGGCC.."], 12, TOP + 3),
    "upper": (["pPPpPPpP", "gSGGGG..", "ggGGGg.."], 12, TOP + 3),
    "back": (["PpPpPPpPPpP", "..GSGGGSG..", "..gGGGGGg.."], 11, TOP + 3),
}
LEGS_Y = TOP + 5
LEG = ["g", "S"]
LEGS = {
    "front": [(14, 0, LEG, 0), (18, 0, LEG, 0)],
    "lower": [(14, 0, LEG, 0), (18, 0, LEG, 0)],
    "back": [(14, 0, LEG, 0), (18, 0, LEG, 0)],
    "side": [(13, 0, LEG, 1), (17, 0, LEG, 0)],
    "upper": [(13, 0, LEG, 1), (17, 0, LEG, 0)],
}
THROAT = [["..."], [".C."], ["CCC"], [".C."]]
THROAT_AT = {"front": (15, TOP + 3), "lower": (15, TOP + 3), "side": (17, TOP + 3)}
DROP = [["N"], ["."], ["."], ["N"]]
DROP_AT = {"side": (14, TOP + 1), "upper": (14, TOP + 1), "back": (17, TOP + 1)}
TRAITS = [
    {"frames": THROAT, "at": THROAT_AT, "follows": "body", "walk": (0, 0, 0, 0, 0, 0)},
    {"frames": DROP, "at": DROP_AT, "follows": "head", "walk": (0, 0, 3, 0, 0, 3)},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, BODIES, LEGS, LEGS_Y, TRAITS, idle_head=(0, 0, 0, 0), idle_body=(0, 0, 0, 0), walk_head=(0, -1, -1, 0, -1, -1), walk_body=(0, -1, -1, 0, -1, -1), foot_reach=(0, -1, 0, 0, -1, 0), foot_lift=(0, 0, 0, 0, 0, 0)),
        outline=OUTLINE,
    )
