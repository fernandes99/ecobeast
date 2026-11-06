"""Ruvak: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,00 m, ele tem 15 pixels de altura. Já cabe o contorno escuro. É um lobo jovem e
esguio, de patas longas e escuras, olhar sério, crina e cauda de fogo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, swayed  # noqa: E402

PALETTE = {
    "K": (60, 18, 14),     # contorno
    "R": (168, 48, 24),    # vermelho: orelha e contorno da chama
    "O": (236, 112, 28),   # laranja
    "L": (250, 164, 50),   # laranja claro
    "S": (204, 68, 24),    # laranja na sombra
    "C": (250, 226, 180),  # creme
    "T": (110, 42, 26),    # pata
    "E": (40, 14, 12),     # olho e focinho
    "A": (252, 196, 60),   # âmbar do olho
    "Y": (255, 224, 96),   # chama clara
    "y": (255, 160, 32),   # chama média
    "F": (236, 84, 24),    # chama forte
}

HEAD_FRONT = [
    "..K.....K..",
    ".KRK...KRK.",
    ".KRCK.KCRK.",
    ".KRCOOOCRK.",
    "KOOOOLOOOOK",
    "KOEAOOOAEOK",
    "KCCCOOOCCCK",
    ".KCCCECCCK.",
    "..KKCCCKK..",
]
HEAD_LOWER = [
    "..K....K...",
    ".KRK..KRK..",
    ".KRCKKCRK..",
    ".KRCOOCRK..",
    "KOOOOLOOOK.",
    "KOOEAOOEAK.",
    "KOCCCOCCCK.",
    ".KCCCCCECK.",
    "..KKCCCKK..",
]
HEAD_SIDE = [
    "...K..K...",
    "..KRKKRK..",
    "..KRCKCK..",
    ".KORCOCK..",
    "KOOOLLOOK.",
    "KOOOOAEOCK",
    ".KOOOCCCCE",
    "..KKCCCCK.",
]
HEADS = {
    "front": (HEAD_FRONT, 11, 17),
    "lower": (HEAD_LOWER, 15, 17),
    "side": (HEAD_SIDE, 18, 17),
    "upper": (recolored(HEAD_LOWER, "CEA", "RRO"), 15, 17),
    "back": (recolored(HEAD_FRONT, "CEA", "RRO"), 11, 17),
}
BODY_FRONT = [
    ".KOCCCOK.",
    "KOOCCCOOK",
    "KSOCCCOSK",
]
BODY_LOWER = [
    "...KKOOOCCK.",
    ".KKOOOOOCCCK",
    "KOOLOOOOCCK.",
    "KSOOOOOOOK..",
]
BODY_SIDE = [
    "....KKKKKOOCCK",
    "..KKOOOOOOOCCK",
    ".KOOLLLOOOOCCK",
    ".KOOOOOOOOCCK.",
    "..KSSSSSSSOK..",
]
BODIES = {
    "front": (BODY_FRONT, 12, 25),
    "lower": (BODY_LOWER, 9, 24),
    "side": (BODY_SIDE, 8, 22),
    "upper": (recolored(BODY_LOWER, "C", "O"), 9, 24),
    "back": (recolored(BODY_FRONT, "C", "O"), 12, 25),
}
NEAR = ["KOK", "KOK", "KSK", "KTK", "TTT"]
FAR = ["KSK", "KSK", "KTK", "KTK", "TTK"]
LEGS = {
    "front": [(12, 0, NEAR, 0), (18, 3, NEAR, 0)],
    "back": [(12, 0, NEAR, 0), (18, 3, NEAR, 0)],
    "side": [(12, 3, FAR, 1), (17, 0, FAR, 1), (9, 0, NEAR, 1), (19, 3, NEAR, 1)],
    "lower": [(14, 3, FAR, 0.5), (10, 0, NEAR, 0.5), (18, 3, NEAR, 0.5)],
    "upper": [(14, 3, FAR, 0.5), (10, 0, NEAR, 0.5), (18, 3, NEAR, 0.5)],
}
TAIL = swayed([
    "..RR....",
    ".RyyR...",
    ".RyYyR..",
    "RyyYyR..",
    "RyYYyyR.",
    "RyYFFyR.",
    "RyFFFFyR",
    ".RFFRFFR",
    "..RFFFFR",
    "...RRRR.",
])
MANE = swayed([
    ".R.R.",
    "RyRyR",
    "RYyYR",
    "RyYyR",
])
TAIL_AT = {"front": (20, 17), "lower": (1, 17), "side": (1, 17), "upper": (2, 19), "back": (11, 21)}
MANE_AT = {"lower": (12, 18), "side": (14, 18), "upper": (12, 18)}
TRAITS = [
    {"frames": MANE, "at": MANE_AT, "behind": ("lower", "side", "upper"), "follows": "head"},
    {"frames": TAIL, "at": TAIL_AT, "behind": ("front", "lower", "side")},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 27, TRAITS))
