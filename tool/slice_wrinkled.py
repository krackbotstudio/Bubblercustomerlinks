"""Slice the wrinkled-clothes sheet into assets/laundry/wrinkled/.

Only the pieces shown in the booking basket are kept. Underwear crops are
skipped on purpose.
"""

from collections import deque
from pathlib import Path

from PIL import Image

src = Path(
    r"C:\Users\sanje\.cursor\projects\d-SaaS-Application-Projects-bubbler-customer-side-links-Bubblercustomerlinks\assets\image-341ffdc6-d1ad-4fb8-b130-0e009ec34487.png"
)
out = Path(__file__).resolve().parents[1] / "assets" / "laundry" / "outline"
out.mkdir(parents=True, exist_ok=True)

# Same left-to-right, top-to-bottom order as the sheet.
order = [
    "tshirt",
    "polo",
    "shirt",
    "plaid",
    "hoodie",
    "sweatshirt",
    "jeans",
    "trousers",
    "cargo",
    "shorts",
    "yellowshorts",
    "underwear",
    "briefs",
    "tank",
    "kurta",
    "saree",
    "dress",
    "salwar",
    "skirt",
    "scarf",
    "socks",
    "anklesocks",
    "towelstack",
    "towel",
    "bedsheet",
    "blanket",
    "stripedsheet",
]
keep = {
    "tshirt",
    "polo",
    "shirt",
    "plaid",
    "hoodie",
    "jeans",
    "trousers",
    "shorts",
    "kurta",
    "saree",
    "dress",
    "towel",
    "blanket",
    "bedsheet",
}


def render(image, points, pad=8):
    """Copy only this garment's pixels. A bounding-box crop keeps neighbors."""
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
        key=lambda box: (
            0
            if box[0] < height * 0.22
            else 1
            if box[0] < height * 0.48
            else 2
            if box[0] < height * 0.74
            else 3,
            box[1],
        )
    )
    return found


def main():
    clothes = Image.open(src).convert("RGBA")
    print("sheet", clothes.size)
    found = components(clothes)
    print("pieces", len(found))
    if len(found) != len(order):
        for box in found:
            print(box)
        raise SystemExit(f"expected {len(order)} pieces, found {len(found)}")
    for name, (min_y, min_x, max_x, max_y, points) in zip(order, found):
        if name not in keep:
            continue
        crop = render(clothes, points)
        crop.save(out / f"{name}.png")
        print(name, crop.size, "pixels", len(points))


if __name__ == "__main__":
    main()
