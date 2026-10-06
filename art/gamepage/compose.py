# Game page art from renders (tiles.py): the "STEAL A SHEEP" title and short captions in the game's own UI look
# (Fredoka One, round white or gold words in a thick black edge: Theme.Line, Snow, Gold), then the final sizes.
# Mock-ups for the user to pick from; nothing here uploads anything.
import glob
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT = next(iter(glob.glob(os.path.expandvars(
    r"%LOCALAPPDATA%\Roblox\Versions\*\content\fonts\FredokaOne-Regular.ttf"))))
LINE = (13, 13, 13)
SNOW = (247, 250, 255)
GOLD_HI = (255, 236, 140)
GOLD = (255, 196, 40)
GOLD_LO = (232, 140, 0)
SKY_HI = (140, 230, 255)
SKY_LO = (40, 150, 255)


def _gradient(size, top, bottom):
    w, h = size
    g = Image.new("RGB", (1, h))
    for y in range(h):
        t = y / max(h - 1, 1)
        g.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)))
    return g.resize((w, h))


def word(text, size, fill=SNOW, fill_bottom=None, stroke=None, shadow=True, tilt=0.0):
    """One line of title text as an RGBA image: a gradient (or flat) fill inside a thick black edge, a soft shadow."""
    font = ImageFont.truetype(FONT, size)
    stroke = stroke if stroke is not None else max(4, size // 9)
    pad = stroke * 3 + size // 4
    box = font.getbbox(text, stroke_width=stroke)
    w, h = box[2] - box[0] + pad * 2, box[3] - box[1] + pad * 2
    origin = (pad - box[0], pad - box[1])
    edge = Image.new("L", (w, h), 0)
    ImageDraw.Draw(edge).text(origin, text, font=font, fill=255, stroke_width=stroke, stroke_fill=255)
    inner = Image.new("L", (w, h), 0)
    ImageDraw.Draw(inner).text(origin, text, font=font, fill=255)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    if shadow:
        sh = edge.filter(ImageFilter.GaussianBlur(stroke * 0.8)).point(lambda v: int(v * 0.55))
        layer = Image.new("RGBA", (w, h), LINE + (0,))
        layer.putalpha(sh)
        out.alpha_composite(layer, (stroke // 2, int(stroke * 1.1)))
    black = Image.new("RGBA", (w, h), LINE + (255,))
    black.putalpha(edge)
    out.alpha_composite(black)
    ink = inner.getbbox() or (0, 0, w, h)
    face = _gradient((w, h), fill, fill_bottom or fill) if fill_bottom is None else Image.new("RGB", (w, h))
    if fill_bottom is not None:
        band = _gradient((w, ink[3] - ink[1]), fill, fill_bottom)
        face = Image.new("RGB", (w, h), fill_bottom)
        face.paste(_gradient((w, ink[1] + 1), fill, fill), (0, 0))
        face.paste(band, (0, ink[1]))
    face = face.convert("RGBA")
    face.putalpha(inner)
    out.alpha_composite(face)
    # A soft shine across the top of the letters, like the game's buttons.
    shine = Image.new("L", (w, h), 0)
    top = ink[1] + (ink[3] - ink[1]) * 0.08
    mid = ink[1] + (ink[3] - ink[1]) * 0.42
    ImageDraw.Draw(shine).rectangle((0, top, w, mid), fill=70)
    shine = Image.composite(shine, Image.new("L", (w, h), 0), inner).filter(ImageFilter.GaussianBlur(size / 40))
    white = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    white.putalpha(shine)
    out.alpha_composite(white)
    if tilt:
        out = out.rotate(tilt, resample=Image.BICUBIC, expand=True)
    return out.crop(out.getbbox())


def place(base, layer, cx, cy):
    """Pastes an RGBA layer centred on (cx, cy)."""
    base.alpha_composite(layer, (int(cx - layer.width / 2), int(cy - layer.height / 2)))


def title_block(width, small="STEAL A", big="SHEEP!", tilt=-4.0, gap=0.0):
    """The two-line title: STEAL A in white over a big gold SHEEP, sized to `width` px."""
    big_img = word(big, 400, GOLD_HI, GOLD_LO)
    small_img = word(small, 250, SNOW, (214, 228, 255))
    scale = width / big_img.width
    big_img = big_img.resize((int(big_img.width * scale), int(big_img.height * scale)), Image.LANCZOS)
    small_img = small_img.resize((int(small_img.width * scale), int(small_img.height * scale)), Image.LANCZOS)
    overlap = int(small_img.height * (0.28 - gap))
    w = max(big_img.width, small_img.width)
    h = small_img.height + big_img.height - overlap
    block = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    block.alpha_composite(big_img, ((w - big_img.width) // 2, small_img.height - overlap))
    block.alpha_composite(small_img, ((w - small_img.width) // 2, 0))
    if tilt:
        block = block.rotate(tilt, resample=Image.BICUBIC, expand=True)
    return block.crop(block.getbbox())


def vignette(img, strength=0.35):
    """Darkens the corners a little so the middle pops."""
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).ellipse((-w * 0.25, -h * 0.25, w * 1.25, h * 1.25), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(min(w, h) / 6))
    dark = Image.new("RGBA", (w, h), LINE + (int(255 * strength),))
    dark.putalpha(Image.eval(mask, lambda v: int((255 - v) * strength)))
    out = img.convert("RGBA")
    out.alpha_composite(dark)
    return out


def finish(img, size, path):
    out = img.convert("RGB").resize(size, Image.LANCZOS)
    out.save(path)
    return out


def contact_sheet(paths, out, thumb, cols, label_size=28, pad=24):
    ims = [Image.open(p).convert("RGB") for p in paths]
    tw, th = thumb
    rows = (len(ims) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (tw + pad) + pad, rows * (th + pad + label_size + 8) + pad), (34, 38, 48))
    font = ImageFont.truetype(FONT, label_size)
    d = ImageDraw.Draw(sheet)
    for n, (im, p) in enumerate(zip(ims, paths)):
        x = pad + (n % cols) * (tw + pad)
        y = pad + (n // cols) * (th + pad + label_size + 8)
        d.text((x, y), os.path.splitext(os.path.basename(p))[0], font=font, fill=SNOW)
        sheet.paste(im.resize((tw, th), Image.LANCZOS), (x, y + label_size + 8))
    sheet.save(out)
