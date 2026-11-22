"""Bloomarch: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,5 m, ele tem 26 pixels de altura pela regra do mapa (creature-scale): 24 de desenho e o
contorno marrom-escuro por fora. Cabem as quatro asas âmbar e laranja, as antenas longas, os
tufos de pétalas rosa e o trevo na cabeça amarela de olho escuro, o mel escorrendo da boca, o
colar de pétalas rosa, o corpo em listras com folhas, as manoplas de mel dourado nas mãos e as
pernas no chão. Ele fica de pé, pesado: as asas batem (baixas e erguidas), o mel das manoplas
pinga, e no walk as pernas marcham.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, mirrored, recolored  # noqa: E402

PALETTE = {
    "o": (60, 30, 14),     # contorno
    "Y": (248, 196, 56),   # pelo
    "A": (212, 138, 40),   # pelo na sombra
    "B": (100, 54, 26),    # listra
    "b": (66, 34, 18),     # antena e perna
    "G": (108, 170, 60),   # folha
    "g": (58, 110, 40),    # folha na sombra
    "P": (242, 124, 154),  # pétala
    "p": (196, 74, 110),   # pétala na sombra
    "E": (50, 24, 12),     # olho
    "H": (252, 186, 34),   # mel
    "h": (255, 234, 136),  # mel aceso
    "R": (253, 216, 140),  # asa clara
    "O": (244, 158, 68),   # asa
    "r": (176, 92, 40),    # borda da asa
}
OUTLINE = {"*": "o", "r": "r"}
TOP = 7

FRONT_BODY = mirrored([
    "......b.",
    ".....b..",
    ".....b..",
    "...P.YYY",
    "..PpYYYY",
    "...GYYYY",
    "...AYEEY",
    "....YAYH",
    "..PPPPGH",
    ".PpPGPPP",
    "..ppPPPP",
    "....gBYB",
    "...bBYYY",
    ".HhbBBBB",
    "HhHHGYYY",
    "HHHHgBBB",
    ".HHH.YYG",
    ".....BBB",
    "....GBYB",
    "....gBB.",
])
FRONT_LEGS = [
    [
        "....bb...bb....",
        "....b.....b....",
        "...bb.....bb...",
        "..bbb.....bbb..",
    ],
    [
        "....bb...bb....",
        "...bb.....b....",
        "..bbb.....bb...",
        "..........bbb..",
    ],
    [
        "....bb...bb....",
        "....b.....bb...",
        "...bb.....bbb..",
        "..bbb..........",
    ],
]
UPPER_WING = mirrored([
    "..rrr..........",
    ".rRRRr.........",
    "rRRRRRr........",
    "rRORRROr.......",
    "rOORRROOr......",
    "rOOOROOOr......",
    ".rOOOOOOr......",
    "..rOOOOr.......",
    "...rrrr........",
])
LOWER_WING = mirrored([
    "..rrrr.........",
    ".rRRROr........",
    "rRROOr.........",
    "rOOOr..........",
    ".rOr...........",
    "..r............",
])
FRONT_WINGS = [((UPPER_WING, 2, 1), (LOWER_WING, 2, 9)), ((UPPER_WING, 2, 0), (LOWER_WING, 2, 10))]

SIDE_BODY = [
    "........b..b",
    ".......b..b.",
    "......PbPb..",
    ".....PpYYYY.",
    "......YYYYY.",
    "......YYYEY.",
    "......GYYYAY",
    ".......AYYH.",
    "....PPPPGPH.",
    "...PpPPPPP..",
    "....pPPPG...",
    ".....BYYB...",
    "....YBBBhH..",
    "...BYYYHhHH.",
    "...BBBBHHHH.",
    "..YYYYGHHHH.",
    "..BBBBg.HH..",
    "...YYYB.....",
    "....GBY.....",
    "....gBB.....",
]
SIDE_LEGS = [
    [
        ".....bb.....",
        "....b.b.....",
        "....b..b....",
        "...bb.bb....",
    ],
    [
        ".....bb.....",
        "....b..b....",
        "...b....b...",
        "..bb....bb..",
    ],
    [
        ".....bb.....",
        ".....bb.....",
        ".....bb.....",
        "....bbbb....",
    ],
]
SIDE_UPPER = [
    "...rrr....",
    ".rRRRRr...",
    "rRRRORRr..",
    "rOORROOr..",
    "rOOOOOOOr.",
    ".rOOOOOr..",
    "..rrrrr...",
]
SIDE_LOWER = [
    "..rrrr...",
    ".rRROOr..",
    "rOOOOr...",
    ".rOOr....",
    "..rr.....",
]
SIDE_WINGS = [((SIDE_UPPER, 6, 2), (SIDE_LOWER, 7, 9)), ((SIDE_UPPER, 6, 1), (SIDE_LOWER, 7, 10))]


DRIPS = {
    "front": ([(2, 17), (12, 17)], [(2, 18), (12, 18)]),
    "side": ([(9, 17)], [(9, 18)]),
}
DRIPS["lower"] = DRIPS["upper"] = DRIPS["side"]
DRIPS["back"] = ([], [])


def faceless(drawing):
    return recolored(drawing, "Eh", "YH")


PARTS = {
    "front": (FRONT_WINGS, (FRONT_BODY, 9), (FRONT_LEGS, 9)),
    "side": (SIDE_WINGS, (SIDE_BODY, 10), (SIDE_LEGS, 10)),
    "back": (FRONT_WINGS, (recolored(FRONT_BODY, "EAhG", "YYHg"), 9), (FRONT_LEGS, 9)),
}
PARTS["lower"] = PARTS["side"]
PARTS["upper"] = (SIDE_WINGS, (faceless(SIDE_BODY), 10), (SIDE_LEGS, 10))
IDLE_WINGS = (0, 1, 0, 1)
IDLE_BOB = (0, 0, 1, 0)
WALK_WINGS = (0, 1, 0, 1, 0, 1)
WALK_BOB = (0, 1, 0, 0, 1, 0)
WALK_LEGS = (0, 1, 1, 0, 2, 2)


def drawer(wing_poses, bob, leg_poses):
    def draw(canvas, view, frame):
        wings, (body, body_left), (legs, legs_left) = PARTS[view]
        drop = bob[frame]
        canvas.stamp(legs[leg_poses[frame]], legs_left, TOP + 20)
        if view != "back":
            for drawing, left, top in wings[wing_poses[frame]]:
                canvas.stamp(drawing, left, TOP + top + drop)
        canvas.stamp(body, body_left, TOP + drop)
        if view == "back":
            for drawing, left, top in wings[wing_poses[frame]]:
                canvas.stamp(drawing, left, TOP + top + drop)
        for x, y in DRIPS[view][frame % 2]:
            canvas.stamp(["h"], body_left + x, TOP + y + drop)

    return draw


if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        {"idle": drawer(IDLE_WINGS, IDLE_BOB, (0, 0, 0, 0)), "walk": drawer(WALK_WINGS, WALK_BOB, WALK_LEGS)},
        outline=OUTLINE,
    )
