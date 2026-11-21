"""Veilmoth: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,5 m, ela tem 11 pixels de altura pela regra do mapa (creature-scale): 9 de desenho e
o contorno violeta-escuro por fora. Cabem as asas violeta com o olho-portal escuro de anel
rosado, a cabeça escura de olhos claros, a gola creme, as antenas lilás e as duas caudas de
véu, que encostam no chão. Ela voa baixo: as asas batem (abertas, no meio e erguidas), e o
anel do olho-portal pisca.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, mirrored, recolored  # noqa: E402

PALETTE = {
    "o": (40, 14, 70),     # contorno
    "V": (118, 56, 184),   # asa
    "v": (78, 28, 134),    # asa na sombra
    "l": (204, 156, 232),  # borda lilás e caudas
    "c": (248, 222, 194),  # gola creme
    "C": (214, 160, 182),  # creme na sombra
    "P": (246, 136, 250),  # anel do olho-portal
    "p": (255, 214, 255),  # anel aceso
    "K": (16, 4, 60),      # centro do olho-portal
    "k": (62, 26, 108),    # cabeça
    "E": (244, 210, 255),  # olho
    "A": (182, 112, 214),  # antena
}
OUTLINE = {"*": "o"}
TOP = 22

FRONT = [
    mirrored([
        ".....A..",
        "......kk",
        "vvvv..Ek",
        "VlPVv.kk",
        "VPKPVccc",
        "lVPVVcCc",
        ".llVvvCv",
        "...l..v.",
        "...l....",
    ]),
    mirrored([
        ".....A..",
        "vv....kk",
        "VVvv..Ek",
        "VPKVv.kk",
        "lPVVVccc",
        ".lVVvcCc",
        "..lvvvCv",
        "...l..v.",
        "...l....",
    ]),
    mirrored([
        ".vv..A..",
        ".VPv..kk",
        ".PKVv.Ek",
        "..PVv.kk",
        "..lVvccc",
        "...vvcCc",
        "....vvCv",
        "...l..v.",
        "...l....",
    ]),
]
SIDE = [
    [
        ".........A..",
        "..........kk",
        "vvVVv....kEk",
        "VPKPVv..ckkk",
        "lVPVVvvcccC.",
        ".llvvvvcCC..",
        "...vv.vvC...",
        "..l.........",
        ".l..........",
    ],
    [
        ".........A..",
        ".vvVv.....kk",
        "vVPKPv...kEk",
        "lVPPVvv.ckkk",
        ".lVVVvvcccC.",
        "..llvvvcCC..",
        "...vv.vvC...",
        "..l.........",
        ".l..........",
    ],
    [
        "...vVVv..A..",
        "..vVPPVv..kk",
        "..VPKKPV.kEk",
        "..lVPPVvckkk",
        "...lVVvcccC.",
        "....vvvcCC..",
        "...vv.vvC...",
        "..l.........",
        ".l..........",
    ],
]
POSES = {
    "front": FRONT,
    "lower": SIDE,
    "side": SIDE,
    "upper": [recolored(pose, "E", "k") for pose in SIDE],
    "back": [recolored(pose, "Ec", "kC") for pose in FRONT],
}
LEFT = {"front": 9, "lower": 9, "side": 9, "upper": 9, "back": 9}
IDLE = (0, 1, 2, 1)
WALK = (0, 1, 2, 0, 1, 2)


def drawer(poses):
    def draw(canvas, view, frame):
        drawing = POSES[view][poses[frame]]
        if frame % 2:
            drawing = recolored(drawing, "P", "p")
        canvas.stamp(drawing, LEFT[view], TOP)

    return draw


if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, {"idle": drawer(IDLE), "walk": drawer(WALK)}, outline=OUTLINE)
