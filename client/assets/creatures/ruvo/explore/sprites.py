"""Ruvo: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,50 m, ele tem 7 pixels de altura, na escala do Domador (veja a skill
creature-sprites). Nesse tamanho, cada olho é um pixel, e o contorno escuro comeria o
corpo: quem separa as partes é a cor. Os pés ficam presos no idle, e no walk cada pata
anda sozinha, com as diagonais alternando.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, rig  # noqa: E402

PALETTE = {
    "K": (60, 20, 16),     # olho e pata de longe
    "O": (240, 120, 24),   # laranja
    "L": (248, 164, 48),   # laranja claro
    "S": (216, 72, 24),    # laranja na sombra
    "T": (160, 44, 24),    # vermelho escuro: orelha e pata
    "C": (248, 220, 174),  # creme
    "P": (224, 112, 104),  # focinho
    "Y": (255, 220, 88),   # chama clara
    "y": (255, 160, 32),   # chama média
    "F": (240, 88, 24),    # chama forte
}

# Desenho, coluna e linha de cada parte em cada ângulo. Os pés ficam na linha 31.
HEADS = {
    "front": ([
        ".T...T.",
        ".TOOOT.",
        "OOLLLOO",
        "OKOCOKO",
        "CCCPCCC",
    ], 13, 25),
    "lower": ([
        "T...T.",
        "TOOOT.",
        "OOLLOO",
        "OKOOKO",
        "CCCPCC",
    ], 15, 25),
    "side": ([
        "T.T...",
        "TOOOO.",
        "OOOKOC",
        "OOCCCP",
    ], 15, 25),
    "upper": ([
        "T...T.",
        "TOOOT.",
        "OOLLOO",
        "OOOOOC",
        "SOOOOC",
    ], 15, 25),
    "back": ([
        ".T...T.",
        ".TOOOT.",
        "OOLLLOO",
        "OOOOOOO",
        "SOOOOOS",
    ], 13, 25),
}
BODIES = {
    "front": (["CCC"], 15, 30),
    "lower": ([
        "OLO",
        "OOOO",
    ], 12, 28),
    "side": ([
        "OLLOOOOC",
        "OOOOOOCC",
    ], 12, 28),
    "upper": ([
        "OLO",
        "OOOO",
    ], 12, 28),
    "back": (["OOO"], 15, 30),
}
FLAME = [
    [
        ".y.",
        "yYy",
        "yFy",
        ".F.",
    ],
    [
        "y..",
        "yYy",
        "yFy",
        ".F.",
    ],
    [
        ".y.",
        "yYy",
        "YFy",
        ".F.",
    ],
    [
        "..y",
        "yYy",
        "yFy",
        ".F.",
    ],
]
FLAMES = {"front": (19, 26), "lower": (9, 26), "side": (9, 26), "upper": (11, 27), "back": (15, 27)}
CRESTS = {"front": (16, 26), "lower": (17, 26), "side": (17, 26), "upper": (17, 26), "back": (16, 26)}
CREST_MARKS = ["Y", "y", "Y", "F"]

LEGS_Y = 30
IDLE_HEAD = (0, 1, 1, 0)
# Só a cabeça desce: em 7 pixels, descer o corpo esconderia as patas.
WALK_HEAD = (1, 0, 0, 1, 0, 0)
# Cada pata em um ponto do ciclo: quanto o pé está à frente do quadril e fora do chão.
FOOT_REACH = (1, 0, -1, -1, 0, 1)
FOOT_LIFT = (0, 0, 0, 0, 1, 1)
# Coluna do quadril, ponto do ciclo, estilo e alcance, de trás para a frente.
NEAR = ["OO", "TT"]
FAR = ["S", "K"]
LEGS = {
    "front": [(14, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "back": [(14, 0, NEAR, 0), (17, 3, NEAR, 0)],
    "side": [(14, 3, FAR, 1), (17, 0, FAR, 1), (12, 0, NEAR, 1), (19, 3, NEAR, 1)],
    "lower": [(16, 3, FAR, 1), (12, 0, NEAR, 1), (18, 3, NEAR, 1)],
    "upper": [(16, 3, FAR, 1), (13, 0, NEAR, 1), (18, 3, NEAR, 1)],
}
TRAITS = [
    {"frames": [[mark] for mark in CREST_MARKS], "at": CRESTS, "follows": "head", "walk": (0, 1, 2, 3, 0, 1)},
    # De trás, a cauda fica na frente de tudo; nos outros ângulos, atrás do corpo.
    {"frames": FLAME, "at": FLAMES, "behind": ("front", "lower", "side")},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, BODIES, LEGS, LEGS_Y, TRAITS, idle_head=IDLE_HEAD, idle_body=(0, 0, 0, 0), walk_head=WALK_HEAD, walk_body=(0, 0, 0, 0, 0, 0), foot_reach=FOOT_REACH, foot_lift=FOOT_LIFT),
    )
