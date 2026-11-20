"""Snekit: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 0,40 m, ela tem 10 pixels de altura pela regra do mapa (creature-scale): 8 de desenho e
o contorno roxo-escuro por fora. Cabem a crista de espinhos, o olho verde-limão meio
fechado, a mandíbula creme, a língua vermelha, a barriga creme em placas, as marcas
verde-limão nas costas e a ponta da cauda em barbatana. Sem patas, ela fica enrolada: no
idle, a língua entra e sai; no walk, as voltas ondulam e a cauda balança.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import VIEWS, build, rig  # noqa: E402

PALETTE = {
    "o": (46, 20, 44),     # contorno
    "L": (164, 100, 136),  # escama na luz
    "P": (124, 64, 98),    # escama roxo-ameixa
    "p": (84, 40, 68),     # escama na sombra
    "G": (190, 236, 52),   # marca verde-limão
    "C": (244, 220, 170),  # barriga creme
    "c": (206, 166, 124),  # creme na sombra
    "E": (230, 255, 90),   # olho
    "T": (220, 50, 84),    # língua
}
OUTLINE = {"*": "o"}

HEAD_SIDE = [
    "pP.P...",
    ".pLLLP.",
    ".pPPEPP",
    "..pPCCC",
]
HEAD_FRONT = [
    "P..P..P",
    ".pLLLp.",
    "pEPPPEp",
    ".pPCPp.",
    "..pCp..",
]
HEAD_BACK = [
    "P..P..P",
    ".pLGLp.",
    "pPPPPPp",
    ".pPGPp.",
    "..pPp..",
]
HEAD_UPPER = [
    "pP.P...",
    ".pLGLP.",
    ".pPPPPP",
    "..pPPPp",
]
HEADS = {
    "front": (HEAD_FRONT, 13, 23),
    "lower": (HEAD_SIDE, 13, 23),
    "side": (HEAD_SIDE, 13, 23),
    "upper": (HEAD_UPPER, 13, 23),
    "back": (HEAD_BACK, 13, 23),
}

COIL_SIDE = [
    ["..pPCC..", "PLPPCC..", "GPPPPCC.", "pcccccc."],
    ["..pPCC..", "PLPPCC..", "PGPPPCC.", "pcccccc."],
    ["..pPCC..", "PLPPCC..", "PPGPPCC.", "pcccccc."],
    ["..pPCC..", "PLPPCC..", "PPPGPCC.", "pcccccc."],
]
COIL_FRONT = [
    ["..pCp..", ".PLPLP.", "GPPGPPG", ".pcccp."],
    ["..pCp..", ".PLGLP.", "PGPPPGP", ".pcccp."],
    ["..pCp..", ".PLPLP.", "GPPGPPG", ".pcccp."],
    ["..pCp..", ".PLGLP.", "PGPPPGP", ".pcccp."],
]
COIL_BACK = [[row.replace("C", "P").replace("c", "p") for row in frame] for frame in COIL_FRONT]
COIL_UPPER = [[row.replace("C", "P").replace("c", "p") for row in frame] for frame in COIL_SIDE]
COIL = {"front": COIL_FRONT, "lower": COIL_SIDE, "side": COIL_SIDE, "upper": COIL_UPPER, "back": COIL_BACK}
COIL_AT = {"front": (13, 27), "lower": (13, 27), "side": (13, 27), "upper": (13, 27), "back": (13, 27)}

TAIL_SIDE = [["G.", "Pp"], [".G", "Pp"], ["G.", "Pp"], ["..", "GP"]]
TAIL_BACK = [["G", "P"], ["G", "P"], [".", "G"], ["G", "P"]]
TAIL = {"lower": TAIL_SIDE, "side": TAIL_SIDE, "upper": TAIL_SIDE, "back": TAIL_BACK}
TAIL_AT = {"lower": (11, 27), "side": (11, 27), "upper": (11, 27), "back": (20, 27)}

TONGUE_SIDE = [["."], ["T"], ["TT"], ["."]]
TONGUE_FRAMES = {"front": [["."], ["T"], ["T"], ["."]], "lower": TONGUE_SIDE, "side": TONGUE_SIDE}
TONGUE_AT = {"front": (16, 28), "lower": (20, 26), "side": (20, 26)}

TRAITS = [
    {"frames": TAIL, "at": TAIL_AT, "behind": VIEWS, "walk": (0, 1, 2, 3, 2, 1)},
    {"frames": COIL, "at": COIL_AT, "behind": VIEWS, "walk": (0, 1, 2, 3, 2, 1)},
    {"frames": TONGUE_FRAMES, "at": TONGUE_AT, "follows": "head", "walk": (0, 1, 2, 0, 1, 2)},
]
NO_LEGS = {view: [] for view in VIEWS}

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, NO_LEGS, 30, TRAITS, idle_head=(0, 0, 1, 0), idle_body=(0, 0, 0, 0), walk_head=(0, 1, 1, 0, 1, 1), walk_body=(0, 0, 0, 0, 0, 0)),
        outline=OUTLINE,
    )
