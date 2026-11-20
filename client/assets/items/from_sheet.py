"""Ícones de item a partir de uma imagem de IA com os objetos lado a lado (.specs/item-icons/02-spheres.md).

python from_sheet.py <imagem> <tamanho> <slug> [<slug> ...]

O fundo é a transparência da imagem ou, sem ela, o magenta chapado. Os objetos são lidos da esquerda
para a direita e reduzidos todos pelo mesmo fator, o que deixa o maior lado do maior com <tamanho> px.
Cada pixel novo pega a cor que mais cobre a área dele, numa paleta de 18 cores do objeto; assim vale
também para as imagens em que a IA desenhou pixels de tamanhos diferentes. Cada ícone vai centrado
numa tela de 32x32, com 1 px livre embaixo.
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

CANVAS = 32
COLORS = 18


def opaque_mask(rgba: np.ndarray) -> np.ndarray:
    alpha = rgba[:, :, 3]
    if (alpha < 128).any():
        return alpha >= 128
    r, g, b = rgba[:, :, 0], rgba[:, :, 1], rgba[:, :, 2]
    magenta = (r > 70) & (b > 70) & (g < 110) & (np.abs(r - b) < 70) & (r > g + 40)
    return ~magenta


def boxes(mask: np.ndarray) -> list[tuple[int, int, int, int]]:
    found, start = [], None
    for x, on in enumerate(list(mask.any(0)) + [False]):
        if on and start is None:
            start = x
        elif not on and start is not None:
            rows = np.where(mask[:, start:x].any(1))[0]
            found.append((start, x, int(rows.min()), int(rows.max()) + 1))
            start = None
    return found


def palette(pixels: np.ndarray) -> np.ndarray:
    rng = np.random.default_rng(1)
    pixels = pixels[rng.choice(len(pixels), min(20000, len(pixels)), replace=False)]
    centers = pixels[rng.choice(len(pixels), COLORS, replace=False)].copy()
    for _ in range(25):
        label = ((pixels[:, None] - centers[None]) ** 2).sum(2).argmin(1)
        for k in range(COLORS):
            if (label == k).any():
                centers[k] = pixels[label == k].mean(0)
    return centers


def reduce(rgb: np.ndarray, mask: np.ndarray, pitch: float) -> Image.Image:
    colors = palette(rgb[mask])
    label = np.full(mask.shape, -1)
    label[mask] = ((rgb[mask][:, None] - colors[None]) ** 2).sum(2).argmin(1)
    height, width = round(mask.shape[0] / pitch), round(mask.shape[1] / pitch)
    out = np.zeros((height, width, 4), np.uint8)
    for ty in range(height):
        for tx in range(width):
            cell = label[round(ty * pitch):round((ty + 1) * pitch), round(tx * pitch):round((tx + 1) * pitch)].ravel()
            if (cell < 0).mean() > 0.5:
                continue
            out[ty, tx] = (*colors[np.bincount(cell[cell >= 0], minlength=COLORS).argmax()].astype(np.uint8), 255)
    icon = Image.fromarray(out)
    return icon.crop(icon.getbbox())


def main() -> None:
    source, size, slugs = sys.argv[1], int(sys.argv[2]), sys.argv[3:]
    rgba = np.asarray(Image.open(source).convert("RGBA")).astype(float)
    mask = opaque_mask(rgba)
    found = boxes(mask)
    assert len(found) == len(slugs), f"{len(found)} objetos na imagem, {len(slugs)} slugs"
    pitch = max(max(x1 - x0, y1 - y0) for x0, x1, y0, y1 in found) / size
    for (x0, x1, y0, y1), slug in zip(found, slugs):
        icon = reduce(rgba[y0:y1, x0:x1, :3], mask[y0:y1, x0:x1], pitch)
        assert icon.width <= CANVAS and icon.height < CANVAS, f"{slug}: {icon.size} não cabe em {CANVAS}x{CANVAS}"
        canvas = Image.new("RGBA", (CANVAS, CANVAS))
        canvas.alpha_composite(icon, ((CANVAS - icon.width) // 2, CANVAS - 1 - icon.height))
        canvas.save(Path(__file__).parent / f"{slug}.png", optimize=True)
        print(slug, icon.size)


if __name__ == "__main__":
    main()
