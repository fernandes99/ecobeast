"""Arbornix: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,80 m, ele tem 30 pixels de altura pela regra do mapa (creature-scale): o desenho de 26
cresce pelo `stretched`, na cabeça, no peito, nas asas e nas pernas. É uma fênix de folhas em pé, em duas pernas escuras
de garras, com os chifres dourados, a cabeça verde-azulada de olhos verdes, a garganta e o
peito creme, o bico claro, as asas de folhas erguidas, de pontas creme e com um losango
claro que brilha, que batem devagar, e a cauda longa, sempre atrás do corpo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, stretched, swayed  # noqa: E402

PALETTE = {
    "K": (0, 40, 40),      # contorno
    "G": (16, 128, 88),    # folha
    "g": (0, 80, 72),      # folha na sombra
    "L": (120, 192, 56),   # folha clara
    "l": (48, 152, 64),    # folha clara na sombra
    "H": (232, 228, 168),  # ponta creme das penas
    "Y": (240, 224, 160),  # creme
    "y": (200, 184, 120),  # creme na sombra
    "E": (16, 56, 40),     # olho
    "C": (184, 224, 72),   # olho verde
    "B": (232, 200, 96),   # bico
    "A": (232, 184, 48),   # chifre dourado
    "a": (184, 128, 32),   # chifre na sombra
    "D": (144, 248, 216),  # losango que brilha
    "F": (24, 48, 56),     # pernas
    "f": (16, 32, 40),     # pernas na sombra
}


def mirror(drawing):
    return [row[::-1] for row in drawing]


HEAD_FRONT = stretched([
    "..KKKKK..",
    ".KGGGGGK.",
    "KGGGGGGGK",
    "KGECGECGK",
    "KYYYBYYYK",
    ".KYYBBYK.",
    "..KYYYK..",
], rows=(2,))
HEAD_LOWER = stretched([
    "..KKKKK...",
    ".KGGGGGK..",
    "KGGGGGGGK.",
    "KGECGGECK.",
    "KYYYYYYBBK",
    ".KYYYYKBBK",
    "..KYYYK.K.",
], rows=(2,))
HEAD_SIDE = stretched([
    "..KKKK....",
    ".KGGGGK...",
    "KGGGGGGK..",
    "KGGGGECKK.",
    "KGYYYYYBBK",
    ".KYYYYKBBK",
    "..KYYYK.K.",
], rows=(2,))
HEAD_BACK = stretched([
    "..KKKKK..",
    ".KGGGGGK.",
    "KGGGGGGGK",
    "KGGgGgGGK",
    "KgGGGGGgK",
    ".KgGGGgK.",
    "..KgGgK..",
], rows=(2,))
HEADS = {
    "front": (HEAD_FRONT, 12, 5),
    "lower": (HEAD_LOWER, 13, 5),
    "side": (HEAD_SIDE, 15, 5),
    "upper": (recolored(HEAD_LOWER, "EC", "GG"), 13, 5),
    "back": (HEAD_BACK, 12, 5),
}
BODY_FRONT = stretched([
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
], rows=(6,))
BODY_LOWER = stretched([
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
], rows=(6,))
BODY_SIDE = stretched([
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
], rows=(6,))
BODY_UPPER = stretched([
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
], rows=(6,))
BODY_BACK = stretched([
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
], rows=(6,))
BODIES = {
    "front": (BODY_FRONT, 10, 12),
    "lower": (BODY_LOWER, 10, 12),
    "side": (BODY_SIDE, 9, 12),
    "upper": (BODY_UPPER, 10, 12),
    "back": (BODY_BACK, 10, 12),
}
NEAR = stretched(["KFK", "KFK", "KFK", "KFFK", "FKFF"], rows=(1, 2))
FAR = stretched(["KfK", "KfK", "KfK", "KffK", "fKff"], rows=(1, 2))
LEGS = {
    "front": [(12, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(12, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(16, 3, FAR, 1), (13, 0, NEAR, 1)],
    "lower": [(15, 3, FAR, 0.5), (12, 0, NEAR, 0.5)],
    "upper": [(15, 3, FAR, 0.5), (12, 0, NEAR, 0.5)],
}
WING = stretched([
    "KK.....",
    "KHK....",
    "KHLK...",
    "KHLLK..",
    "KHLDLK.",
    ".KHDGLK",
    ".KHLlGK",
    "..KHLlK",
    "..KHLGK",
    "...KLlK",
    "...KlgK",
    "....KK.",
], rows=(6,))
WING_SIDE = stretched([
    "KK.......",
    "KHKK.....",
    "KHHLKK...",
    ".KHLLLK..",
    ".KHLDLLK.",
    "..KHDGLLK",
    "..KHLLGLK",
    "...KHLGLK",
    "...KHLlGK",
    "....KLlgK",
    ".....KKK.",
], rows=(5,))
LEFT_WING = swayed(WING, (0, -1, -2, -1))
RIGHT_WING = [mirror(frame) for frame in LEFT_WING]
SIDE_WING = swayed(WING_SIDE, (0, -1, -2, -1))
CREST = swayed([
    "A.A.A.A",
    ".Aa.aA.",
    "..A.A..",
    "..a.a..",
], (0, 0, 1, 0))
CREST_SIDE = swayed([
    "AA.A.....",
    ".AaA.A...",
    "...AaA...",
    "....aA...",
], (0, -1, -1, 0))
TAIL_SIDE = [
    "........KK..",
    "......KKLGK.",
    "....KKLLGLK.",
    "..KKHLLGLLK.",
    ".KHHLLGLLK..",
    "KHHLDGGLK...",
    "KHLLGLLK....",
    ".KHLLLK.....",
    "..KKKK......",
]
TAIL_LOWER = [
    "......KK...",
    "....KKLGK..",
    "..KKHLGLK..",
    ".KHHLGLLK..",
    "KHHLDGLK...",
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
    "KHHLDLDLHHK",
    "KHHHKHKHHHK",
    ".KKK.K.KKK.",
]
TAIL_FRAMES = {
    "side": swayed(TAIL_SIDE, (0, 0, 1, 0)),
    "lower": swayed(TAIL_LOWER, (0, 0, 1, 0)),
    "upper": swayed(TAIL_UPPER, (0, 0, 1, 0)),
    "back": swayed(TAIL_BACK, (0, 0, 1, 0)),
}
TAIL_AT = {"side": (0, 16), "lower": (2, 17), "upper": (3, 17), "back": (10, 18)}
LEFT_WING_AT = {"front": (3, 6), "back": (3, 6), "lower": (3, 6), "upper": (3, 6)}
RIGHT_WING_AT = {"front": (19, 6), "back": (19, 6), "lower": (19, 6), "upper": (19, 6)}
SIDE_WING_AT = {"side": (7, 4)}
CREST_AT = {"front": (12, 2), "back": (12, 2), "lower": (13, 2), "upper": (13, 2)}
CREST_SIDE_AT = {"side": (11, 2)}
TRAITS = [
    {"frames": TAIL_FRAMES, "at": TAIL_AT, "behind": ("lower", "side")},
    {"frames": CREST, "at": CREST_AT, "follows": "head"},
    {"frames": CREST_SIDE, "at": CREST_SIDE_AT, "follows": "head"},
    {"frames": LEFT_WING, "at": LEFT_WING_AT, "follows": "body"},
    {"frames": RIGHT_WING, "at": RIGHT_WING_AT, "follows": "body"},
    {"frames": SIDE_WING, "at": SIDE_WING_AT, "follows": "body"},
]

if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, rig(HEADS, BODIES, LEGS, 25, TRAITS))
