from collections import deque
from pathlib import Path

from PIL import Image

src = Path(
    r"C:\Users\sanje\.cursor\projects\d-SaaS-Application-Projects-bubbler-customer-side-links-Bubblercustomerlinks\assets"
)
clothes = Image.open(
    src / "image-2c6d4203-5e38-4968-943b-e51e036ae774.png"
).convert("RGBA")
basket = Image.open(
    src / "image-822845a4-f070-40ab-b2c0-5a71c3855a8f.png"
).convert("RGBA")
out = Path(__file__).resolve().parents[1] / "assets" / "laundry"
out.mkdir(parents=True, exist_ok=True)


def trim(image, pad=8):
    bbox = image.getbbox()
    if not bbox:
        return image
    left, top, right, bottom = bbox
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(image.width, right + pad)
    bottom = min(image.height, bottom + pad)
    return image.crop((left, top, right, bottom))


trim(basket, 12).save(out / "basket.png")

width, height = clothes.size
pixels = clothes.load()
seen = bytearray(width * height)
components = []
for y in range(height):
    for x in range(width):
        index = y * width + x
        if seen[index] or pixels[x, y][3] < 40:
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
            for nx, ny in ((cx - 1, cy), (cx + 1, cy), (cx, cy - 1), (cx, cy + 1)):
                if 0 <= nx < width and 0 <= ny < height:
                    neighbor = ny * width + nx
                    if not seen[neighbor] and pixels[nx, ny][3] >= 40:
                        seen[neighbor] = 1
                        queue.append((nx, ny))
        if area > 400:
            components.append((min_y, min_x, max_x, max_y))

components.sort(key=lambda box: (0 if box[0] < 80 else 1 if box[0] < 250 else 2 if box[0] < 430 else 3, box[1]))
names = [
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
if len(names) != len(components):
    raise SystemExit(f"expected {len(names)} pieces, found {len(components)}")

for name, (min_y, min_x, max_x, max_y) in zip(names, components):
    crop = clothes.crop((min_x, min_y, max_x + 1, max_y + 1))
    trim(crop, 4).save(out / f"{name}.png")
    print(name, crop.size)
