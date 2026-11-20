"""Owlume: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,90 m, ele tem 17 pixels de altura pela regra do mapa (creature-scale). É a coruja do
meio da linha, mais esguia que o Lume e menor que o Noclume, com as cores dos dois: a
cabeça roxo-escura com as orelhas de pena, a lua na testa, o disco claro do rosto e os olhos
dourados, o peito creme, as asas roxas de pontas lavanda com as pintas claras, meio abertas
e batendo no idle e no andar, a cauda curta em leque e as garras douradas.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, swayed  # noqa: E402

PALETTE = {
    "K": (24, 18, 52),     # contorno
    "T": (62, 46, 118),    # roxo
    "D": (40, 30, 84),     # roxo na sombra
    "t": (110, 86, 184),   # roxo claro
    "W": (240, 228, 216),  # creme
    "S": (196, 180, 200),  # creme na sombra
    "G": (164, 144, 224),  # ponta das penas
    "O": (232, 168, 52),   # bico e garras
    "o": (168, 108, 32),   # garras na sombra
    "E": (20, 16, 36),     # pupila
    "R": (240, 180, 48),   # olho
    "M": (246, 226, 150),  # lua
}


def flared(drawing, amounts):
    """Como `swayed`, com o topo preso e a base deslocada: a asa abre pela ponta."""
    return [frame[::-1] for frame in swayed(drawing[::-1], amounts)]


def mirror(drawing):
    return [row[::-1] for row in drawing]


HEAD_FRONT = [
    "KK.....KK",
    "KTKKKKKTK",
    "KTTTMTTTK",
    "KTWWTWWTK",
    "KWRRWRRWK",
    ".KREOERK.",
    "..KWWWK..",
]
HEAD_LOWER = [
    ".KK....KK",
    ".KTKKKKTK",
    "KTTTTMTTK",
    "KTTWWTWWK",
    "KTWRRWRRK",
    ".KWREWREK",
    "..KWWWOK.",
]
HEAD_SIDE = [
    "...KK....",
    "..KTKKK..",
    ".KTTTMTK.",
    "KTTTTWWK.",
    "KTTTWRRK.",
    ".KTTWREOK",
    "..KKWWKK.",
]
HEAD_BACK = [
    "KK.....KK",
    "KTKKKKKTK",
    "KTTTtTTTK",
    "KTTTTTTTK",
    "KTTTTTTTK",
    ".KDTTTDK.",
    "..KDTDK..",
]
HEADS = {
    "front": (HEAD_FRONT, 12, 15),
    "lower": (HEAD_LOWER, 12, 15),
    "side": (HEAD_SIDE, 13, 15),
    "upper": (recolored(HEAD_LOWER, "ERWOM", "TTTKT"), 12, 15),
    "back": (HEAD_BACK, 12, 15),
}
BODY_FRONT = [
    "..KWWWWWK..",
    ".KTWWWWWTK.",
    ".KTTWWWTTK.",
    ".KWTTWTTWK.",
    ".KWWTTTWWK.",
    ".KSWWTWWSK.",
    "..KSSWSSK..",
    "...KKKKK...",
]
BODY_LOWER = [
    "...KWWWWK..",
    "..KTTWWWWK.",
    ".KTTTWWTWK.",
    ".KTTTTWWWK.",
    ".KTTTWTWWK.",
    ".KDTTSWWSK.",
    "..KDDSSSK..",
    "...KKKKK...",
]
BODY_SIDE = [
    "....KWWK...",
    "...KTWWWK..",
    "..KTTWWTWK.",
    ".KTTTTWWWK.",
    ".KTTTTWTWK.",
    ".KDTTTSWSK.",
    "..KDDSSSK..",
    "...KKKKK...",
]
BODY_BACK = [
    "..KTTTTTK..",
    ".KTTTtTTTK.",
    ".KTTTTTTTK.",
    ".KTTtTtTTK.",
    ".KDTTTTTDK.",
    ".KDTTTTTDK.",
    "..KDDTDDK..",
    "...KKKKK...",
]
BODIES = {
    "front": (BODY_FRONT, 11, 21),
    "lower": (BODY_LOWER, 11, 21),
    "side": (BODY_SIDE, 11, 21),
    "upper": (BODY_BACK, 11, 21),
    "back": (BODY_BACK, 11, 21),
}
NEAR = ["KOK", "KOOK", "OOOO"]
FAR = ["KoK", "KooK", "oooo"]
LEGS = {
    "front": [(13, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(13, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(16, 3, FAR, 1), (13, 0, NEAR, 1)],
    "lower": [(16, 3, FAR, 0.5), (13, 0, NEAR, 0.5)],
    "upper": [(16, 3, FAR, 0.5), (13, 0, NEAR, 0.5)],
}
WING = [
    ".KKK",
    "KTTK",
    "KTWK",
    "KTGK",
    "KWGK",
    "KTGK",
    ".KGK",
    "..K.",
]
WING_SIDE = [
    "..KKK...",
    ".KTTTKK.",
    "KTTWTTTK",
    "KTtTTWTK",
    "KDTWTTTK",
    ".KGDTTK.",
    "..KGGGK.",
    "...KKKK.",
]
LEFT_WING = flared(WING, (0, -1, -2, -1))
RIGHT_WING = [mirror(frame) for frame in LEFT_WING]
SIDE_WING = flared(mirror(WING_SIDE), (0, 1, 1, 0))
TAIL = [
    ".KKKKK.",
    "KGTDTGK",
    "KGGKGGK",
    ".K...K.",
]
TAIL_SIDE = [
    "..KKK",
    ".KTTK",
    "KGTK.",
    "KGGK.",
    ".KK..",
]
TAIL_FRAMES = {
    "front": swayed(TAIL, (0, 0, 0, 0)),
    "back": swayed(TAIL, (0, 0, 1, 0)),
    "side": swayed(TAIL_SIDE, (0, 0, 1, 0)),
    "lower": swayed(TAIL_SIDE, (0, 0, 1, 0)),
    "upper": swayed(TAIL_SIDE, (0, 0, 1, 0)),
}
TAIL_AT = {"front": (13, 26), "back": (13, 26), "side": (8, 24), "lower": (8, 24), "upper": (8, 24)}
LEFT_WING_AT = {"front": (8, 21), "back": (8, 21), "lower": (9, 21)}
RIGHT_WING_AT = {"front": (18, 21), "back": (18, 21), "upper": (18, 21)}
SIDE_WING_AT = {"side": (10, 21), "lower": (11, 21), "upper": (10, 21)}
TRAITS = [
    {"frames": TAIL_FRAMES, "at": TAIL_AT, "behind": ("front", "lower", "side")},
    {"frames": LEFT_WING, "at": LEFT_WING_AT, "follows": "body"},
    {"frames": RIGHT_WING, "at": RIGHT_WING_AT, "follows": "body"},
    {"frames": SIDE_WING, "at": SIDE_WING_AT, "follows": "body"},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 29, TRAITS, idle_head=(0, 1, 1, 0), idle_body=(0, 0, 1, 0)))
