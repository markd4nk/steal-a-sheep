"""Cuts a sheep out of two Studio captures of the same view, one on black and one on white (studio/RobuxSheepIcons.luau),
for the product icons (make_product_icons.py). Where the two agree the sheep is solid; where they differ by the whole
range it's background; in between (edges, Kronos's glass cape) it's see-through by that much, and its colour is the
black capture's divided by its opacity.

    python art/store/cut_out_sheep.py <on black> <on white> <out.png> [--box x,y,w,h]

The box is the view's place in the captures (what the Studio snippet returns); without it the whole capture is used.
Writes a transparent PNG trimmed to the sheep, art/store/sheep/<Family>.png for the icons.
"""

import sys

import numpy as np
from PIL import Image


def main():
    args = sys.argv[1:]
    box = None
    if "--box" in args:
        at = args.index("--box")
        box = tuple(int(v) for v in args[at + 1].split(","))
        del args[at:at + 2]
    if len(args) != 3:
        sys.exit(__doc__)
    black_path, white_path, out_path = args
    black = Image.open(black_path).convert("RGB")
    white = Image.open(white_path).convert("RGB")
    if box:
        x, y, w, h = box
        black = black.crop((x, y, x + w, y + h))
        white = white.crop((x, y, x + w, y + h))
    b = np.asarray(black, dtype=np.float32) / 255
    w = np.asarray(white, dtype=np.float32) / 255
    # The captures are JPEGs: a little noise either way is still background or still solid.
    alpha = 1 - (w - b).mean(axis=2)
    alpha = np.clip((alpha - 0.04) / 0.92, 0, 1)
    colour = np.where(alpha[..., None] > 0.01, b / np.maximum(alpha[..., None], 0.01), 0)
    rgba = np.dstack([np.clip(colour, 0, 1), alpha])
    image = Image.fromarray((rgba * 255 + 0.5).astype(np.uint8), "RGBA")
    solid = image.getchannel("A").point(lambda a: 255 if a > 24 else 0)
    image = image.crop(solid.getbbox())
    image.save(out_path)
    print(f"Wrote {out_path} ({image.width} x {image.height})")


if __name__ == "__main__":
    main()
