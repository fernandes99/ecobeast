"""Ruvak: as folhas da luta, idle.png e walk.png (board-battle/07).

Uso: python -I sprites.py <pasta das prévias>

Desenhado à mão, sem o PixelLab, por decisão do dono: um boneco de peças (puppet.py,
na skill creature-sprites) que o renderizador vira para cada vista. O Ruvak é um lobo
jovem e esguio: patas longas e escuras, peito e bochechas creme, orelhas altas, olhar
sério, crina e cauda de fogo.
"""
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / ".claude/skills/creature-sprites/scripts"))

from puppet import Decal, Part, Renderer, chain, rotation, write_preview, write_sheet  # noqa: E402

CELL = 64
PALETTE = {
    "K": (48, 14, 12),     # contorno
    "R": (176, 44, 20),    # contorno da chama
    "E": (28, 8, 6),       # pupila e focinho
    "A": (255, 186, 52),   # âmbar do olho
    "W": (255, 246, 220),  # brilho do olho
    "C": (250, 226, 186),  # creme da sobrancelha
}
RAMPS = {
    "fur": [(194, 64, 26), (232, 108, 34), (250, 156, 56)],
    "dark": [(122, 32, 20), (166, 50, 26), (204, 80, 32)],
    "cream": [(214, 168, 128), (244, 214, 172), (255, 238, 208)],
    "sock": [(66, 22, 16), (98, 36, 24), (132, 54, 34)],
    "inner": [(176, 96, 64), (226, 168, 124), (246, 206, 160)],
}
FLAME = [(255, 236, 128), (255, 176, 40), (242, 96, 24)]

# Olhos: o ponto do carimbo marcado pela âncora cai sobre o olho. "front" é o olho
# esquerdo da tela (o direito do Ruvak); o outro sai espelhado.
EYE = {
    "front": ["KK.", "EAK", "KK."],
    "turned": ["KK.", "EAK", ".K."],
    "side": ["KK", "EA", ".K"],
}
NOSE = {"front": ["EE"], "turned": ["EE"], "side": ["E"]}

IDLE_FRAMES = 8
WALK_FRAMES = 4


def cream_front(threshold):
    return lambda u: "cream" if u[0] > threshold else "fur"


def torso_paint(u):
    return "dark" if u[1] > 0.45 else "fur"


def head_paint(u):
    if u[1] < -0.15 and u[0] > -0.2:
        return "cream"
    return "fur"


def snout_paint(u):
    return "cream" if u[1] < 0.15 else "fur"


def ear_paint(u):
    return "inner" if u[0] > 0.35 else "dark"


def flame_glow(u):
    # A ponta da chama é vermelha; o meio, laranja; a base, amarela.
    if u[1] > 0.45 or abs(u[2]) > 0.8:
        return FLAME[2]
    if u[1] > -0.2:
        return FLAME[1]
    return FLAME[0]


def leg(hip, foot, bend, parts):
    """Coxa laranja, canela escura e pata, com o joelho empurrado por `bend`."""
    length = 25.0
    d = math.dist(hip, foot)
    lift = math.sqrt(max(0.0, (length / 2.0) ** 2 - (d / 2.0) ** 2))
    knee = ((hip[0] + foot[0]) / 2.0 + bend * lift, (hip[1] + foot[1]) / 2.0, (hip[2] + foot[2]) / 2.0)
    # O escuro começa no meio da canela, como no front.png.
    ankle = (knee[0] + (foot[0] - knee[0]) * 0.4, knee[1] + (foot[1] - knee[1]) * 0.4, knee[2] + (foot[2] - knee[2]) * 0.4)
    parts += chain([hip, knee], (3.4, 2.4), "fur", tag="leg")
    parts += chain([knee, ankle], (2.4, 2.1), "fur", tag="leg")
    parts += chain([ankle, foot], (2.1, 1.8), "sock", tag="leg")
    parts.append(Part((foot[0] + 1.3, foot[1] - 0.3, foot[2]), (2.8, 1.6, 2.2), "sock", tag="leg"))


def flame(base, height, phase, parts, tag):
    """Uma chama de 3 línguas que tremula com `phase` (0 a 1)."""
    sway = math.sin(phase * 2 * math.pi)
    parts.append(Part(base, (height * 0.42, height * 0.5, height * 0.42), None, glow=flame_glow, outline="R", tag=tag))
    tip = (base[0] - 1.0 + sway * 1.2, base[1] + height * 0.55, base[2])
    parts.append(Part(tip, (height * 0.26, height * 0.42, height * 0.26), None, glow=flame_glow, outline="R", tag=tag))
    tongue = (base[0] + 2.0 - sway, base[1] + height * 0.35 + abs(sway), base[2] + 1.0)
    parts.append(Part(tongue, (height * 0.18, height * 0.3, height * 0.18), None, glow=flame_glow, outline="R", tag=tag))


def model(feet, body_y=0.0, head_y=0.0, breath=0.0, tail_sway=0.0, flicker=0.0):
    """As peças do Ruvak. `feet` é {nome: (frente, altura)} de cada pata."""
    parts = []
    by = 26.0 + body_y
    # Patas: as de lá primeiro não importa; quem decide quem cobre é a profundidade.
    hips = {"fl": (9.0, by - 2.0, -4.6), "fr": (9.0, by - 2.0, 4.6), "bl": (-10.0, by - 1.0, -4.6), "br": (-10.0, by - 1.0, 4.6)}
    rest = {"fl": 11.0, "fr": 11.0, "bl": -11.0, "br": -11.0}
    for name, hip in hips.items():
        reach, lift = feet[name]
        foot = (rest[name] + reach, 1.8 + lift, hip[2])
        leg(hip, foot, 0.4 if name[0] == "f" else -0.8, parts)
    # Corpo esguio: quadril, tronco e peito.
    parts.append(Part((-9.0, by + 1.0, 0.0), (7.5, 7.0 + breath * 0.3, 6.6), torso_paint, tag="body"))
    parts.append(Part((0.0, by + 1.0, 0.0), (12.0, 6.5 + breath * 0.4, 6.2), torso_paint, tag="body"))
    parts.append(Part((9.5, by + 1.5, 0.0), (6.8, 8.0 + breath * 0.5, 7.2), cream_front(0.35), tag="body"))
    # Tufo do peito.
    for side in (-1.5, 1.5):
        parts.append(Part((14.0, by - 4.5, side), (1.6, 3.6, 1.4), "cream", axes=rotation(pitch=-20), tag="body"))
    # Pescoço e cabeça.
    hy = by + 15.0 + head_y
    parts += chain([(9.0, by + 4.0, 0.0), (14.0, hy - 3.0, 0.0)], (5.4, 4.6), cream_front(0.4), tag="body")
    parts.append(Part((16.0, hy, 0.0), (6.4, 6.0, 6.8), head_paint, tag="head"))
    parts.append(Part((22.0, hy - 1.8, 0.0), (5.2, 2.8, 3.0), snout_paint, axes=rotation(pitch=-8), tag="head"))
    # Bochechas de pelo creme, pontudas para trás.
    for side in (-1, 1):
        parts.append(Part((13.0, hy - 3.5, side * 5.2), (4.0, 1.6, 1.6), "cream", axes=rotation(yaw=side * 25, pitch=-25), tag="head"))
    # Orelhas altas.
    for side in (-1, 1):
        parts += chain([(14.0, hy + 4.0, side * 3.2), (12.5, hy + 13.0, side * 4.2)], (3.0, 0.7), ear_paint, tag="ear")
    # Crina: tufos escuros apontando para trás e uma chama atrás da cabeça.
    parts.append(Part((9.0, hy + 1.0, 0.0), (5.0, 2.4, 3.4), "dark", axes=rotation(pitch=155), tag="mane"))
    flame((6.5, hy + 1.5, 0.0), 4.5, flicker, parts, "mane-flame")
    # Cauda cheia que vira chama na ponta.
    sway = tail_sway
    tail = [(-15.0, by + 3.0, 0.0), (-21.0, by + 5.0, sway * 0.5), (-25.0, by + 10.0, sway)]
    parts += chain(tail, (2.6, 5.6), "fur", tag="tail")
    flame((-26.0 + sway * 0.3, by + 15.0, sway), 9.5, flicker + 0.3, parts, "tail-flame")

    head = (16.0, hy, 0.0)
    decals = []
    for side in (-1, 1):
        point = (head[0] + 4.6, head[1] + 1.0, side * 3.0)
        normal = (0.7, 0.15, side * 0.7)
        decals.append(Decal(point, normal, EYE, anchor=(1, 1), mirror=side > 0, min_facing=0.05))
    decals.append(Decal((27.0, hy - 0.8, 0.0), (1.0, 0.3, 0.0), NOSE, anchor=(0, 0), min_facing=0.05))
    return parts, decals


def idle(view, frame):
    phase = frame / IDLE_FRAMES
    breath = math.sin(phase * 2 * math.pi)
    still = {name: (0.0, 0.0) for name in ("fl", "fr", "bl", "br")}
    return model(still, body_y=0.0, head_y=round(breath * 0.6, 2), breath=breath, tail_sway=math.sin(phase * 2 * math.pi) * 1.5, flicker=phase)


# Diagonais juntas: a dianteira esquerda com a traseira direita, e o contrário.
WALK_REACH = {"a": (4.0, 0.0, -4.0, 0.0), "b": (-4.0, 0.0, 4.0, 0.0)}
WALK_LIFT = {"a": (0.0, 0.0, 0.0, 3.0), "b": (0.0, 3.0, 0.0, 0.0)}
WALK_BODY = (-1.0, 0.0, -1.0, 0.0)
WALK_HEAD = (0.0, -1.0, 0.0, -1.0)


def walk(view, frame):
    pair = {"fl": "a", "br": "a", "fr": "b", "bl": "b"}
    feet = {name: (WALK_REACH[p][frame], WALK_LIFT[p][frame]) for name, p in pair.items()}
    return model(feet, body_y=WALK_BODY[frame], head_y=WALK_HEAD[frame], tail_sway=(1.5, 0.0, -1.5, 0.0)[frame], flicker=frame / WALK_FRAMES)


def main():
    here = Path(__file__).parent
    previews = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    renderer = Renderer(PALETTE, RAMPS, cell=CELL, ground_row=58)
    sheets = {
        "idle": (("south", "north"), IDLE_FRAMES, idle),
        "walk": (("south-east", "east", "north-east"), WALK_FRAMES, walk),
    }
    for name, (views, count, build) in sheets.items():
        lines = []
        for view in views:
            lines.append([renderer.render(view, *build(view, frame)) for frame in range(count)])
        write_sheet(here / (name + ".png"), lines, CELL)
        if previews is not None:
            previews.mkdir(parents=True, exist_ok=True)
            write_preview(previews / (name + "_quadros.png"), lines, CELL)
    print("folhas em", here)


if __name__ == "__main__":
    main()
