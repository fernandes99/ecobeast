"""Nilgorr: as folhas idle.png e walk.png. Uso: python sprites.py <pasta das prévias>

Com 1,50 m e 160 kg, ele tem 26 pixels de altura pela regra do mapa (creature-scale), com
o desenho de 22 crescido pelo `stretched` no casco, nos olhos, nas patas e nas pinças, e o corpo mais pesado do catálogo: um
caranguejo baixo e largo, com casco de pedra sobre uma bolha de água, duas antenas de
água e pinças enormes. Anda devagar, com passos curtos, em grupos alternados.
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from spritekit import build, recolored, rig, stretched, swayed  # noqa: E402

PALETTE = {
    "K": (20, 28, 60),     # contorno
    "B": (47, 102, 200),   # azul
    "D": (28, 58, 136),    # azul na sombra
    "L": (105, 208, 255),  # água
    "W": (205, 244, 255),  # brilho
    "S": (140, 138, 144),  # pedra
    "s": (92, 90, 98),     # pedra na sombra
    "G": (176, 174, 170),  # pedra na luz
    "E": (10, 16, 40),     # olho
    "A": (73, 200, 240),   # olho claro
}

HEAD_FRONT = stretched([
    ".......KKKKKK.......",
    ".....KKLLLWLLKK.....",
    "...KKLLBLLLLBLLKK...",
    "..KSKBBBLLLLBBBKSK..",
    ".KGSKBDBBLLBBDBKSGK.",
    ".KSSsKBBBBBBBBKsSSK.",
    "KGSSSKKSGKKGSKKSSSGK",
    "KSSsKSSSSSSSSSSKsSSK",
    "KssKDDSSSSSSSSDDKssK",
    ".KKDDDSEAKKAESDDDKK.",
    "...KDDDSSSSSSDDDK...",
    "....KKDDsKKsDDKK....",
    "......KKKKKKKK......",
], rows=(5, 9))
HEAD_LOWER = stretched([
    "........KKKKKK......",
    "......KKLLLWLLKK....",
    "....KKLLBLLLLBLLK...",
    "...KSKBBBLLLLBBBKK..",
    "..KGSKBDBBLLBBDBKSK.",
    "..KSSsKBBBBBBBBKsGK.",
    ".KGSSSKKSGKKGSKKSSK.",
    ".KSSsKSSSSSSSSSSSsK.",
    ".KssKDDSSSSSSSSSSDK.",
    "..KKDDDDSSEAKEAKDK..",
    "....KDDDDSSSSSSSK...",
    ".....KKDDDsKKsDK....",
    ".......KKKKKKKK.....",
], rows=(5, 9))
HEAD_SIDE = stretched([
    "......KKKKKK........",
    "....KKLLLWLLKK......",
    "..KKLLBLLLLBLLK.....",
    ".KSKBBBLLLLBBBKK....",
    "KGSKBDBBLLBBDBKSK...",
    "KSSsKBBBBBBBBKsGK...",
    "KGSSKKSGKKGSKKSSKK..",
    "KSSKSSSSSSSSSSSSSK..",
    "KsKDDSSSSSSSSSSSSSK.",
    ".KDDDDDDSSSSSEAKSSK.",
    "..KDDDDDDDSSSSSSSK..",
    "...KKDDDDDsKKssKK...",
    ".....KKKKKKKKKK.....",
], rows=(5, 9))
HEADS = {
    "front": (HEAD_FRONT, 6, 8),
    "lower": (HEAD_LOWER, 6, 8),
    "side": (HEAD_SIDE, 5, 8),
    "upper": (recolored(HEAD_LOWER, "EA", "SS"), 6, 8),
    "back": (recolored(HEAD_FRONT, "EA", "SS"), 6, 8),
}
LEG_NEAR = stretched(["KSSK", "KSSK", "KSSK", "KSsK", "KDsK", "KDDK", ".KK."], rows=(1, 2))
LEG_FAR = stretched([".KsK", ".KsK", ".KsK", "KsK.", "KDK.", "KDK.", "KK.."], rows=(1, 2))
LEGS = {
    "front": [(6, 0, LEG_FAR, 1), (9, 3, LEG_NEAR, 1), (15, 0, LEG_NEAR, 1), (19, 3, LEG_FAR, 1)],
    "back": [(6, 0, LEG_FAR, 1), (9, 3, LEG_NEAR, 1), (15, 0, LEG_NEAR, 1), (19, 3, LEG_FAR, 1)],
    "side": [(7, 0, LEG_FAR, 1), (10, 3, LEG_NEAR, 1), (14, 0, LEG_NEAR, 1), (18, 3, LEG_FAR, 1)],
    "lower": [(7, 0, LEG_FAR, 1), (10, 3, LEG_NEAR, 1), (15, 0, LEG_NEAR, 1), (19, 3, LEG_FAR, 1)],
    "upper": [(7, 0, LEG_FAR, 1), (10, 3, LEG_NEAR, 1), (15, 0, LEG_NEAR, 1), (19, 3, LEG_FAR, 1)],
}
CLAW_OPEN = stretched([
    ".KKK...",
    "KSGSK..",
    "KSSSK.K",
    "KLLBKKL",
    "KLWLBLK",
    "KLLWLLK",
    ".KLLLK.",
    "..KLK..",
    "...K...",
], rows=(4,))
CLAW_SHUT = stretched([
    ".KKK...",
    "KSGSK..",
    "KSSSKK.",
    "KLLBLLK",
    "KLWLLLK",
    "KLLWLLK",
    ".KLLLK.",
    "..KLK..",
    "...K...",
], rows=(4,))


def claws(left, gap):
    """As duas pinças na mesma linha, com a da direita espelhada."""
    return [row + "." * gap + row[::-1] for row in left]


ALL_CLAWS = [claws(CLAW_OPEN, 14), claws(CLAW_OPEN, 14), claws(CLAW_SHUT, 14), claws(CLAW_OPEN, 14)]
ONE_CLAW = [CLAW_OPEN, CLAW_OPEN, CLAW_SHUT, CLAW_OPEN]
ANTENNAE = swayed([
    "L....L",
    ".L...L",
    ".L..L.",
])
ANTENNAE_AT = {"front": (12, 6), "lower": (14, 6), "side": (11, 6), "upper": (14, 6), "back": (12, 6)}
CLAWS_AT = {"front": (2, 16), "back": (2, 16), "lower": (3, 16), "upper": (3, 16)}
TRAITS = [
    {"frames": ANTENNAE, "at": ANTENNAE_AT, "behind": ("front", "lower", "side", "upper", "back"), "follows": "head"},
    {"frames": ALL_CLAWS, "at": CLAWS_AT, "follows": "body"},
    {"frames": ONE_CLAW, "at": {"side": (19, 17)}, "follows": "body"},
]

if __name__ == "__main__":
    build(
        Path(__file__).parent,
        sys.argv[1],
        PALETTE,
        rig(HEADS, {}, LEGS, 23, TRAITS, idle_head=(0, 0, 1, 0), idle_body=(0, 0, 1, 0), walk_head=(0, 1, 0, 0, 1, 0), walk_body=(0, 1, 0, 0, 1, 0), foot_reach=(1, 0, -1, -1, 0, 1), foot_lift=(0, 0, 0, 0, 1, 1)),
    )
