"""Ruvaroth: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,60 m, ele tem 28 pixels de altura pela regra do mapa (creature-scale), um pouco mais
alto que o Domador: o desenho de 24 cresce pelo `stretched`, nos olhos, no tronco, nas patas
e na cauda, sem ficar mais largo, porque já ocupa 30 dos 32 pixels da célula. É um lobo grande e escuro, de
olhos vermelhos e peito cor de terra. O fogo sai da crina, das patas e de uma cauda alta
que começa em chama e termina em fumaça escura.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, stretched, swayed  # noqa: E402

PALETTE = {
    "K": (26, 12, 14),     # contorno
    "B": (70, 42, 44),     # pelo
    "D": (46, 28, 32),     # pelo na sombra e fumaça
    "H": (96, 62, 60),     # pelo na luz
    "M": (176, 126, 94),   # peito
    "R": (196, 44, 28),    # vermelho
    "F": (236, 84, 24),    # chama forte
    "y": (255, 160, 32),   # chama média
    "Y": (255, 224, 96),   # chama clara
    "E": (20, 8, 10),      # olho e focinho
    "A": (255, 120, 40),   # olho
}

HEAD_FRONT = stretched([
    "..K.........K..",
    ".KRK.......KRK.",
    ".KBRK.....KRBK.",
    ".KBRBK...KBRBK.",
    ".KBBBBKKKBBBBK.",
    "KBBBBBRRRBBBBBK",
    "KBDBAEBRBEABDBK",
    "KBBBBBBHBBBBBBK",
    ".KDBBMMMMMBBDK.",
    "..KKBMMEMMBKK..",
    "....KKMMMKK....",
], rows=(6,))
HEAD_LOWER = stretched([
    "..K........K...",
    ".KRK......KRK..",
    ".KBRK....KRBK..",
    ".KBRBK..KBRBK..",
    ".KBBBBKKBBBBK..",
    "KBBBBBRRRBBBBK.",
    "KBDBBBAEBRAEBK.",
    "KBBBBBBHBBBBBK.",
    ".KDBBBMMMMMMK..",
    "..KKBMMMMEMK...",
    "....KKMMMKK....",
], rows=(6,))
HEAD_SIDE = stretched([
    "...K....K.....",
    "..KRK..KRK....",
    "..KBRK.KBK....",
    ".KBBRKKBBK....",
    ".KBBBBBBBBK...",
    "KBBBBBBRRBBK..",
    "KBDBBBBBBAEBK.",
    ".KBBBBBBBBMMMK",
    ".KDBBBBMMMMMEK",
    "..KKBBMMMMMKK.",
    "....KKKKKKK...",
], rows=(6,))
HEADS = {
    "front": (HEAD_FRONT, 9, 5),
    "lower": (HEAD_LOWER, 14, 5),
    "side": (HEAD_SIDE, 17, 5),
    "upper": (recolored(HEAD_LOWER, "MEA", "DBB"), 14, 5),
    "back": (recolored(HEAD_FRONT, "MEA", "DBB"), 9, 5),
}
BODY_FRONT = stretched([
    "..KRFBMMBFRK.",
    ".KRFFBMMMBFRK",
    ".KFyFBMMMBFFK",
    ".KBFFBMMMBFBK",
    ".KBBFBMMBFBBK",
    "..KBBBBBBBBK.",
], rows=(2,))
BODY_LOWER = stretched([
    ".....KKKBBMMK.",
    "...KKBBBBBMMMK",
    ".KKBBBBBBBFMMK",
    "KBBHHBBBBFyFMK",
    "KBBBBBBBBBFFMK",
    "KBDBBBBBBBBFK.",
    ".KBBBKKKKKBBK.",
    "..KK......KK..",
], rows=(3,))
BODY_SIDE = stretched([
    "......KKKKKBMMK.",
    "....KKBBBBBBMMMK",
    "..KKBBHHBBBBMMMK",
    ".KBBBHHBBBBBFMMK",
    ".KBBBBBBBBBBFFMK",
    ".KBDBBBBBBBBFyFK",
    "..KBBBBBDBBBFyK.",
    "..KBBKKKKKKBBK..",
    "...KK.....KK....",
], rows=(3,))
BODIES = {
    "front": (BODY_FRONT, 10, 16),
    "lower": (BODY_LOWER, 7, 14),
    "side": (BODY_SIDE, 7, 14),
    "upper": (recolored(BODY_LOWER, "MFy", "BBB"), 7, 14),
    "back": (recolored(BODY_FRONT, "M", "B"), 10, 16),
}
NEAR = stretched(["KBBK", "KBBK", "KFBK", "KFFK", "KyFK", "KYyK", "KKKK"], rows=(1, 2))
FAR = stretched(["KDK", "KDK", "KDK", "KFK", "KFK", "KyK", "KKK"], rows=(1, 2))
LEGS = {
    "front": [(11, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(11, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(12, 3, FAR, 1), (16, 0, FAR, 1), (8, 0, NEAR, 1), (18, 3, NEAR, 1)],
    "lower": [(14, 3, FAR, 0.5), (9, 0, NEAR, 0.5), (18, 3, NEAR, 0.5)],
    "upper": [(14, 3, FAR, 0.5), (9, 0, NEAR, 0.5), (18, 3, NEAR, 0.5)],
}
TAIL = swayed(stretched([
    "...DDD...",
    "..DBBBD..",
    ".DBBDBBD.",
    ".DBD.DBD.",
    "..D..DBD.",
    "....DBFD.",
    "...DFyFD.",
    "..DFyYyFD",
    ".DFyYYyFD",
    "DFyYYYyFD",
    "DFyYYyyFD",
    "DFFyyFFFD",
    ".DFFFFFFD",
    "..DFFFDDD",
    "...DDD...",
], rows=(9,)), (0, 1, 0, -1))
MANE = swayed([
    "..R....R..",
    ".RyR..RyR.",
    ".RyyRRyyR.",
    "RyYyyyyYyR",
    "RyYYyyYYyR",
    "RFyYYYYyFR",
    ".RFFyyFFR.",
])
TAIL_AT = {"front": (21, 5), "lower": (0, 4), "side": (0, 4), "upper": (1, 6), "back": (10, 10)}
MANE_AT = {"front": (10, 5), "lower": (10, 7), "side": (12, 5), "upper": (10, 7), "back": (10, 5)}
TRAITS = [
    {"frames": MANE, "at": MANE_AT, "behind": ("front", "lower", "side", "upper", "back"), "follows": "head"},
    {"frames": TAIL, "at": TAIL_AT, "behind": ("front", "lower", "side")},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 23, TRAITS))
