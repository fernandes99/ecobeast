"""Umbrantis: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,5 m, ele tem 26 pixels de altura pela regra do mapa (creature-scale). Parte do
esqueleto do Mantorn (`grown`, no `sprites.py` dele), repintado de marrom e cinza de folha
morta, com os olhos roxos, as asas de folha seca rasgadas, abertas atrás, e fiapos de névoa
roxa que sobem dos lados. A névoa, as patas e as antenas são linhas sem contorno.
"""
import importlib.util
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, rig, swayed  # noqa: E402

_spec = importlib.util.spec_from_file_location("mantorn_sprites", Path(__file__).parents[2] / "mantorn/explore/sprites.py")
mantorn = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(mantorn)

PALETTE = {
    "o": (34, 24, 22),     # contorno
    "B": (104, 82, 64),    # marrom-acinzentado
    "L": (146, 124, 100),  # na luz
    "D": (62, 48, 38),     # na sombra, antenas e patas
    "S": (80, 62, 48),     # mancha
    "C": (178, 166, 148),  # foice e peito
    "G": (204, 124, 255),  # olho
    "k": (98, 34, 152),    # pupila
    "R": (122, 94, 68),    # folha da asa
    "r": (84, 64, 48),     # veio da folha
    "M": (92, 54, 136),    # névoa
    "m": (140, 92, 196),   # névoa clara
}
OUTLINE = {"*": "o"}

WING = [
    "RR......",
    "RrRR....",
    "R.rRRR..",
    ".RRr.RR.",
    ".R.RrRRR",
    "..RR.rRR",
    "...RRRrR",
    "....R.RR",
    ".....RRR",
]
SIDE_WING = [
    "RR........",
    "RrRR......",
    ".R.rRR....",
    "..RRr.RR..",
    "...R.rRRR.",
    "....RR.rRR",
    ".....RRrRR",
    "......R.rR",
    "........RR",
]
BEAT = (0, 1, 1, 0)
LEFT_WINGS = swayed(WING, BEAT)
RIGHT_WINGS = [[row[::-1] for row in frame] for frame in swayed(WING, tuple(-a for a in BEAT))]
SIDE_WINGS = swayed(SIDE_WING, BEAT)
LEFT_WING_AT = {"front": (6, 8), "lower": (7, 8), "upper": (7, 8), "back": (6, 8)}
RIGHT_WING_AT = {"front": (17, 8), "lower": (18, 8), "upper": (18, 8), "back": (17, 8)}
SIDE_WING_AT = {"side": (5, 7)}
FRONT_VIEWS = ("front", "lower", "side")

WISP = [
    ".m.",
    "M..",
    ".M.",
    "..M",
    ".M.",
    "M..",
]
WISPS = swayed(WISP, (0, 1, 0, -1))
LEFT_WISP_AT = {"front": (8, 21), "lower": (5, 21), "side": (3, 20), "upper": (5, 21), "back": (8, 21)}
RIGHT_WISP_AT = {"front": (20, 22), "lower": (20, 22), "side": (19, 22), "upper": (19, 22), "back": (20, 22)}

skeleton = mantorn.grown()
WINGS = [
    {"frames": LEFT_WINGS, "at": LEFT_WING_AT, "behind": FRONT_VIEWS, "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": RIGHT_WINGS, "at": RIGHT_WING_AT, "behind": FRONT_VIEWS, "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": SIDE_WINGS, "at": SIDE_WING_AT, "behind": FRONT_VIEWS, "walk": (0, 1, 2, 3, 0, 1)},
]
LINES = mantorn.antennae(skeleton["antennae_at"]) + [
    {"frames": WISPS, "at": LEFT_WISP_AT, "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": WISPS[2:] + WISPS[:2], "at": RIGHT_WISP_AT, "walk": (0, 1, 2, 3, 0, 1)},
]
ANIMATION = dict(mantorn.ANIMATION, idle_head=(0, 0, 1, 0), idle_body=(0, 0, 0, 0))

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        mantorn.thin(
            PALETTE,
            OUTLINE,
            rig(skeleton["heads"], skeleton["bodies"], {view: [] for view in skeleton["legs"]}, skeleton["legs_top"], WINGS + skeleton["scythes"], **ANIMATION),
            rig(mantorn.NO_HEADS, {}, skeleton["legs"], skeleton["legs_top"], LINES, **ANIMATION),
        ),
    )
