"""Steal a Sheep's eating faces, drawn with Shear a Sheep's own face helpers (its art/sheep/mock_faces.py) so they
match the faces the sheep already wear: two variants, two frames each (a grazing sheep swaps between its frames as it
chews), shown on a pale and a black face beside Idle. Needs Pillow and a Shear a Sheep checkout on the Desktop.

    python art/faces/chew_faces.py

Writes art/faces/renders/<Name>.png (1024 x 1024, transparent, to upload) and art/faces/renders/sheet.png (the
mock-up). Variant A "Munch": MunchA, MunchB. Variant B "Nom": NomOpen, NomShut.
"""

import math
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = pathlib.Path(__file__).resolve().parent
# Shear a Sheep's checkout, on either of the user's PCs.
SHEAR = next(
    (
        path
        for path in (
            pathlib.Path.home() / "OneDrive" / "Desktop" / "Shear A Sheep" / "art" / "sheep",
            pathlib.Path.home() / "Desktop" / "Shear A Sheep" / "art" / "sheep",
        )
        if path.exists()
    ),
    None,
)
if SHEAR is None:
    sys.exit("Shear a Sheep's art/sheep folder isn't on the Desktop")
sys.path.insert(0, str(SHEAR))
sys.dont_write_bytecode = True

import mock_faces as faces  # noqa: E402

OUT = HERE / "renders"
GRASS, GRASS_DARK = (118, 206, 74), (70, 150, 48)


def blade(face, base, angle, length, width):
    """A grass blade from `base` (in the mouth) pointing `angle` degrees (0 = straight right, + bending down),
    tapering to a point and curving a little, with a thin ink edge so it reads on any face colour."""
    a = math.radians(angle)
    direction = (math.cos(a), math.sin(a))
    normal = (-direction[1], direction[0])
    points_top, points_bottom = [], []
    steps = 12
    for i in range(steps + 1):
        t = i / steps
        droop = 0.25 * length * t * t
        cx = base[0] + direction[0] * length * t + normal[0] * droop
        cy = base[1] + direction[1] * length * t + normal[1] * droop
        w = width * (1 - t) ** 0.8
        points_top.append((cx + normal[0] * w, cy + normal[1] * w))
        points_bottom.append((cx - normal[0] * w, cy - normal[1] * w))
    outline = points_top + points_bottom[::-1]
    face.line(outline + [outline[0]], 0.012, faces.INK, None)
    face.polygon(outline, GRASS)
    mid = [((a[0] + b[0]) / 2, (a[1] + b[1]) / 2) for a, b in zip(points_top[:9], points_bottom[:9])]
    face.line(mid, 0.006, GRASS_DARK, None)


def sprig(face, base, side):
    """A sprig of three blades poking out of the mouth's corner on `side` (1 right, -1 left)."""
    for angle, length, width in ((-28, 0.14, 0.02), (0, 0.17, 0.024), (26, 0.12, 0.018)):
        if side > 0:
            blade(face, base, angle, length, width)
        else:
            blade(face, base, 180 - angle, length, width)


def cheeks(face, strength=0.75):
    """Full cheeks: big round blush, a chewing sheep's mouthful."""
    for x in (0.25, 0.75):
        face.ellipse((x, 0.635), 0.075, 0.05, faces.BLUSH, strength)


def munch_mouth(face, shift):
    """A closed mouth working sideways: a small wavy line pushed `shift` to one side."""
    cx = 0.5 + shift
    face.line([(cx - 0.055, 0.69), (cx - 0.027, 0.705), (cx, 0.69), (cx + 0.027, 0.705), (cx + 0.055, 0.69)], 0.02)


# Variant A, "Munch": eyes shut and savouring (^ ^), full cheeks, the mouth working side to side with a sprig of grass
# sticking out of its corner.
def munch_a(face):
    faces.closed_eyes(face, up=True)
    cheeks(face)
    sprig(face, (0.555, 0.695), 1)
    munch_mouth(face, 0.025)


def munch_b(face):
    faces.closed_eyes(face, up=True)
    cheeks(face)
    sprig(face, (0.445, 0.695), -1)
    munch_mouth(face, -0.025)


# Variant B, "Nom": eyes open, looking down at the grass, the mouth opening on a green mouthful and closing again, a
# sprig hanging out of its side.
def nom_open(face):
    faces.open_eyes(face, look=(0.0, 0.035))
    faces.blush(face, 0.6)
    center, rx, ry = (0.5, 0.675), 0.06, 0.055
    faces.open_mouth(face, center, rx, ry, tongue=False)
    face.ellipse((0.5, 0.705), 0.04, 0.022, GRASS)
    sprig(face, (0.545, 0.69), 1)


def nom_shut(face):
    faces.open_eyes(face, look=(0.0, 0.035))
    cheeks(face, 0.7)
    sprig(face, (0.535, 0.7), 1)
    face.line(faces.arc((0.445, 0.695), (0.5, 0.715), (0.555, 0.695)), 0.02)


FACES = {"MunchA": munch_a, "MunchB": munch_b, "NomOpen": nom_open, "NomShut": nom_shut, "Idle": faces.idle}


def head_tile(face_png, colour, size):
    """The face on a rounded head of `colour`, as the Decal sits on the sheep's head."""
    tile = Image.new("RGBA", (size, size), (40, 44, 52, 255))
    head = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(head).rounded_rectangle((size * 0.06, size * 0.06, size * 0.94, size * 0.94), radius=size * 0.18,
                                           fill=colour + (255,))
    tile = Image.alpha_composite(tile, head)
    picture = face_png.resize((round(size * 0.88), round(size * 0.88)), Image.LANCZOS)
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    layer.paste(picture, (round(size * 0.06), round(size * 0.06)), picture)
    return Image.alpha_composite(tile, layer)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    pictures = {}
    for name, draw in FACES.items():
        face = faces.Face()
        draw(face)
        face.save(OUT / f"{name}.png")
        pictures[name] = Image.open(OUT / f"{name}.png").convert("RGBA")
    tile = 300
    rows = [("A  Munch", ["MunchA", "MunchB"]), ("B  Nom", ["NomOpen", "NomShut"])]
    colours = [(238, 216, 182), (36, 32, 34)]
    gap, label = 16, 44
    width = gap + (tile + gap) * 5
    height = label + (tile + gap) * 2 + gap
    sheet = Image.new("RGBA", (width, height), (24, 26, 32, 255))
    draw = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("arialbd.ttf", 26)
    except OSError:
        font = ImageFont.load_default()
    titles = ["now: Idle", "A frame 1", "A frame 2", "B frame 1", "B frame 2"]
    for column, title in enumerate(titles):
        draw.text((gap + column * (tile + gap) + 8, 10), title, fill=(230, 232, 240), font=font)
    names = ["Idle", "MunchA", "MunchB", "NomOpen", "NomShut"]
    for row, colour in enumerate(colours):
        for column, name in enumerate(names):
            sheet.paste(head_tile(pictures[name], colour, tile), (gap + column * (tile + gap), label + row * (tile + gap)))
    sheet.convert("RGB").save(OUT / "sheet.png")
    print("Wrote", OUT / "sheet.png")


if __name__ == "__main__":
    main()
