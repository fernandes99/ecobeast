"""Bumbit: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,3 m, ele tem 8 pixels de altura pela regra do mapa (creature-scale): 6 de desenho e o
contorno marrom-escuro por fora. Cabem a bolinha de pelo amarelo com as listras marrons, as
asinhas creme pequenas demais para o corpo, as antenas curtas, os olhos escuros, o pólen
dourado no focinho e as perninhas no chão. As asinhas tremem (baixas e erguidas), e no walk
as perninhas trocam de passo.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored  # noqa: E402

PALETTE = {
    "o": (62, 32, 16),     # contorno
    "Y": (250, 198, 52),   # pelo
    "A": (218, 150, 34),   # pelo na sombra
    "B": (112, 60, 30),    # listra
    "b": (78, 40, 20),     # antena e perna
    "W": (252, 240, 222),  # asa
    "E": (44, 22, 12),     # olho
    "P": (246, 168, 28),   # pólen
}
OUTLINE = {"*": "o"}
TOP = 25

FRONT = [
    [
        ".b...b.",
        "WYYYYYW",
        "WYEYEYW",
        ".YYPYY.",
        ".BBBBB.",
        "..b.b..",
    ],
    [
        "Wb...bW",
        "WYYYYYW",
        ".YEYEY.",
        ".YYPYY.",
        ".BBBBB.",
        "..b.b..",
    ],
]
SIDE = [
    [
        "....b.b",
        "WW.YYYY",
        "WWBYYEY",
        ".BYBYYP",
        ".BABAA.",
        "..b..b.",
    ],
    [
        "WW..b.b",
        "WW.YYYY",
        ".WBYYEY",
        ".BYBYYP",
        ".BABAA.",
        "..b..b.",
    ],
]
BACK = [
    [
        ".b...b.",
        "WYYYYYW",
        "WBBBBBW",
        ".YYYYY.",
        ".BBBBB.",
        "..b.b..",
    ],
    [
        "Wb...bW",
        "WYYYYYW",
        ".BBBBB.",
        ".YYYYY.",
        ".BBBBB.",
        "..b.b..",
    ],
]
STEPS = {"front": ".b...b.", "side": ".b...b.", "back": ".b...b."}
POSES = {
    "front": FRONT,
    "lower": SIDE,
    "side": SIDE,
    "upper": [recolored(pose, "EP", "YY") for pose in SIDE],
    "back": BACK,
}
LEFT = {"front": 13, "lower": 13, "side": 13, "upper": 13, "back": 13}
IDLE = (0, 1, 0, 1)
WALK = (0, 1, 0, 1, 0, 1)
WALK_STEP = (False, False, False, True, True, True)


def stepping(pose, view):
    last = STEPS["front" if view == "front" else "back" if view == "back" else "side"]
    return pose[:-1] + [last]


def drawer(poses, steps):
    def draw(canvas, view, frame):
        pose = POSES[view][poses[frame]]
        if steps[frame]:
            pose = stepping(pose, view)
        canvas.stamp(pose, LEFT[view], TOP)

    return draw


if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        {"idle": drawer(IDLE, (False,) * 4), "walk": drawer(WALK, WALK_STEP)},
        outline=OUTLINE,
    )
