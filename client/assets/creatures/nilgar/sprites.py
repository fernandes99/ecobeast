"""Nilgar: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,90 m, ele tem 13 pixels de altura. É um caranguejo armado: concha azul com a ponta
de água, duas pinças grandes que abrem e fecham, e patas curtas que correm em passos
miúdos, em grupos alternados.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig  # noqa: E402

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

HEAD_FRONT = [
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
]
HEAD_LOWER = [
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
]
HEAD_SIDE = [
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
]
HEADS = {
    "front": (HEAD_FRONT, 10, 19),
    "lower": (HEAD_LOWER, 10, 19),
    "side": (HEAD_SIDE, 10, 19),
    "upper": (recolored(HEAD_LOWER, "CEA", "DDD"), 10, 19),
    "back": (recolored(HEAD_FRONT, "CEA", "DDD"), 10, 19),
}
LEG_NEAR = ["KGK", "DDD"]
LEG_FAR = ["KD", "DD"]
LEGS = {
    "front": [(10, 0, LEG_FAR, 1), (13, 3, LEG_NEAR, 1), (17, 0, LEG_NEAR, 1), (20, 3, LEG_FAR, 1)],
    "back": [(10, 0, LEG_FAR, 1), (13, 3, LEG_NEAR, 1), (17, 0, LEG_NEAR, 1), (20, 3, LEG_FAR, 1)],
    "side": [(11, 0, LEG_FAR, 1), (13, 3, LEG_NEAR, 1), (15, 0, LEG_NEAR, 1), (17, 3, LEG_FAR, 1)],
    "lower": [(11, 0, LEG_FAR, 1), (13, 3, LEG_NEAR, 1), (16, 0, LEG_NEAR, 1), (19, 3, LEG_FAR, 1)],
    "upper": [(11, 0, LEG_FAR, 1), (13, 3, LEG_NEAR, 1), (16, 0, LEG_NEAR, 1), (19, 3, LEG_FAR, 1)],
}


def claws(left, right, gap):
    """As duas pinças na mesma linha, com a da direita espelhada."""
    return [a + "." * gap + b[::-1] for a, b in zip(left, right)]


CLAW_OPEN = [
    ".KK...",
    "KLLK.K",
    "KLWLKL",
    "KLLLLK",
    ".KBLK.",
    "..KK..",
]
CLAW_SHUT = [
    "......",
    ".KKKK.",
    "KLLLLK",
    "KLWLLK",
    ".KBLLK",
    "..KKK.",
]
ALL_CLAWS = [claws(CLAW_OPEN, CLAW_OPEN, 10), claws(CLAW_OPEN, CLAW_OPEN, 10), claws(CLAW_SHUT, CLAW_SHUT, 10), claws(CLAW_OPEN, CLAW_OPEN, 10)]
ONE_CLAW = [CLAW_OPEN, CLAW_OPEN, CLAW_SHUT, CLAW_OPEN]
TIP = [["L"], ["W"], ["L"], ["L"]]
CLAWS_AT = {"front": (5, 24), "back": (5, 24), "lower": (5, 24), "upper": (5, 24)}
TRAITS = [
    {"frames": [["D"], ["L"], ["D"], ["L"]], "at": {"back": (15, 22), "upper": (16, 22)}, "follows": "head"},
    {"frames": ALL_CLAWS, "at": CLAWS_AT, "follows": "body"},
    {"frames": ONE_CLAW, "at": {"side": (19, 25)}, "follows": "body"},
    {"frames": TIP, "at": {"front": (15, 21), "lower": (17, 21), "side": (15, 21)}, "follows": "head"},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, LEGS, 30, TRAITS, idle_head=(0, 0, 1, 0), idle_body=(0, 0, 1, 0), walk_head=(0, 1, 0, 0, 1, 0), walk_body=(0, 1, 0, 0, 1, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 1, 1)),
    )
