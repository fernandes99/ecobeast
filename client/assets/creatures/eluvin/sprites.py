"""Eluvin: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,90 m, ele tem 13 pixels de altura. É uma lebre esguia de folhas: orelhas compridas
para trás, olhar afiado, peito creme e uma cauda de folhas que mexe a cada quadro.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, swayed  # noqa: E402

PALETTE = {
    "K": (28, 74, 36),     # contorno
    "G": (108, 184, 60),   # verde
    "D": (47, 122, 44),    # verde na sombra
    "Y": (180, 224, 90),   # verde claro
    "C": (251, 240, 200),  # creme
    "T": (36, 95, 40),     # pata
    "E": (20, 40, 24),     # olho e focinho
    "A": (200, 232, 80),   # olho claro
}

HEAD_FRONT = [
    "K.........K",
    "GK.......KG",
    "GGK.K.K.KGG",
    ".KGGGYGGGK.",
    "KGGAEGEAGGK",
    "KCCCGGGCCCK",
    ".KCCCECCCK.",
    "..KKCCCKK..",
]
HEAD_LOWER = [
    "K.......K..",
    "GK.....KG..",
    "GGK.K.KGG..",
    ".KGGGYGGK..",
    "KGGGAEGAEK.",
    "KCCCCGCCCK.",
    ".KCCCCCECK.",
    "..KKCCCKK..",
]
HEAD_SIDE = [
    "..KK......",
    ".KGYK.K...",
    "KGGGKKGK..",
    "KDGGGKGK..",
    ".KKGGGGGK.",
    "...KGAEGCK",
    "...KGGCCCE",
    "....KCCCK.",
]
HEADS = {
    "front": (HEAD_FRONT, 11, 19),
    "lower": (HEAD_LOWER, 14, 19),
    "side": (HEAD_SIDE, 16, 19),
    "upper": (recolored(HEAD_LOWER, "CEA", "GDG"), 14, 19),
    "back": (recolored(HEAD_FRONT, "CEA", "GDG"), 11, 19),
}
BODY_FRONT = [
    ".KGCCCGK.",
    "KGGCCCGGK",
    "KDGCCCGDK",
]
BODY_LOWER = [
    "...KGGGCCK.",
    ".KKGGGGCCCK",
    "KGGYGGGCCK.",
    "KDGGGGGGK..",
]
BODY_SIDE = [
    "...KKKKKKGCK.",
    "..KGGGYGGGCCK",
    ".KGYYGGGGCCCK",
    ".KGGGGGGGCCK.",
    "..KDDDDDDGK..",
]
BODIES = {
    "front": (BODY_FRONT, 12, 26),
    "lower": (BODY_LOWER, 9, 25),
    "side": (BODY_SIDE, 9, 24),
    "upper": (recolored(BODY_LOWER, "C", "G"), 9, 25),
    "back": (recolored(BODY_FRONT, "C", "G"), 12, 26),
}
NEAR = ["KGK", "KGK", "KDK", "TTT"]
FAR = ["KDK", "KDK", "KTK", "TTK"]
LEGS = {
    "front": [(12, 0, NEAR, 0), (18, 3, NEAR, 0)],
    "back": [(12, 0, NEAR, 0), (18, 3, NEAR, 0)],
    "side": [(12, 3, FAR, 1), (16, 0, FAR, 1), (10, 0, NEAR, 1), (18, 3, NEAR, 1)],
    "lower": [(14, 3, FAR, 0.5), (10, 0, NEAR, 0.5), (17, 3, NEAR, 0.5)],
    "upper": [(14, 3, FAR, 0.5), (10, 0, NEAR, 0.5), (17, 3, NEAR, 0.5)],
}
TAIL = swayed([
    "..K...",
    ".KGK..",
    "KGYGK.",
    "KGYGGK",
    "KDGYGK",
    ".KDGGK",
    "..KDDK",
])
TAIL_AT = {"front": (20, 20), "lower": (3, 20), "side": (4, 20), "upper": (4, 21), "back": (12, 23)}
TRAITS = [{"frames": TAIL, "at": TAIL_AT, "behind": ("front", "lower", "side")}]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 28, TRAITS, walk_body=(1, 0, 0, 1, 0, 0), foot_reach=(1, 1, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 1, 1)))
