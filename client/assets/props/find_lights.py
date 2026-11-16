"""Acha os pontos de luz da noite na arte das peças (.specs/day-night/03-night-lights.md).

Uso: python -I find_lights.py   (precisa do Pillow; roda de dentro de assets/props)

Imprime as linhas de server/prisma/seed-data/prop_type_lights.json. Como acha (ver LUZES.md):
- janela: os pixels de vidro (azul claro: b ≥ 140, b − r ≥ 40, b ≥ g), juntos em grupos, e os
  grupos a até 2 px um do outro viram uma janela só; o centro do retângulo é a luz;
- telhado ou parede azul fica de fora: um grupo grande (20 px de largura ou 16 de altura) que
  começa nos 45% de cima da arte;
- lâmpada: os pixels amarelos (r > 200, g > 150, b < 140) numa faixa escolhida à mão (LAMPS);
- as variantes com a mesma silhueta só mudam de cor e ficam com as luzes da que achou mais
  janelas (um telhado azul ou roxo engole a janela encostada nele);
- uma variante só ganha linhas próprias quando as luzes dela mudam; senão, vale a variante 0.
O x e o y são o pixel do centro da luz a partir do pé (o meio da borda de baixo da arte).
"""

import json
import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))

WINDOW_COLOR = "ffcf70"
LAMP_COLOR = "ffd890"
LAMP_RADIUS = 28
WALL_LAMP_RADIUS = 18

# tipo de peça, slug, quantas variantes
TYPES = [
    (18, "lamp_post", 2),
    (22, "refuge_building", 1),
    (23, "shop_building", 1),
    (24, "town_house", 9),
    (25, "town_house_medium", 12),
    (26, "town_house_large", 10),
    (27, "observatory", 1),
    (95, "big_house", 8),
    (96, "small_house", 8),
    (97, "small_townhouse", 8),
]

# as lâmpadas: (slug, variante) -> [(x0, y0, x1, y1) da faixa onde procurar o amarelo, raio]
LAMPS = {
    ("lamp_post", 1): [((0, 0, 26, 16), LAMP_RADIUS)],
    ("lamp_post", 2): [((12, 0, 26, 16), LAMP_RADIUS)],
    ("observatory", 1): [((28, 50, 42, 64), WALL_LAMP_RADIUS), ((52, 50, 66, 64), WALL_LAMP_RADIUS)],
}

# o telhado azul da Loja não é vidro
SKIP_ABOVE = {"shop_building": 35}


def is_glass(pixel: tuple) -> bool:
    r, g, b, a = pixel
    return a > 200 and b >= 140 and b - r >= 40 and b >= g


def is_lamp(pixel: tuple) -> bool:
    r, g, b, a = pixel
    return a > 200 and r > 200 and g > 150 and b < 140


def groups(image: Image.Image, test, area=None, skip_above=0) -> list:
    width, height = image.size
    pixels = image.load()
    x0, y0, x1, y1 = area or (0, 0, width, height)
    seen = set()
    found = []
    for y in range(max(y0, skip_above), min(y1, height)):
        for x in range(x0, min(x1, width)):
            if (x, y) in seen or not test(pixels[x, y]):
                continue
            stack = [(x, y)]
            seen.add((x, y))
            box = [x, y, x, y]
            while stack:
                cx, cy = stack.pop()
                box = [min(box[0], cx), min(box[1], cy), max(box[2], cx), max(box[3], cy)]
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    inside = x0 <= nx < min(x1, width) and max(y0, skip_above) <= ny < min(y1, height)
                    if inside and (nx, ny) not in seen and test(pixels[nx, ny]):
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            found.append(box)
    return found


def merge(boxes: list, gap: int = 2) -> list:
    boxes = [list(b) for b in boxes]
    changed = True
    while changed:
        changed = False
        for i in range(len(boxes)):
            for j in range(i + 1, len(boxes)):
                a, b = boxes[i], boxes[j]
                if a[0] - gap <= b[2] + 1 and b[0] - gap <= a[2] + 1 and a[1] - gap <= b[3] + 1 and b[1] - gap <= a[3] + 1:
                    boxes[i] = [min(a[0], b[0]), min(a[1], b[1]), max(a[2], b[2]), max(a[3], b[3])]
                    del boxes[j]
                    changed = True
                    break
            if changed:
                break
    return boxes


def lights_of(slug: str, variant: int) -> list:
    image = Image.open(os.path.join(HERE, slug, f"{variant}.png")).convert("RGBA")
    width, height = image.size
    result = []

    def add(box: list, radius: int, color: str) -> None:
        cx = (box[0] + box[2]) // 2
        cy = (box[1] + box[3]) // 2
        result.append((cx - width // 2, cy - height, radius, color))

    if (slug, variant) in LAMPS:
        for area, radius in LAMPS[(slug, variant)]:
            found = groups(image, is_lamp, area)
            if found:
                add(merge(found, 8)[0], radius, LAMP_COLOR)
        return result
    for box in merge(groups(image, is_glass, skip_above=SKIP_ABOVE.get(slug, 0))):
        box_width = box[2] - box[0] + 1
        box_height = box[3] - box[1] + 1
        if box_width * box_height < 6:
            continue
        # um telhado ou uma parede azul: grande e no alto da arte
        if (box_width >= 20 or box_height >= 16) and box[1] < height * 0.45:
            continue
        size = max(box[2] - box[0] + 1, box[3] - box[1] + 1)
        add(box, max(6, min(16, size // 2 + 4)), WINDOW_COLOR)
    result.sort(key=lambda light: (light[1], light[0]))
    return result


def shape_of(slug: str, variant: int) -> bytes:
    return Image.open(os.path.join(HERE, slug, f"{variant}.png")).convert("RGBA").getchannel("A").tobytes()


def main() -> None:
    rows = []
    for type_id, slug, variants in TYPES:
        per_variant = {v: lights_of(slug, v) for v in range(1, variants + 1)}
        # As variantes de mesmo formato (a mesma silhueta) só mudam de cor; um telhado
        # azul ou roxo engole a janela ao lado, então vale a que achou mais janelas.
        shapes = {}
        for v in per_variant:
            shapes.setdefault(shape_of(slug, v), []).append(v)
        for group in shapes.values():
            best = max((per_variant[v] for v in group), key=len)
            for v in group:
                per_variant[v] = best
        common = per_variant[1]
        same = all(lights == common for lights in per_variant.values())
        targets = {0: common} if same else per_variant
        for variant, lights in targets.items():
            for position, (x, y, radius, color) in enumerate(lights):
                rows.append({
                    "id": len(rows) + 1,
                    "prop_type_id": type_id,
                    "variant": variant,
                    "position": position,
                    "x": x,
                    "y": y,
                    "radius": radius,
                    "color": color,
                })
    print("[")
    print(",\n".join("\t" + json.dumps(row, ensure_ascii=False).replace('{"', '{ "').replace('}', ' }').replace('", "', '", "') for row in rows))
    print("]")


if __name__ == "__main__":
    main()
