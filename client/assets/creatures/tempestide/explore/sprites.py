"""Tempestide: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 2,00 m, ele tem 32 pixels de altura, o máximo da regra do mapa (creature-scale): o desenho
de 29 cresce pelo `stretched`, nos olhos, no peito e no tronco, e ocupa a célula inteira.
Nada sobe acima da primeira linha: o balanço do idle desce. É um dragão-marinho enorme em pé, em S: os chifres
dourados em galho, a cabeça verde-azulada com o focinho amarelo, o pescoço e a barriga
creme, as veias douradas, os cristais azuis, os véus de folha dos lados e das costas, que
balançam, e a cauda enrolada no chão. Sem patas, ele flutua: a parte de cima balança, a
cauda empurra no walk, e os raios estalam em volta, de um lado e do outro.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import VIEWS, build, recolored, rig, stretched, swayed  # noqa: E402

PALETTE = {
    "K": (8, 56, 56),      # contorno
    "G": (24, 144, 104),   # verde-azulado
    "g": (0, 96, 88),      # verde-azulado na sombra
    "L": (160, 208, 56),   # folha
    "l": (72, 168, 72),    # folha na sombra
    "Y": (240, 220, 150),  # barriga creme
    "y": (208, 184, 112),  # creme na sombra
    "A": (232, 184, 40),   # chifre e veia dourada
    "E": (16, 40, 48),     # olho
    "B": (232, 196, 72),   # focinho
    "S": (120, 208, 248),  # cristal
    "s": (200, 244, 255),  # faísca
    "Z": (48, 160, 240),   # raio
}

FRONT = stretched([
    "...A.A...A.A...",
    "....AA...AA....",
    ".....AL.LA.....",
    "....LLKKKLL....",
    "...LGKGGGKGL...",
    "....KGEGEGK....",
    "....KGYBYGK....",
    ".....KYBYK.....",
    ".....KYYYK.....",
    "....KSGYGSK....",
    "...KSGYYYGSK...",
    "...KGAYYYAGK...",
    "...KGGYYYGGK...",
    "...KGAYYYAGK...",
    "...KgGYYYGgK...",
    "....KgYYYgK....",
    "....KgGYGgK....",
    "....KgGYGgK....",
    ".....KgYgK.....",
    ".....KgYgK.....",
    ".....KgGgK.....",
    ".....KgGgK.....",
    "......KgK......",
    "......KgK......",
    "......KgK......",
], rows=(5, 12, 17))
BACK = stretched([
    "...A.A...A.A...",
    "....AA...AA....",
    ".....AL.LA.....",
    "....LLKKKLL....",
    "...LGKGGGKGL...",
    "....KGGgGGK....",
    "....KGGGGGK....",
    ".....KGSGK.....",
    ".....KGSGK.....",
    "....KGGSGGK....",
    "...KSGGSGGSK...",
    "...KGAGSGAGK...",
    "...KGGGSGGGK...",
    "...KGAGgGAGK...",
    "...KgGGGGGgK...",
    "....KgGGGgK....",
    "....KgGGGgK....",
    "....KgGgGgK....",
    ".....KgGgK.....",
    ".....KgGgK.....",
    ".....KgGgK.....",
    ".....KgGgK.....",
    "......KgK......",
    "......KgK......",
    "......KgK......",
], rows=(5, 12, 17))
SIDE = stretched([
    "........A..A......",
    ".......AA.AA......",
    "........AAA.A.....",
    ".......LLAALL.....",
    "......LGKKKKGL....",
    ".....LGKGGGGK.....",
    "......KGGGGEYK....",
    "......KGGGYYYBBK..",
    ".......KGGYYYKKK..",
    ".......KGGYYK.....",
    "......KSGGYYK.....",
    "......KSGGYYYK....",
    ".....KSGGGAYYK....",
    ".....KSGGAGYYYK...",
    "....KSGGGGAYYYK...",
    "....KGGAGGGYYYK...",
    "....KGGGAGGYYYK...",
    "....KgGGGAGYYK....",
    ".....KgGGGYYYK....",
    ".....KgGGGYYK.....",
    "......KgGGYYK.....",
    "......KgGGYK......",
    ".......KgGYK......",
    ".......KgGGK......",
    ".......KgGGK......",
], rows=(5, 12, 17))
HEADS = {
    "front": (FRONT, 9, 0),
    "lower": (SIDE, 6, 0),
    "side": (SIDE, 7, 0),
    "upper": (recolored(SIDE, "YyE", "GgG"), 6, 0),
    "back": (BACK, 9, 0),
}
CURL = ["KgGGK....", "KgKKggK..", "KgKKgGgK.", ".KgggggK."]
PUSH = [".KgGGK...", "KgKKgK...", "KgKgK....", "KgggK...."]
LOOP = [".KgK.", "KgKgK", "KgKgK", ".KgK."]
TAIL = {
    "front": [LOOP] * 4,
    "lower": [CURL, CURL, PUSH, CURL],
    "side": [CURL, CURL, PUSH, CURL],
    "upper": [CURL, CURL, PUSH, CURL],
    "back": [LOOP] * 4,
}
TAIL_AT = {"front": (14, 28), "lower": (12, 28), "side": (13, 28), "upper": (12, 28), "back": (14, 28)}
VEIL = [
    ".....L",
    "....LG",
    "...LGl",
    "..LGGl",
    ".LGlGl",
    "LGlLGl",
    "LGlGl.",
    ".LGGl.",
    ".LGl..",
    "..LGl.",
    "...Ll.",
    "....L.",
]
LEFT_VEIL = swayed(VEIL, (0, -1, 0, 1))
RIGHT_VEIL = [[row[::-1] for row in frame] for frame in swayed(VEIL, (0, 1, 0, -1))]
LEFT_VEIL_AT = {"front": (6, 10), "back": (6, 10), "lower": (5, 11)}
RIGHT_VEIL_AT = {"front": (19, 10), "back": (19, 10)}
DORSAL = swayed([
    "....LL.",
    "...LGl.",
    "..LGGl.",
    ".LGlGl.",
    "LGlLGl.",
    "LGlGGl.",
    ".LGGlGl",
    ".LGlGl.",
    "..LGGl.",
    "...LGl.",
    "..LGl..",
    ".LGl...",
    "..Ll...",
], (0, -1, 0, 1))
DORSAL_AT = {"side": (4, 10), "upper": (3, 10), "lower": (3, 10)}
BOLT = ["..Z", ".Zs", "Z..", ".Z.", "Z.."]
SMALL = [".s", "Z.", ".Z"]
NONE = ["."]
RIGHT_BOLT = [BOLT, NONE, SMALL, NONE]
LEFT_BOLT = [NONE, [row[::-1] for row in BOLT], NONE, [row[::-1] for row in SMALL]]
RIGHT_BOLT_AT = {view: (25, 7) for view in VIEWS}
LEFT_BOLT_AT = {view: (4, 6) for view in VIEWS}
TRAITS = [
    {"frames": TAIL, "at": TAIL_AT, "behind": VIEWS, "walk": (0, 2, 2, 0, 2, 2)},
    {"frames": DORSAL, "at": DORSAL_AT, "follows": "head", "behind": VIEWS, "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": LEFT_VEIL, "at": LEFT_VEIL_AT, "follows": "head", "behind": VIEWS, "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": RIGHT_VEIL, "at": RIGHT_VEIL_AT, "follows": "head", "behind": VIEWS, "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": RIGHT_BOLT, "at": RIGHT_BOLT_AT, "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": LEFT_BOLT, "at": LEFT_BOLT_AT, "walk": (0, 1, 2, 3, 0, 1)},
]
NO_LEGS = {view: [] for view in VIEWS}

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, NO_LEGS, 31, TRAITS, idle_head=(0, 1, 1, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 1, 1, 0, 1, 1), walk_body=(0, 0, 0, 0, 0, 0)),
    )
