# What every god shares, so the thirty read as one family: the palette's golds and eye colours, the angry eyes and
# brows, fists, belts and trims laid on the body (shells), the bones, and how a skirt or gown follows the legs.
import numpy as np

import sdf
from sdf import ellipsoid, look_rot, rot, sphere

GOLD = (246, 192, 48)
GOLD_DARK = (200, 134, 30)
EYE_WHITE = (250, 250, 248)
PUPIL = (24, 18, 14)
SOLE = (112, 70, 40)


def mix(a, b, t):
    t = np.clip(t, 0, 1)[:, None]
    return np.asarray(a, float) * (1 - t) + np.asarray(b, float) * t


def strands(base, dark, freq, ax=0, az=0.0, amount=0.6):
    """Hair, beard and brows: soft darker strands across the base colour."""

    def color(P):
        t = 0.5 + 0.5 * np.sin(freq * P[:, ax] + az * P[:, 2])
        return mix(base, dark, amount * t * t)

    return color


def slab(point, axis, half):
    """Negative within `half` of the plane through point across axis: where belts and straps go."""
    p0 = np.asarray(point, float)
    a = np.asarray(axis, float)
    a = a / np.linalg.norm(a)
    return lambda P: np.abs((P - p0) @ a) - half


def shell(parts, thickness, clip, k=0.02, **kw):
    """A layer `thickness` out from the union of `parts`, cut to where clip(P) < 0: belts, straps, trims, crowns."""
    lo = np.min([p.lo for p in parts], axis=0)
    hi = np.max([p.hi for p in parts], axis=0)
    return sdf.Prim(lambda P: sdf.evaluate_points(parts, P) - thickness, world=True, bounds=(lo, hi),
                    clip=(clip, k), **kw)


def angry_eyes(add, eye_x, eye_y, eye_z, iris, lid, brow_color, brow_size=(0.27, 0.12, 0.1), brow_tilt=24,
               brow_lift=0.14, eye_size=(0.16, 0.08, 0.105), wing=False, brow_forward=0.03):
    """Sockets, eyes and brows: the upper lid and the brows slant down to the nose, which is the glare every god has.
    wing: a little flick of liner at the outer corner (the goddesses)."""
    for side in (1, -1):
        add(ellipsoid((side * eye_x, eye_y - 0.07, eye_z), (eye_size[0] + 0.01, 0.1, eye_size[2] - 0.005), k=0.05,
                      sub=True, name="socket"))

    def eye_color(P):
        out = np.tile(np.asarray(EYE_WHITE, float), (len(P), 1))
        for side in (1, -1):
            mine = np.sign(P[:, 0]) == side
            dx = P[:, 0] - side * (eye_x - 0.02)
            dz = P[:, 2] - (eye_z - 0.01)
            r = np.sqrt(dx * dx + dz * dz)
            out[(r < 0.085) & mine] = iris
            out[(r < 0.05) & mine] = PUPIL
            up = P[:, 2] - eye_z
            across = np.abs(P[:, 0]) - eye_x
            lid_line = (up > 0.055 - 0.3 * across) & mine
            if wing:
                lid_line |= (up > 0.03 - 0.3 * across) & (across > 0.08) & mine
            out[lid_line] = lid
        return out

    for side in (1, -1):
        add(ellipsoid((side * eye_x, eye_y, eye_z), eye_size, color=eye_color, bone="Head", name="eye"))
        add(ellipsoid((side * (eye_x + 0.03), eye_y - brow_forward, eye_z + brow_lift), brow_size,
                      R=rot(y=-brow_tilt * side), k=0.04, color=brow_color, bone="Head", name="brow"))


def fist(add, name, wr, fore, color, size=(0.4, 0.34, 0.44), knuckle=0.11):
    """A clenched fist at the end of the forearm, four knuckles across its front."""
    add(ellipsoid(wr + fore * 0.3, size, R=look_rot(fore), k=0.12, color=color, bone=name + "Hand", name="fist",
                  reach=0.15))
    across = np.cross(fore, np.array([0, 1.0, 0]))
    across /= np.linalg.norm(across)
    for n in range(4):
        off = (n - 1.5) * knuckle * 1.55
        add(sphere(wr + fore * (size[2] + 0.16) + across * off + np.array([0, -size[1] * 0.53, 0]), knuckle, k=0.06,
                   color=color, bone=name + "Hand", name="knuckle"))


def bones():
    """The rig every god shares (R15-style names), as (head joint, tail joint, parent); build.rig adds a Root."""
    B = {
        "LowerTorso": ("pelvis", "waist", None),
        "UpperTorso": ("waist", "neck", "LowerTorso"),
        "Head": ("neck", "headTop", "UpperTorso"),
    }
    for side in ("Left", "Right"):
        B[side + "UpperArm"] = (side + "Shoulder", side + "Elbow", "UpperTorso")
        B[side + "LowerArm"] = (side + "Elbow", side + "Wrist", side + "UpperArm")
        B[side + "Hand"] = (side + "Wrist", side + "Fist", side + "LowerArm")
        B[side + "UpperLeg"] = (side + "Hip", side + "Knee", "LowerTorso")
        B[side + "LowerLeg"] = (side + "Knee", side + "Ankle", side + "UpperLeg")
        B[side + "Foot"] = (side + "Ankle", side + "Toe", side + "LowerLeg")
    return B


def arm_joints(J, shoulder_x, shoulder_z, spread, upper, fore_spread, fore_len, fist_len=0.62):
    """Shoulder, elbow, wrist and fist for an A-pose: arms `spread` degrees out, forearms a little forward."""
    for side, name in ((1, "Left"), (-1, "Right")):
        shoulder = np.array([side * shoulder_x, 0.05, shoulder_z])
        down = np.array([side * np.sin(np.radians(spread)), 0.0, -np.cos(np.radians(spread))])
        elbow = shoulder + down * upper
        fore = np.array([side * np.sin(np.radians(fore_spread)), -0.3, -np.cos(np.radians(fore_spread))])
        fore /= np.linalg.norm(fore)
        wrist = elbow + fore * fore_len
        J[name + "Shoulder"] = shoulder
        J[name + "Elbow"] = elbow
        J[name + "Wrist"] = wrist
        J[name + "Fist"] = wrist + fore * fist_len


def follow_legs(prims, P, who, names, W, part, top, bottom, share=0.8, knee=None, knee_share=0.0):
    """A skirt or gown (the shape named `part`) hangs from the hips and follows each thigh more towards its hem
    (`share` of it at the hem), split down the middle; with `knee` (a height), the part below it also follows the
    shins a little, so a long hem keeps up with the feet."""
    skirt = [n for n, p in enumerate(prims) if p.name == part]
    sel = np.isin(who, skirt)
    z = P[sel, 2]
    a = share * np.clip((top - z) / (top - bottom), 0, 1) ** 1.2
    t = np.clip((P[sel, 0] + 0.45) / 0.9, 0, 1)
    left = t * t * (3 - 2 * t)
    b = knee_share * np.clip((knee - z) / max(knee - bottom, 1e-6), 0, 1) if knee is not None else 0.0 * z
    W[sel] = 0
    W[sel, names.index("LowerTorso")] = 1 - a
    for side, s in (("Left", left), ("Right", 1 - left)):
        W[sel, names.index(side + "UpperLeg")] = a * s * (1 - b)
        W[sel, names.index(side + "LowerLeg")] = a * s * b
    return W
