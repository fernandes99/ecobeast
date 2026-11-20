NILU_PAL = {
    "o": (22, 40, 98), "B": (44, 120, 224), "D": (28, 72, 168), "L": (120, 212, 255),
    "W": (226, 248, 255), "C": (248, 240, 224), "c": (206, 196, 184), "e": (20, 30, 70),
    "m": (226, 104, 120),
}
NILU = [
    "....oooo....",
    "..ooBLWBoo..",
    ".oLBBBBBBLo.",
    ".oDDDDDDDDo.",
    "oLoCeCCeCoLo",
    "oLLocCmcoLLo",
    ".oDooooooDo.",
    "..o.o..o.o..",
]

SEEDLET_PAL = {
    "o": (26, 62, 38), "G": (98, 186, 60), "g": (46, 132, 74), "Y": (190, 228, 78),
    "C": (246, 234, 178), "c": (214, 196, 136), "e": (18, 52, 34), "E": (60, 160, 84),
    "W": (255, 255, 255), "T": (36, 80, 92), "t": (24, 52, 62),
}
SEEDLET = [
    "..o..o..o...",
    ".oYooGooYo..",
    ".oGYGGGYGo..",
    "oGgGGGGGgGo.",
    "oGCeCCCeCGo.",
    "oCCeCCCeCCo.",
    ".ocCCmmCcoGo",
    "..oCCCCCoYGo",
    "..oTooooTo..",
    "..oTo..oTo..",
]
SEEDLET_PAL["m"] = (190, 120, 90)

RUVO_PAL = {
    "o": (92, 34, 18), "R": (226, 104, 38), "r": (184, 66, 26), "Y": (246, 160, 70),
    "C": (248, 222, 176), "c": (226, 186, 140), "e": (52, 24, 14), "E": (196, 100, 30),
    "W": (255, 250, 236), "F": (255, 214, 72), "f": (238, 76, 40), "P": (132, 42, 24),
    "n": (200, 90, 90),
}
RUVO = [
    ".o..F...o.....",
    "oCooFfooCo..F.",
    "oRRRRRRRRo.FfF",
    "oReWRReWRo.fFo",
    "oRECCCECRo.oFo",
    ".oCCnCCCo.oFo.",
    "..oCCCCoRRfo..",
    "..oRCCCRRRo...",
    "..oRCCCRrRo...",
    "..oRooRRoRo...",
    "..oPo.oPoPo...",
]


def to_image(grid, pal):
    from PIL import Image
    w = max(len(r) for r in grid)
    im = Image.new("RGBA", (w, len(grid)))
    px = im.load()
    for y, row in enumerate(grid):
        for x, ch in enumerate(row):
            if ch != ".":
                px[x, y] = pal[ch] + (255,)
    return im


SPRITES = {"nilu": (NILU, NILU_PAL), "seedlet": (SEEDLET, SEEDLET_PAL), "ruvo": (RUVO, RUVO_PAL)}
