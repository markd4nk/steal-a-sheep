"""The Creator Hub icons for the Robux store's developer products and game passes (what Roblox's purchase dialog and
the game page show): each one's picture from its store card, on the card's colour with its studs and white rays, and
the card's own words where it has them ("+150K CLIMB", "2x SPEED", "Lv 1 > 2"); no prices or Robux. Squares for the
products; the passes keep their picture and words inside the circle Roblox crops them to.

    python art/store/make_store_art.py                                     the cards' pictures (art/store/export)
    the two Robux sheep, with the game's studs, into art/store/sheep: captured in a playtest
    (studio/RobuxSheepIcons.luau) and cut out by art/store/cut_out_sheep.py; render_robux_sheep.py
    draws studless stand-ins in Blender when no Studio is free
    python art/store/make_product_icons.py [<out folder>] [--store <Store.luau>]

Reads the products and passes from src/shared/Config/Store.luau (or the --store file, for a branch with the Creator Hub
ids), the walker's levels from Utils/Economy.luau, and the cards' colours from Screens/Store.luau's TINTS, so the
icons follow the game. Writes <Key>.png (512 x 512) for each into the out folder (default art/store/icons, gitignored:
the pictures hold gvesster's icons, which a game may use but not share) and contact_sheet.png: every icon with its key
and id, then the passes cropped to a circle. Needs Pillow and Roblox's Fredoka One (any installed version).
"""

import math
import os
import pathlib
import re
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SRC = ROOT / "src"
EXPORT = HERE / "export"
SHEEP = HERE / "sheep"
STUDS = ROOT / "DESIGN" / "ui" / "assets" / "studs.png"

SIZE = 512
SCALE = 2  # drawn at twice the size, then scaled down
STUD_TILE = 64  # pixels a stud tile at 512: the cards' 32-point tile, at the card's width to the icon's
RAYS = 16
RAY_SHARE = 1 / 3  # of each ray's slice that's white
RAY_ALPHA = 0.30  # the cards' Burst at 70% transparency
SHADE = 165 / 255  # the cards' gradient: their colour at the top, this much of it at the bottom
INK = (13, 13, 13)  # Theme's Color.Line
SNOW = (247, 250, 255)  # Color.Snow
LIME = (109, 255, 61)  # Color.Lime (the walker's next level)
GOLD = (255, 216, 74)  # Screens/Store's GOLD

# Each card's picture: a file in art/store/export (make_store_art.py's Theme.Icons names).
CLIMB_ART = [f"StoreClimb{i}" for i in range(1, 7)]
CASH_ART = [f"StoreCash{i}" for i in range(1, 6)]
PASS_ART = {"DoubleMoney": "StoreMoney", "DoubleGrowth": "StoreGrowth"}


def read(path):
    return pathlib.Path(path).read_text(encoding="utf-8")


def catalog(store_path):
    """The store's products and passes, in the store's order, from Config/Store.luau and Economy.luau."""
    store = read(store_path)
    economy = read(SRC / "shared" / "Utils" / "Economy.luau")
    screen = read(SRC / "client" / "Controllers" / "UIController" / "Screens" / "Store.luau")
    tints_block = re.search(r"local TINTS = \{(.*?)\n\}", screen, re.S).group(1)
    tints = {name: tuple(int(v) for v in rgb) for name, *rgb in
             re.findall(r"(\w+) = Color3\.fromRGB\((\d+), (\d+), (\d+)\)", tints_block)}
    ids_block = re.search(r"local PRODUCT_IDS[^=]*= \{([^{}]*)\}", store).group(1)
    ids = {key: int(value) for key, value in re.findall(r'\["([\w.]+)"\] = (\d+)', ids_block)}
    pass_block = re.search(r"local PASS_IDS[^=]*= \{([^{}]*)\}", store).group(1)
    ids.update({key: int(value) for key, value in re.findall(r"(\w+) = (\d+)", pass_block)})
    speed = re.search(r"Store\.SpeedPrices = table\.freeze\(\{(.*?)\}\)", store, re.S).group(1)
    rates = re.search(r"Economy\.WalkerRates = table\.freeze\(\{(.*?)\}\)", economy, re.S).group(1)
    max_walker = len(re.findall(r"[\d.e]+", rates)) - 1

    items = []
    for key, family in re.findall(r'Key = "(Sheep\.\w+)", Family = "(\w+)"', store):
        items.append(dict(Key=key, Kind="Sheep", Picture=SHEEP / f"{family}.png", Tint=tints[family]))
    for key, name in re.findall(r'\{ Key = "(\w+)", Name = "([^"]+)"', store):
        gold, word = name.split(" ", 1)
        items.append(dict(Key=key, Kind="Pass", Picture=EXPORT / f"{PASS_ART[key]}.png", Tint=tints[key],
                          Words=[(gold, GOLD, 1.0), (word.upper(), SNOW, 0.66)]))
    for buy in range(1, len(re.findall(r"\d+", speed)) + 1):
        items.append(dict(Key=f"Speed.{buy}", Kind="Product", Picture=EXPORT / "StoreSpeed.png",
                          Tint=tints["Speed"], Words=[("2x", GOLD, 1.0), ("SPEED", SNOW, 0.66)]))
    for level in range(max_walker):
        items.append(dict(Key=f"Walker.{level}", Kind="Product", Picture=EXPORT / "StoreWalker.png",
                          Tint=tints["Walker"], Words=[(f"Lv {level + 1}", SNOW, 0.8), (">", SNOW, 0.8),
                                                       (str(level + 2), LIME, 1.0)]))
    packs = re.findall(r'Key = "((Climb|Cash)\.(\d+))", Amount = ([\d.e]+)', store)
    for key, kind, index, amount in packs:
        art = (CLIMB_ART if kind == "Climb" else CASH_ART)[int(index) - 1]
        items.append(dict(Key=key, Kind="Product", Picture=EXPORT / f"{art}.png", Tint=tints[kind],
                          Words=[(f"+{short(float(amount))}", GOLD, 1.0), (kind.upper(), SNOW, 0.66)]))
    for item in items:
        item["Id"] = ids.get(item["Key"])
    return items


SUFFIXES = ["K", "M", "B", "T", "Qa", "Qi", "Sx"]


def short(value):
    """Utils/Format.Short: 150000 -> "150K", 1e6 -> "1M", 2.5e6 -> "2.5M"."""
    whole = int(abs(value))
    if whole < 1000:
        return str(whole)
    index = 0
    while index < len(SUFFIXES) - 1 and whole >= 1000 ** (index + 2):
        index += 1
    unit = 1000 ** (index + 1)
    if whole >= 1000 * unit:
        return f"{whole // unit:,}{SUFFIXES[index]}"
    decimals = 2 if whole < 10 * unit else 1 if whole < 100 * unit else 0
    kept = whole // (unit // 10 ** decimals)
    text = str(kept // 10 ** decimals)
    fraction = f"{kept % 10 ** decimals:0{decimals}d}".rstrip("0") if decimals else ""
    return text + ("." + fraction if fraction else "") + SUFFIXES[index]


def fredoka(size):
    versions = pathlib.Path(os.environ.get("LOCALAPPDATA", "")) / "Roblox" / "Versions"
    for font in sorted(versions.glob("*/content/fonts/FredokaOne-Regular.ttf")):
        return ImageFont.truetype(str(font), size)
    sys.exit(f"Roblox's FredokaOne-Regular.ttf isn't under {versions}")


def flat(colour, alpha):
    image = Image.new("RGBA", alpha.size, colour)
    image.putalpha(alpha)
    return image


def backdrop(tint, size):
    """The card: its colour at the top shading to 65% at the bottom, its studs, white rays from the middle."""
    bottom = tuple(round(c * SHADE) for c in tint)
    gradient = Image.new("RGB", (1, 256))
    for y in range(256):
        t = y / 255
        gradient.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(tint, bottom)))
    image = gradient.resize((size, size), Image.BILINEAR).convert("RGBA")

    tile = Image.open(STUDS).convert("RGBA").resize((STUD_TILE * SCALE,) * 2, Image.LANCZOS)
    studs = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    for y in range(0, size, tile.height):
        for x in range(0, size, tile.width):
            studs.alpha_composite(tile, (x, y))
    image.alpha_composite(studs)

    centre, reach = size / 2, size
    rays = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(rays)
    for i in range(RAYS):
        start = math.radians(i * 360 / RAYS - 90)
        end = math.radians(i * 360 / RAYS + 360 / RAYS * RAY_SHARE - 90)
        draw.polygon([(centre, centre), (centre + reach * math.cos(start), centre + reach * math.sin(start)),
                      (centre + reach * math.cos(end), centre + reach * math.sin(end))], fill=255)
    falloff = Image.radial_gradient("L").resize((size, size), Image.BILINEAR)
    falloff = falloff.point(lambda v: round(255 * max(0.0, 1 - v / 255 / 0.95) ** 0.8))
    rays = ImageChops.multiply(rays, falloff).point(lambda v: round(v * RAY_ALPHA))
    image.alpha_composite(flat((255, 255, 255), rays))

    glow = Image.radial_gradient("L").resize((size, size), Image.BILINEAR)
    glow = glow.point(lambda v: round(255 * 0.22 * max(0.0, 1 - v / 255 / 0.55) ** 1.5))
    image.alpha_composite(flat((255, 255, 255), glow))
    # A darker rim, so the icon holds together on Roblox's light and dark pages.
    rim = Image.radial_gradient("L").resize((size, size), Image.BILINEAR)
    rim = rim.point(lambda v: round(255 * 0.26 * min(1.0, max(0.0, (v / 255 - 0.62) / 0.5)) ** 1.4))
    image.alpha_composite(flat((0, 0, 0), rim))
    return image


def trimmed(path):
    if not path.exists():
        sys.exit(f"Missing {path}: run the commands in this script's docstring first")
    image = Image.open(path).convert("RGBA")
    return image.crop(image.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox())


def outlined(art, radius):
    """`art` in the store pictures' thick ink outline (compose2's ink and dilation), so a sheep reads on a card of its
    own colour. The ink goes round the silhouette only, never behind its see-through parts (Kronos's glass cape)."""
    import compose2
    import numpy as np

    padded = Image.new("RGBA", (art.width + 2 * radius + 4, art.height + 2 * radius + 4), (0, 0, 0, 0))
    padded.alpha_composite(art, (radius + 2, radius + 2))
    alpha = np.asarray(padded.getchannel("A"), dtype=np.uint8)
    solid = np.where(alpha > 8, 255, 0).astype(np.uint8)
    inside = 255 - compose2.dilate(255 - solid, 3)  # the silhouette less a 3-pixel edge band
    ink = np.where(inside > 0, 0, compose2.dilate(solid, radius)).astype(np.uint8)
    whole = Image.new("RGBA", padded.size, compose2.INK + (0,))
    whole.putalpha(Image.fromarray(ink))
    whole.alpha_composite(padded)
    return whole


def place(image, art, box, centre_x, foot_y, shadow=True, outline=0):
    """`art` fitted into a `box` square, its foot at `foot_y`, with a soft drop shadow (and an ink outline that many
    pixels wide)."""
    k = box / max(art.size)
    art = art.resize((max(1, round(art.width * k)), max(1, round(art.height * k))), Image.LANCZOS)
    if outline:
        art = outlined(art, outline)
    x, y = round(centre_x - art.width / 2), round(foot_y - art.height)
    if shadow:
        size = image.width
        drop = Image.new("RGBA", art.size, (0, 0, 0, 0))
        drop.putalpha(art.getchannel("A").point(lambda v: round(v * 0.34)))
        drop = drop.filter(ImageFilter.GaussianBlur(size * 0.012))
        image.alpha_composite(drop, (x, y + round(size * 0.02)))
    image.alpha_composite(art, (x, y))
    return (x, y, x + art.width, y + art.height)


def ground(image, centre_x, foot_y, width):
    """A soft oval shadow under a sheep's feet."""
    size = image.width
    oval = Image.new("L", (size, size), 0)
    h = width * 0.16
    ImageDraw.Draw(oval).ellipse((centre_x - width / 2, foot_y - h / 2, centre_x + width / 2, foot_y + h / 2), fill=90)
    image.alpha_composite(flat((0, 0, 0), oval.filter(ImageFilter.GaussianBlur(size * 0.018))))


def words(image, parts, height, centre_x, baseline):
    """A line of words, each (text, colour, size share), centred on `centre_x` with their feet on `baseline`, each
    with a thick ink edge as the cards' text has. ">" is drawn as the cards' little chevron."""
    pieces = []
    for text, colour, share in parts:
        size = round(height * share)
        font = fredoka(size)
        edge = max(2, round(size * 0.12))
        if text == ">":
            pieces.append(("chevron", colour, size, edge, size * 0.42))
            continue
        box = ImageDraw.Draw(image).textbbox((0, 0), text, font=font, anchor="ls", stroke_width=edge)
        pieces.append((text, colour, font, edge, box))
    gap = height * 0.16
    widths = [p[4] if p[0] == "chevron" else p[4][2] - p[4][0] for p in pieces]
    x = centre_x - (sum(widths) + gap * (len(pieces) - 1)) / 2
    draw = ImageDraw.Draw(image)
    for piece, width in zip(pieces, widths):
        if piece[0] == "chevron":
            _, colour, size, edge, w = piece
            mid = baseline - size * 0.36
            points = [(x, mid - w * 0.62), (x + w, mid), (x, mid + w * 0.62)]
            draw.polygon(points, fill=INK)
            draw.line(points + [points[0]], fill=INK, width=edge * 2, joint="curve")
            inset = [(x + w * 0.16, mid - w * 0.38), (x + w * 0.74, mid), (x + w * 0.16, mid + w * 0.38)]
            draw.polygon(inset, fill=colour)
        else:
            text, colour, font, edge, box = piece
            draw.text((x - box[0], baseline), text, font=font, anchor="ls", fill=colour, stroke_width=edge,
                      stroke_fill=INK)
        x += width + gap
    return x


def reach(image_alpha, centre):
    """How far from `centre` the farthest clearly visible pixel of a layer is."""
    box = image_alpha.point(lambda a: 255 if a > 40 else 0).getbbox()
    if not box:
        return 0
    corners = [(box[0], box[1]), (box[2], box[1]), (box[0], box[3]), (box[2], box[3])]
    return max(math.dist(c, centre) for c in corners)


def icon(item):
    size = SIZE * SCALE
    image = backdrop(item["Tint"], size)
    art = trimmed(item["Picture"])
    if item["Kind"] == "Sheep":
        box, foot = size * 0.78, size * 0.87
        ground(image, size / 2, foot - size * 0.03, size * 0.52)
        place(image, art, box, size / 2, foot, shadow=False, outline=round(size * 0.012))
    elif item["Kind"] == "Pass":
        # Inside the circle the game page crops a pass to: shrink the picture until its corners are.
        box = size * 0.66
        while True:
            layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
            place(layer, art, box, size / 2, size * 0.66)
            if reach(layer.getchannel("A"), (size / 2, size / 2)) <= size / 2 * 0.95 or box < size * 0.4:
                break
            box *= 0.96
        image.alpha_composite(layer)
        words(image, item["Words"], size * 0.15, size / 2, size * 0.84)
    else:
        place(image, art, size * 0.74, size / 2, size * 0.8)
        words(image, item["Words"], size * 0.16, size / 2, size * 0.93)
    return image.resize((SIZE, SIZE), Image.LANCZOS)


def contact_sheet(items, icons):
    """Every icon with its key (and Creator Hub id), then the passes as Roblox's game page shows them."""
    cell, pad, label = 168, 14, 34
    columns = 9
    rows = math.ceil(len(items) / columns)
    width = pad + columns * (cell + pad)
    passes = [item for item in items if item["Kind"] == "Pass"]
    height = pad + rows * (cell + label + pad) + 40 + cell + label + pad
    sheet = Image.new("RGBA", (width, height), (32, 30, 44, 255))
    draw = ImageDraw.Draw(sheet)
    font, small = fredoka(17), fredoka(13)
    for index, item in enumerate(items):
        x = pad + (index % columns) * (cell + pad)
        y = pad + (index // columns) * (cell + label + pad)
        sheet.alpha_composite(icons[item["Key"]].resize((cell, cell), Image.LANCZOS), (x, y))
        draw.text((x + cell / 2, y + cell + 4), item["Key"], font=font, fill=SNOW, anchor="mt")
        if item["Id"]:
            draw.text((x + cell / 2, y + cell + 22), str(item["Id"]), font=small, fill=(170, 170, 190), anchor="mt")
    y = pad + rows * (cell + label + pad) + 6
    draw.text((pad, y), "Passes as the game page crops them:", font=font, fill=SNOW)
    mask = Image.new("L", (cell * 4, cell * 4), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, cell * 4 - 1, cell * 4 - 1), fill=255)
    mask = mask.resize((cell, cell), Image.LANCZOS)
    for index, item in enumerate(passes):
        x = pad + index * (cell + pad)
        round_icon = icons[item["Key"]].resize((cell, cell), Image.LANCZOS)
        round_icon.putalpha(ImageChops.multiply(round_icon.getchannel("A"), mask))
        sheet.alpha_composite(round_icon, (x, y + 34))
    return sheet.convert("RGB")


def main():
    args = sys.argv[1:]
    store = SRC / "shared" / "Config" / "Store.luau"
    if "--store" in args:
        at = args.index("--store")
        store = pathlib.Path(args[at + 1])
        del args[at:at + 2]
    out = pathlib.Path(args[0]) if args else HERE / "icons"
    out.mkdir(parents=True, exist_ok=True)
    items = catalog(store)
    icons = {}
    for item in items:
        icons[item["Key"]] = icon(item)
        icons[item["Key"]].save(out / f"{item['Key']}.png")
    contact_sheet(items, icons).save(out / "contact_sheet.png")
    products = sum(1 for item in items if item["Kind"] != "Pass")
    print(f"Wrote {products} product and {len(items) - products} pass icons, and contact_sheet.png, to {out}")


if __name__ == "__main__":
    main()
