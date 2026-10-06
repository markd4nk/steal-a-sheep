"""The store's pictures, each drawn as one icon: the containers (gen_svg.py) in a back and a front layer with the
winged sandals (gen_talaria.py) or the pack's cash between them, every piece edged thinly in the pack's ink, then one
thick outline round the whole, as the pack's own icons have. make_store_art.py runs it; it writes
composed/<sandal>/<name>.png (512 x 512)."""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
# gvesster's "Free Icon Pack v3.1 (Basic)": its icons are placed as they are (its licence lets a game use them, not
# edit or share them), so its PNGs and everything made with them stay out of git.
PACK = os.environ.get(
    "ICON_PACK",
    os.path.join(os.path.expanduser("~"), "Downloads", "Free Icon Pack v3.1 (Basic)", "Free Icon Pack v3.1 (Basic)"),
)
FILES = {
    "cash": r"Currency\Cash\256px\Green Cash 1st 256px.png",
    "bolt": r"Main\Lighting\256px\Blue Lighting 1st 256px.png",
    "clock": r"Item\Clock\256px\Golden Clock 1st 256px.png",
    "leaf": r"Nature\Leaf\256px\Leaf 1st 256px.png",
    "arrow": r"Main\Upgrade\256px\Green Upgrade 1st 256px.png",
}
W = 1024
INK = (4, 4, 53)
INNER = 9  # a piece's own edge, at 1024
OUTER = 24  # round the whole picture
OUT = os.path.join(HERE, "composed")

_cache = {}


SHOE = "talaria_white"  # the sandal every shoe in a picture is (make_store_art.py switches it for 2x Speed)


def load(name):
    if name == "shoe":
        name = SHOE
    if name not in _cache:
        if name in FILES:
            im = Image.open(os.path.join(PACK, FILES[name])).convert("RGBA")
        else:
            im = Image.open(os.path.join(HERE, "pieces", name + ".png")).convert("RGBA")
        _cache[name] = im
    return _cache[name]


def dilate(alpha, r):
    """Grey dilation of an alpha array by a disc of radius r (anti-aliased edges survive)."""
    out = alpha.copy()
    h, w = alpha.shape
    for dy in range(-r, r + 1):
        span = int(math.sqrt(r * r - dy * dy))
        for dx in range(-span, span + 1):
            if dx == 0 and dy == 0:
                continue
            ys, yd = (slice(0, h - dy), slice(dy, h)) if dy >= 0 else (slice(-dy, h), slice(0, h + dy))
            xs, xd = (slice(0, w - dx), slice(dx, w)) if dx >= 0 else (slice(-dx, w), slice(0, w + dx))
            np.maximum(out[yd, xd], alpha[ys, xs], out=out[yd, xd])
    return out


def ink_under(img, r):
    a = np.asarray(img.getchannel("A"), dtype=np.uint8)
    grown = dilate(a, r)
    edge = Image.new("RGBA", img.size, INK + (0,))
    edge.putalpha(Image.fromarray(grown))
    return edge


class Pic:
    def __init__(self):
        self.canvas = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        self.fx = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        self.under = Image.new("RGBA", (W, W), (0, 0, 0, 0))

    def lines(self, dx=0, dy=0, alpha=0.9):
        im = load("lines")
        layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        layer.alpha_composite(im, (dx, dy))
        layer.putalpha(layer.getchannel("A").point(lambda a: int(a * alpha)))
        self.under.alpha_composite(layer)
        return self

    def glow(self, cx, cy, r, color=(255, 230, 120), alpha=200):
        layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        ImageDraw.Draw(layer).ellipse((cx - r, cy - r, cx + r, cy + r), fill=color + (alpha,))
        self.under.alpha_composite(layer.filter(ImageFilter.GaussianBlur(r * 0.45)))
        return self

    def put(self, name, cx=512, cy=512, width=None, rot=0.0, flip=False, edge=True):
        """A pack icon by its centre and width, or a drawn piece as it lies on its own canvas (cx, cy, width None)."""
        im = load(name)
        if flip:
            im = im.transpose(Image.FLIP_LEFT_RIGHT)
        if width is not None:
            box = im.getbbox()
            im = im.crop(box)
            im = im.resize((round(width), round(im.height * width / im.width)), Image.LANCZOS)
        if rot:
            im = im.rotate(rot, resample=Image.BICUBIC, expand=True)
        layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        if width is None:
            layer.alpha_composite(im, (round(cx - 512), round(cy - 512)))
        else:
            layer.alpha_composite(im, (round(cx - im.width / 2), round(cy - im.height / 2)))
        if edge:
            self.canvas.alpha_composite(ink_under(layer, INNER))
        self.canvas.alpha_composite(layer)
        return self

    def sparkle(self, cx, cy, r):
        layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        t = r * 0.2
        d.polygon(
            [(cx, cy - r), (cx + t, cy - t), (cx + r, cy), (cx + t, cy + t), (cx, cy + r), (cx - t, cy + t), (cx - r, cy), (cx - t, cy - t)],
            fill=(255, 255, 255, 255),
        )
        self.fx.alpha_composite(layer.filter(ImageFilter.GaussianBlur(r * 0.3)))
        self.fx.alpha_composite(layer)
        return self

    def glint(self, cx, cy, r):
        """A white glint on the picture itself (the pack's corner shine), under the outline pass."""
        layer = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        d = ImageDraw.Draw(layer)
        t = r * 0.18
        d.polygon(
            [(cx, cy - r), (cx + t, cy - t), (cx + r, cy), (cx + t, cy + t), (cx, cy + r), (cx - t, cy + t), (cx - r, cy), (cx - t, cy - t)],
            fill=(255, 255, 255, 255),
        )
        self.canvas.alpha_composite(layer)
        return self

    def save(self, name, fill=0.96):
        whole = Image.new("RGBA", (W, W), (0, 0, 0, 0))
        whole.alpha_composite(self.under)
        whole.alpha_composite(ink_under(self.canvas, OUTER))
        whole.alpha_composite(self.canvas)
        whole.alpha_composite(self.fx)
        box = whole.getchannel("A").point(lambda a: 255 if a > 10 else 0).getbbox()
        box = (max(0, box[0] - 8), max(0, box[1] - 8), min(W, box[2] + 8), min(W, box[3] + 8))
        art = whole.crop(box)
        room = 488 * fill
        k = room / max(art.width, art.height)
        art = art.resize((max(1, round(art.width * k)), max(1, round(art.height * k))), Image.LANCZOS)
        out = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
        out.alpha_composite(art, ((512 - art.width) // 2, 500 - art.height - round((488 - room) / 2)))
        os.makedirs(os.path.join(OUT, SHOE), exist_ok=True)
        out.save(os.path.join(OUT, SHOE, name + ".png"))


def climb1():
    p = Pic()
    p.put("shoe", 520, 520, 640, -4)
    p.sparkle(880, 300, 44)
    return p


def climb2():
    p = Pic()
    p.put("shoe", 360, 400, 520, -2)
    p.put("shoe", 650, 620, 560, -6)
    p.sparkle(900, 300, 44).sparkle(160, 790, 30)
    return p


def climb3():
    p = Pic()
    p.put("shoe", 340, 660, 480, 4)
    p.put("shoe", 700, 670, 480, -6, True)
    p.put("shoe", 520, 440, 520, -3)
    p.sparkle(900, 260, 44).sparkle(120, 360, 32)
    return p


def in_sack(p, items, front="sack_front", back="sack_back"):
    # the sack's canvas is 512 points drawn at 1024: its mouth at (512, 428)
    p.put(back)
    for it in items:
        p.put(*it)
    p.put(front)


def climb4():
    p = Pic()
    in_sack(p, [("shoe", 420, 290, 400, 12), ("shoe", 620, 285, 400, -12, True), ("shoe", 525, 262, 430, 0)])
    p.sparkle(920, 230, 44).sparkle(110, 300, 30)
    return p


def in_chest(p, items, kind="chest"):
    p.put(kind + "_back")
    for it in items:
        p.put(*it)
    p.put(kind + "_front")


def climb5():
    p = Pic()
    in_chest(p, [("shoe", 400, 385, 420, 10), ("shoe", 725, 385, 420, -10, True), ("shoe", 565, 405, 470, -2)])
    p.sparkle(950, 280, 46).sparkle(110, 520, 30)
    return p


def climb6():
    p = Pic()
    in_chest(
        p,
        [
            ("shoe", 350, 345, 380, 10),
            ("shoe", 770, 345, 380, -10, True),
            ("shoe", 560, 300, 390, 0),
            ("shoe", 440, 405, 420, 4),
            ("shoe", 680, 405, 420, -4, True),
        ],
        "goldchest",
    )
    p.sparkle(960, 200, 50).sparkle(80, 220, 36).sparkle(940, 640, 28).sparkle(560, 120, 30)
    return p


def coins1():
    p = Pic()
    p.put("cash", 512, 540, 620, -4)
    p.sparkle(860, 300, 44)
    return p


def coins2():
    p = Pic()
    p.put("cash", 470, 640, 560, -4)
    p.put("cash", 560, 450, 560, 6)
    p.sparkle(880, 260, 44).sparkle(170, 380, 30)
    return p


def coins3():
    p = Pic()
    p.put("cash", 330, 650, 450, -4)
    p.put("cash", 700, 660, 450, 4)
    p.put("cash", 512, 460, 470, -2)
    p.sparkle(890, 290, 44).sparkle(140, 360, 32)
    return p


def coins4():
    p = Pic()
    in_sack(
        p,
        [("cash", 420, 410, 300, 24), ("cash", 620, 400, 300, -20), ("cash", 515, 330, 300, -6), ("cash", 512, 430, 310, 2)],
        front="moneysack_front",
    )
    p.sparkle(900, 250, 44).sparkle(120, 300, 30)
    return p


def coins5():
    p = Pic()
    in_chest(
        p,
        [
            ("cash", 360, 520, 330, 16),
            ("cash", 740, 520, 330, -12),
            ("cash", 450, 430, 320, 10),
            ("cash", 660, 425, 320, -8),
            ("cash", 556, 350, 340, -2),
        ],
    )
    p.sparkle(950, 290, 46).sparkle(110, 300, 34).sparkle(940, 640, 26)
    return p


def speed2x():
    p = Pic()
    p.lines(-200, 90)
    p.put("bolt", 840, 330, 260, -14, True)
    p.put("shoe", 560, 560, 680, -8)
    p.sparkle(900, 160, 44).sparkle(240, 800, 26)
    return p


def money2x():
    p = Pic()
    p.put("cash", 300, 680, 420, -4)
    p.put("cash", 720, 690, 420, 4)
    p.put("cash", 410, 500, 430, -6)
    p.put("cash", 620, 505, 430, 6)
    p.put("cash", 512, 330, 440, -2)
    p.sparkle(150, 300, 34).sparkle(880, 300, 40)
    return p


def growth2x():
    p = Pic()
    p.put("clock", 760, 330, 330, 8)
    p.put("pot_back")
    p.put("sprout", 512, 512, edge=True)
    p.put("leaf", 420, 350, 230, 30, flip=True)
    p.put("leaf", 640, 330, 250, -25)
    p.put("pot_front")
    p.sparkle(150, 300, 34).sparkle(890, 760, 26)
    return p


def walker():
    p = Pic()
    p.put("arrow", 300, 420, 250, 0)
    p.put("stairs", 512, 512, edge=True)
    p.put("shoe", 650, 330, 400, -4)
    p.sparkle(900, 200, 40)
    return p


def single():
    p = Pic()
    p.put("shoe", 512, 512, 800, 0)
    return p


ALL = {
    "talaria": (single, 0.98),
    "climb1": (climb1, 0.74),
    "climb2": (climb2, 0.8),
    "climb3": (climb3, 0.86),
    "climb4": (climb4, 0.92),
    "climb5": (climb5, 0.96),
    "climb6": (climb6, 1.0),
    "coins1": (coins1, 0.74),
    "coins2": (coins2, 0.8),
    "coins3": (coins3, 0.87),
    "coins4": (coins4, 0.94),
    "coins5": (coins5, 1.0),
    "speed2x": (speed2x, 0.98),
    "money2x": (money2x, 0.96),
    "growth2x": (growth2x, 0.96),
    "walker": (walker, 0.96),
}
