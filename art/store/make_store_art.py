"""The Robux store's pictures (the user's picks from the 2026-10-05 mock-ups): Hermes' winged sandal with white wings
for the climbing icon and every Climbing pack, gold wings for 2x Speed, cash for the Cash packs, all drawn as single
outlined icons in gvesster's pack's manner.

    python art/store/make_store_art.py

Needs Pillow, numpy, Chrome or Edge (it draws the SVGs), and gvesster's "Free Icon Pack v3.1 (Basic)" in Downloads
(or ICON_PACK pointing at its folder). Writes export/<Theme.Icons name>.png at 512 px (and Talaria at 256, the HUD's
size) plus export/sheet.png. Nothing it writes goes in git: the pictures hold the pack's icons, whose licence allows
using them in a game, not sharing them.

To upload: serve the folder (`python -m http.server 8765 --bind 127.0.0.1 --directory art/store/export`), pass
`http://127.0.0.1:8765/<name>.png` to the Studio MCP's `upload_image`, and put each id in Theme.Icons under that name.
"""

import os
import shutil
import subprocess
import sys

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import compose2  # noqa: E402
import gen_svg  # noqa: E402,F401  (writes draw/*.svg as it loads)
import gen_talaria  # noqa: E402,F401

BROWSERS = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
]
DRAW = os.path.join(HERE, "draw")
PIECES = os.path.join(HERE, "pieces")
EXPORT = os.path.join(HERE, "export")
ROBUX_ICON = os.path.join("Currency", "Robux", "256px", "Golden Robux 1st Outline 256px.png")

# Theme.Icons name: (the sandal the picture is drawn with, the composer's picture).
PICTURES = {
    "StoreClimb1": ("talaria_white", "climb1"),
    "StoreClimb2": ("talaria_white", "climb2"),
    "StoreClimb3": ("talaria_white", "climb3"),
    "StoreClimb4": ("talaria_white", "climb4"),
    "StoreClimb5": ("talaria_white", "climb5"),
    "StoreClimb6": ("talaria_white", "climb6"),
    "StoreCash1": ("talaria_white", "coins1"),
    "StoreCash2": ("talaria_white", "coins2"),
    "StoreCash3": ("talaria_white", "coins3"),
    "StoreCash4": ("talaria_white", "coins4"),
    "StoreCash5": ("talaria_white", "coins5"),
    "StoreSpeed": ("talaria_gold", "speed2x"),
    "StoreMoney": ("talaria_white", "money2x"),
    "StoreGrowth": ("talaria_white", "growth2x"),
    "StoreWalker": ("talaria_white", "walker"),
    "Talaria": ("talaria_white", "talaria"),
}


def browser() -> str:
    for path in BROWSERS:
        if os.path.exists(path):
            return path
    raise SystemExit("Chrome or Edge is needed to draw the SVGs")


def render_svgs():
    """Each drawn piece at 1024 px on a transparent canvas."""
    os.makedirs(PIECES, exist_ok=True)
    exe = browser()
    for file in sorted(os.listdir(DRAW)):
        if not file.endswith(".svg"):
            continue
        out = os.path.join(PIECES, file[:-4] + ".png")
        subprocess.run(
            [
                exe,
                "--headless=new",
                "--disable-gpu",
                "--hide-scrollbars",
                "--force-device-scale-factor=2",
                "--window-size=512,512",
                "--default-background-color=00000000",
                "--virtual-time-budget=3000",
                f"--screenshot={out}",
                "file:///" + os.path.join(DRAW, file).replace("\\", "/"),
            ],
            check=True,
            capture_output=True,
        )


def compose():
    for sandal in ("talaria_white", "talaria_gold"):
        compose2.SHOE = sandal
        compose2._cache.pop("talaria_white", None)
        compose2._cache.pop("talaria_gold", None)
        for theme_name, (wanted, picture) in PICTURES.items():
            if wanted == sandal:
                make, fill = compose2.ALL[picture]
                make().save(picture, fill)
                print("made", theme_name, flush=True)


def export():
    os.makedirs(EXPORT, exist_ok=True)
    for theme_name, (sandal, picture) in PICTURES.items():
        shutil.copy(os.path.join(compose2.OUT, sandal, picture + ".png"), os.path.join(EXPORT, theme_name + ".png"))
    Image.open(os.path.join(EXPORT, "Talaria.png")).resize((256, 256), Image.LANCZOS).save(
        os.path.join(EXPORT, "TalariaHud.png")
    )
    shutil.copy(os.path.join(compose2.PACK, ROBUX_ICON), os.path.join(EXPORT, "HudRobux.png"))
    names = list(PICTURES) + ["HudRobux"]
    sheet = Image.new("RGBA", (6 * 180, ((len(names) + 5) // 6) * 180), (34, 150, 224, 255))
    for index, name in enumerate(names):
        im = Image.open(os.path.join(EXPORT, name + ".png")).convert("RGBA").resize((170, 170), Image.LANCZOS)
        sheet.alpha_composite(im, ((index % 6) * 180 + 5, (index // 6) * 180 + 5))
    sheet.save(os.path.join(EXPORT, "sheet.png"))


if __name__ == "__main__":
    render_svgs()
    compose()
    export()
    print("wrote", EXPORT)
