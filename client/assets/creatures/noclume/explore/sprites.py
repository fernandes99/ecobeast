"""Noclume: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,50 m, ele tem 26 pixels de altura pela regra do mapa (creature-scale). Parte do
esqueleto do Galecrest, outra ave em pé de 26 pixels: duas pernas douradas, a cabeça
roxo-escura com o disco claro do rosto, os olhos dourados e a lua na testa, as orelhas de
pena em volta da lua, o peito creme com as listras roxas, as asas roxas de pontas lavanda,
com as pintas e a lua clara, e a cauda longa de penas, sempre atrás do corpo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, stretched, swayed  # noqa: E402

PALETTE = {
    "K": (24, 18, 52),     # contorno
    "T": (62, 46, 118),    # roxo
    "D": (40, 30, 84),     # roxo na sombra
    "t": (110, 86, 184),   # roxo claro
    "W": (240, 228, 216),  # creme
    "S": (196, 180, 200),  # creme na sombra
    "G": (164, 144, 224),  # ponta das penas
    "O": (232, 168, 52),   # bico e pernas
    "o": (168, 108, 32),   # bico e pernas na sombra
    "E": (20, 16, 36),     # pupila
    "R": (240, 180, 48),   # olho
    "M": (246, 226, 150),  # lua
}


def flared(drawing, amounts):
    """Como `swayed`, com o topo preso e a base deslocada: a asa abre pela ponta."""
    return [frame[::-1] for frame in swayed(drawing[::-1], amounts)]


def mirror(drawing):
    return [row[::-1] for row in drawing]


HEAD_FRONT = stretched([
    "..KKKKK..",
    ".KTTMTTK.",
    "KTTTTTTTK",
    "KTWWTWWTK",
    "KWRRWRRWK",
    ".KREOERK.",
    "..KWWWK..",
], rows=(2,))
HEAD_LOWER = stretched([
    "..KKKKK...",
    ".KTTTMTK..",
    "KTTTTTTTK.",
    "KTTWWTWWK.",
    "KTWRRWRRK.",
    ".KWREWREOK",
    "..KWWWWKK.",
], rows=(2,))
HEAD_SIDE = stretched([
    "..KKKK....",
    ".KTTMTK...",
    "KTTTTTTK..",
    "KTTTWWWK..",
    "KTTWRRWKK.",
    ".KTWREWOK.",
    "..KWWWKK..",
], rows=(2,))
HEAD_BACK = stretched([
    "..KKKKK..",
    ".KTTtTTK.",
    "KTTTTTTTK",
    "KTTTTTTTK",
    "KDTTTTTDK",
    ".KDTTTDK.",
    "..KDTDK..",
], rows=(2,))
HEADS = {
    "front": (HEAD_FRONT, 12, 8),
    "lower": (HEAD_LOWER, 13, 8),
    "side": (HEAD_SIDE, 15, 8),
    "upper": (recolored(HEAD_LOWER, "ECRWOoM", "TTTTKKT"), 13, 8),
    "back": (HEAD_BACK, 12, 8),
}
BODY_FRONT = stretched([
    "...KWWWWWK...",
    "..KWWWWWWWK..",
    ".KTWWWWWWWTK.",
    ".KTTWWWWWTTK.",
    ".KWTTWWWTTWK.",
    ".KWWTTWTTWWK.",
    ".KWWWTTTWWWK.",
    ".KSWWWTWWWSK.",
    ".KSWWSWSWWSK.",
    "..KSSWWWSSK..",
    "...KKSSSKK...",
], rows=(4,))
BODY_LOWER = stretched([
    "....KWWWWWK..",
    "...KWWWWWWWK.",
    "..KTTWWWWTWK.",
    "..KTTTWWTTWK.",
    ".KTTTTTTTWWK.",
    ".KTTTWTTTWWK.",
    ".KTTWWWTWWWK.",
    ".KTSWWWWWWSK.",
    ".KSSWWSWWWSK.",
    "..KSSWWWWSK..",
    "...KKSSSKK...",
], rows=(4,))
BODY_SIDE = stretched([
    "......KWWWK..",
    ".....KTWWWWK.",
    "....KTTWWTWK.",
    "...KTTTWWWTWK",
    "..KTTTTWTWWWK",
    ".KTTTTTWWTWWK",
    ".KTTTTTWWWWWK",
    ".KDTTTTSWWWSK",
    "..KDTTSSWWWSK",
    "...KDSSWWSSK.",
    "....KKSSSKK..",
], rows=(4,))
BODY_UPPER = stretched([
    "....KTTTTTK..",
    "...KTTTTTTTK.",
    "..KTTTTTTTTK.",
    "..KTTTtTTTTK.",
    ".KTTTTTTTTTK.",
    ".KTTTtTTTTTK.",
    ".KDTTTTTTTDK.",
    ".KDTTTTTTTDK.",
    ".KDDTTTTTDDK.",
    "..KDDTTTDDK..",
    "...KKDDDKK...",
], rows=(4,))
BODY_BACK = stretched([
    "...KTTTTTK...",
    "..KTTTTTTTK..",
    ".KTTTTtTTTTK.",
    ".KTTTTTTTTTK.",
    ".KTTTtTtTTTK.",
    ".KTTTTTTTTTK.",
    ".KDTTTTTTTDK.",
    ".KDTTTTTTTDK.",
    ".KDDTTTTTDDK.",
    "..KDDTTTDDK..",
    "...KKDDDKK...",
], rows=(4,))
BODIES = {
    "front": (BODY_FRONT, 10, 14),
    "lower": (BODY_LOWER, 10, 14),
    "side": (BODY_SIDE, 9, 14),
    "upper": (BODY_UPPER, 10, 14),
    "back": (BODY_BACK, 10, 14),
}
NEAR = stretched(["KOK", "KOK", "KOK", "KOOK", "OOOO"], rows=(1, 2))
FAR = stretched(["KoK", "KoK", "KoK", "KooK", "oooo"], rows=(1, 2))
LEGS = {
    "front": [(12, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(12, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(16, 3, FAR, 1), (13, 0, NEAR, 1)],
    "lower": [(15, 3, FAR, 0.5), (12, 0, NEAR, 0.5)],
    "upper": [(15, 3, FAR, 0.5), (12, 0, NEAR, 0.5)],
}
WING = stretched([
    ".KK.",
    "KTTK",
    "KTTK",
    "KTWK",
    "KTGK",
    "KWGK",
    "KTGK",
    "KDGK",
    ".KGK",
    "..K.",
], rows=(4,))
WING_SIDE = stretched([
    "..KKK....",
    ".KTTTKK..",
    "KTTTTMTK.",
    "KTtTMTTTK",
    "KDTTTMTTK",
    ".KGDTTTK.",
    "..KGGDK..",
    "...KGGGK.",
    "....KKGK.",
    "......KK.",
], rows=(3,))
LEFT_WING = flared(WING, (0, -1, -2, -1))
RIGHT_WING = [mirror(frame) for frame in LEFT_WING]
SIDE_WING = flared(mirror(WING_SIDE), (0, 1, 1, 0))
CREST = swayed([
    "KK.....KK",
    "KTK.M.KTK",
    "KTTKMKTTK",
], (0, 0, 1, 0))
CREST_SIDE = swayed([
    "KK.....",
    "KTK.M..",
    "KTTKMK.",
], (0, -1, -1, 0))
TAIL = swayed([
    "..KKK.......KKK..",
    ".KGTTK.....KTTGK.",
    "KGWTDK.....KDTWGK",
    "KGTTK.......KTTGK",
    ".KKK.........KKK.",
], (0, 0, 0, 0))
TAIL_SIDE = [
    "........KK....",
    "......KKTWK...",
    "....KKTTWWK...",
    "..KKGTTWTTK...",
    ".KGGTTWWTK....",
    "KGGTTWTTK.....",
    "KGTTWTTK......",
    ".KKKKKK.......",
]
TAIL_BACK = [
    "...KKKKK...",
    "..KDTTTDK..",
    "..KTTtTTK..",
    ".KTTDTDTTK.",
    ".KTtDTDtTK.",
    "KGTTDTDTTGK",
    "KGGGKGKGGGK",
    ".KKK.K.KKK.",
]
TAIL_LOWER = [
    ".......KK....",
    ".....KKTWK...",
    "...KKTTWWK...",
    "..KGTTWTTK...",
    ".KGTTWWTK....",
    "KGGTWTTK.....",
    ".KKKKKK......",
]
TAIL_UPPER = [
    "......KKKK...",
    "....KKTWTK...",
    "...KTTWWTK...",
    "..KTTWTWK....",
    ".KGTWTWTK....",
    "KGGTWTTK.....",
    "KGGGGGK......",
    ".KKKKK.......",
]
TAIL_FRAMES = {
    "front": TAIL,
    "side": swayed(TAIL_SIDE, (0, 0, 1, 0)),
    "lower": swayed(TAIL_LOWER, (0, 0, 1, 0)),
    "upper": swayed(TAIL_UPPER, (0, 0, 1, 0)),
    "back": swayed(TAIL_BACK, (0, 0, 1, 0)),
}
TAIL_AT = {"front": (8, 23), "side": (1, 20), "lower": (2, 21), "upper": (3, 20), "back": (9, 21)}
LEFT_WING_AT = {"front": (6, 15), "back": (6, 15), "lower": (7, 15)}
RIGHT_WING_AT = {"front": (19, 15), "back": (19, 15), "upper": (19, 15)}
SIDE_WING_AT = {"side": (9, 15), "lower": (10, 15), "upper": (8, 15)}
CREST_AT = {"front": (12, 6), "back": (12, 6), "lower": (12, 6), "upper": (12, 6)}
CREST_SIDE_AT = {"side": (15, 6)}
TRAITS = [
    {"frames": TAIL_FRAMES, "at": TAIL_AT, "behind": ("front", "lower", "side")},
    {"frames": CREST, "at": CREST_AT, "follows": "head"},
    {"frames": CREST_SIDE, "at": CREST_SIDE_AT, "follows": "head"},
    {"frames": LEFT_WING, "at": LEFT_WING_AT, "follows": "body"},
    {"frames": RIGHT_WING, "at": RIGHT_WING_AT, "follows": "body"},
    {"frames": SIDE_WING, "at": SIDE_WING_AT, "follows": "body"},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 25, TRAITS))
