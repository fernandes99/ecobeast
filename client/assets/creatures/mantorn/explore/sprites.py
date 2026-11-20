"""Mantorn: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,0 m, ele tem 19 pixels de altura pela regra do mapa (creature-scale): 17 de desenho e
o contorno marrom-escuro por fora. É o louva-a-deus esguio, de pé nas 4 patas finas, com a
cabeça triangular de olhos verdes, as antenas, o tórax subindo, as asas fechadas manchadas
de casca sobre o abdômen e as duas foices claras dobradas na frente do peito. As patas e as
antenas são linhas de 1 pixel sem contorno, desenhadas por baixo do resto (`thin`): com o
contorno, elas engrossavam e ele parecia um cervo.

O desenho é o esqueleto do Solantis e do Umbrantis: o `sprites.py` deles importa este.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import Canvas, build, outlined, recolored, rig, stretched  # noqa: E402

PALETTE = {
    "o": (54, 32, 18),     # contorno
    "B": (142, 94, 52),    # marrom
    "L": (194, 142, 84),   # marrom na luz
    "D": (98, 62, 34),     # marrom na sombra, antenas e patas
    "S": (120, 76, 40),    # mancha de casca
    "C": (232, 206, 160),  # foice e peito
    "G": (156, 222, 46),   # olho
    "k": (52, 110, 22),    # pupila
}
OUTLINE = {"*": "o"}

TOP = 14
HEAD_FRONT = [
    "GGBLBGG",
    "GkBBBkG",
    ".BBCBB.",
    "..BCB..",
]
HEAD_SIDE = [
    ".BLLB.",
    "BBLBGG",
    ".BBGGk",
    "..BBGB",
    "...BC.",
]
HEADS = {
    "front": (HEAD_FRONT, 13, 16),
    "lower": (HEAD_FRONT, 15, 16),
    "side": (HEAD_SIDE, 18, 16),
    "upper": (recolored(HEAD_FRONT, "GkC", "BDB"), 14, 16),
    "back": (recolored(HEAD_FRONT, "GkC", "BDB"), 13, 16),
}
BODIES = {
    "front": ([
        "...BCB...",
        "...BCB...",
        "..BBCBB..",
        ".DBBCBBD.",
        ".DBBBBBD.",
        "..DDDDD..",
    ], 12, 20),
    "lower": ([
        "........BCB",
        "..LLL...BCB",
        ".LSLSLLBBCB",
        "BBBBBBBBBCB",
        ".DBBBBBBDB.",
        "..DDDDDD...",
    ], 6, 20),
    "side": ([
        ".............BB",
        "...LLLLLLL..BB.",
        "..LSBSLSBLLBBB.",
        ".BBBBBBBBBBBBC.",
        "..DBBBBBBBDDB..",
        "....DDDDDD.....",
    ], 4, 20),
    "upper": ([
        "........BBB",
        "..LLL..LLLL",
        ".LSLSLLLSLL",
        "BBBBBBLLLLB",
        ".DBBBBBSLSD",
        "..DDDDDDDD.",
    ], 6, 20),
    "back": ([
        "...BBB...",
        "..LLLLL..",
        "..LSLSL..",
        ".BLLSLLB.",
        ".DLSLLSD.",
        "..DDDDD..",
    ], 12, 20),
}
SCYTHE_LEFT = [
    "..B",
    ".BL",
    "BLC",
    "LC.",
    "C..",
]
SCYTHE_RIGHT = [row[::-1] for row in SCYTHE_LEFT]
SCYTHE_SIDE = [
    "B....",
    ".BL..",
    "..BLC",
    "..BC.",
    ".CC..",
]
SCYTHE_SIDE_UP = [
    "B....",
    ".BLC.",
    "..BC.",
    "..BC.",
    ".CC..",
]
SCYTHE_TIP = ["C", "C"]
STILL = [SCYTHE_LEFT] * 4
LEFT_SCYTHE_AT = {"front": (9, 20), "lower": (12, 20), "back": (10, 21), "upper": (13, 21)}
RIGHT_SCYTHE_AT = {"front": (20, 20), "lower": (19, 20)}
BACK_TIPS_AT = {"back": (21, 22)}
SIDE_SCYTHE_AT = {"side": (19, 20)}
ANTENNAE = {
    "front": [
        ["D.......D", ".D.....D.", "..D...D.."],
        [".D......D", "..D....D.", "..D...D.."],
        ["D.......D", ".D.....D.", "..D...D.."],
        ["D......D.", ".D.....D.", "..D...D.."],
    ],
    "side": [
        ["DD....", "..DD..", "....D."],
        [".DD...", "...D..", "....D."],
        ["DD....", "..DD..", "....D."],
        ["D.D...", "..D.D.", "....D."],
    ],
}
ANTENNAE["lower"] = ANTENNAE["front"]
ANTENNAE["upper"] = ANTENNAE["front"]
ANTENNAE["back"] = ANTENNAE["front"]
ANTENNAE_AT = {"front": (12, 13), "lower": (14, 13), "side": (16, 13), "upper": (13, 13), "back": (12, 13)}

LEGS_Y = 26
REAR = ["..D", "..D", ".D.", ".D.", "D..", "D.."]
MID = [row[::-1] for row in REAR]
REAR_NEAR = [row.replace("D", "B") for row in REAR[:3]] + REAR[3:]
MID_NEAR = [row.replace("D", "B") for row in MID[:3]] + MID[3:]
OUT_LEFT = REAR
OUT_RIGHT = MID
DOWN = ["D"] * 6
LEGS = {
    "front": [(11, 0, OUT_LEFT, 0), (14, 3, DOWN, 0), (18, 0, DOWN, 0), (19, 3, OUT_RIGHT, 0)],
    "back": [(11, 0, OUT_LEFT, 0), (14, 3, DOWN, 0), (18, 0, DOWN, 0), (19, 3, OUT_RIGHT, 0)],
    "side": [(7, 3, REAR, 1), (14, 0, MID, 1), (9, 0, REAR_NEAR, 1), (16, 3, MID_NEAR, 1)],
    "lower": [(7, 3, REAR, 1), (15, 0, MID, 1), (10, 0, REAR_NEAR, 1), (17, 3, MID_NEAR, 1)],
    "upper": [(9, 3, REAR, 1), (16, 0, MID, 1), (6, 0, REAR_NEAR, 1), (13, 3, MID_NEAR, 1)],
}
NO_HEADS = {view: (["."], 0, 0) for view in ("front", "lower", "side", "upper", "back")}

def antennae(at=ANTENNAE_AT):
    return [{"frames": ANTENNAE, "at": at, "follows": "head", "walk": (0, 1, 2, 3, 0, 1)}]


def traits(left_at=LEFT_SCYTHE_AT, right_at=RIGHT_SCYTHE_AT, side_at=SIDE_SCYTHE_AT, tips_at=BACK_TIPS_AT):
    return [
        {"frames": STILL, "at": left_at, "follows": "body", "behind": ("back", "upper")},
        {"frames": [SCYTHE_RIGHT] * 4, "at": right_at, "follows": "body"},
        {"frames": [SCYTHE_SIDE, SCYTHE_SIDE, SCYTHE_SIDE_UP, SCYTHE_SIDE], "at": side_at, "follows": "body"},
        {"frames": [SCYTHE_TIP] * 4, "at": tips_at, "follows": "body", "behind": ("back",)},
    ]


def thin(palette, outline, solid, lines):
    """`solid` desenhado com o contorno e, só onde ficou vazio, `lines` sem contorno."""

    def wrap(name):
        def draw(canvas, view, frame):
            main = Canvas(palette)
            solid[name](main, view, frame)
            parts = outlined(main.pixels, palette, outline)
            under = Canvas(palette)
            lines[name](under, view, frame)
            for y, row in enumerate(parts):
                for x, pixel in enumerate(row):
                    canvas.pixels[y][x] = pixel or under.pixels[y][x]

        return draw

    return {name: wrap(name) for name in ("idle", "walk")}


def moved(places, dy):
    return {view: (x, y + dy) for view, (x, y) in places.items()}


def grown():
    """O esqueleto do Solantis e do Umbrantis, com 26 pixels: a cabeça, o tórax, o abdômen e
    as patas mais compridos pelo `stretched`, sem ficar mais largos."""
    legs = {
        view: [(hip, phase, stretched(style, rows=(1, 3)), reach) for hip, phase, style, reach in rows]
        for view, rows in LEGS.items()
    }
    scythes = traits(moved(LEFT_SCYTHE_AT, -3), moved(RIGHT_SCYTHE_AT, -3), moved(SIDE_SCYTHE_AT, -3), moved(BACK_TIPS_AT, -3))
    for trait in scythes:
        trait["frames"] = [stretched(frame, rows=(1,)) for frame in trait["frames"]]
    return {
        "heads": {view: (stretched(drawing, rows=(1,)), x, y - 5) for view, (drawing, x, y) in HEADS.items()},
        "bodies": {view: (stretched(drawing, rows=(0, 1, 3)), x, y - 4) for view, (drawing, x, y) in BODIES.items()},
        "scythes": scythes,
        "antennae_at": moved(ANTENNAE_AT, -5),
        "legs": legs,
        "legs_top": 24,
    }


ANIMATION = dict(idle_head=(0, 1, 1, 0), idle_body=(0, 0, 1, 0), walk_head=(1, 1, 0, 1, 1, 0), walk_body=(1, 0, 0, 1, 0, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 2, 1))

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        thin(PALETTE, OUTLINE, rig(HEADS, BODIES, {view: [] for view in LEGS}, LEGS_Y, traits(), **ANIMATION), rig(NO_HEADS, {}, LEGS, LEGS_Y, antennae(), **ANIMATION)),
    )
