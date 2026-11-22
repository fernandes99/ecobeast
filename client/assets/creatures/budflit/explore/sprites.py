"""Budflit: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,2 m, ela tem 7 pixels de altura pela regra do mapa (creature-scale): 5 de desenho e o
contorno roxo-escuro por fora. Cabem as asas fechadas lilás, rosa e creme, como um botão de
flor, a cabeça lilás de olho magenta, a bolinha rosa da antena, a gola de pétalas rosa e as
perninhas no chão. Ela fica sentada: as asas abrem um pouco e fecham, como quem espia, e no
walk ela anda batendo as asas fechadas.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored  # noqa: E402

PALETTE = {
    "o": (58, 20, 86),     # contorno
    "V": (150, 90, 214),   # asa
    "v": (96, 44, 156),    # asa na sombra
    "P": (246, 128, 168),  # rosa
    "c": (252, 228, 200),  # creme
    "H": (180, 124, 232),  # cabeça
    "E": (196, 30, 120),   # olho
    "m": (74, 32, 116),    # perna
    "R": (234, 98, 192),   # bolinha da antena
}
OUTLINE = {"*": "o"}
TOP = 26

FRONT = [
    [
        ".R...R.",
        "VVHHHVV",
        "PVEHEVP",
        "VPPPPPV",
        ".vm.mv.",
    ],
    [
        ".R...R.",
        "VVHHHVV",
        "cVEHEVc",
        "PPPPPPP",
        ".vm.mv.",
    ],
]
SIDE = [
    [
        "VV..R",
        "VcVHH",
        "PcVHE",
        "VPVPP",
        ".vm.m",
    ],
    [
        ".VV.R",
        "VVcHH",
        "VPcHE",
        ".VPPP",
        ".vm.m",
    ],
]
BACK = [
    [
        ".R...R.",
        "VVHHHVV",
        "PVcVcVP",
        "VPcVcPV",
        ".vm.mv.",
    ],
    [
        ".R...R.",
        "VVHHHVV",
        "cVcVcVc",
        "PPcVcPP",
        ".vm.mv.",
    ],
]
POSES = {
    "front": FRONT,
    "lower": SIDE,
    "side": SIDE,
    "upper": [recolored(pose, "E", "H") for pose in SIDE],
    "back": BACK,
}
LEFT = {"front": 13, "lower": 14, "side": 14, "upper": 14, "back": 13}
IDLE = (0, 0, 1, 0)
WALK = (0, 1, 0, 0, 1, 0)


def drawer(poses):
    def draw(canvas, view, frame):
        canvas.stamp(POSES[view][poses[frame]], LEFT[view], TOP)

    return draw


if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, {"idle": drawer(IDLE), "walk": drawer(WALK)}, outline=OUTLINE)
