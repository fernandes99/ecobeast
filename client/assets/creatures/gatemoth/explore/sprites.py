"""Gatemoth: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,4 m, ele tem 25 pixels de altura pela regra do mapa (creature-scale): 23 de desenho e
o contorno violeta-escuro por fora. Cabem as asas largas com os olhos-portal (o centro escuro,
o anel rosado e a faixa creme), as antenas de pluma douradas, a máscara escura de olhos claros,
a juba creme com o broche de cristal em moldura dourada, o corpo de penas violeta e as caudas
de véu com o cristal na ponta, que encostam no chão. As asas, o corpo e as caudas são partes
separadas: só as asas batem, e o anel dos olhos-portal pisca.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, mirrored, recolored  # noqa: E402

PALETTE = {
    "o": (36, 10, 64),     # contorno
    "V": (112, 50, 178),   # asa
    "v": (72, 24, 126),    # asa na sombra
    "l": (198, 150, 228),  # lilás
    "c": (248, 222, 194),  # creme
    "C": (214, 162, 180),  # creme na sombra
    "P": (244, 132, 248),  # anel do olho-portal
    "p": (255, 214, 255),  # anel aceso
    "K": (14, 4, 56),      # centro do olho-portal
    "M": (20, 6, 58),      # máscara
    "m": (66, 26, 112),    # penas do corpo
    "E": (246, 206, 255),  # olho
    "G": (252, 214, 140),  # ouro
    "g": (206, 146, 74),   # ouro na sombra
    "X": (206, 128, 252),  # cristal
    "x": (122, 48, 178),   # cristal na sombra
}
OUTLINE = {"*": "o"}
TOP = 8

FRONT_BODY = mirrored([
    "G.....",
    "GG....",
    ".Gg...",
    "..g...",
    "...gmm",
    "...mMM",
    "...MEM",
    "..cmMM",
    ".cccMc",
    ".ccccc",
    ".cCccG",
    "..CcGX",
    "..mmmG",
    "..mmmm",
    "..mvmm",
    "..mmmm",
    "...mvm",
    "....mm",
])
FRONT_TAILS = mirrored([
    ".l.....m",
    ".l.....l",
    "l......l",
    "xX....xX",
    "xX....xX",
    ".x.....x",
])
WING_OPEN = [
    "..vvvv..........",
    ".vVVVVvv........",
    "vVVlllVVv.......",
    "VVlcPPclVv......",
    "VlcPKKPcVVv.....",
    "VlcPKKPcVVVv....",
    "VVlcPPclVVVVv...",
    ".VVlccllVVVVVv..",
    "..vVVVVVVVvvvv..",
    "...vvVVVVvv.....",
    "..vVVVVvv.......",
    ".vVPKPVvv.......",
    ".vVPPVVv........",
    "..vVVvv.........",
    "...vv...........",
]
WING_RAISED = [
    ".......vvv......",
    "......vVVVv.....",
    ".....vVlllVv....",
    ".....VlcPPcVv...",
    "....VlcPKKPcVv..",
    "....VlcPKKPcVVv.",
    "....VVlcPPclVVv.",
    ".....VVlcclVVVv.",
    "......vVVVVVVv..",
    ".......vVVVvv...",
    "......vVVvv.....",
    ".....vVPKPVv....",
    ".....vVPPVv.....",
    "......vVVv......",
    ".......vv.......",
]
FRONT_WINGS = [
    (mirrored([row[1:] for row in WING_OPEN]), 2, TOP + 2),
    (mirrored([row[2:] for row in WING_OPEN]), 3, TOP + 1),
    (mirrored([row[1:] for row in WING_RAISED]), 2, TOP),
]

SIDE_BODY = [
    "......G.G.....",
    ".....G..G.....",
    ".....g.g......",
    "......gg......",
    "......mMMM....",
    ".....mMMEMM...",
    "....cmMMMMM...",
    "...ccccMMMc...",
    "..cccccccc....",
    "..cCcccGc.....",
    "..mCcCGXG.....",
    "..mmmmcG......",
    ".mmmmmmm......",
    ".mmvmmmm......",
    "mmmmmvm.......",
    "mmvmmm........",
    ".mmm..........",
]
SIDE_TAILS = [
    ".......lll",
    ".....ll.l.",
    "....l..l..",
    "...l...l..",
    "..l....l..",
    ".xX...xX..",
    ".xX...xX..",
    "..x....x..",
]
SIDE_OPEN = [
    "...vvvvv......",
    "..vVVVVVvv....",
    ".vVllllVVVv...",
    "vVlcPPPclVVv..",
    "VlcPKKKPcVVVv.",
    "VlcPKKKPcVVVVv",
    "VVlcPPPclVVVVv",
    ".VVlcccllVVVv.",
    "..vVVVVVVVvv..",
    "...vvVVVvv....",
    "..vVVVvv......",
    ".vVPKPVv......",
    ".vVVPVv.......",
    "..vvvv........",
]
SIDE_RAISED = [
    ".....vvv....",
    "....vVVVv...",
    "...vVlllVv..",
    "...VlcPPcVv.",
    "..VlcPKKPcVv",
    "..VlcPKKPcVv",
    "..VVlcPPclVv",
    "...VVlcclVVv",
    "....vVVVVVv.",
    ".....vVVVv..",
    "....vVVv....",
    "...vVPVv....",
    "...vVVv.....",
]
SIDE_WINGS = [
    (SIDE_OPEN, 5, TOP + 2),
    (SIDE_OPEN, 6, TOP + 1),
    (SIDE_RAISED, 8, TOP),
]


def faceless(drawing):
    return recolored(drawing, "E", "M")


PARTS = {
    "front": (FRONT_WINGS, [(FRONT_BODY, 11, TOP), (FRONT_TAILS, 9, TOP + 17)]),
    "side": (SIDE_WINGS, [(SIDE_TAILS, 3, TOP + 15), (SIDE_BODY, 12, TOP + 2)]),
    "back": (
        [(recolored(d, "c", "C"), x, y) for d, x, y in FRONT_WINGS],
        [(recolored(FRONT_BODY, "EcX", "MCx"), 11, TOP), (FRONT_TAILS, 9, TOP + 17)],
    ),
}
PARTS["lower"] = PARTS["side"]
PARTS["upper"] = (SIDE_WINGS, [(SIDE_TAILS, 3, TOP + 15), (faceless(SIDE_BODY), 12, TOP + 2)])
IDLE = (0, 1, 2, 1)
WALK = (0, 1, 2, 0, 1, 2)


def drawer(poses):
    def draw(canvas, view, frame):
        wings, parts = PARTS[view]
        drawing, left, top = wings[poses[frame]]
        if frame % 2:
            drawing = recolored(drawing, "P", "p")
        canvas.stamp(drawing, left, top)
        for part, left, top in parts:
            canvas.stamp(part, left, top)

    return draw


if __name__ == "__main__":
    build(Path(__file__).parent, sys.argv[1], PALETTE, {"idle": drawer(IDLE), "walk": drawer(WALK)}, outline=OUTLINE)
