"""Ruvak: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,00 m, ele tem 19 pixels de altura pela regra do mapa (creature-scale): o desenho de
15 pixels cresce pelo `stretched`, com uma linha a mais na testa e no tronco e duas nas
patas, e o tronco fica 1 pixel mais comprido. Já cabe o contorno escuro. É um lobo jovem e
esguio, de patas longas e escuras, olhar sério, crina e cauda de fogo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, stretched, swayed  # noqa: E402

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

HEAD_FRONT = stretched([
    "..K.....K..",
    ".KRK...KRK.",
    ".KRCK.KCRK.",
    ".KRCOOOCRK.",
    "KOOOOLOOOOK",
    "KOEAOOOAEOK",
    "KCCCOOOCCCK",
    ".KCCCECCCK.",
    "..KKCCCKK..",
], rows=(4,))
HEAD_LOWER = stretched([
    "..K....K...",
    ".KRK..KRK..",
    ".KRCKKCRK..",
    ".KRCOOCRK..",
    "KOOOOLOOOK.",
    "KOOEAOOEAK.",
    "KOCCCOCCCK.",
    ".KCCCCCECK.",
    "..KKCCCKK..",
], rows=(4,))
HEAD_SIDE = stretched([
    "...K..K...",
    "..KRKKRK..",
    "..KRCKCK..",
    ".KORCOCK..",
    "KOOOLLOOK.",
    "KOOOOAEOCK",
    ".KOOOCCCCE",
    "..KKCCCCK.",
], rows=(4,))
HEADS = {
    "front": (HEAD_FRONT, 11, 13),
    "lower": (HEAD_LOWER, 16, 13),
    "side": (HEAD_SIDE, 19, 13),
    "upper": (recolored(HEAD_LOWER, "CEA", "RRO"), 16, 13),
    "back": (recolored(HEAD_FRONT, "CEA", "RRO"), 11, 13),
}
BODY_FRONT = stretched([
    ".KOCCCOK.",
    "KOOCCCOOK",
    "KSOCCCOSK",
], rows=(1,))
BODY_LOWER = stretched([
    "...KKOOOCCK.",
    ".KKOOOOOCCCK",
    "KOOLOOOOCCK.",
    "KSOOOOOOOK..",
], rows=(2,), cols=(5,))
BODY_SIDE = stretched([
    "....KKKKKOOCCK",
    "..KKOOOOOOOCCK",
    ".KOOLLLOOOOCCK",
    ".KOOOOOOOOCCK.",
    "..KSSSSSSSOK..",
], rows=(2,), cols=(7,))
BODIES = {
    "front": (BODY_FRONT, 12, 22),
    "lower": (BODY_LOWER, 9, 21),
    "side": (BODY_SIDE, 8, 19),
    "upper": (recolored(BODY_LOWER, "C", "O"), 9, 21),
    "back": (recolored(BODY_FRONT, "C", "O"), 12, 22),
}
NEAR = stretched(["KOK", "KOK", "KSK", "KTK", "TTT"], rows=(1, 2))
FAR = stretched(["KSK", "KSK", "KTK", "KTK", "TTK"], rows=(1, 2))
LEGS = {
    "front": [(12, 0, NEAR, 0), (18, 3, NEAR, 0)],
    "back": [(12, 0, NEAR, 0), (18, 3, NEAR, 0)],
    "side": [(12, 3, FAR, 1), (18, 0, FAR, 1), (9, 0, NEAR, 1), (20, 3, NEAR, 1)],
    "lower": [(14, 3, FAR, 0.5), (10, 0, NEAR, 0.5), (19, 3, NEAR, 0.5)],
    "upper": [(14, 3, FAR, 0.5), (10, 0, NEAR, 0.5), (19, 3, NEAR, 0.5)],
}
TAIL = swayed(stretched([
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
], rows=(3,)))
MANE = swayed([
    ".R.R.",
    "RyRyR",
    "RYyYR",
    "RyYyR",
])
TAIL_AT = {"front": (20, 14), "lower": (1, 14), "side": (1, 14), "upper": (2, 16), "back": (11, 18)}
MANE_AT = {"lower": (13, 14), "side": (15, 14), "upper": (13, 14)}
TRAITS = [
    {"frames": MANE, "at": MANE_AT, "behind": ("lower", "side", "upper"), "follows": "head"},
    {"frames": TAIL, "at": TAIL_AT, "behind": ("front", "lower", "side")},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 25, TRAITS))
