# Zeus, modelled from shapes (sdf.py). Studs, Z up, facing -Y; his left is +X. The user's rules: one whole mesh,
# fully clothed, bulky, angry, two arms, about 6,000 triangles, one texture; the bolt is neon blocks in Roblox, not
# part of the mesh.
import numpy as np

import sdf
from sdf import box, cylinder, ellipsoid, limb, look_rot, plane_f, rot, sphere

SKIN = (214, 146, 104)
CLOTH = (240, 238, 230)
DRAPE = (252, 252, 250)
RED = (192, 40, 40)
GOLD = (246, 192, 48)
GOLD_DARK = (200, 134, 30)
HAIR = (238, 240, 246)
HAIR_DARK = (178, 184, 200)
SOLE = (112, 70, 40)
EYE_WHITE = (250, 250, 248)
IRIS = (74, 50, 34)
PUPIL = (24, 18, 14)
LID = (64, 38, 28)
MOUTH = (82, 28, 26)
LIP = (196, 120, 98)

HEM = 3.05  # bottom of the tunic


def joints():
    """Skeleton points; the right side mirrors the left (+X)."""
    J = {}
    J["pelvis"] = np.array([0.0, 0.0, 4.75])
    J["waist"] = np.array([0.0, 0.0, 5.55])
    J["neck"] = np.array([0.0, 0.05, 7.8])
    J["headTop"] = np.array([0.0, 0.0, 9.6])
    for side, name in ((1, "Left"), (-1, "Right")):
        shoulder = np.array([side * 1.76, 0.05, 7.4])
        down = np.array([side * np.sin(np.radians(36)), 0.0, -np.cos(np.radians(36))])
        elbow = shoulder + down * 1.72
        fore = np.array([side * np.sin(np.radians(26)), -0.3, -np.cos(np.radians(26))])
        fore /= np.linalg.norm(fore)
        wrist = elbow + fore * 1.48
        J[name + "Shoulder"] = shoulder
        J[name + "Elbow"] = elbow
        J[name + "Wrist"] = wrist
        J[name + "Fist"] = wrist + fore * 0.62
        J[name + "Hip"] = np.array([side * 0.55, 0.0, 4.55])
        J[name + "Knee"] = np.array([side * 0.64, -0.06, 2.6])
        J[name + "Ankle"] = np.array([side * 0.66, 0.08, 0.52])
        J[name + "Toe"] = np.array([side * 0.7, -0.92, 0.25])
    return J


def _mix(a, b, t):
    t = np.clip(t, 0, 1)[:, None]
    return np.asarray(a, float) * (1 - t) + np.asarray(b, float) * t


def _strands(freq, ax=0, az=0.0):
    def color(P):
        t = 0.5 + 0.5 * np.sin(freq * P[:, ax] + az * P[:, 2])
        return _mix(HAIR, HAIR_DARK, 0.6 * t * t)

    return color


def _slab(point, axis, half):
    p0 = np.asarray(point, float)
    a = np.asarray(axis, float)
    a = a / np.linalg.norm(a)
    return lambda P: np.abs((P - p0) @ a) - half


def shell(parts, thickness, clip, k=0.02, **kw):
    """A layer `thickness` out from the union of `parts`, cut to where clip(P) < 0: belts, straps, trims."""
    lo = np.min([p.lo for p in parts], axis=0)
    hi = np.max([p.hi for p in parts], axis=0)
    return sdf.Prim(lambda P: sdf.evaluate_points(parts, P) - thickness, world=True, bounds=(lo, hi),
                    clip=(clip, k), **kw)


def shapes(J):
    S = []
    add = S.append

    # Torso, V-shaped: the tunic is its surface (the body under it never shows); chest and shoulders read through.
    torso = [
        ellipsoid((0, 0.08, 6.85), (1.66, 0.88, 0.95), color=CLOTH, bone="UpperTorso", name="chest"),
        ellipsoid((0, 0.2, 7.4), (1.3, 0.6, 0.5), k=0.35, color=CLOTH, bone="UpperTorso", name="traps"),
        ellipsoid((0.6, -0.45, 7.0), (0.72, 0.42, 0.5), k=0.3, color=CLOTH, bone="UpperTorso", name="pecL"),
        ellipsoid((-0.6, -0.45, 7.0), (0.72, 0.42, 0.5), k=0.3, color=CLOTH, bone="UpperTorso", name="pecR"),
        ellipsoid((0, 0.04, 5.8), (1.08, 0.74, 0.95), k=0.5, color=CLOTH, bone="LowerTorso", name="belly"),
        ellipsoid((0, 0.04, 4.98), (1.12, 0.8, 0.6), k=0.35, color=CLOTH, bone="LowerTorso", name="hips"),
    ]
    S.extend(torso)

    # The skirt: flared to a flat hem, folds deepening towards it; a red hem band and the drape's red edge running
    # diagonally down the front.
    def skirt_folds(P):
        a = np.arctan2(P[:, 1], P[:, 0])
        depth = np.clip((5.0 - P[:, 2]) / 1.8, 0, 1)
        return 0.045 * np.sin(16 * a) * depth

    stripe_c = np.array([0.85, 0.0, 5.0])
    stripe_n = np.array([0.8, 0.0, -0.6])

    def skirt_color(P):
        out = np.tile(np.asarray(CLOTH, float), (len(P), 1))
        hem = P[:, 2] < HEM + 0.24
        thin = (P[:, 2] > HEM + 0.31) & (P[:, 2] < HEM + 0.37)
        diag = (np.abs((P - stripe_c) @ stripe_n) < 0.09) & (P[:, 1] < 0.0)
        out[hem | thin | diag] = RED
        return out

    add(limb((0, 0.04, 5.05), (0, 0.04, HEM - 0.6), 1.2, 1.55, scale=(0.76, 1.0), k=0.3, color=skirt_color,
             bone="LowerTorso", name="skirt", bias=0.03, disp=skirt_folds, disp_amp=0.05,
             clip=(lambda P: np.maximum(HEM - P[:, 2], P[:, 2] - 5.1), 0.06)))

    # The drape over his left shoulder: a white band with red edges across the chest and back, gold brooches.
    band_c = np.array([0.25, 0.0, 6.4])
    band_n = np.array([0.72, 0.0, -0.7])
    band_n /= np.linalg.norm(band_n)

    def drape_color(P):
        t = (P - band_c) @ band_n
        out = np.tile(np.asarray(DRAPE, float), (len(P), 1))
        out[(t > 0.3) | (t < -0.4)] = RED
        return out

    upper = torso[:4] + torso[4:5]
    add(shell(upper, 0.13, lambda P: np.maximum(np.abs((P - band_c) @ band_n) - 0.5, 5.35 - P[:, 2]), k=0.04,
              color=drape_color, bone="UpperTorso", name="drape"))
    add(cylinder((1.0, -0.55, 7.42), 0.26, 0.07, R=look_rot((0.5, -1, 0.5)), round_=0.03, color=GOLD,
                 bone="UpperTorso", name="broochShoulder"))
    add(cylinder((0.05, -0.97, 6.3), 0.3, 0.08, R=look_rot((0.05, -1, 0.1)), round_=0.03, color=GOLD,
                 bone="UpperTorso", name="broochChest"))

    # Gold belt and buckle, hugging the waist.
    belt_c = 5.2
    add(shell(torso, 0.1, _slab((0, 0, belt_c), (0, 0, 1), 0.13), k=0.03, color=GOLD, bone="LowerTorso",
              name="belt"))
    add(box((0, -0.86, belt_c), (0.26, 0.1, 0.2), round_=0.05, color=GOLD_DARK, bone="LowerTorso", name="buckle"))

    # Neck and head.
    add(limb((0, 0.1, 7.45), (0, 0.0, 8.3), 0.52, 0.44, k=0.25, color=SKIN, bone="Head", name="neck", reach=0.3))
    head = np.array([0.0, 0.04, 8.86])
    add(ellipsoid(head, (0.62, 0.66, 0.7), color=SKIN, bone="Head", name="cranium"))
    add(ellipsoid((0, -0.16, 8.5), (0.56, 0.54, 0.46), k=0.25, color=SKIN, bone="Head", name="jaw"))
    add(ellipsoid((0, -0.52, 8.95), (0.55, 0.2, 0.13), k=0.15, color=SKIN, bone="Head", name="browRidge"))
    eye_z = 8.78
    for side in (1, -1):
        add(ellipsoid((side * 0.31, -0.47, 8.62), (0.21, 0.16, 0.13), k=0.15, color=SKIN, bone="Head", name="cheek"))
        add(ellipsoid((side * 0.62, 0.06, 8.75), (0.09, 0.17, 0.22), k=0.06, color=SKIN, bone="Head", name="ear"))
        add(ellipsoid((side * 0.23, -0.64, eye_z), (0.17, 0.1, 0.1), k=0.05, sub=True, name="socket"))

    def eye_color(P):
        out = np.tile(np.asarray(EYE_WHITE, float), (len(P), 1))
        for side in (1, -1):
            dx = P[:, 0] - side * 0.21
            dz = P[:, 2] - (eye_z - 0.01)
            r = np.sqrt(dx * dx + dz * dz)
            out[r < 0.085] = IRIS
            out[r < 0.05] = PUPIL
            # The upper lid, slanting down to the nose: the glare.
            lid = (P[:, 2] - eye_z) > 0.055 - 0.3 * (np.abs(P[:, 0]) - 0.23)
            out[lid & (np.sign(P[:, 0]) == side)] = LID
        return out

    for side in (1, -1):
        add(ellipsoid((side * 0.23, -0.57, eye_z), (0.16, 0.08, 0.105), color=eye_color, bone="Head", name="eye"))
        # Angry brows: thick, slanting down to the nose, over the top of the eyes.
        add(ellipsoid((side * 0.26, -0.6, 8.92), (0.27, 0.12, 0.1), R=rot(y=-24 * side), k=0.04,
                      color=_strands(50, 2), bone="Head", name="brow"))
        add(ellipsoid((side * 0.1, -0.74, 8.58), (0.09, 0.07, 0.06), k=0.05, color=SKIN, bone="Head",
                      name="nostril"))
    add(limb((0, -0.65, 8.9), (0, -0.82, 8.62), 0.07, 0.115, k=0.08, color=SKIN, bone="Head", name="nose"))
    # Frown: a dark mouth line and a lower lip under the moustache.
    add(ellipsoid((0, -0.69, 8.39), (0.17, 0.06, 0.03), color=MOUTH, bone="Head", name="mouth"))
    add(ellipsoid((0, -0.67, 8.33), (0.14, 0.07, 0.05), k=0.03, color=LIP, bone="Head", name="lip"))

    # Beard from the jaw down onto the chest, moustache, hair: white with soft grey strands.
    beard_c = _strands(20, 0, 3.0)

    def beard_disp(P):
        return 0.012 * np.sin(20 * P[:, 0] + 3.0 * P[:, 2])

    add(ellipsoid((0, -0.3, 8.08), (0.6, 0.4, 0.36), color=beard_c, bone="Head", name="beard"))
    # Five chunky locks falling to a point on his chest.
    for x0 in (-0.38, -0.19, 0.0, 0.19, 0.38):
        top = (x0, -0.62 + 0.25 * abs(x0), 8.17)
        tip = (x0 * 0.45, -0.72 + 0.12 * abs(x0), 7.12 + 0.75 * abs(x0))
        add(limb(top, tip, 0.17, 0.06, k=0.035, color=beard_c, bone="Head", name="beardLock", disp=beard_disp,
                 disp_amp=0.03))
    for side in (1, -1):
        add(ellipsoid((side * 0.52, -0.22, 8.4), (0.15, 0.3, 0.42), k=0.15, color=beard_c, bone="Head",
                      name="sideburn"))
        # Beard over the jaw between the moustache's end and the sideburn: no skin showing in that crease.
        add(ellipsoid((side * 0.36, -0.5, 8.3), (0.2, 0.17, 0.17), k=0.1, color=beard_c, bone="Head", name="jowl"))
        add(limb((side * 0.07, -0.8, 8.5), (side * 0.36, -0.7, 8.32), 0.085, 0.065, k=0.06, color=beard_c,
                 bone="Head", name="moustache"))
        add(limb((side * 0.36, -0.7, 8.32), (side * 0.43, -0.64, 8.12), 0.065, 0.045, k=0.04, color=beard_c,
                 bone="Head", name="moustacheEnd"))

    hair_c = _strands(30, 0, 2.0)

    def hair_disp(P):
        return 0.014 * np.sin(30 * P[:, 0] + 2.0 * P[:, 2])

    hairline = plane_f((0, -0.5, 9.22), (0, -0.55, -0.83))
    add(sdf.Prim(sdf.f_ellipsoid((0.7, 0.74, 0.8)), head + np.array([0, 0.02, 0.04]), radius=0.85, color=hair_c,
                 bone="Head", name="hair", clip=(hairline, 0.08), disp=hair_disp, disp_amp=0.04))
    add(ellipsoid((0, 0.44, 8.3), (0.76, 0.42, 0.82), k=0.15, color=hair_c, bone="Head", name="hairBack",
                  disp=hair_disp, disp_amp=0.04))
    for side in (1, -1):
        add(limb((side * 0.5, 0.28, 8.75), (side * 0.86, 0.42, 7.55), 0.3, 0.2, k=0.18, color=hair_c, bone="Head",
                 name="lock", disp=hair_disp, disp_amp=0.04))

    # Arms: short white sleeves with red trim, bare arms, gold armlets and bracers, fists.
    for side, name in ((1, "Left"), (-1, "Right")):
        sh, el, wr = J[name + "Shoulder"], J[name + "Elbow"], J[name + "Wrist"]
        up = (el - sh) / np.linalg.norm(el - sh)
        fore = (wr - el) / np.linalg.norm(wr - el)
        upper_arm = limb(sh + up * 0.45, el, 0.58, 0.46, color=SKIN, bone=name + "UpperArm", name="upperArm")
        bicep = ellipsoid(sh + up * 1.05 + np.array([0, -0.2, 0]), (0.45, 0.38, 0.5), R=look_rot(up), k=0.25,
                          color=SKIN, bone=name + "UpperArm", name="bicep")
        add(upper_arm)
        add(bicep)
        sleeve = limb(sh + np.array([-side * 0.12, 0, -0.02]), sh + up * 0.62, 0.64, 0.63, k=0.22, color=CLOTH,
                      bone=name + "UpperArm", name="sleeve", reach=0.3)
        add(sleeve)
        add(shell([sleeve], 0.04, _slab(sh + up * 0.58, up, 0.07), color=RED, bone=name + "UpperArm", name="trim"))
        add(shell([upper_arm, bicep], 0.06, _slab(sh + up * 1.08, up, 0.08), color=GOLD, bone=name + "UpperArm",
                  name="armlet"))
        forearm = limb(el, wr, 0.5, 0.34, color=SKIN, bone=name + "LowerArm", name="forearm", reach=0.2)
        muscle = ellipsoid(el + fore * 0.42 + np.array([0, -0.08, 0]), (0.46, 0.41, 0.56), R=look_rot(fore), k=0.2,
                           color=SKIN, bone=name + "LowerArm", name="forearmMuscle")
        add(forearm)
        add(muscle)

        def bracer_color(P, el=el, fore=fore):
            t = (P - el) @ fore
            out = np.tile(np.asarray(GOLD, float), (len(P), 1))
            out[(np.abs(t - 0.86) < 0.05) | (np.abs(t - 1.36) < 0.05)] = GOLD_DARK
            return out

        add(shell([forearm, muscle], 0.07, _slab(el + fore * 1.1, fore, 0.3), color=bracer_color,
                  bone=name + "LowerArm", name="bracer"))
        add(ellipsoid(wr + fore * 0.3, (0.4, 0.34, 0.44), R=look_rot(fore), k=0.12, color=SKIN, bone=name + "Hand",
                      name="fist", reach=0.15))
        across = np.cross(fore, np.array([0, 1.0, 0]))
        across /= np.linalg.norm(across)
        for n in range(4):
            off = (n - 1.5) * 0.17
            add(sphere(wr + fore * 0.6 + across * off + np.array([0, -0.18, 0]), 0.11, k=0.06, color=SKIN,
                       bone=name + "Hand", name="knuckle"))

        # Legs: thighs under the tunic, knees, big calves, sandals with gold straps up the shin.
        hp, kn, an, to = J[name + "Hip"], J[name + "Knee"], J[name + "Ankle"], J[name + "Toe"]
        add(limb(hp + np.array([0, 0, -0.25]), kn, 0.56, 0.5, color=SKIN, bone=name + "UpperLeg", name="thigh",
                 reach=0.2))
        shin = limb(kn, an, 0.5, 0.31, k=0.15, color=SKIN, bone=name + "LowerLeg", name="shin", reach=0.2)
        calf = ellipsoid(kn + np.array([0, 0.14, -0.7]), (0.45, 0.44, 0.74), k=0.3, color=SKIN,
                         bone=name + "LowerLeg", name="calf")
        add(shin)
        add(calf)
        axis = (an - kn) / np.linalg.norm(an - kn)
        for t in (0.42, 0.6, 0.78, 0.93):
            add(shell([shin, calf], 0.05, _slab(kn + (an - kn) * t, axis, 0.045), color=GOLD,
                      bone=name + "LowerLeg", name="strap"))
        foot = ellipsoid((to + an) / 2 + np.array([0, 0.08, -0.04]), (0.3, 0.6, 0.23), k=0.15, color=SKIN,
                         bone=name + "Foot", name="foot", reach=0.15)
        add(foot)
        add(box((an[0], -0.3, 0.1), (0.36, 0.72, 0.1), round_=0.06, color=SOLE, bone=name + "Foot", name="sole"))
        for t in (0.15, 0.55):
            p = an + (to - an) * t
            add(shell([foot], 0.04, _slab(p, (0, 1, 0.6), 0.05), color=GOLD, bone=name + "Foot", name="footStrap"))
    return S


BONES = {
    # name: (head joint, tail joint, parent)
    "LowerTorso": ("pelvis", "waist", None),
    "UpperTorso": ("waist", "neck", "LowerTorso"),
    "Head": ("neck", "headTop", "UpperTorso"),
}
for _side in ("Left", "Right"):
    BONES[_side + "UpperArm"] = (_side + "Shoulder", _side + "Elbow", "UpperTorso")
    BONES[_side + "LowerArm"] = (_side + "Elbow", _side + "Wrist", _side + "UpperArm")
    BONES[_side + "Hand"] = (_side + "Wrist", _side + "Fist", _side + "LowerArm")
    BONES[_side + "UpperLeg"] = (_side + "Hip", _side + "Knee", "LowerTorso")
    BONES[_side + "LowerLeg"] = (_side + "Knee", _side + "Ankle", _side + "UpperLeg")
    BONES[_side + "Foot"] = (_side + "Ankle", _side + "Toe", _side + "LowerLeg")

BOUNDS = ((-4.5, -1.7, -0.05), (4.5, 1.3, 9.8))


def reweight(prims, P, who, names, W):
    """The skirt hangs from the hips and follows each thigh more towards the hem, split down the middle."""
    skirt = [n for n, p in enumerate(prims) if p.name == "skirt"][0]
    sel = who == skirt
    a = 0.8 * np.clip((4.85 - P[sel, 2]) / (4.85 - HEM), 0, 1) ** 1.2
    t = np.clip((P[sel, 0] + 0.45) / 0.9, 0, 1)
    left = t * t * (3 - 2 * t)
    W[sel] = 0
    W[sel, names.index("LowerTorso")] = 1 - a
    W[sel, names.index("LeftUpperLeg")] = a * left
    W[sel, names.index("RightUpperLeg")] = a * (1 - left)
    return W

# The head's UV islands get this much more texture than their size would, for the painted eyes.
FACE_ABOVE = 7.9
FACE_UV_SCALE = 1.7



def detail(J):
    """Where decimation keeps more triangles: (centre, radius, weight)."""
    spots = [((0, -0.45, 8.65), 0.55, 1.0), ((0, -0.5, 7.7), 0.6, 0.5)]  # face, beard
    for name in ("Left", "Right"):
        spots.append(((J[name + "Wrist"] + J[name + "Fist"]) / 2, 0.45, 0.5))
    return spots


DETAIL_FACTOR = 8.0
