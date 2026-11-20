"""Venomaw: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,20 m e 38 kg, ela tem 22 pixels de altura pela regra do mapa (creature-scale): 20 de
desenho e o contorno roxo-escuro por fora. É uma serpente grossa, de várias voltas, com a
cabeça erguida, a juba de espinhos, a boca escancarada com as presas e a língua, o olho
verde-limão, a barriga creme e as marcas verde-limão em labareda. No idle, a língua entra e
sai e uma gota de veneno cai da presa; no walk, as marcas correm pelas voltas, como se o
corpo deslizasse.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import VIEWS, build, mirrored, recolored, rig  # noqa: E402

PALETTE = {
    "o": (46, 20, 44),     # contorno
    "L": (164, 100, 136),  # escama na luz
    "P": (124, 64, 98),    # escama roxo-ameixa
    "p": (84, 40, 68),     # escama na sombra
    "G": (190, 236, 52),   # marca verde-limão
    "C": (244, 220, 170),  # barriga creme
    "c": (206, 166, 124),  # creme na sombra
    "E": (230, 255, 90),   # olho
    "W": (250, 246, 230),  # presa
    "R": (140, 30, 56),    # boca
    "T": (220, 50, 84),    # língua
    "V": (150, 220, 40),   # gota de veneno
}
OUTLINE = {"*": "o"}

HEAD_SIDE = [
    "..p.p.p......",
    ".pPpPpPPp....",
    "pPPLLLLLPPp..",
    ".pPPPPEEPPPPp",
    "..pPPPPCCWCCW",
    "..pPPRRRRRRT.",
    "...pPCCWCCC..",
]
HEAD_FRONT = mirrored([
    "p...p..p",
    "Pp.pPPpP",
    ".pPPLLLL",
    "pPEEPPPP",
    ".pPPPCCC",
    "..pWRRRR",
    "...pCCWT",
])
NO_FACE = ("ECWRT", "PPPpp")
HEADS = {
    "front": (HEAD_FRONT, 9, 11),
    "lower": (HEAD_SIDE, 14, 11),
    "side": (HEAD_SIDE, 14, 11),
    "upper": (recolored(HEAD_SIDE, *NO_FACE), 14, 11),
    "back": (recolored(HEAD_FRONT, *NO_FACE), 9, 11),
}

COIL_SIDE = [
    "...........pPCC.......",
    "..........pPGCC.......",
    "......pPPPPPPCCp......",
    ".....pPLLGPPPCCPp.....",
    "G...pPPGGPPPPPPPPp....",
    "Pp..ppppppppppppppp...",
    "pPppPLLGPPPPPLLGPPPp..",
    ".pPPGGPPPPPGPPPPGGPPp.",
    ".pppppppppppppppppppp.",
    "pPLLLGPPPPPLLGGPPPLLPp",
    "pPGGPPPPPPGPPPPPGPPPPp",
    "pPPPPPPGPPPPPPPPPPPPPp",
    ".cccccccccccccccccccc.",
]
COIL_FRONT = mirrored([
    "........pC",
    ".......pPC",
    ".....pPPPC",
    "....pPLGPP",
    "....pPPGGP",
    "...ppppppp",
    "..pPLLGPPP",
    ".pPGGPPPPG",
    ".ppppppppp",
    "pPLLPPGGPP",
    "pPGPPPPPPP",
    "pPPPPPGPPP",
    ".ccccccccc",
])
NO_BELLY = ("Cc", "Pp")


def sliding(drawing):
    """Os 4 quadros das voltas: as marcas verdes andam 0 a 3 colunas pelas escamas."""
    base = [row.replace("G", "P") for row in drawing]
    frames = []
    for shift in range(4):
        frame = [list(row) for row in base]
        for j, row in enumerate(drawing):
            for i, mark in enumerate(row):
                if mark != "G":
                    continue
                k = i + shift
                while k < len(row) and base[j][k] != "P":
                    k += 1
                if k < len(row):
                    frame[j][k] = "G"
        frames.append(["".join(row) for row in frame])
    return frames


COIL = {
    "front": sliding(COIL_FRONT),
    "lower": sliding(COIL_SIDE),
    "side": sliding(COIL_SIDE),
    "upper": sliding(recolored(COIL_SIDE, *NO_BELLY)),
    "back": sliding(recolored(COIL_FRONT, *NO_BELLY)),
}
COIL_AT = {"front": (7, 18), "lower": (5, 18), "side": (5, 18), "upper": (5, 18), "back": (7, 18)}

TONGUE_SIDE = [["."], ["T"], ["TT"], ["T"]]
TONGUE_FRONT = [["."], ["T"], ["T", "T"], ["T"]]
TONGUE = {"front": TONGUE_FRONT, "lower": TONGUE_SIDE, "side": TONGUE_SIDE}
TONGUE_AT = {"front": (16, 18), "lower": (26, 16), "side": (26, 16)}

DRIP = [["V"], [".", "V"], [".", ".", "V"], ["."]]
DRIP_AT = {"front": (12, 17), "lower": (26, 17), "side": (26, 17)}

TRAITS = [
    {"frames": COIL, "at": COIL_AT, "behind": VIEWS, "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": TONGUE, "at": TONGUE_AT, "follows": "head", "walk": (0, 1, 2, 3, 0, 1)},
    {"frames": DRIP, "at": DRIP_AT, "follows": "head", "walk": (0, 1, 2, 3, 0, 1)},
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
