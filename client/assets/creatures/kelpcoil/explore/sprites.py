"""Kelpcoil: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,10 m, ele tem 20 pixels de altura pela regra do mapa (creature-scale): o desenho de 16
pixels cresce pelo `stretched`, com os olhos, o pescoço e o tronco mais altos. É um dragão-marinho esguio em pé: a crina de folhas,
a cabeça verde-azulada com o focinho amarelo, a barriga creme, as veias douradas, os cristais
azuis nas costas, as nadadeiras e as folhas das costas, que balançam, e a cauda enrolada no
chão. Sem patas, ele flutua: a parte de cima balança, a cauda empurra no walk, e os raios
piscam em volta da crina.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import VIEWS, build, rig, stretched, swayed  # noqa: E402

PALETTE = {
    "K": (8, 56, 56),      # contorno
    "G": (24, 144, 104),   # verde-azulado
    "g": (0, 96, 88),      # verde-azulado na sombra
    "L": (160, 208, 56),   # folha
    "l": (72, 168, 72),    # folha na sombra
    "Y": (240, 220, 150),  # barriga creme
    "y": (208, 184, 112),  # creme na sombra
    "A": (232, 184, 40),   # veia dourada
    "E": (16, 40, 48),     # olho
    "B": (232, 196, 72),   # focinho
    "S": (120, 208, 248),  # cristal
    "s": (200, 244, 255),  # faísca
    "Z": (48, 160, 240),   # raio
}

HEADS = {
    "front": (stretched([
        "...L.L.L...",
        "..LGLGLGL..",
        "...KGGGK...",
        "..KGEGEGK..",
        "..KGYBYGK..",
        "...KYBYK...",
        "...KYYYK...",
        "...KGYGK...",
        "...KGYGK...",
        "...KAYAK...",
        "...KGYGK...",
        "...KGYGK...",
        "...KgYgK...",
    ], rows=(3, 6, 8, 11)), 11, 12),
    "lower": (stretched([
        "...L.L.L....",
        "..LGLGLGL...",
        "...KGGGK....",
        "..KGEGGEK...",
        "..KGYYYBBK..",
        "...KYYYKK...",
        "...KYYYK....",
        "...KGYYYK...",
        "..KSGYYYK...",
        "..KGAGYYK...",
        "..KgGAYYK...",
        "...KgGYK....",
        "...KgGYK....",
    ], rows=(3, 6, 8, 11)), 10, 12),
    "side": (stretched([
        ".....L.L.L....",
        "....LGLGLGL...",
        ".....KGGGK....",
        "....KGGGEYK...",
        "....KGGYYYBBK.",
        ".....KGYYKKK..",
        ".....KGYYK....",
        "....KSGGYYK...",
        "...KSGGGYYK...",
        "...KGGAGYYK...",
        "...KgGGAYYK...",
        "....KgGGYK....",
        "....KgGGYK....",
    ], rows=(3, 6, 8, 11)), 9, 12),
    "upper": (stretched([
        "...L.L.L....",
        "..LGLGLGL...",
        "...KGGGK....",
        "..KGGGGGK...",
        "..KGGGGBBK..",
        "...KGGGKK...",
        "...KSGGK....",
        "...KSGGGK...",
        "..KSGGGGK...",
        "..KGAGGGK...",
        "..KgGAGGK...",
        "...KgGGK....",
        "...KgGGK....",
    ], rows=(3, 6, 8, 11)), 10, 12),
    "back": (stretched([
        "...L.L.L...",
        "..LGLGLGL..",
        "...KGGGK...",
        "..KGGgGGK..",
        "..KGGGGGK..",
        "...KGSGK...",
        "...KGSGK...",
        "...KgSgK...",
        "...KGSGK...",
        "...KAgAK...",
        "...KGGGK...",
        "...KgGgK...",
        "...KgGgK...",
    ], rows=(3, 6, 8, 11)), 11, 12),
}
CURL = ["KgGyK..", "KgK.KgK", ".KgggK."]
PUSH = [".KgGyK.", "KgK.KK.", "KggK..."]
CURL_BACK = ["KgGgK..", "KgK.KgK", ".KgggK."]
PUSH_BACK = [".KgGgK.", "KgK.KK.", "KggK..."]
LOOP = [".KgK.", "KgKgK", ".KgK."]
TAIL = {
    "front": [LOOP] * 4,
    "lower": [CURL, CURL, PUSH, CURL],
    "side": [CURL, CURL, PUSH, CURL],
    "upper": [CURL_BACK, CURL_BACK, PUSH_BACK, CURL_BACK],
    "back": [LOOP] * 4,
}
TAIL_AT = {"front": (14, 29), "lower": (13, 29), "side": (13, 29), "upper": (13, 29), "back": (14, 29)}
FIN = ["..L", ".LG", "LGl", ".LG", "..L"]
LEFT_FIN = swayed(FIN, (0, 1, 0, -1))
RIGHT_FIN = [[row[::-1] for row in frame] for frame in swayed(FIN, (0, -1, 0, 1))]
LEFT_FIN_AT = {"front": (10, 19), "back": (10, 19), "lower": (9, 21)}
RIGHT_FIN_AT = {"front": (18, 19), "back": (18, 19)}
DORSAL = swayed(["..LL", ".LGl", "LGl.", ".LGl", "LGl.", ".Ll."], (0, -1, 0, 1))
DORSAL_AT = {"side": (8, 19), "upper": (8, 19), "lower": (9, 18)}
SPARK = [["s.", ".Z"], [".s", "Z."], ["..", ".."], ["Z.", ".s"]]
SPARK_AT = {"front": (20, 12), "lower": (20, 12), "side": (20, 12), "upper": (20, 12), "back": (20, 12)}
TRAITS = [
    {"frames": TAIL, "at": TAIL_AT, "behind": VIEWS, "walk": (0, 2, 2, 0, 2, 2)},
    {"frames": DORSAL, "at": DORSAL_AT, "follows": "head", "behind": VIEWS, "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": LEFT_FIN, "at": LEFT_FIN_AT, "follows": "head", "behind": ("lower",), "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": RIGHT_FIN, "at": RIGHT_FIN_AT, "follows": "head", "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": SPARK, "at": SPARK_AT, "follows": "head", "walk": (0, 1, 2, 3, 0, 1)},
]
NO_LEGS = {view: [] for view in VIEWS}

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, NO_LEGS, 31, TRAITS, idle_head=(0, 1, 1, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 1, 1, 0, 1, 1), walk_body=(0, 0, 0, 0, 0, 0)),
    )
