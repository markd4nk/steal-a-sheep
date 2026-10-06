"""Hermes' winged sandal (talaria) for the climbing icon, in the pack's manner: flat faces in two or three tones, light
from the top left, no lines inside the shape (the composer outlines the whole). The toe points right, the wing rises up
and back from the ankle. Writes draw/talaria_<variant>.svg on a 512 x 512 canvas."""

import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "draw")
os.makedirs(OUT, exist_ok=True)
GOLD = {"l": "#FFD84A", "m": "#FFB41F", "d": "#FF941F", "x": "#E07112", "xx": "#A9500C"}
BRONZE = {"l": "#B9733A", "m": "#94552A", "d": "#6E3A1B", "x": "#4A2410", "in": "#2E140A"}
WHITE = {"l": "#FFFFFF", "m": "#E6F7FF", "d": "#A9DDEB", "x": "#6FB9CB"}
WGOLD = {"l": "#FFE47A", "m": "#FFC93C", "d": "#FFA22A", "x": "#E07A12"}
INK = "#040435"


def feather(cx, cy, angle, length, width, fill, shade):
    """A feather from (cx, cy) along `angle` degrees: a long leaf with a round tip, its lower half shaded."""
    L, w = length, width
    body = (
        f"M0,0 C{L * 0.25},{-w} {L * 0.8},{-w} {L},{-w * 0.15} "
        f"Q{L + w * 0.35},0 {L},{w * 0.25} C{L * 0.8},{w} {L * 0.25},{w} 0,0 Z"
    )
    low = f"M0,0 C{L * 0.25},{w * 0.25} {L * 0.8},{w * 0.35} {L},{w * 0.25} C{L * 0.8},{w} {L * 0.25},{w} 0,0 Z"
    t = f'transform="translate({cx},{cy}) rotate({angle})"'
    return f'<path d="{body}" fill="{fill}" {t}/><path d="{low}" fill="{shade}" {t}/>'


def wing(cx, cy, colors, scale=1.0):
    """Three rows of feathers fanning up and back from (cx, cy), the longest on top, then the coverts over the roots."""
    s = scale
    out = []
    # primaries: long, pointing up-left
    for i, (ang, length) in enumerate([(-112, 250), (-128, 262), (-144, 254), (-160, 232), (-176, 200)]):
        out.append(feather(cx, cy, ang, length * s, 30 * s, colors["m"] if i % 2 else colors["l"], colors["d"]))
    # secondaries
    for ang, length in [(-120, 170), (-140, 178), (-160, 166), (-180, 140)]:
        out.append(feather(cx, cy, ang, length * s, 30 * s, colors["l"], colors["d"]))
    # coverts: a rounded cap over the roots
    out.append(
        f'<path d="M{cx},{cy} C{cx - 30 * s},{cy - 120 * s} {cx - 120 * s},{cy - 130 * s} {cx - 140 * s},{cy - 60 * s} '
        f'C{cx - 100 * s},{cy - 50 * s} {cx - 60 * s},{cy - 10 * s} {cx},{cy} Z" fill="{colors["m"]}"/>'
    )
    out.append(
        f'<path d="M{cx},{cy} C{cx - 20 * s},{cy - 80 * s} {cx - 80 * s},{cy - 96 * s} {cx - 100 * s},{cy - 60 * s} '
        f'C{cx - 70 * s},{cy - 46 * s} {cx - 40 * s},{cy - 14 * s} {cx},{cy} Z" fill="{colors["l"]}"/>'
    )
    return "".join(out)


def swept_wing(rx, ry, colors, scale=1.0, tilt=0.0):
    """The scalloped wing from the 2x Speed art (root at (256, 300) on its canvas), its root moved to (rx, ry)."""
    outer = (
        "M256,300 C232,250 196,196 96,168 C86,186 96,200 112,204 C92,214 92,230 112,236 "
        "C96,250 100,266 124,268 C112,284 124,298 146,296 C140,312 158,322 180,316 C190,330 220,330 256,300 Z"
    )
    mid = (
        "M256,300 C236,262 210,232 150,212 C146,226 158,236 172,238 C162,250 168,262 186,262 "
        "C182,276 196,286 214,282 C216,296 236,302 256,300 Z"
    )
    inner = "M256,300 C244,278 228,262 200,252 C200,266 212,276 226,278 C228,292 244,298 256,300 Z"
    lead = "M96,168 C150,178 200,206 236,250 C196,216 150,196 104,190 Z"
    ticks = (
        "M112,204 C108,216 116,226 128,228 M112,236 C110,248 118,258 132,258 M124,268 C122,280 132,290 148,288 "
        "M146,296 C146,306 156,312 168,310"
    )
    g = f'transform="translate({rx},{ry}) rotate({tilt}) scale({scale}) translate(-256,-300)"'
    return (
        f'<g {g}><path d="{outer}" fill="{colors["m"]}"/><path d="{mid}" fill="{colors["l"]}"/>'
        f'<path d="{inner}" fill="{colors["m"]}"/><path d="{lead}" fill="{colors["l"]}"/>'
        f'<path d="{ticks}" fill="none" stroke="{colors["d"]}" stroke-width="7" stroke-linecap="round"/></g>'
    )


def sandal(wing_colors):
    parts = []
    # the wing behind the sandal, from the ankle
    far = {"l": wing_colors["m"], "m": wing_colors["d"], "d": wing_colors["x"]}
    parts.append(swept_wing(236, 262, far, 1.3, 18))
    parts.append(swept_wing(204, 270, wing_colors, 1.45, 8))
    # the sole: a thick gold slab, toe turned up a little
    parts.append(
        f'<path d="M112,376 H404 C444,376 462,392 450,410 C442,420 426,424 404,424 H128 C108,424 100,410 104,396 Z" fill="{GOLD["x"]}"/>'
    )
    parts.append(f'<path d="M112,376 H404 C436,376 452,386 452,396 H106 C106,386 108,378 112,376 Z" fill="{GOLD["m"]}"/>')
    # the shoe: a bronze heel cup and upper, dark inside at the ankle
    upper = "M122,380 C112,334 114,292 136,262 L240,254 C258,292 304,322 362,336 C406,346 434,356 438,380 Z"
    parts.append(f'<path d="{upper}" fill="{BRONZE["m"]}"/>')
    parts.append(f'<path d="M122,380 C112,334 114,292 136,262 L160,262 C142,296 140,338 150,380 Z" fill="{BRONZE["l"]}"/>')
    parts.append(f'<path d="M362,336 C406,346 434,356 438,380 H330 C350,370 360,352 362,336 Z" fill="{BRONZE["d"]}"/>')
    parts.append(f'<ellipse cx="188" cy="260" rx="54" ry="12" fill="{BRONZE["in"]}"/>')
    # gold straps: round the ankle, crossing down the instep, across the foot
    straps = [
        ("M130,272 C160,282 210,280 246,266", 20),
        ("M232,274 C250,320 290,336 336,346", 18),
        ("M246,300 C222,330 190,352 150,370", 18),
        ("M300,330 C290,350 280,366 270,380", 20),
        ("M372,342 C366,356 360,370 356,382", 20),
    ]
    for d, w in straps:
        parts.append(f'<path d="{d}" fill="none" stroke="{GOLD["x"]}" stroke-width="{w}" stroke-linecap="round" transform="translate(0,4)"/>')
        parts.append(f'<path d="{d}" fill="none" stroke="{GOLD["m"]}" stroke-width="{w}" stroke-linecap="round"/>')
        parts.append(f'<path d="{d}" fill="none" stroke="{GOLD["l"]}" stroke-width="{w * 0.35}" stroke-linecap="round" transform="translate(-2,-4)"/>')
    # the medallion on the ankle strap
    parts.append(f'<circle cx="198" cy="282" r="30" fill="{GOLD["x"]}"/>')
    parts.append(f'<circle cx="196" cy="279" r="26" fill="{GOLD["m"]}"/>')
    parts.append(f'<circle cx="196" cy="279" r="15" fill="{GOLD["d"]}"/>')
    parts.append(f'<circle cx="191" cy="274" r="6" fill="{GOLD["l"]}"/>')
    return "".join(parts)


def boot(wing_colors):
    parts = []
    far = {"l": wing_colors["m"], "m": wing_colors["d"], "d": wing_colors["x"]}
    parts.append(swept_wing(206, 186, far, 1.2, 16))
    parts.append(swept_wing(176, 196, wing_colors, 1.35, 6))
    parts.append(
        f'<path d="M104,376 H404 C444,376 462,392 450,410 C442,420 426,424 404,424 H120 C100,424 92,410 96,396 Z" fill="{GOLD["x"]}"/>'
    )
    parts.append(f'<path d="M104,376 H404 C436,376 452,386 452,396 H98 C98,386 100,378 104,376 Z" fill="{GOLD["m"]}"/>')
    shaft = "M116,380 C108,300 118,220 128,150 L250,140 C252,210 262,270 300,306 C340,330 420,342 440,380 Z"
    parts.append(f'<path d="{shaft}" fill="{BRONZE["m"]}"/>')
    parts.append(f'<path d="M116,380 C108,300 118,220 128,150 L156,148 C142,220 136,300 146,380 Z" fill="{BRONZE["l"]}"/>')
    parts.append(f'<path d="M300,306 C340,330 420,342 440,380 H330 C336,350 324,326 300,306 Z" fill="{BRONZE["d"]}"/>')
    # the cuff
    parts.append(f'<path d="M122,146 L254,136 L256,166 L124,176 Z" fill="{GOLD["m"]}"/>')
    parts.append(f'<path d="M124,166 L256,156 L256,166 L124,176 Z" fill="{GOLD["x"]}"/>')
    # laces crossing down the front of the shaft
    for y in (190, 228, 266):
        parts.append(f'<path d="M232,{y} L262,{y + 34}" stroke="{GOLD["m"]}" stroke-width="14" stroke-linecap="round"/>')
        parts.append(f'<path d="M262,{y} L232,{y + 34}" stroke="{GOLD["l"]}" stroke-width="14" stroke-linecap="round"/>')
    parts.append(f'<circle cx="168" cy="200" r="24" fill="{GOLD["x"]}"/>')
    parts.append(f'<circle cx="166" cy="197" r="20" fill="{GOLD["m"]}"/>')
    parts.append(f'<circle cx="166" cy="197" r="10" fill="{GOLD["d"]}"/>')
    return "".join(parts)


def write(name, body):
    with open(os.path.join(OUT, name + ".svg"), "w", encoding="utf-8", newline="") as f:
        # everything shrunk a little and moved right, so the wing stays on the canvas
        f.write(
            f'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">'
            f'<g transform="translate(70,70) scale(0.78)">{body}</g></svg>'
        )


write("talaria_white", sandal(WHITE))
write("talaria_gold", sandal(WGOLD))
write("talaria_boot", boot(WHITE))
