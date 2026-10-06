"""The store art's own drawings, in gvesster's pack's manner (flat faces in two or three tones, light from the top left,
no lines inside the shape; the outline is added round the finished picture later). Containers come in a back layer and
a front layer so what they hold sits inside them. Writes draw/<name>.svg on a 512 x 512 canvas."""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "draw")
os.makedirs(OUT, exist_ok=True)

RED = {"l": "#F7375C", "m": "#E02250", "d": "#C11744", "x": "#82083A", "xx": "#4E0628"}
GOLD = {"l": "#FFC41D", "m": "#FFB41F", "d": "#FF941F", "x": "#FF7B22", "xx": "#B85412"}
PURPLE = {"l": "#B57BFF", "m": "#9B4DFF", "d": "#7B2FE0", "x": "#5A1CB0", "xx": "#2E0A66"}
BURLAP = {"l": "#EDBB76", "m": "#D69A57", "d": "#B5773D", "x": "#875427", "xx": "#4A2A12"}
MARBLE = {"l": "#F4F7FF", "m": "#D5DEF0", "d": "#AAB8D6", "x": "#8496BE"}
WING = {"l": "#FFFFFF", "m": "#DCF7FF", "d": "#8FD6E2", "x": "#58B5BF"}
GREEN = {"l": "#5FD14A", "m": "#39B742", "d": "#009345", "x": "#007231"}
INK = "#040435"


def write(name, body):
    with open(os.path.join(OUT, name + ".svg"), "w", encoding="utf-8", newline="") as f:
        f.write(f'<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512">{body}</svg>')


def poly(points, fill):
    return f'<polygon points="{" ".join(f"{x},{y}" for x, y in points)}" fill="{fill}"/>'


# ---- the chest, open: front face x 168..444, y 300..452; the left side goes back up-left by (-60, -38) ----
def chest(body, trim, name):
    back = []
    # the lid, standing open behind the hinge and leaning back a little: its end cap (the barrel's side) on the left,
    # then its inside, a panel framed in trim
    back.append(f'<path d="M108,262 C58,252 40,168 94,128 L104,134 C66,170 76,240 114,258 Z" fill="{trim["d"]}"/>')
    back.append(f'<path d="M108,262 C66,246 60,176 98,136 L116,262 Z" fill="{body["d"]}"/>')
    back.append(poly([(108, 262), (386, 262), (372, 128), (94, 128)], trim["m"]))
    back.append(poly([(124, 252), (372, 252), (360, 142), (110, 142)], body["x"]))
    back.append(poly([(150, 252), (196, 252), (186, 142), (140, 142)], body["d"]))
    back.append(poly([(94, 128), (372, 128), (376, 140), (96, 140)], trim["l"]))
    # hinges
    for x in (150, 330):
        back.append(f'<rect x="{x}" y="250" width="30" height="16" rx="4" fill="{trim["d"]}"/>')
    # the inside: the back wall's inner face, then the floor in shadow
    back.append(poly([(108, 262), (384, 262), (444, 300), (168, 300)], body["xx"]))
    back.append(poly([(108, 262), (384, 262), (384, 282), (108, 282)], body["x"]))
    back.append(poly([(104, 256), (390, 256), (390, 266), (104, 266)], trim["d"]))
    write(name + "_back", "".join(back))

    front = []
    # the left side, the front, a sheen
    front.append(poly([(168, 300), (108, 262), (108, 414), (168, 452)], body["d"]))
    front.append(f'<path d="M168,300 H444 V440 Q444,452 432,452 H168 Z" fill="{body["m"]}"/>')
    front.append(poly([(250, 324), (282, 324), (232, 452), (200, 452)], body["l"]))
    front.append(poly([(296, 324), (308, 324), (258, 452), (246, 452)], body["l"]))
    # bands down the front and the side, the corner pieces
    for x in (214, 384):
        front.append(f'<rect x="{x}" y="318" width="32" height="134" fill="{trim["m"]}"/>')
        front.append(f'<rect x="{x + 22}" y="318" width="10" height="134" fill="{trim["d"]}"/>')
    front.append(poly([(146, 287), (128, 276), (128, 428), (146, 439)], trim["d"]))
    front.append(poly([(156, 293), (180, 300), (180, 452), (156, 444)], trim["l"]))
    front.append(f'<path d="M430,300 H452 V442 Q452,456 438,456 H430 Z" fill="{trim["m"]}"/>')
    front.append(poly([(156, 444), (180, 452), (180, 460), (156, 452)], trim["d"]))
    # the rim round the opening: its top edge, its front, its side
    front.append(poly([(160, 292), (452, 292), (452, 300), (160, 300)], trim["l"]))
    front.append(f'<rect x="160" y="300" width="292" height="24" fill="{trim["m"]}"/>')
    front.append(poly([(160, 292), (100, 254), (100, 262), (160, 300)], trim["l"]))
    front.append(poly([(160, 300), (100, 262), (100, 284), (160, 324)], trim["d"]))
    # the lock
    front.append(f'<rect x="284" y="314" width="48" height="60" rx="10" fill="{trim["l"]}"/>')
    front.append(f'<rect x="284" y="352" width="48" height="22" rx="8" fill="{trim["d"]}"/>')
    front.append(f'<circle cx="308" cy="336" r="8" fill="{body["xx"]}"/>')
    front.append(f'<path d="M304,338 H312 L314,358 H302 Z" fill="{body["xx"]}"/>')
    write(name + "_front", "".join(front))


chest(RED, GOLD, "chest")
chest(GOLD, PURPLE, "goldchest")


# ---- the sack: its mouth an ellipse at (256, 214), a cinched neck, a round body ----
def sack(name, emblem):
    back = [
        f'<ellipse cx="256" cy="214" rx="112" ry="32" fill="{BURLAP["xx"]}"/>',
        f'<ellipse cx="256" cy="214" rx="112" ry="32" fill="none" stroke="{BURLAP["l"]}" stroke-width="18"/>',
        f'<ellipse cx="256" cy="206" rx="100" ry="22" fill="{BURLAP["x"]}"/>',
    ]
    write(name + "_back", "".join(back))
    body = (
        "M150,226 C176,252 200,256 210,268 L210,284 C120,312 82,404 116,452 C146,494 366,494 396,452 "
        "C430,404 392,312 302,284 L302,268 C312,256 336,252 362,226 Z"
    )
    shade = (
        "M302,284 C392,312 430,404 396,452 C380,476 330,486 290,488 C350,470 384,430 376,384 "
        "C370,340 338,306 302,292 Z"
    )
    front = [
        f'<path d="{body}" fill="{BURLAP["m"]}"/>',
        f'<path d="{shade}" fill="{BURLAP["d"]}"/>',
        f'<path d="M150,300 C130,340 128,390 150,430 L170,426 C152,388 156,344 176,310 Z" fill="{BURLAP["l"]}"/>',
        # the front lip of the mouth, over whatever sticks out of it
        f'<path d="M144,214 A112,32 0 0 0 368,214" fill="none" stroke="{BURLAP["l"]}" stroke-width="18" stroke-linecap="round"/>',
        f'<path d="M160,232 A100,26 0 0 0 352,232" fill="none" stroke="{BURLAP["m"]}" stroke-width="8"/>',
        # the rope and its bow
        f'<rect x="200" y="262" width="112" height="24" rx="12" fill="{RED["m"]}"/>',
        f'<rect x="200" y="276" width="112" height="10" rx="5" fill="{RED["d"]}"/>',
        f'<path d="M300,272 C340,246 368,262 350,282 C340,294 318,286 300,276 Z" fill="{RED["l"]}"/>',
        f'<path d="M300,276 C330,300 336,330 322,340 C312,320 304,300 294,284 Z" fill="{RED["d"]}"/>',
        f'<circle cx="300" cy="275" r="11" fill="{RED["m"]}"/>',
    ]
    if emblem:
        front.append(f'<circle cx="250" cy="392" r="50" fill="{GOLD["d"]}"/>')
        front.append(f'<circle cx="246" cy="388" r="44" fill="{GOLD["l"]}"/>')
        front.append(
            f'<text x="246" y="410" text-anchor="middle" font-family="Arial Black, Arial" font-weight="900" '
            f'font-size="62" fill="{GOLD["xx"]}">$</text>'
        )
    write(name + "_front", "".join(front))


sack("sack", False)
sack("moneysack", True)


# ---- a wing, root at (0, 0), sweeping up and back to the left; placed (and flipped) by the composer ----
def wing():
    outer = (
        "M256,300 C232,250 196,196 96,168 C86,186 96,200 112,204 C92,214 92,230 112,236 "
        "C96,250 100,266 124,268 C112,284 124,298 146,296 C140,312 158,322 180,316 C190,330 220,330 256,300 Z"
    )
    mid = (
        "M256,300 C236,262 210,232 150,212 C146,226 158,236 172,238 C162,250 168,262 186,262 "
        "C182,276 196,286 214,282 C216,296 236,302 256,300 Z"
    )
    inner = "M256,300 C244,278 228,262 200,252 C200,266 212,276 226,278 C228,292 244,298 256,300 Z"
    body = [
        f'<path d="{outer}" fill="{WING["m"]}"/>',
        f'<path d="{mid}" fill="{WING["l"]}"/>',
        f'<path d="{inner}" fill="{WING["m"]}"/>',
        f'<path d="M96,168 C150,178 200,206 236,250 C196,216 150,196 104,190 Z" fill="{WING["l"]}"/>',
        f'<path d="M112,204 C108,216 116,226 128,228 M112,236 C110,248 118,258 132,258 M124,268 C122,280 132,290 148,288" '
        f'fill="none" stroke="{WING["d"]}" stroke-width="7" stroke-linecap="round"/>',
    ]
    write("wing", "".join(body))


wing()


# ---- three marble steps rising to the right, the depth going up-left as the chest's ----
def stairs():
    out = []
    steps = [(96, 470, 416, 404), (176, 404, 416, 338), (256, 338, 416, 272)]  # x0, y_bottom, x1, y_top
    for x0, yb, x1, yt in steps:
        dx, dy = -44, -28
        out.append(poly([(x0, yt), (x0 + dx, yt + dy), (x1 + dx, yt + dy), (x1, yt)], MARBLE["l"]))
        out.append(poly([(x0, yt), (x0 + dx, yt + dy), (x0 + dx, yb + dy), (x0, yb)], MARBLE["d"]))
        out.append(f'<rect x="{x0}" y="{yt}" width="{x1 - x0}" height="{yb - yt}" fill="{MARBLE["m"]}"/>')
        out.append(f'<rect x="{x0}" y="{yt}" width="{x1 - x0}" height="8" fill="{GOLD["l"]}"/>')
        out.append(f'<rect x="{x0}" y="{yt + 8}" width="{x1 - x0}" height="5" fill="{GOLD["d"]}"/>')
    # the right side of the whole flight
    out.append(poly([(416, 272), (416, 470), (430, 462), (430, 280)], MARBLE["x"]))
    write("stairs", "".join(out))


stairs()


# ---- a sprout: a stem that bends, for the growth pass (its leaves are the pack's) ----
def sprout():
    write(
        "sprout",
        f'<path d="M256,312 C250,270 262,226 262,186" fill="none" stroke="{GREEN["d"]}" stroke-width="24" stroke-linecap="round"/>'
        f'<path d="M251,310 C245,270 256,228 256,192" fill="none" stroke="{GREEN["m"]}" stroke-width="10" stroke-linecap="round"/>',
    )


sprout()

# ---- a terracotta pot for the growth pass: the soil in the back layer, the rim's front and the body in the front ----
CLAY = {"l": "#F49A5C", "m": "#DD7238", "d": "#B9551F", "x": "#7E3613", "soil": "#4A2A12", "soil2": "#6B3E1C"}
write(
    "pot_back",
    f'<ellipse cx="256" cy="306" rx="92" ry="24" fill="{CLAY["l"]}"/>'
    f'<ellipse cx="256" cy="308" rx="76" ry="16" fill="{CLAY["soil"]}"/>'
    f'<ellipse cx="248" cy="305" rx="40" ry="7" fill="{CLAY["soil2"]}"/>',
)
write(
    "pot_front",
    f'<path d="M190,340 H322 L306,452 Q304,466 290,466 H222 Q208,466 206,452 Z" fill="{CLAY["m"]}"/>'
    f'<path d="M288,340 H322 L306,452 Q304,466 290,466 H276 Q290,460 292,446 Z" fill="{CLAY["d"]}"/>'
    f'<path d="M206,350 H226 L236,452 H218 Z" fill="{CLAY["l"]}"/>'
    f'<path d="M164,306 A92,24 0 0 0 348,306 V334 Q348,346 336,346 H176 Q164,346 164,334 Z" fill="{CLAY["m"]}"/>'
    f'<path d="M164,306 A92,24 0 0 0 348,306 V316 A92,24 0 0 1 164,316 Z" fill="{CLAY["l"]}"/>'
    f'<path d="M300,328 H348 V334 Q348,346 336,346 H300 Z" fill="{CLAY["d"]}"/>',
)

# ---- speed lines, for the 2x Speed art ----
write(
    "lines",
    "".join(
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h / 2}" fill="#FFFFFF"/>'
        for x, y, w, h in [(40, 200, 170, 20), (70, 252, 130, 14), (24, 300, 160, 18), (90, 344, 90, 12)]
    ),
)
