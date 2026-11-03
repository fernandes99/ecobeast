"""Eluvara: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,40 m e 42 kg, ela tem 21 pixels de altura e o corpo esguio. É a guardiã dos bosques:
pescoço longo, orelhas largas, galhos na testa, patas escuras e uma cauda cheia de folhas.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, swayed  # noqa: E402

PALETTE = {
    "K": (24, 60, 32),     # contorno
    "G": (104, 176, 60),   # verde
    "D": (44, 112, 44),    # verde na sombra
    "Y": (188, 226, 96),   # verde claro
    "C": (250, 238, 200),  # creme
    "P": (214, 150, 128),  # orelha
    "T": (30, 74, 34),     # pata
    "W": (124, 84, 48),    # galho
    "E": (18, 36, 20),     # olho e focinho
    "A": (214, 236, 92),   # olho claro
}

HEAD_FRONT = [
    "K...........K",
    "GK.........KG",
    "GCK.......KCG",
    "GPCK.KKK.KCPG",
    ".KPGKGYGKGPK.",
    "..KGGGYGGGK..",
    ".KGGAEGEAGGK.",
    ".KCCGGGGGCCK.",
    "..KCCCECCCK..",
    "...KKCCCKK...",
]
HEAD_LOWER = [
    "K.........K..",
    "GK.......KG..",
    "GCK.....KCG..",
    "GPCK.KKKCPG..",
    ".KPGKGYGGPK..",
    "..KGGGYGGGK..",
    ".KGGGGAEGAEK.",
    ".KCCCGGGCCCK.",
    "..KCCCCCCECK.",
    "...KKCCCKK...",
]
HEAD_SIDE = [
    "...KK.......",
    "..KGGK.KK...",
    ".KGYGKKGGK..",
    "KGCPGGKGYK..",
    "KDCPGGGGGK..",
    ".KKGGGGGGGK.",
    "...KGGAEGGCK",
    "...KGGGCCCCE",
    "....KKCCCCK.",
]
HEADS = {
    "front": (HEAD_FRONT, 10, 11),
    "lower": (HEAD_LOWER, 13, 11),
    "side": (HEAD_SIDE, 17, 11),
    "upper": (recolored(HEAD_LOWER, "EA", "DG"), 13, 11),
    "back": (recolored(HEAD_FRONT, "EA", "DG"), 10, 11),
}
BODY_FRONT = [
    "...KGCCCGK...",
    "...KGCCCGK...",
    "..KGGCCCGGK..",
    ".KYGGCCCGGYK.",
    ".KGGGCCCGGGK.",
    ".KDGGCCCGGDK.",
    "..KDGGCGGDK..",
]
BODY_LOWER = [
    "........KGCCK.",
    "........KGCCK.",
    "......KKGGCCK.",
    "..KKKKGGGGCCK.",
    ".KGYYGGGGGCCK.",
    "KGGYYYGGGGCCK.",
    "KDGGGGGGDGGCK.",
    ".KDDDDDDDDDK..",
]
BODY_SIDE = [
    "............KGCCK.",
    "............KGCCK.",
    "..........KKGGCCK.",
    "...KKKKKKKGGGGCCK.",
    "..KGGYYGGGGGGGCCK.",
    ".KGGYYYGGGGGDGGCK.",
    ".KDGGGGGGDGGGGGK..",
    "..KDDDDDDDDDDDK...",
]
BODIES = {
    "front": (BODY_FRONT, 10, 19),
    "lower": (BODY_LOWER, 7, 18),
    "side": (BODY_SIDE, 6, 18),
    "upper": (recolored(BODY_LOWER, "C", "G"), 7, 18),
    "back": (recolored(BODY_FRONT, "C", "G"), 10, 19),
}
NEAR = ["KGK", "KGK", "KCK", "KDK", "KDK", "KTK", "TTT"]
FAR = ["KDK", "KDK", "KTK", "KTK", "KTK", "KTK", "TTK"]
LEGS = {
    "front": [(11, 0, NEAR, 0), (18, 3, NEAR, 0)],
    "back": [(11, 0, NEAR, 0), (18, 3, NEAR, 0)],
    "side": [(11, 3, FAR, 1), (16, 0, FAR, 1), (8, 0, NEAR, 1), (18, 3, NEAR, 1)],
    "lower": [(13, 3, FAR, 0.5), (9, 0, NEAR, 0.5), (17, 3, NEAR, 0.5)],
    "upper": [(13, 3, FAR, 0.5), (9, 0, NEAR, 0.5), (17, 3, NEAR, 0.5)],
}
TAIL = swayed([
    "...K.....",
    "..KGK.K..",
    ".KGYGKGK.",
    ".KGYYGGK.",
    "KGGYYGGK.",
    "KGYYGGGGK",
    "KDGYYGGGK",
    "KDGGYGGGK",
    ".KDGGGGDK",
    "..KDGGDK.",
    "...KDDK..",
])
ANTLERS = swayed([
    "W.W",
    ".W.",
    ".W.",
])
TAIL_AT = {"front": (21, 12), "lower": (1, 12), "side": (0, 12), "upper": (2, 14), "back": (11, 17)}
ANTLERS_AT = {"front": (14, 11), "lower": (16, 11), "side": (22, 11), "upper": (16, 11), "back": (14, 11)}
TRAITS = [
    {"frames": ANTLERS, "at": ANTLERS_AT, "follows": "head"},
    {"frames": TAIL, "at": TAIL_AT, "behind": ("front", "lower", "side")},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 25, TRAITS))
