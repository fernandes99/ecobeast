"""Buzzwork: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,8 m, ele tem 16 pixels de altura pela regra do mapa (creature-scale): 14 de desenho e o
contorno marrom-escuro por fora. Cabem as antenas, o lenço de folha verde na testa, a cabeça
amarela de olho escuro, a gola de penugem creme, o corpo em listras amarelas e marrons, os
cestos de pólen dourado nas pernas, as asas translúcidas e, de lado, a folha enrolada debaixo
do braço. Ele fica de pé: as asas vibram (baixas e erguidas), e no walk as pernas marcham.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, mirrored, recolored  # noqa: E402

PALETTE = {
    "o": (58, 30, 14),     # contorno
    "Y": (250, 196, 50),   # amarelo
    "A": (214, 142, 32),   # amarelo na sombra
    "B": (108, 58, 28),    # listra
    "b": (72, 38, 18),     # antena e perna
    "G": (112, 172, 62),   # folha
    "g": (60, 112, 40),    # folha na sombra
    "c": (252, 234, 196),  # gola
    "W": (246, 228, 212),  # asa
    "w": (208, 176, 160),  # asa na sombra
    "E": (52, 26, 12),     # olho
    "P": (244, 176, 36),   # pólen
    "p": (255, 222, 104),  # pólen aceso
}
OUTLINE = {"*": "o"}
TOP = 17

FRONT_TOP = mirrored([
    ".b...",
    "..b..",
    ".gGGG",
    "YYYYY",
    ".YEEY",
    "..YAb",
    ".cccc",
    "..YYY",
    "..BBB",
    "..YYY",
])
FRONT_LEGS = [
    mirrored([
        "PpBBB",
        "PPb..",
        ".b...",
        "bb...",
    ]),
    [
        "PpBBBBBpP",
        "PPb...bPP",
        ".b....b..",
        "bb.....bb",
    ],
    [
        "PpBBBBBpP",
        "PPb...bPP",
        "..b...b.",
        ".bb...bb",
    ],
]
FRONT_WING = [
    mirrored([
        "WW......",
        "wWW.....",
        ".ww.....",
    ]),
    mirrored([
        "W.......",
        "WW......",
        "wW......",
    ]),
]

SIDE_TOP = [
    "......b.b.",
    ".....b.b..",
    "..ggGGGG..",
    "....YYYYY.",
    "....YYYEY.",
    "....AYYEb.",
    "....cccc..",
    "...BYYGG..",
    "..YBBGGg..",
    ".BYYBBg...",
]
SIDE_LEGS = [
    [
        ".BBYPpP...",
        "..BPPPP...",
        "....b.b...",
        "...bb.bb..",
    ],
    [
        ".BBYPpP...",
        "..BPPPP...",
        "...b..b...",
        "..bb..bb..",
    ],
    [
        ".BBYPpP...",
        "..BPPPP...",
        ".....bb...",
        "....bbbb..",
    ],
]
SIDE_WING = [
    [
        "..WW..",
        ".WWWW.",
        "WWwW..",
        "Ww....",
    ],
    [
        ".WW...",
        "WWWW..",
        "WwW...",
        "w.....",
    ],
]


def faceless(drawing):
    return recolored(drawing, "Ec", "YY")


PARTS = {
    "front": (FRONT_WING, 9, 5, [(FRONT_TOP, 12, 0)], FRONT_LEGS, 12),
    "side": (SIDE_WING, 9, 4, [(SIDE_TOP, 11, 0)], SIDE_LEGS, 11),
    "back": (FRONT_WING, 9, 5, [(recolored(FRONT_TOP, "EAc", "YYY"), 12, 0)], FRONT_LEGS, 12),
}
PARTS["lower"] = PARTS["side"]
PARTS["upper"] = (SIDE_WING, 9, 4, [(faceless(SIDE_TOP), 11, 0)], SIDE_LEGS, 11)
IDLE = (0, 1, 0, 1)
WALK_WING = (0, 1, 0, 1, 0, 1)
WALK_LEGS = (0, 1, 1, 0, 2, 2)
BOB = (0, 0, 1, 0)


def drawer(wing_poses, leg_poses, bob):
    def draw(canvas, view, frame):
        wings, wing_left, wing_top, parts, legs, legs_left = PARTS[view]
        drop = bob[frame]
        if view == "back":
            for part, left, top in parts:
                canvas.stamp(part, left, TOP + top + drop)
            canvas.stamp(legs[leg_poses[frame]], legs_left, TOP + 10)
            canvas.stamp(wings[wing_poses[frame]], wing_left, TOP + wing_top + drop)
            return
        canvas.stamp(wings[wing_poses[frame]], wing_left, TOP + wing_top + drop)
        canvas.stamp(legs[leg_poses[frame]], legs_left, TOP + 10)
        for part, left, top in parts:
            canvas.stamp(part, left, TOP + top + drop)

    return draw


if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        {"idle": drawer(IDLE, (0, 0, 0, 0), BOB), "walk": drawer(WALK_WING, WALK_LEGS, (0, 1, 0, 0, 1, 0))},
        outline=OUTLINE,
    )
