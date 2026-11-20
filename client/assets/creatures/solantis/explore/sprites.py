"""Solantis: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,5 m, ele tem 26 pixels de altura pela regra do mapa (creature-scale). Parte do
esqueleto do Mantorn (`grown`, no `sprites.py` dele), repintado de branco e dourado, com as
asas de pétalas de luz abertas atrás, que batem devagar, e a auréola dourada sobre a
cabeça, que pisca. A auréola, as patas e as antenas são linhas sem contorno.
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
    "o": (128, 86, 30),    # contorno
    "q": (206, 150, 52),   # contorno das asas
    "B": (226, 192, 118),  # dourado
    "L": (250, 236, 194),  # dourado na luz
    "D": (176, 132, 66),   # dourado na sombra, antenas e patas
    "S": (206, 166, 92),   # mancha
    "C": (255, 249, 226),  # foice e peito
    "G": (156, 222, 46),   # olho
    "k": (52, 110, 22),    # pupila
    "W": (255, 244, 208),  # pétala
    "w": (240, 198, 104),  # veio da pétala
    "Y": (255, 222, 84),   # auréola
    "y": (255, 246, 184),  # auréola acesa
}
OUTLINE = {"*": "o", "W": "q", "w": "q"}

WING = [
    "WW......",
    "WWWW....",
    "WWwWWW..",
    ".WWwWWW.",
    ".WWWwWWW",
    "..WWWwWW",
    "...WWWwW",
    "....WWWW",
    ".....WWW",
]
SIDE_WING = [
    "WW........",
    "WWWW......",
    ".WWwWW....",
    "..WWwWWW..",
    "...WWwWWW.",
    "....WWwWWW",
    ".....WWwWW",
    "......WWwW",
    "........WW",
]
BEAT = (0, 1, 1, 0)
LEFT_WINGS = swayed(WING, BEAT)
RIGHT_WINGS = [[row[::-1] for row in frame] for frame in swayed(WING, tuple(-a for a in BEAT))]
SIDE_WINGS = swayed(SIDE_WING, BEAT)
LEFT_WING_AT = {"front": (6, 8), "lower": (7, 8), "upper": (7, 8), "back": (6, 8)}
RIGHT_WING_AT = {"front": (17, 8), "lower": (18, 8), "upper": (18, 8), "back": (17, 8)}
SIDE_WING_AT = {"side": (5, 7)}
HALO = [".YYY.", "Y...Y", ".YYY."]
HALO_LIT = [".yYy.", "Y...Y", ".YyY."]
HALO_SIDE = [".Y.", "Y.Y", ".Y."]
HALO_SIDE_LIT = [".y.", "Y.Y", ".Y."]
HALOS = {
    "front": [HALO, HALO_LIT, HALO, HALO],
    "lower": [HALO, HALO_LIT, HALO, HALO],
    "upper": [HALO, HALO_LIT, HALO, HALO],
    "back": [HALO, HALO_LIT, HALO, HALO],
    "side": [HALO_SIDE, HALO_SIDE_LIT, HALO_SIDE, HALO_SIDE],
}
HALO_AT = {"front": (14, 6), "lower": (16, 6), "upper": (15, 6), "back": (14, 6), "side": (20, 6)}
FRONT_VIEWS = ("front", "lower", "side")

skeleton = mantorn.grown()
WINGS = [
    {"frames": LEFT_WINGS, "at": LEFT_WING_AT, "behind": FRONT_VIEWS, "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": RIGHT_WINGS, "at": RIGHT_WING_AT, "behind": FRONT_VIEWS, "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": SIDE_WINGS, "at": SIDE_WING_AT, "behind": FRONT_VIEWS, "walk": (0, 1, 2, 3, 0, 1)},
]
LINES = mantorn.antennae(skeleton["antennae_at"]) + [
    {"frames": HALOS, "at": HALO_AT, "follows": "head", "walk": (0, 1, 2, 3, 0, 1)},
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
