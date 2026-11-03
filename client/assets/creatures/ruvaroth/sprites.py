"""Ruvaroth: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,60 m, ele tem 24 pixels de altura, quase o Domador. É um lobo grande e escuro, de
olhos vermelhos e peito cor de terra. O fogo sai da crina, das patas e de uma cauda alta
que começa em chama e termina em fumaça escura.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, swayed  # noqa: E402

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

HEAD_FRONT = [
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
]
HEAD_LOWER = [
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
]
HEAD_SIDE = [
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
]
HEADS = {
    "front": (HEAD_FRONT, 9, 9),
    "lower": (HEAD_LOWER, 14, 9),
    "side": (HEAD_SIDE, 17, 9),
    "upper": (recolored(HEAD_LOWER, "MEA", "DBB"), 14, 9),
    "back": (recolored(HEAD_FRONT, "MEA", "DBB"), 9, 9),
}
BODY_FRONT = [
    "..KRFBMMBFRK.",
    ".KRFFBMMMBFRK",
    ".KFyFBMMMBFFK",
    ".KBFFBMMMBFBK",
    ".KBBFBMMBFBBK",
    "..KBBBBBBBBK.",
]
BODY_LOWER = [
    ".....KKKBBMMK.",
    "...KKBBBBBMMMK",
    ".KKBBBBBBBFMMK",
    "KBBHHBBBBFyFMK",
    "KBBBBBBBBBFFMK",
    "KBDBBBBBBBBFK.",
    ".KBBBKKKKKBBK.",
    "..KK......KK..",
]
BODY_SIDE = [
    "......KKKKKBMMK.",
    "....KKBBBBBBMMMK",
    "..KKBBHHBBBBMMMK",
    ".KBBBHHBBBBBFMMK",
    ".KBBBBBBBBBBFFMK",
    ".KBDBBBBBBBBFyFK",
    "..KBBBBBDBBBFyK.",
    "..KBBKKKKKKBBK..",
    "...KK.....KK....",
]
BODIES = {
    "front": (BODY_FRONT, 10, 19),
    "lower": (BODY_LOWER, 7, 17),
    "side": (BODY_SIDE, 7, 17),
    "upper": (recolored(BODY_LOWER, "MFy", "BBB"), 7, 17),
    "back": (recolored(BODY_FRONT, "M", "B"), 10, 19),
}
NEAR = ["KBBK", "KBBK", "KFBK", "KFFK", "KyFK", "KYyK", "KKKK"]
FAR = ["KDK", "KDK", "KDK", "KFK", "KFK", "KyK", "KKK"]
LEGS = {
    "front": [(11, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(11, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(12, 3, FAR, 1), (16, 0, FAR, 1), (8, 0, NEAR, 1), (18, 3, NEAR, 1)],
    "lower": [(14, 3, FAR, 0.5), (9, 0, NEAR, 0.5), (18, 3, NEAR, 0.5)],
    "upper": [(14, 3, FAR, 0.5), (9, 0, NEAR, 0.5), (18, 3, NEAR, 0.5)],
}
TAIL = swayed([
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
], (0, 1, 0, -1))
MANE = swayed([
    "..R....R..",
    ".RyR..RyR.",
    ".RyyRRyyR.",
    "RyYyyyyYyR",
    "RyYYyyYYyR",
    "RFyYYYYyFR",
    ".RFFyyFFR.",
])
TAIL_AT = {"front": (22, 9), "lower": (0, 8), "side": (0, 8), "upper": (1, 10), "back": (10, 14)}
MANE_AT = {"front": (10, 9), "lower": (10, 11), "side": (12, 9), "upper": (10, 11), "back": (10, 9)}
TRAITS = [
    {"frames": MANE, "at": MANE_AT, "behind": ("front", "lower", "side", "upper", "back"), "follows": "head"},
    {"frames": TAIL, "at": TAIL_AT, "behind": ("front", "lower", "side")},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 25, TRAITS))
