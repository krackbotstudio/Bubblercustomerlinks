"""Slice the latest clothes sheet into assets/laundry/catalog/.

Each file keeps only the pixels of that garment. Bounding boxes overlap
where pieces sit close together, and a plain crop was leaving a sliver of
the neighbour on the card.
"""

from collections import deque
from pathlib import Path

from PIL import Image

src = Path(
    r"C:\Users\sanje\.cursor\projects\d-SaaS-Application-Projects-bubbler-customer-side-links-Bubblercustomerlinks\assets\image-494972fc-6a2c-4410-ad46-581af0c0bdbf.png"
)
out = Path(__file__).resolve().parents[1] / "assets" / "laundry" / "catalog"
out.mkdir(parents=True, exist_ok=True)

# Left to right, top to bottom. The yellow hoodie and purple sweatshirt touch,
# so that component is split before naming. Underwear is not saved.
order = [
    "shirt",
    "polo",
    "tshirt",
    "hoodie",
    "sweatshirt",
    "shorts",
    "trousers",
    "cargos",
    "blazer",
    "kurta",
    "tank",
    "socks",
    "underwear",
    "saree",
    "blouse",
    "kurti",
    "salwar",
    "dress",
    "skirt",
    "leggings",
    "scarf",
    "cardigan",
    "pajamas",
    "camisole",
    "kidstee",
    "kidshorts",
    "kiddress",
    "uniform",
    "kidpants",
    "kidskirt",
    "onesie",
    "overalls",
    "kidhoodie",
    "kidpajamas",
    "towel",
    "handtowel",
    "bedsheet",
    "pillow",
    "blanket",
    "curtain",
    "tablecloth",
    "cushion",
    "mat",
]
skip = {"underwear"}


def components(image, alpha=40, min_area=400):
    width, height = image.size
    pixels = image.load()
    seen = bytearray(width * height)
    found = []
    for y in range(height):
        for x in range(width):
            index = y * width + x
            if seen[index] or pixels[x, y][3] < alpha:
                continue
            queue = deque([(x, y)])
            seen[index] = 1
            points = []
            min_x = max_x = x
            min_y = max_y = y
            while queue:
                cx, cy = queue.popleft()
                points.append((cx, cy))
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)
                for nx, ny in (
                    (cx - 1, cy),
                    (cx + 1, cy),
                    (cx, cy - 1),
                    (cx, cy + 1),
                ):
                    if 0 <= nx < width and 0 <= ny < height:
                        neighbor = ny * width + nx
                        if not seen[neighbor] and pixels[nx, ny][3] >= alpha:
                            seen[neighbor] = 1
                            queue.append((nx, ny))
            if len(points) > min_area:
                found.append((min_y, min_x, max_x, max_y, points))
    found.sort(
        key=lambda piece: (
            0
            if piece[0] < height * 0.22
            else 1
            if piece[0] < height * 0.48
            else 2
            if piece[0] < height * 0.74
            else 3,
            piece[1],
        )
    )
    return found


def split_touching_tops(image, pieces):
    """Split the one top-row piece that contains both the hoodie and sweatshirt."""
    pixels = image.load()
    split = []
    for min_y, min_x, max_x, max_y, points in pieces:
        width = max_x - min_x
        if len(points) < 10000 or width < 140:
            split.append(points)
            continue
        columns = {}
        for x, y in points:
            columns[x] = columns.get(x, 0) + (1 if pixels[x, y][3] >= 40 else 0)
        best_x = None
        best_count = 10**9
        for x in range(min_x + 40, max_x - 40):
            count = columns.get(x, 0)
            if count < best_count:
                best_count = count
                best_x = x
        if best_x is None:
            split.append(points)
            continue
        left = [(x, y) for x, y in points if x <= best_x]
        right = [(x, y) for x, y in points if x > best_x]
        split.append(left)
        split.append(right)
    return split


def render(image, points, pad=10):
    pixels = image.load()
    xs = [x for x, _ in points]
    ys = [y for _, y in points]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    crop = Image.new(
        "RGBA",
        (max_x - min_x + 1 + pad * 2, max_y - min_y + 1 + pad * 2),
        (0, 0, 0, 0),
    )
    target = crop.load()
    for x, y in points:
        target[x - min_x + pad, y - min_y + pad] = pixels[x, y]
    return crop


def main():
    clothes = Image.open(src).convert("RGBA")
    pieces = split_touching_tops(clothes, components(clothes))
    print("sheet", clothes.size, "pieces", len(pieces))
    if len(pieces) != len(order):
        raise SystemExit(f"expected {len(order)} pieces, found {len(pieces)}")
    for name, points in zip(order, pieces):
        if name in skip:
            print("skip", name, len(points))
            continue
        crop = render(clothes, points)
        crop.save(out / f"{name}.png")
        print(name, crop.size, "pixels", len(points))


if __name__ == "__main__":
    main()
