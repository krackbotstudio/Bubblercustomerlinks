"""Slice the folded-clothes sheet into assets/laundry/folded/.

Only the pieces shown in the booking basket are kept. Underwear crops are
skipped on purpose.
"""

from collections import deque
from pathlib import Path

from PIL import Image

src = Path(
    r"C:\Users\sanje\.cursor\projects\d-SaaS-Application-Projects-bubbler-customer-side-links-Bubblercustomerlinks\assets\image-8b554e17-1e45-46c6-a03e-adb28d725085.png"
)
out = Path(__file__).resolve().parents[1] / "assets" / "laundry" / "folded"
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
    "cushion",
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


def trim(image, pad=6):
    bbox = image.getbbox()
    if not bbox:
        return image
    left, top, right, bottom = bbox
    return image.crop(
        (
            max(0, left - pad),
            max(0, top - pad),
            min(image.width, right + pad),
            min(image.height, bottom + pad),
        )
    )


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
            min_x = max_x = x
            min_y = max_y = y
            area = 0
            while queue:
                cx, cy = queue.popleft()
                area += 1
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
            if area > min_area:
                found.append((min_y, min_x, max_x, max_y, area))
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
    for name, (min_y, min_x, max_x, max_y, area) in zip(order, found):
        if name not in keep:
            continue
        crop = trim(clothes.crop((min_x, min_y, max_x + 1, max_y + 1)))
        crop.save(out / f"{name}.png")
        print(name, crop.size, "area", area)


if __name__ == "__main__":
    main()
