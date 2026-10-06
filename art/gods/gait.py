# The gods' walk and run, as functions of the cycle's phase (0-1), so the same numbers can drive Roblox Bones later.
# Rotations are in the rig's axes, carried by the parent bone: X across (his left +X), Y backwards, Z up.
#   Rx(-a) swings a hanging limb forward, Rx(+a) bends a knee (foot back) or leans the torso forward,
#   Rz(+a) turns the left side backwards, Ry(+a) brings his left arm in (his right arm out).
# The pose is then grounded: the body drops so the lowest sole touches the floor, which gives the bob for free.
import math

import bpy
from mathutils import Quaternion, Vector

WALK_FRAMES = 28  # at 24 fps: a heavy, deliberate stride
RUN_FRAMES = 16


def Rx(deg):
    return Quaternion((1, 0, 0), math.radians(deg))


def Ry(deg):
    return Quaternion((0, 1, 0), math.radians(deg))


def Rz(deg):
    return Quaternion((0, 0, 1), math.radians(deg))


def _legs(rot, p, thigh_mid, thigh_amp, knee_rest, knee_amp, push):
    for side, offset in (("Left", 0.0), ("Right", 0.5)):
        a = 2 * math.pi * (p + offset)
        s, c = math.sin(a), math.cos(a)
        thigh = thigh_mid + thigh_amp * s
        knee = knee_rest + knee_amp * max(0.0, c) ** 1.3
        toe = push * max(0.0, -s) * max(0.0, c + 0.3)
        rot[side + "UpperLeg"] = Rx(-thigh)
        rot[side + "LowerLeg"] = Rx(knee)
        rot[side + "Foot"] = Rx(thigh - knee + toe)


def walk(p, right="raise"):
    """A heavy, angry stride. right: "raise" holds the right fist up (Zeus's bolt), "carry" holds it in front, the
    forearm forward (a sceptre carried upright)."""
    rot = {}
    s = math.sin(2 * math.pi * p)
    c4 = math.cos(4 * math.pi * p)
    _legs(rot, p, 3, 24, 6, 42, 18)
    rot["LowerTorso"] = Rz(-6 * s) @ Rx(2)
    rot["UpperTorso"] = Rz(13 * s) @ Rx(6 + 1.5 * c4)
    rot["Head"] = Rz(-7 * s) @ Rx(-6)
    rot["LeftUpperArm"] = Rx(20 * s) @ Ry(18)
    rot["LeftLowerArm"] = Rx(-(18 + 14 * max(0.0, -s)))
    rot["LeftHand"] = Rx(-6)
    if right == "carry":
        rot["RightUpperArm"] = Rx(-14 + 2 * c4) @ Ry(-12)
        rot["RightLowerArm"] = Rx(-72)
    else:
        rot["RightUpperArm"] = Rx(-22 + 3 * c4) @ Ry(40)
        rot["RightLowerArm"] = Ry(100) @ Rx(-10)
    rot["RightHand"] = Rx(-8)
    return rot


def run(p):
    """A charging sprint, leaning in, fists pumping, the bolt carried forward."""
    rot = {}
    s = math.sin(2 * math.pi * p)
    _legs(rot, p, 12, 42, 22, 82, 28)
    rot["LowerTorso"] = Rz(-8 * s) @ Rx(8)
    rot["UpperTorso"] = Rz(18 * s) @ Rx(12)
    rot["Head"] = Rz(-9 * s) @ Rx(-18)
    rot["LeftUpperArm"] = Rx(40 * s) @ Ry(22)
    rot["LeftLowerArm"] = Rx(-(78 + 12 * s))
    rot["RightUpperArm"] = Rx(-40 * s) @ Ry(-22)
    rot["RightLowerArm"] = Rx(-(78 - 12 * s))
    rot["LeftHand"] = Rx(-10)
    rot["RightHand"] = Rx(-70)  # the bolt stays upright, not pointed ahead like a spear
    return rot


def _sole_points(rig):
    """Heel and toe of each sole in the rest pose, in rig space."""
    pts = {}
    for side in ("Left", "Right"):
        foot = rig.data.bones[side + "Foot"]
        ankle = foot.head_local
        toe = foot.tail_local
        pts[side] = [Vector((ankle.x, ankle.y + 0.42, 0.0)), Vector((toe.x, -1.0, 0.0)),
                     Vector((ankle.x + 0.3, -0.3, 0.0)), Vector((ankle.x - 0.3, -0.3, 0.0))]
    return pts


def pose(rig, rot, lift=0.0):
    """Sets the rig to a pose from rotations in rig axes, grounded so the lowest sole is on the floor (plus lift)."""
    for pb in rig.pose.bones:
        pb.rotation_mode = "QUATERNION"
        rest = pb.bone.matrix_local.to_quaternion()
        q = rot.get(pb.name, Quaternion())
        pb.rotation_quaternion = rest.inverted() @ q @ rest
        pb.location = (0, 0, 0)
    bpy.context.view_layer.update()
    lowest = math.inf
    contact = None
    for side, pts in _sole_points(rig).items():
        pb = rig.pose.bones[side + "Foot"]
        m = pb.matrix @ pb.bone.matrix_local.inverted()
        for v in pts:
            w = m @ v
            if w.z < lowest:
                lowest, contact = w.z, w.copy()
    hips = rig.pose.bones["LowerTorso"]
    rest = hips.bone.matrix_local.to_quaternion()
    hips.location = rest.inverted() @ Vector((0, 0, -lowest + lift))
    bpy.context.view_layer.update()
    upright(rig, "RightHand")
    return contact


BOLT_UP = Vector((0, -0.18, 1)).normalized()  # the held symbol points up and a little ahead, whatever the arm does


def upright(rig, name, direction=BOLT_UP):
    """Turns a hand so it (and what it holds) points along `direction` in the rig, the shortest way round."""
    pb = rig.pose.bones[name]
    parent = pb.parent
    carried = (parent.matrix @ parent.bone.matrix_local.inverted()).to_quaternion()
    rest_dir = (pb.bone.tail_local - pb.bone.head_local).normalized()
    q = rest_dir.rotation_difference(carried.inverted() @ direction)
    rest = pb.bone.matrix_local.to_quaternion()
    pb.rotation_quaternion = rest.inverted() @ q @ rest
    bpy.context.view_layer.update()


def bake(rig, name, fn, frames, lift=None):
    """Keys one cycle of fn as an action (looping), and returns its ground speed in studs per frame: how fast the
    planted foot slides back, which the body has to move forward to keep it planted."""
    action = bpy.data.actions.get(name)
    if action is not None:
        bpy.data.actions.remove(action)
    rig.animation_data_create()
    action = bpy.data.actions.new(name)
    rig.animation_data.action = action
    contacts = []
    for f in range(frames + 1):
        p = f / frames
        contacts.append(pose(rig, fn(p), lift(p) if lift else 0.0))
        for pb in rig.pose.bones:
            pb.keyframe_insert("rotation_quaternion", frame=f + 1)
            pb.keyframe_insert("location", frame=f + 1)
    # Ground speed: the contact point's backward travel while the same foot stays down.
    travel = 0.0
    for a, b in zip(contacts, contacts[1:]):
        if (a - b).length < 1.5:
            travel += max(0.0, b.y - a.y)
    action.use_cyclic = True
    action.use_frame_range = True
    action.frame_start = 1
    action.frame_end = frames
    return travel / frames


def bake_speed(rig, fn, frames, lift=None):
    """The cycle's ground speed in studs per frame, without keying anything."""
    contacts = [pose(rig, fn(f / frames), lift(f / frames) if lift else 0.0) for f in range(frames + 1)]
    travel = 0.0
    for a, b in zip(contacts, contacts[1:]):
        if (a - b).length < 1.5:
            travel += max(0.0, b.y - a.y)
    return travel / frames


def run_lift(p):
    """A little flight between strides."""
    return 0.25 * max(0.0, math.sin(4 * math.pi * (p - 0.06))) ** 2
