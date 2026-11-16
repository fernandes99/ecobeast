"""Galecrest: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,50 m, ele tem 22 pixels de altura. É uma ave em pé, em duas pernas laranja, com a
cabeça verde-azulada, o bico laranja, a crista branca, o peito branco com as listras
verde-azuladas, as asas verde-azuladas de pontas claras junto ao corpo, que se abrem um
pouco no idle e no andar, e a cauda longa listrada, sempre atrás do corpo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, swayed  # noqa: E402

PALETTE = {
    "K": (14, 40, 52),     # contorno
    "T": (24, 112, 124),   # verde-azulado
    "D": (12, 78, 92),     # verde-azulado na sombra
    "t": (88, 160, 168),   # verde-azulado claro
    "W": (236, 246, 246),  # branco
    "S": (172, 196, 206),  # branco na sombra
    "G": (128, 156, 180),  # ponta das penas
    "O": (236, 128, 40),   # bico e pernas
    "o": (172, 82, 24),    # bico e pernas na sombra
    "E": (20, 20, 30),     # olho
    "R": (232, 120, 40),   # íris
    "C": (255, 255, 255),  # brilho do olho
}


def flared(drawing, amounts):
    """Como `swayed`, com o topo preso e a base deslocada: a asa abre pela ponta."""
    return [frame[::-1] for frame in swayed(drawing[::-1], amounts)]


def mirror(drawing):
    return [row[::-1] for row in drawing]


HEAD_FRONT = [
    "..KKKKK..",
    ".KTTtTTK.",
    "KTTTTTTTK",
    "KTECTECTK",
    "KWRETERWK",
    ".KWWOWWK.",
    "..KWoWK..",
]
HEAD_LOWER = [
    "..KKKKK...",
    ".KTTTtTK..",
    "KTTTTTTTK.",
    "KTTECTECK.",
    "KTWRETERKK",
    ".KWWWWWOoK",
    "..KWWWWKK.",
]
HEAD_SIDE = [
    "..KKKK....",
    ".KTTtTK...",
    "KTTTTTTK..",
    "KTTTTECK..",
    "KTTTWERTKK",
    ".KTWWWWOOK",
    "..KWWWKoK.",
]
HEAD_BACK = [
    "..KKKKK..",
    ".KTTtTTK.",
    "KTTTTTTTK",
    "KTTTTTTTK",
    "KDTTTTTDK",
    ".KDTTTDK.",
    "..KDTDK..",
]
HEADS = {
    "front": (HEAD_FRONT, 12, 12),
    "lower": (HEAD_LOWER, 13, 12),
    "side": (HEAD_SIDE, 15, 12),
    "upper": (recolored(HEAD_LOWER, "ECRWOo", "TTTTKK"), 13, 12),
    "back": (HEAD_BACK, 12, 12),
}
BODY_FRONT = [
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
]
BODY_LOWER = [
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
]
BODY_SIDE = [
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
]
BODY_UPPER = [
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
]
BODY_BACK = [
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
]
BODIES = {
    "front": (BODY_FRONT, 10, 17),
    "lower": (BODY_LOWER, 10, 17),
    "side": (BODY_SIDE, 9, 17),
    "upper": (BODY_UPPER, 10, 17),
    "back": (BODY_BACK, 10, 17),
}
NEAR = ["KOK", "KOK", "KOK", "KOOK", "OOOO"]
FAR = ["KoK", "KoK", "KoK", "KooK", "oooo"]
LEGS = {
    "front": [(12, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(12, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(16, 3, FAR, 1), (13, 0, NEAR, 1)],
    "lower": [(15, 3, FAR, 0.5), (12, 0, NEAR, 0.5)],
    "upper": [(15, 3, FAR, 0.5), (12, 0, NEAR, 0.5)],
}
WING = [
    ".KK.",
    "KTTK",
    "KTTK",
    "KTtK",
    "KTGK",
    "KTGK",
    "KTGK",
    "KDGK",
    ".KGK",
    "..K.",
]
WING_SIDE = [
    "..KKK....",
    ".KTTTKK..",
    "KTTTTTTK.",
    "KTtTTTTTK",
    "KDTTTTTTK",
    ".KGDTTTK.",
    "..KGGDK..",
    "...KGGGK.",
    "....KKGK.",
    "......KK.",
]
LEFT_WING = flared(WING, (0, -1, -2, -1))
RIGHT_WING = [mirror(frame) for frame in LEFT_WING]
SIDE_WING = flared(mirror(WING_SIDE), (0, 1, 1, 0))
CREST = swayed([
    "..KK.",
    ".KWWK",
    "KWtK.",
], (0, 0, 1, 0))
CREST_SIDE = swayed([
    "KKK....",
    "KWWKKK.",
    ".KKWWtK",
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
TAIL_AT = {"front": (8, 25), "side": (1, 22), "lower": (2, 23), "upper": (3, 22), "back": (9, 23)}
LEFT_WING_AT = {"front": (6, 18), "back": (6, 18), "lower": (7, 18)}
RIGHT_WING_AT = {"front": (19, 18), "back": (19, 18), "upper": (19, 18)}
SIDE_WING_AT = {"side": (9, 18), "lower": (10, 18), "upper": (8, 18)}
CREST_AT = {"front": (14, 10), "back": (14, 10), "lower": (15, 10), "upper": (15, 10)}
CREST_SIDE_AT = {"side": (13, 10)}
TRAITS = [
    {"frames": TAIL_FRAMES, "at": TAIL_AT, "behind": ("front", "lower", "side")},
    {"frames": CREST, "at": CREST_AT, "follows": "head"},
    {"frames": CREST_SIDE, "at": CREST_SIDE_AT, "follows": "head"},
    {"frames": LEFT_WING, "at": LEFT_WING_AT, "follows": "body"},
    {"frames": RIGHT_WING, "at": RIGHT_WING_AT, "follows": "body"},
    {"frames": SIDE_WING, "at": SIDE_WING_AT, "follows": "body"},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 27, TRAITS))
