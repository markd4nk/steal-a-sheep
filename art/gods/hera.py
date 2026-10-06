# Hera, queen of the gods, in the game's colours for her (a purple robe, gold): a long gown with a front panel and
# a hem of peacock eyes (her bird), a cape from the shoulders, a gold diadem with a purple gem, a dark updo with
# locks over the shoulders, and the gods' angry glare. Her sceptre is neon blocks in Roblox, like Zeus's bolt.
import numpy as np

import sdf
import style
from sdf import box, cylinder, ellipsoid, limb, look_rot, plane_f, rot, sphere
from style import GOLD, GOLD_DARK, SOLE, shell, slab

SKIN = (238, 188, 148)
GOWN = (112, 52, 152)
GOWN_LIGHT = (152, 96, 194)
GOWN_DARK = (76, 32, 110)
TEAL = (36, 168, 160)
PEACOCK = (34, 78, 176)
GEM = (156, 62, 206)
HAIR = (72, 40, 28)
HAIR_LIGHT = (128, 80, 54)
IRIS = (92, 58, 36)
LID = (36, 20, 26)
BROW = (58, 32, 24)
LIP = (186, 64, 84)
LIP_LOW = (204, 84, 100)
MOUTH = (90, 26, 36)

HEM = 0.42  # bottom of the gown, just showing the sandals


def joints():
    """Skeleton points; the right side mirrors the left (+X)."""
    J = {}
    J["pelvis"] = np.array([0.0, 0.0, 4.7])
    J["waist"] = np.array([0.0, 0.0, 5.6])
    J["neck"] = np.array([0.0, 0.05, 7.75])
    J["headTop"] = np.array([0.0, 0.0, 9.45])
    style.arm_joints(J, 1.34, 7.28, 30, 1.6, 20, 1.38, fist_len=0.52)
    for side, name in ((1, "Left"), (-1, "Right")):
        J[name + "Hip"] = np.array([side * 0.5, 0.0, 4.5])
        J[name + "Knee"] = np.array([side * 0.56, -0.04, 2.55])
        J[name + "Ankle"] = np.array([side * 0.58, 0.06, 0.5])
        J[name + "Toe"] = np.array([side * 0.62, -0.85, 0.22])
    return J


def _hair(freq, ax=0, az=0.0):
    return style.strands(HAIR, HAIR_LIGHT, freq, ax, az, amount=0.35)


def shapes(J):
    S = []
    add = S.append

    # Bodice: the gown is the torso's surface; a narrow waist under the bust.
    torso = [
        ellipsoid((0, 0.06, 6.85), (1.16, 0.68, 0.85), color=GOWN, bone="UpperTorso", name="chest"),
        ellipsoid((0, 0.14, 7.25), (0.95, 0.44, 0.36), k=0.35, color=GOWN, bone="UpperTorso", name="shoulders"),
        ellipsoid((0.38, -0.38, 6.88), (0.4, 0.34, 0.36), k=0.25, color=GOWN, bone="UpperTorso", name="bustL"),
        ellipsoid((-0.38, -0.38, 6.88), (0.4, 0.34, 0.36), k=0.25, color=GOWN, bone="UpperTorso", name="bustR"),
        ellipsoid((0, 0.03, 5.9), (0.8, 0.58, 0.85), k=0.5, color=GOWN, bone="LowerTorso", name="waist"),
        ellipsoid((0, 0.04, 5.0), (1.04, 0.74, 0.6), k=0.4, color=GOWN, bone="LowerTorso", name="hips"),
    ]
    S.extend(torso)

    # The gown: an A-line to the ankles, soft folds, a lighter panel down the front between gold lines, a gold hem
    # and above it a row of peacock eyes.
    def gown_folds(P):
        a = np.arctan2(P[:, 1], P[:, 0])
        depth = np.clip((5.2 - P[:, 2]) / 3.5, 0, 1)
        return 0.055 * np.sin(18 * a) * depth

    eyes_z = HEM + 0.5
    step = 2 * np.pi / 22

    def gown_color(P):
        out = np.tile(np.asarray(GOWN, float), (len(P), 1))
        x, y, z = P[:, 0], P[:, 1], P[:, 2]
        front = y < 0
        out[front & (np.abs(x) < 0.33)] = GOWN_LIGHT
        out[front & (np.abs(x) >= 0.33) & (np.abs(x) < 0.39)] = GOLD
        a = np.arctan2(y, x)
        k = np.round(a / step)
        arc = (a - k * step) * np.hypot(x, y)
        e = (arc / 0.14) ** 2 + ((z - eyes_z) / 0.22) ** 2
        out[e < 1.0] = TEAL
        out[e < 0.5] = PEACOCK
        out[e < 0.15] = GOLD
        out[z < HEM + 0.2] = GOLD
        out[(z > HEM + 0.8) & (z < HEM + 0.86)] = GOLD
        return out

    add(limb((0, 0.04, 5.7), (0, 0.04, -0.6), 0.92, 1.65, scale=(0.8, 1.0), k=0.3, color=gown_color,
             bone="LowerTorso", name="gown", bias=0.03, disp=gown_folds, disp_amp=0.06,
             clip=(lambda P: np.maximum(HEM - P[:, 2], P[:, 2] - 5.75), 0.06)))

    # Gold girdle under the bust, a choker and a teal pendant.
    add(shell(torso, 0.07, slab((0, 0, 6.32), (0, 0, 1), 0.08), k=0.03, color=GOLD, bone="UpperTorso",
              name="girdle"))
    add(cylinder((0, -0.6, 6.32), 0.13, 0.05, R=look_rot((0, -1, 0)), round_=0.03, color=TEAL, bone="UpperTorso",
                 name="clasp"))
    neck = limb((0, 0.08, 7.35), (0, 0.0, 8.25), 0.34, 0.3, k=0.25, color=SKIN, bone="Head", name="neck", reach=0.3)
    add(neck)
    add(shell([neck], 0.05, slab((0, 0, 7.72), (0, 0.3, 1), 0.06), color=GOLD, bone="Head", name="choker"))
    add(ellipsoid((0, -0.66, 7.24), (0.09, 0.05, 0.13), color=TEAL, bone="UpperTorso", name="pendant"))

    # A cape hanging from her shoulders down her back, dark purple edged in gold, held by two brooches.
    cone = limb((0, 0.15, 7.5), (0, 0.6, 1.0), 1.15, 1.75, scale=(0.62, 1.0))

    def cape_color(P):
        out = np.tile(np.asarray(GOWN_DARK, float), (len(P), 1))
        out[((P[:, 1] < 0.32) & (P[:, 2] < 7.0)) | (P[:, 2] < 1.62)] = GOLD
        return out

    add(sdf.Prim(lambda P: np.abs(cone.eval(P)) - 0.07, world=True, bounds=(cone.lo, cone.hi), color=cape_color,
                 bone="UpperTorso", name="cape", reach=0.3,
                 clip=(lambda P: np.maximum.reduce([0.15 - P[:, 1], 1.4 - P[:, 2], P[:, 2] - 7.5]), 0.03)))
    for side in (1, -1):
        add(cylinder((side * 0.84, -0.1, 7.5), 0.18, 0.06, R=look_rot((side * 0.3, -0.6, 1)), round_=0.03,
                     color=GOLD, bone="UpperTorso", name="brooch"))

    # Head: a strong, stern face; thin dark brows, lined eyes, red lips in a frown, gold earrings.
    head = np.array([0.0, 0.04, 8.8])
    add(ellipsoid(head, (0.56, 0.6, 0.67), color=SKIN, bone="Head", name="cranium"))
    add(ellipsoid((0, -0.13, 8.47), (0.41, 0.46, 0.4), k=0.25, color=SKIN, bone="Head", name="jaw"))
    add(ellipsoid((0, -0.45, 8.22), (0.13, 0.11, 0.11), k=0.12, color=SKIN, bone="Head", name="chin"))
    add(ellipsoid((0, -0.47, 8.92), (0.46, 0.15, 0.1), k=0.15, color=SKIN, bone="Head", name="browRidge"))
    for side in (1, -1):
        add(ellipsoid((side * 0.28, -0.42, 8.64), (0.17, 0.13, 0.11), k=0.15, color=SKIN, bone="Head", name="cheek"))
        add(ellipsoid((side * 0.55, 0.05, 8.7), (0.08, 0.15, 0.2), k=0.06, color=SKIN, bone="Head", name="ear"))
    style.angry_eyes(add, 0.21, -0.48, 8.76, IRIS, LID, BROW, brow_size=(0.22, 0.06, 0.05), brow_tilt=20,
                     brow_lift=0.15, eye_size=(0.155, 0.078, 0.105), wing=True, brow_forward=0.1)
    add(limb((0, -0.6, 8.86), (0, -0.73, 8.6), 0.055, 0.085, k=0.08, color=SKIN, bone="Head", name="nose"))
    for side in (1, -1):
        add(ellipsoid((side * 0.07, -0.67, 8.57), (0.065, 0.05, 0.045), k=0.05, color=SKIN, bone="Head",
                      name="nostril"))

    def lips_color(P):
        x, z = P[:, 0], P[:, 2]
        line = 8.385 - 1.0 * x * x  # the corners turn down: a frown
        out = np.tile(np.asarray(LIP, float), (len(P), 1))
        out[z < line] = LIP_LOW
        out[np.abs(z - line) < 0.012] = MOUTH
        return out

    add(ellipsoid((0, -0.635, 8.41), (0.15, 0.05, 0.035), k=0.03, color=lips_color, bone="Head", name="lips"))
    add(ellipsoid((0, -0.615, 8.35), (0.12, 0.055, 0.04), k=0.03, color=lips_color, bone="Head", name="lips"))
    for side in (1, -1):
        add(sphere((side * 0.57, -0.02, 8.47), 0.06, color=GOLD, bone="Head", name="earring"))
        add(sphere((side * 0.57, -0.02, 8.38), 0.05, color=TEAL, bone="Head", name="earringGem"))

    # Hair: dark, parted in the middle and swept back over the ears into a bun behind the diadem, a lock over each
    # shoulder.
    def hair_disp(P):
        return 0.01 * np.sin(30 * P[:, 0] + 2.0 * P[:, 2])

    def curl_disp(P):
        return 0.025 * np.sin(24 * P[:, 2])

    strands = _hair(30, 0, 2.0)

    def parted(P):
        out = strands(P)
        part = (np.abs(P[:, 0]) < 0.018) & (P[:, 1] < 0.2) & (P[:, 2] > 9.0)
        out[part] *= 0.6
        return out

    hairline = plane_f((0, -0.52, 9.02), (0, -0.6, -0.8))
    cap = sdf.Prim(sdf.f_ellipsoid((0.65, 0.71, 0.76)), head + np.array([0, 0.02, 0.06]), radius=0.85,
                   color=parted, bone="Head", name="hair", clip=(hairline, 0.08), disp=hair_disp, disp_amp=0.02)
    add(cap)
    for side in (1, -1):
        add(ellipsoid((side * 0.49, -0.08, 8.86), (0.23, 0.47, 0.35), R=rot(x=-15), k=0.12, color=_hair(30, 2),
                      bone="Head", name="sweep"))
    bun = ellipsoid((0, 0.64, 9.12), (0.47, 0.38, 0.41), k=0.1, color=_hair(28, 0, 6.0), bone="Head", name="bun")
    add(bun)
    add(shell([bun], 0.04, slab((0, 0.64, 9.12), (0, 1, 0.35), 0.06), color=GOLD, bone="Head", name="bunBand"))
    add(ellipsoid((0, 0.42, 8.3), (0.58, 0.36, 0.66), k=0.15, color=_hair(30, 0), bone="Head", name="hairBack",
                  disp=hair_disp, disp_amp=0.03))
    for side in (1, -1):
        mid = (side * 0.64, -0.24, 7.55)
        add(limb((side * 0.5, 0.0, 8.6), mid, 0.2, 0.16, k=0.12, color=_hair(40, 2), bone="Head", name="lock",
                 disp=curl_disp, disp_amp=0.03))
        add(limb(mid, (side * 0.56, -0.42, 6.95), 0.16, 0.08, k=0.06, color=_hair(40, 2), bone="Head", name="lock",
                 disp=curl_disp, disp_amp=0.03))

    # The diadem: a gold band round her head rising to five points at the front, a purple gem in the middle.
    # It sits on the hair, tilted back like a tiara: higher at the front.
    c, r = head + np.array([0, 0.02, 0.06]), np.array([0.73, 0.79, 0.83])
    add(shell([ellipsoid(c, r)], 0.05, slab((0, 0.05, 9.15), (0, 0.3, 1), 0.08), k=0.02, color=GOLD, bone="Head",
              name="diadem"))
    for angle, height in ((0, 0.34), (25, 0.25), (-25, 0.25), (50, 0.17), (-50, 0.17)):
        t = np.radians(angle)
        z = 9.3
        for _ in range(4):  # where the band's top meets the head's outline at this angle
            f = np.sqrt(max(0.0, 1 - ((z - c[2]) / r[2]) ** 2))
            x, y = r[0] * f * np.sin(t), c[1] - r[1] * f * np.cos(t)
            z = 9.15 - 0.3 * (y - 0.05) + 0.05
        base = np.array([x, y, z]) + 0.04 * np.array([np.sin(t), -np.cos(t), 0])
        add(limb(base, base + np.array([0, 0.05, height]), 0.075, 0.025, k=0.03, color=GOLD, bone="Head",
                 name="point"))
        if angle == 0:
            add(ellipsoid(base + np.array([0, -0.07, -0.06]), (0.1, 0.07, 0.12), color=GEM, bone="Head",
                          name="gem", bias=0.02))
            add(sphere(base + np.array([0, 0.05, height + 0.03]), 0.05, color=TEAL, bone="Head", name="tipGem"))

    # Arms: cap sleeves edged in gold, strong bare arms, a gold armlet and bracelets, fists.
    for side, name in ((1, "Left"), (-1, "Right")):
        sh, el, wr = J[name + "Shoulder"], J[name + "Elbow"], J[name + "Wrist"]
        up = (el - sh) / np.linalg.norm(el - sh)
        fore = (wr - el) / np.linalg.norm(wr - el)
        upper_arm = limb(sh + up * 0.4, el, 0.4, 0.33, color=SKIN, bone=name + "UpperArm", name="upperArm")
        bicep = ellipsoid(sh + up * 0.95 + np.array([0, -0.12, 0]), (0.31, 0.27, 0.42), R=look_rot(up), k=0.25,
                          color=SKIN, bone=name + "UpperArm", name="bicep")
        add(upper_arm)
        add(bicep)
        # A puffed cap sleeve, gathered by a gold band.
        sleeve = ellipsoid(sh + up * 0.22 + np.array([0, 0, 0.04]), (0.5, 0.47, 0.42), R=look_rot(up), k=0.18,
                           color=GOWN, bone=name + "UpperArm", name="sleeve", reach=0.3)
        add(sleeve)
        add(shell([upper_arm], 0.06, slab(sh + up * 0.6, up, 0.06), color=GOLD, bone=name + "UpperArm", name="trim"))
        add(shell([upper_arm, bicep], 0.05, slab(sh + up * 1.02, up, 0.07), color=GOLD, bone=name + "UpperArm",
                  name="armlet"))
        forearm = limb(el, wr, 0.34, 0.25, color=SKIN, bone=name + "LowerArm", name="forearm", reach=0.2)
        muscle = ellipsoid(el + fore * 0.4 + np.array([0, -0.05, 0]), (0.32, 0.29, 0.42), R=look_rot(fore), k=0.2,
                           color=SKIN, bone=name + "LowerArm", name="forearmMuscle")
        add(forearm)
        add(muscle)
        add(shell([forearm, muscle], 0.05, slab(el + fore * 1.18, fore, 0.13), color=GOLD, bone=name + "LowerArm",
                  name="bracelet"))
        style.fist(add, name, wr, fore, SKIN, size=(0.31, 0.27, 0.35), knuckle=0.085)

        # Legs under the gown (they carry the weights and the feet), gold sandals peeping out.
        hp, kn, an, to = J[name + "Hip"], J[name + "Knee"], J[name + "Ankle"], J[name + "Toe"]
        add(limb(hp + np.array([0, 0, -0.25]), kn, 0.5, 0.42, color=GOWN, bone=name + "UpperLeg", name="thigh",
                 reach=0.2))
        add(limb(kn, an, 0.4, 0.26, k=0.15, color=SKIN, bone=name + "LowerLeg", name="shin", reach=0.2))
        foot = ellipsoid((to + an) / 2 + np.array([0, 0.06, -0.06]), (0.26, 0.52, 0.2), k=0.15, color=SKIN,
                         bone=name + "Foot", name="foot", reach=0.15)
        add(foot)
        add(box((an[0], -0.28, 0.08), (0.3, 0.62, 0.08), round_=0.05, color=SOLE, bone=name + "Foot", name="sole"))
        add(shell([foot], 0.04, slab(an + (to - an) * 0.5, (0, 1, 0.6), 0.06), color=GOLD, bone=name + "Foot",
                  name="footStrap"))
    return S


BONES = style.bones()

BOUNDS = ((-4.0, -1.8, -0.05), (4.0, 1.9, 10.0))


def reweight(prims, P, who, names, W):
    """The gown hangs from the hips and follows each leg towards the hem, a little of the shin below the knee so the
    hem keeps up with the feet; the cape hangs from the shoulders, its foot following the hips."""
    W = style.follow_legs(prims, P, who, names, W, "gown", 4.9, HEM, share=0.85, knee=2.6, knee_share=0.35)
    cape = [n for n, p in enumerate(prims) if p.name == "cape"]
    sel = np.isin(who, cape)
    w = np.clip((P[sel, 2] - 4.0) / 2.8, 0, 1)
    W[sel] = 0
    W[sel, names.index("UpperTorso")] = w
    W[sel, names.index("LowerTorso")] = 1 - w
    return W


# The head's UV islands get this much more texture than their size would, for the painted eyes and lips.
FACE_ABOVE = 7.9
FACE_UV_SCALE = 1.7


def detail(J):
    """Where decimation keeps more triangles: (centre, radius, weight)."""
    spots = [((0, -0.45, 8.65), 0.5, 1.0), ((0, -0.2, 9.45), 0.6, 0.6)]  # face, diadem
    for name in ("Left", "Right"):
        spots.append(((J[name + "Wrist"] + J[name + "Fist"]) / 2, 0.4, 0.5))
    return spots


DETAIL_FACTOR = 8.0

# How she walks: the sceptre carried upright in front of her (Zeus raises his bolt).
WALK_RIGHT = "carry"
