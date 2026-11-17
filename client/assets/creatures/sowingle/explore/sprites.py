"""Sowingle: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,80 m, ele tem 26 pixels de altura. É uma ave grande em pé, em duas pernas escuras de
garras verdes, com a crista de folhas jogada para trás, o rosto e o peito creme com o V
verde, a sobrancelha verde, o bico verde e curvo, as asas verde-limão erguidas, de pontas
claras, que batem devagar, e a cauda longa em leque, sempre atrás do corpo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, swayed  # noqa: E402

PALETTE = {
    "K": (24, 48, 24),     # contorno
    "G": (0, 144, 0),      # folha
    "g": (0, 96, 24),      # folha na sombra
    "L": (168, 192, 48),   # verde-limão
    "l": (120, 144, 24),   # verde-limão na sombra
    "H": (232, 232, 136),  # ponta clara das penas
    "Y": (240, 224, 150),  # creme
    "y": (200, 176, 96),   # creme na sombra
    "E": (24, 24, 24),     # olho
    "C": (255, 255, 255),  # brilho do olho
    "F": (56, 56, 48),     # pernas
    "f": (32, 32, 28),     # pernas na sombra
}


def mirror(drawing):
    return [row[::-1] for row in drawing]


HEAD_FRONT = [
    "..KKKKK..",
    ".KYYYYYK.",
    "KGGGYGGGK",
    "KYECYECYK",
    "KYYYGYYYK",
    ".KYYGGYK.",
    "..KYGYK..",
]
HEAD_LOWER = [
    "..KKKKK...",
    ".KYYYYYK..",
    "KGGGGGGGK.",
    "KYECYYECK.",
    "KYYYYYYGGK",
    ".KYYYYKGGK",
    "..KYYYK.K.",
]
HEAD_SIDE = [
    "..KKKK....",
    ".KYYYYK...",
    "KGGGGGGK..",
    "KYYYYECKK.",
    "KYYYYYYGGK",
    ".KYYYYKGGK",
    "..KYYYK.K.",
]
HEAD_BACK = [
    "..KKKKK..",
    ".KGGGGGK.",
    "KGGGGGGGK",
    "KYYYYYYYK",
    "KyYYYYYyK",
    ".KyYYYyK.",
    "..KyYyK..",
]
HEADS = {
    "front": (HEAD_FRONT, 12, 9),
    "lower": (HEAD_LOWER, 13, 9),
    "side": (HEAD_SIDE, 15, 9),
    "upper": (recolored(HEAD_LOWER, "EC", "YY"), 13, 9),
    "back": (HEAD_BACK, 12, 9),
}
BODY_FRONT = [
    "...KYYYYYK...",
    "..KYYYYYYYK..",
    ".KGGYYYYYGGK.",
    ".KLGGYYYGGLK.",
    ".KLLGGYGGLLK.",
    ".KLLLGYGLLLK.",
    ".KlLLYYYLLlK.",
    ".KlLYYYYYLlK.",
    ".KglYYYYYlgK.",
    "..KgyYYYygK..",
    "..KggyyyggK..",
    "...KKgggKK...",
]
BODY_LOWER = [
    "....KYYYYK...",
    "...KGYYYYYK..",
    "..KGGGYYYYGK.",
    ".KLLGGGYYGGK.",
    ".KLLLGGYGGLK.",
    ".KLLLLGYGLLK.",
    ".KlLLLYYYLLK.",
    ".KlLLYYYYYLK.",
    ".KglLYYYYylK.",
    "..KglyYYYyK..",
    "..KggyyyygK..",
    "...KKgggKK...",
]
BODY_SIDE = [
    "......KYYYK..",
    ".....KGYYYYK.",
    "....KGGYYYYK.",
    "...KLLGGYYYYK",
    "..KLLLLGYYYYK",
    ".KLLlLLLGYYYK",
    ".KLLLlLLLYYYK",
    ".KlLLLlLLyYYK",
    ".KglLLLLlyyYK",
    "..KgglLLlyyK.",
    "...KKgggyyK..",
    ".....KKKKK...",
]
BODY_UPPER = [
    "....KGGGGK...",
    "...KGGGGGGK..",
    "..KGGGGGGGGK.",
    "..KLGGGGGGLK.",
    ".KLLGGGGGLLK.",
    ".KLLLGGGLLLK.",
    ".KlLLLGLLLlK.",
    ".KlLLLGLLLlK.",
    ".KglLLGLLlgK.",
    "..KgglLlggK..",
    "..KKggggKK...",
    "....KKKK.....",
]
BODY_BACK = [
    "...KGGGGGK...",
    "..KGGGGGGGK..",
    ".KGGGGGGGGGK.",
    ".KLGGGGGGGLK.",
    ".KLLGGGGGLLK.",
    ".KLLLGGGLLLK.",
    ".KlLLLGLLLlK.",
    ".KlLLLGLLLlK.",
    ".KglLLGLLlgK.",
    "..KgglLlggK..",
    "..KKggggKK...",
    "....KKKK.....",
]
BODIES = {
    "front": (BODY_FRONT, 10, 15),
    "lower": (BODY_LOWER, 10, 15),
    "side": (BODY_SIDE, 9, 15),
    "upper": (BODY_UPPER, 10, 15),
    "back": (BODY_BACK, 10, 15),
}
NEAR = ["KFK", "KFK", "KFK", "KFFK", "GFGG"]
FAR = ["KfK", "KfK", "KfK", "KffK", "GfGG"]
LEGS = {
    "front": [(12, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(12, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(16, 3, FAR, 1), (13, 0, NEAR, 1)],
    "lower": [(15, 3, FAR, 0.5), (12, 0, NEAR, 0.5)],
    "upper": [(15, 3, FAR, 0.5), (12, 0, NEAR, 0.5)],
}
WING = [
    "KK.....",
    "KHK....",
    "KHLK...",
    "KHLLK..",
    "KHLGLK.",
    ".KHLGLK",
    ".KHLlGK",
    "..KHLlK",
    "..KHLGK",
    "...KLlK",
    "...KlgK",
    "....KK.",
]
WING_SIDE = [
    "KK.......",
    "KHKK.....",
    "KHHLKK...",
    ".KHLLLK..",
    ".KHLGLLK.",
    "..KHLGLLK",
    "..KHLLGLK",
    "...KHLGLK",
    "...KHLlGK",
    "....KLlgK",
    ".....KKK.",
]
LEFT_WING = swayed(WING, (0, -1, -2, -1))
RIGHT_WING = [mirror(frame) for frame in LEFT_WING]
SIDE_WING = swayed(WING_SIDE, (0, -1, -2, -1))
CREST = swayed([
    "L..G..L",
    "GL.L.LG",
    ".GLGLG.",
    "..GGG..",
], (0, 0, 1, 0))
CREST_SIDE = swayed([
    "LGG......",
    ".GLLGG...",
    "..GGLLGG.",
    "....GGGG.",
], (0, -1, -1, 0))
TAIL_SIDE = [
    "........KK..",
    "......KKLGK.",
    "....KKLLGLK.",
    "..KKHLLGLLK.",
    ".KHHLLGLLK..",
    "KHHLLGGLK...",
    "KHLLGLLK....",
    ".KHLLLK.....",
    "..KKKK......",
]
TAIL_LOWER = [
    "......KK...",
    "....KKLGK..",
    "..KKHLGLK..",
    ".KHHLGLLK..",
    "KHHLGGLK...",
    "KHLLGLK....",
    ".KKKKK.....",
]
TAIL_UPPER = [
    "......KKKK.",
    "....KKLGLK.",
    "...KHLGLLK.",
    "..KHLGLGK..",
    ".KHLGLGLK..",
    "KHHLGLLK...",
    "KHHHHHK....",
    ".KKKKK.....",
]
TAIL_BACK = [
    "...KKKKK...",
    "..KLLGLLK..",
    "..KLGLGLK..",
    ".KHLGLGLHK.",
    ".KHLGLGLHK.",
    "KHHLGLGLHHK",
    "KHHHKHKHHHK",
    ".KKK.K.KKK.",
]
TAIL_FRAMES = {
    "side": swayed(TAIL_SIDE, (0, 0, 1, 0)),
    "lower": swayed(TAIL_LOWER, (0, 0, 1, 0)),
    "upper": swayed(TAIL_UPPER, (0, 0, 1, 0)),
    "back": swayed(TAIL_BACK, (0, 0, 1, 0)),
}
TAIL_AT = {"side": (0, 19), "lower": (2, 20), "upper": (3, 20), "back": (10, 21)}
LEFT_WING_AT = {"front": (3, 9), "back": (3, 9), "lower": (3, 9), "upper": (3, 9)}
RIGHT_WING_AT = {"front": (19, 9), "back": (19, 9), "lower": (19, 9), "upper": (19, 9)}
SIDE_WING_AT = {"side": (7, 7)}
CREST_AT = {"front": (12, 6), "back": (12, 6), "lower": (13, 6), "upper": (13, 6)}
CREST_SIDE_AT = {"side": (11, 6)}
TRAITS = [
    {"frames": TAIL_FRAMES, "at": TAIL_AT, "behind": ("lower", "side")},
    {"frames": CREST, "at": CREST_AT, "follows": "head"},
    {"frames": CREST_SIDE, "at": CREST_SIDE_AT, "follows": "head"},
    {"frames": LEFT_WING, "at": LEFT_WING_AT, "follows": "body"},
    {"frames": RIGHT_WING, "at": RIGHT_WING_AT, "follows": "body"},
    {"frames": SIDE_WING, "at": SIDE_WING_AT, "follows": "body"},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 27, TRAITS))
