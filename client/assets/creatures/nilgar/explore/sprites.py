"""Nilgar: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,90 m, ele tem 17 pixels de altura pela regra do mapa (creature-scale), com o desenho de
13 pixels crescido pelo `stretched`. É um caranguejo armado: concha azul com a ponta
de água, duas pinças grandes que abrem e fecham, e patas curtas que correm em passos
miúdos, em grupos alternados.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, stretched  # noqa: E402

GROW = {"rows": (4, 7, 8), "cols": (5, 6)}

PALETTE = {
    "K": (18, 36, 92),     # contorno
    "B": (47, 114, 216),   # concha
    "D": (28, 68, 160),    # concha na sombra
    "L": (120, 216, 255),  # água
    "W": (216, 246, 255),  # brilho
    "G": (140, 150, 170),  # armadura
    "C": (244, 239, 230),  # rosto
    "E": (12, 20, 56),     # olho
    "A": (73, 200, 240),   # olho claro
}

HEAD_FRONT = stretched([
    ".....KK.....",
    "....KLLK....",
    "...KLWLLK...",
    ".KKGLLLLGKK.",
    "KBBBBLLBBBBK",
    "KBDBBBBBBDBK",
    "KDDGBKKBGDDK",
    ".KCEACCAECK.",
    "..KCCCCCCK..",
    ".KGGDDDDGGK.",
    "..KKKKKKKK..",
], **GROW)
HEAD_LOWER = stretched([
    "......KK....",
    ".....KLLK...",
    "....KLWLLK..",
    "..KKGLLLLGK.",
    ".KBBBBBLLBBK",
    "KBDBBBBBBBDK",
    "KDDGBBBKKGDK",
    ".KKCCEACAEK.",
    "...KCCCCCK..",
    "..KGGDDDGGK.",
    "...KKKKKKK..",
], **GROW)
HEAD_SIDE = stretched([
    "....KK......",
    "...KLLK.....",
    "..KLWLLK....",
    ".KGLLLLGKK..",
    "KBBBLLBBBBK.",
    "KDBBBBBBBBBK",
    "KDDGBBBBKKGK",
    ".KKDDCCCEACK",
    "...KKCCCCCK.",
    "..KGGDDDGGK.",
    "...KKKKKKK..",
], **GROW)
HEADS = {
    "front": (HEAD_FRONT, 9, 15),
    "lower": (HEAD_LOWER, 9, 15),
    "side": (HEAD_SIDE, 9, 15),
    "upper": (recolored(HEAD_LOWER, "CEA", "DDD"), 9, 15),
    "back": (recolored(HEAD_FRONT, "CEA", "DDD"), 9, 15),
}
LEG_NEAR = ["KGK", "KGK", "DDD"]
LEG_FAR = ["KD", "KD", "DD"]
LEGS = {
    "front": [(9, 0, LEG_FAR, 1), (13, 3, LEG_NEAR, 1), (17, 0, LEG_NEAR, 1), (21, 3, LEG_FAR, 1)],
    "back": [(9, 0, LEG_FAR, 1), (13, 3, LEG_NEAR, 1), (17, 0, LEG_NEAR, 1), (21, 3, LEG_FAR, 1)],
    "side": [(11, 0, LEG_FAR, 1), (13, 3, LEG_NEAR, 1), (15, 0, LEG_NEAR, 1), (17, 3, LEG_FAR, 1)],
    "lower": [(11, 0, LEG_FAR, 1), (13, 3, LEG_NEAR, 1), (16, 0, LEG_NEAR, 1), (19, 3, LEG_FAR, 1)],
    "upper": [(11, 0, LEG_FAR, 1), (13, 3, LEG_NEAR, 1), (16, 0, LEG_NEAR, 1), (19, 3, LEG_FAR, 1)],
}


def claws(left, right, gap):
    """As duas pinças na mesma linha, com a da direita espelhada."""
    return [a + "." * gap + b[::-1] for a, b in zip(left, right)]


CLAW_OPEN = stretched([
    ".KK...",
    "KLLK.K",
    "KLWLKL",
    "KLLLLK",
    ".KBLK.",
    "..KK..",
], rows=(2,))
CLAW_SHUT = stretched([
    "......",
    ".KKKK.",
    "KLLLLK",
    "KLWLLK",
    ".KBLLK",
    "..KKK.",
], rows=(2,))
ALL_CLAWS = [claws(CLAW_OPEN, CLAW_OPEN, 12), claws(CLAW_OPEN, CLAW_OPEN, 12), claws(CLAW_SHUT, CLAW_SHUT, 12), claws(CLAW_OPEN, CLAW_OPEN, 12)]
ONE_CLAW = [CLAW_OPEN, CLAW_OPEN, CLAW_SHUT, CLAW_OPEN]
TIP = [["LL"], ["WW"], ["LW"], ["LL"]]
CLAWS_AT = {"front": (4, 22), "back": (4, 22), "lower": (4, 22), "upper": (4, 22)}
TRAITS = [
    {"frames": [["D"], ["L"], ["D"], ["L"]], "at": {"back": (15, 18), "upper": (16, 18)}, "follows": "head"},
    {"frames": ALL_CLAWS, "at": CLAWS_AT, "follows": "body"},
    {"frames": ONE_CLAW, "at": {"side": (20, 22)}, "follows": "body"},
    {"frames": TIP, "at": {"front": (14, 17), "lower": (17, 17), "side": (14, 17)}, "follows": "head"},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, LEGS, 29, TRAITS, idle_head=(0, 0, 1, 0), idle_body=(0, 0, 1, 0), walk_head=(0, 1, 0, 0, 1, 0), walk_body=(0, 1, 0, 0, 1, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 1, 1)),
    )
