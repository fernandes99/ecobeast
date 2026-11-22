"""Gera as nuvens em pixel art da Home do Hub (.specs/hub-start/05-island-walk.md).

Uso: python -I make_clouds.py   (precisa do Pillow; grava clouds.png ao lado)

Uma folha de 3 nuvens lado a lado, cada uma numa célula de 64×28: cada nuvem é a união
de bolhas redondas com o pé reto, em 3 tons (o alto claro, o meio e a barriga azulada).
O jogo escurece a folha à noite pelo modulate.
"""

import math
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
CELL = (64, 28)
TOP = (255, 255, 255, 255)
MID = (233, 242, 251, 255)
BELLY = (196, 214, 235, 255)
## As bolhas de cada nuvem: centro x, centro y e raio, na célula.
CLOUDS = [
    [(14, 18, 8), (26, 13, 11), (40, 15, 9), (51, 19, 7)],
    [(12, 19, 6), (22, 15, 9), (34, 12, 10), (45, 17, 8)],
    [(18, 18, 9), (32, 14, 10), (46, 19, 6)],
]
BASE = 23


def inside(blobs, x: float, y: float) -> bool:
    if y > BASE:
        return False
    return any(math.hypot(x - cx, y - cy) <= r for cx, cy, r in blobs)


def light(blobs, x: float, y: float) -> float:
    """Quanto o pixel está perto do alto da bolha mais alta que o cobre (0 a 1)."""
    best = 0.0
    for cx, cy, r in blobs:
        d = math.hypot(x - cx, y - cy)
        if d <= r:
            best = max(best, (cy - y) / r * 0.5 + 0.5)
    return best


def main() -> None:
    sheet = Image.new("RGBA", (CELL[0] * len(CLOUDS), CELL[1]), (0, 0, 0, 0))
    for index, blobs in enumerate(CLOUDS):
        for y in range(CELL[1]):
            for x in range(CELL[0]):
                px, py = x + 0.5, y + 0.5
                if not inside(blobs, px, py):
                    continue
                if py > BASE - 3 or not inside(blobs, px, py + 3):
                    color = BELLY
                elif light(blobs, px, py) > 0.72:
                    color = TOP
                else:
                    color = MID
                sheet.putpixel((index * CELL[0] + x, y), color)
    sheet.save(os.path.join(HERE, "clouds.png"))


if __name__ == "__main__":
    main()
