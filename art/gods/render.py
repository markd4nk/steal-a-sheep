# Mock-up renders of a rigged god: the neon bolt in his fist (as the game's neon blocks), a floor, stills and a
# walk-then-run clip. Only for showing the user; the game gets the mesh, rig and texture.
import glob
import math
import os
import shutil
import subprocess

import bpy
from mathutils import Matrix, Quaternion, Vector

import gait

BOLT = [(0.6, 2.3), (-0.35, 0.25), (0.5, 0.25), (-0.55, -2.3)]  # the game's neon bolt, 4.6 tall at scale 1
BOLT_WIDTHS = [0.62, 0.55, 0.5]
BOLT_COLOR = (1.0, 0.76, 0.06, 1)  # 255, 226, 70 in linear
# Blender's own PATH may miss a winget ffmpeg.
FFMPEG = next(iter(glob.glob(os.path.expandvars(
    r"%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg*\ffmpeg-*\bin\ffmpeg.exe"))), "ffmpeg")


def _emission(name, color, strength):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    for n in list(nodes):
        nodes.remove(n)
    out = nodes.new("ShaderNodeOutputMaterial")
    em = nodes.new("ShaderNodeEmission")
    em.inputs[0].default_value = color
    em.inputs[1].default_value = strength
    mat.node_tree.links.new(em.outputs[0], out.inputs[0])
    return mat


def bolt(rig, height=5.0, up=1.15, forward=0.12):
    """The neon bolt held in the right fist, along the forearm, its lower part in the grip."""
    for o in [o for o in bpy.data.objects if o.name.startswith("Bolt")]:
        bpy.data.objects.remove(o, do_unlink=True)
    rig.data.pose_position = "REST"
    bpy.context.view_layer.update()
    hand = rig.data.bones["RightHand"]
    frame = rig.matrix_world @ hand.matrix_local  # Y along the hand, X across, Z forward
    k = height / 4.6
    mat = _emission("BoltNeon", BOLT_COLOR, 2.2)
    for n, (a, b) in enumerate(zip(BOLT, BOLT[1:])):
        a = Vector((a[0] * k, a[1] * k))
        b = Vector((b[0] * k, b[1] * k))
        mid = (a + b) / 2
        d = b - a
        length = d.length + BOLT_WIDTHS[n] * 0.5
        angle = math.atan2(d.x, d.y)
        bpy.ops.mesh.primitive_cube_add(size=1)
        o = bpy.context.active_object
        o.name = f"Bolt{n + 1}"
        o.data.materials.append(mat)
        local = (Matrix.Translation((mid.x, up + mid.y, forward)) @ Matrix.Rotation(-angle, 4, "Z")
                 @ Matrix.Diagonal((BOLT_WIDTHS[n] * k, length, 0.45 * k, 1)))
        world = frame @ local
        o.parent = rig
        o.parent_type = "BONE"
        o.parent_bone = "RightHand"
        o.matrix_world = world
    rig.data.pose_position = "POSE"
    bpy.context.view_layer.update()


def stage():
    """A floor of marble tiles, sky-blue world, sun and fill."""
    sc = bpy.context.scene
    floor = bpy.data.objects.get("Floor")
    if floor is None:
        bpy.ops.mesh.primitive_plane_add(size=400)
        floor = bpy.context.active_object
        floor.name = "Floor"
    mat = bpy.data.materials.get("FloorTiles") or bpy.data.materials.new("FloorTiles")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    for n in list(nodes):
        nodes.remove(n)
    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    checker = nodes.new("ShaderNodeTexChecker")
    coord = nodes.new("ShaderNodeTexCoord")
    mapping = nodes.new("ShaderNodeMapping")
    mapping.inputs["Scale"].default_value = (40, 40, 40)
    checker.inputs["Color1"].default_value = (0.5, 0.48, 0.45, 1)
    checker.inputs["Color2"].default_value = (0.38, 0.36, 0.34, 1)
    links = mat.node_tree.links
    links.new(coord.outputs["UV"], mapping.inputs[0])
    links.new(mapping.outputs[0], checker.inputs[0])
    links.new(checker.outputs[0], bsdf.inputs[0])
    links.new(bsdf.outputs[0], out.inputs[0])
    bsdf.inputs["Roughness"].default_value = 0.8
    floor.data.materials.clear()
    floor.data.materials.append(mat)
    w = sc.world
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs[0].default_value = (0.42, 0.62, 0.9, 1)
    bg.inputs[1].default_value = 0.7
    try:
        sc.eevee.use_shadows = True
    except AttributeError:
        pass
    return floor


def aim(target, direction, distance, lens=50):
    cam = bpy.data.objects["Camera"]
    t = Vector(target)
    d = Vector(direction).normalized()
    cam.location = t + d * distance
    cam.rotation_euler = (t - cam.location).to_track_quat("-Z", "Y").to_euler()
    cam.data.lens = lens
    bpy.context.scene.camera = cam


def still(path, size=(1200, 1200)):
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = size
    sc.render.image_settings.file_format = "PNG"
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)


def demo(rig, folder, walk_cycles=2, run_cycles=3, blend=8, size=(960, 720), start=0, stop=None):
    """Walk then run across the floor, the camera following, rendered to PNGs (frames start to stop, so a long
    clip can go in several calls); encode() makes the mp4. Returns the clip's frame count."""
    os.makedirs(folder, exist_ok=True)
    sc = bpy.context.scene
    sc.render.resolution_x, sc.render.resolution_y = size
    sc.render.image_settings.file_format = "PNG"
    if rig.animation_data:
        rig.animation_data.action = None
    walk_speed = gait.bake_speed(rig, gait.walk, gait.WALK_FRAMES)
    run_speed = gait.bake_speed(rig, gait.run, gait.RUN_FRAMES, gait.run_lift)
    walk_len = walk_cycles * gait.WALK_FRAMES
    total = walk_len + blend + run_cycles * gait.RUN_FRAMES
    phase, y = 0.0, 0.0
    root = rig.pose.bones["Root"]
    stop = total if stop is None else min(stop, total)
    for f in range(stop):
        t = min(max((f - walk_len) / blend, 0.0), 1.0)
        t = t * t * (3 - 2 * t)
        rate = (1 - t) / gait.WALK_FRAMES + t / gait.RUN_FRAMES
        speed = (1 - t) * walk_speed + t * run_speed
        if f >= start:
            a, b = gait.walk(phase % 1.0), gait.run(phase % 1.0)
            rot = {k: a.get(k, Quaternion()).slerp(b.get(k, Quaternion()), t) for k in set(a) | set(b)}
            gait.pose(rig, rot, t * gait.run_lift(phase % 1.0))
            rest = root.bone.matrix_local.to_quaternion()
            root.location = rest.inverted() @ Vector((0, -y, 0))
            bpy.context.view_layer.update()
            aim((0, -y - 0.5, 4.6), (1.0, -0.75, 0.1), 23, 50)
            sc.render.filepath = os.path.join(folder, f"f{f:04d}.png")
            bpy.ops.render.render(write_still=True)
        phase += rate
        y += speed
    return total


def encode(folder):
    mp4 = os.path.join(folder, "demo.mp4")
    ffmpeg = shutil.which("ffmpeg") or os.path.expandvars(FFMPEG)
    subprocess.run([ffmpeg, "-y", "-framerate", "24", "-i", os.path.join(folder, "f%04d.png"), "-c:v", "libx264",
                    "-pix_fmt", "yuv420p", "-crf", "20", mp4], check=True, capture_output=True)
    return mp4
