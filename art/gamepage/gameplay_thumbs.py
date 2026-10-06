# Game page thumbnails from real gameplay frames: Studio captures of a playtest (1914 x 960, the viewport with Studio's
# panels closed and Full Screen on), each cropped to 16:9, scaled to 1920 x 1080 and given the "STEAL A SHEEP!" title
# from compose.py. How the frames were staged is in README.md. Mock-ups for the user; nothing here uploads anything.
#
#   python gameplay_thumbs.py <frames dir> <out dir>
import os
import sys

from PIL import Image

from compose import contact_sheet, finish, place, title_block, vignette

SIZE = (1920, 1080)

# Frame file, where the 16:9 crop starts (0 = left edge, 1 = right edge), and the title: centre as a share of the
# final frame, width in px and tilt (None: no title).
SHOTS = [
    ("1_pan_dives", "pan_lunge.jpg", 0.5, (0.21, 0.8), 640, 4.0),
    ("2_zeus_dives", "zeus_lunge.jpg", 0.0, (0.25, 0.8), 640, 4.0),
    ("3_behind_you", "sneak.jpg", 0.0, (0.25, 0.18), 640, -4.0),
    ("4_run_home", "run.jpg", 0.0, (0.3, 0.17), 680, -4.0),
    ("5_full_pen", "pen.jpg", 0.5, (0.21, 0.17), 620, -4.0),
]


def crop_16_9(img, at):
    w, h = img.size
    cw = round(h * 16 / 9)
    if cw <= w:
        x = round((w - cw) * at)
        return img.crop((x, 0, x + cw, h))
    ch = round(w * 9 / 16)
    return img.crop((0, 0, w, ch))


def build(frames, out):
    os.makedirs(out, exist_ok=True)
    titled, clean = [], []
    for name, frame, at, centre, width, tilt in SHOTS:
        img = crop_16_9(Image.open(os.path.join(frames, frame)).convert("RGB"), at).resize(SIZE, Image.LANCZOS)
        plain = os.path.join(out, f"gamepage_play_{name}_clean.png")
        finish(img, SIZE, plain)
        clean.append(plain)
        art = vignette(img, 0.22)
        if width:
            place(art, title_block(width, tilt=tilt), SIZE[0] * centre[0], SIZE[1] * centre[1])
        path = os.path.join(out, f"gamepage_play_{name}.png")
        finish(art, SIZE, path)
        titled.append(path)
    contact_sheet(titled, os.path.join(out, "gamepage_play_sheet.png"), (640, 360), 2)
    contact_sheet(clean, os.path.join(out, "gamepage_play_clean_sheet.png"), (640, 360), 2)


if __name__ == "__main__":
    build(sys.argv[1], sys.argv[2])
